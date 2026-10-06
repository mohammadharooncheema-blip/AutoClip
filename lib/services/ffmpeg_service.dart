import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:autoclip/models/app_settings.dart';
import 'package:autoclip/models/clip_segment.dart';
import 'package:autoclip/models/editing_style.dart';
import 'package:autoclip/services/caption_service.dart';

typedef ProgressCallback = void Function(double progressFraction);

class FFmpegService {
  static int? _activeSessionId;

  /// Cancel any ongoing video rendering session immediately
  static Future<void> cancelActiveSession() async {
    if (_activeSessionId != null) {
      await FFmpegKit.cancel(_activeSessionId!);
      _activeSessionId = null;
    } else {
      await FFmpegKit.cancel();
    }
  }

  /// Render a single clip segment from the source video applying the selected style preset
  static Future<File> renderClip({
    required String sourceVideoPath,
    required ClipSegment clip,
    required AppSettings settings,
    ProgressCallback? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final outputFileName = 'render_${clip.id}_${clip.fileName}';
    final outputFile = File(p.join(tempDir.path, outputFileName));

    if (await outputFile.exists()) {
      await outputFile.delete();
    }

    final outWidth = settings.quality.width;
    final outHeight = settings.quality.height;
    final durationSec = clip.duration.inMilliseconds / 1000.0;
    final startSec = clip.startTime.inMilliseconds / 1000.0;

    // 1. Build Subtitles if enabled
    File? subtitleFile;
    if (settings.captionsEnabled) {
      subtitleFile = await CaptionService.generateSubtitleFile(
        clipId: clip.id,
        style: clip.style,
        duration: clip.duration,
      );
    }

    // 2. Build Video Filter Graph
    final filterGraph = _buildFilterGraph(
      style: clip.style,
      outWidth: outWidth,
      outHeight: outHeight,
      subtitleFile: subtitleFile,
    );

    // 3. Build Audio Filter
    final audioFilter = _buildAudioFilter(style: clip.style);

    // 4. Construct complete FFmpeg CLI command
    // Using fast seek -ss before -i and accurate duration -t
    final command = StringBuffer();
    command.write('-ss ${startSec.toStringAsFixed(3)} ');
    command.write('-t ${durationSec.toStringAsFixed(3)} ');
    command.write('-i "$sourceVideoPath" ');

    if (filterGraph.isNotEmpty) {
      command.write('-vf "$filterGraph" ');
    }

    if (audioFilter.isNotEmpty) {
      command.write('-af "$audioFilter" ');
    }

    // Video encoding parameters
    command.write('-c:v libx264 -preset veryfast -crf 22 -pix_fmt yuv420p ');
    command.write('-b:v ${settings.quality.videoBitrate} -maxrate ${settings.quality.videoBitrate} -bufsize 10M ');

    // Audio encoding parameters
    command.write('-c:a aac -b:a 192k -ar 44100 ');

    // Web optimization & fast streaming flags
    command.write('-movflags +faststart -y "${outputFile.path}"');

    final completer = Completer<File>();

    final session = await FFmpegKit.executeAsync(
      command.toString(),
      (session) async {
        _activeSessionId = null;
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          completer.complete(outputFile);
        } else if (ReturnCode.isCancel(returnCode)) {
          completer.completeError(Exception('Clip rendering was cancelled by user'));
        } else {
          final logs = await session.getAllLogsAsString();
          completer.completeError(
            Exception('FFmpeg failed with return code $returnCode: $logs'),
          );
        }
      },
      (log) {
        // Log stream
      },
      (statistics) {
        final timeMs = statistics.getTime();
        if (timeMs > 0 && durationSec > 0) {
          final progress = (timeMs / (durationSec * 1000.0)).clamp(0.0, 1.0);
          onProgress?.call(progress);
        }
      },
    );

    _activeSessionId = session.getSessionId();

    return completer.future;
  }

  /// Builds the 9:16 vertical crop, style-specific zoom, color grading, and subtitle filtergraph
  static String _buildFilterGraph({
    required EditingStyle style,
    required int outWidth,
    required int outHeight,
    File? subtitleFile,
  }) {
    final filters = <String>[];

    // Intelligent 9:16 vertical crop without stretching
    // First crop to 9:16 aspect ratio preserving center action
    filters.add("crop=w='min(iw,ih*9/16)':h='min(ih,iw*16/9)':x='(iw-ow)/2':y='(ih-oh)/2'");

    // Scale to target vertical resolution
    filters.add('scale=$outWidth:$outHeight:flags=lanczos');

    // Style-specific camera motion & zoom effects
    switch (style.zoomMode) {
      case 'subtle':
        // Slow subtle zoom from 1.00 to 1.05
        filters.add(
          "zoompan=z='min(zoom+0.0004,1.05)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=${outWidth}x$outHeight:fps=30",
        );
        break;

      case 'fast':
        // Punchy pacing zoom with periodic reset
        filters.add(
          "zoompan=z='1.0+0.10*mod(in,75)/75':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=${outWidth}x$outHeight:fps=30",
        );
        break;

      case 'punch':
        // Gaming punch zoom on action beats (every 4 seconds)
        filters.add(
          "zoompan=z='if(between(mod(time,4),0,0.45),1.15,1.0)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=${outWidth}x$outHeight:fps=30",
        );
        break;

      case 'smooth_wave':
        // Smooth sine-wave oscillating zoom (1.0 to 1.07)
        filters.add(
          "zoompan=z='1.035+0.035*sin(2*PI*time/5)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=${outWidth}x$outHeight:fps=30",
        );
        break;

      case 'static':
      default:
        // No extra zoom for minimal preset
        break;
    }

    // Color grading & adjustments
    if (style.colorFilter.isNotEmpty) {
      filters.add(style.colorFilter);
    }

    // Subtitle overlay
    if (subtitleFile != null && subtitleFile.existsSync()) {
      // Escape Windows path backslashes for FFmpeg filter syntax
      final escapedSubPath = subtitleFile.path.replaceAll('\\', '/').replaceAll(':', '\\:');
      filters.add("ass='$escapedSubPath'");
    }

    return filters.join(',');
  }

  /// Audio filter for loudness normalization and punchy sound
  static String _buildAudioFilter({required EditingStyle style}) {
    final filters = <String>[];

    if (style.playbackSpeed > 1.0) {
      filters.add('atempo=${style.playbackSpeed.toStringAsFixed(2)}');
    }

    if (style.enableAudioEnhance) {
      // EBU R128 loudness normalization for broadcast-quality mobile audio
      filters.add('loudnorm=I=-16:TP=-1.5:LRA=11');
    }

    if (style.type == StyleType.gaming) {
      // Slight bass boost for gaming impacts
      filters.add('bass=g=3:f=110');
    }

    return filters.join(',');
  }

  /// Generate a high-quality video thumbnail for preview in results screen
  static Future<String> generateThumbnail(String videoPath, String clipId) async {
    final tempDir = await getTemporaryDirectory();
    final thumbPath = p.join(tempDir.path, 'thumb_$clipId.jpg');

    final command = '-ss 00:00:01.000 -i "$videoPath" -vframes 1 -q:v 2 -y "$thumbPath"';
    await FFmpegKit.execute(command);

    return thumbPath;
  }
}
