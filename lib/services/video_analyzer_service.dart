import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';

class VideoMetadata {
  final Duration duration;
  final int width;
  final int height;
  final double fps;
  final bool hasAudio;

  const VideoMetadata({
    required this.duration,
    required this.width,
    required this.height,
    required this.fps,
    required this.hasAudio,
  });

  bool get isVertical => height > width;
}

class CutBoundary {
  final Duration start;
  final Duration end;
  final double confidence; // 1.0 for detected scene/silence, 0.5 for interval fallback

  const CutBoundary({
    required this.start,
    required this.end,
    this.confidence = 0.5,
  });

  Duration get duration => end - start;
}

class VideoAnalyzerService {
  /// Extract video metadata including duration, dimensions, framerate, and audio track
  static Future<VideoMetadata> probeVideo(String videoPath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(videoPath);
      final info = session.getMediaInformation();

      if (info == null) {
        // Fallback default if probe returns null
        return const VideoMetadata(
          duration: Duration(seconds: 60),
          width: 1920,
          height: 1080,
          fps: 30.0,
          hasAudio: true,
        );
      }

      final durationSec = double.tryParse(info.getDuration() ?? '0') ?? 0.0;
      final duration = Duration(milliseconds: (durationSec * 1000).toInt());

      int width = 1920;
      int height = 1080;
      double fps = 30.0;
      bool hasAudio = false;

      final streams = info.getStreams();
      for (final stream in streams) {
        final type = stream.getType();
        if (type == 'video') {
          width = stream.getWidth() ?? width;
          height = stream.getHeight() ?? height;
          final rFrameRate = stream.getRealFrameRate();
          if (rFrameRate != null && rFrameRate.contains('/')) {
            final parts = rFrameRate.split('/');
            final num = double.tryParse(parts[0]) ?? 30.0;
            final den = double.tryParse(parts[1]) ?? 1.0;
            fps = den > 0 ? num / den : 30.0;
          }
        } else if (type == 'audio') {
          hasAudio = true;
        }
      }

      return VideoMetadata(
        duration: duration,
        width: width,
        height: height,
        fps: fps,
        hasAudio: hasAudio,
      );
    } catch (e) {
      // Graceful fallback
      return const VideoMetadata(
        duration: Duration(seconds: 60),
        width: 1920,
        height: 1080,
        fps: 30.0,
        hasAudio: true,
      );
    }
  }

  /// Analyze video to detect natural scene boundaries, silence pauses, and black frame intervals
  static Future<List<double>> detectNaturalCutPoints(
    String videoPath, {
    Duration? maxAnalyzeDuration,
  }) async {
    final candidatePoints = <double>[];

    try {
      // Use FFmpeg scene detection filter and silencedetect
      // select='gt(scene,0.3)' detects major visual scene changes
      // silencedetect finds pauses in speech/audio
      final command =
          "-i \"$videoPath\" -filter_complex \"[0:v]select='gt(scene,0.3)',showinfo[v_out];[0:a]silencedetect=noise=-30dB:d=0.4[a_out]\" "
          "-map \"[v_out]\" -map \"[a_out]\" -f null -";

      final session = await FFmpegKit.execute(command);
      final logs = await session.getAllLogsAsString();

      if (logs != null) {
        // Parse showinfo pts_time
        final ptsRegex = RegExp(r'pts_time:([0-9]+\.?[0-9]*)');
        for (final match in ptsRegex.allMatches(logs)) {
          final timeStr = match.group(1);
          if (timeStr != null) {
            final t = double.tryParse(timeStr);
            if (t != null && t > 1.0) {
              candidatePoints.add(t);
            }
          }
        }

        // Parse silencedetect silence_end
        final silenceRegex = RegExp(r'silence_end:\s*([0-9]+\.?[0-9]*)');
        for (final match in silenceRegex.allMatches(logs)) {
          final timeStr = match.group(1);
          if (timeStr != null) {
            final t = double.tryParse(timeStr);
            if (t != null && t > 1.0) {
              candidatePoints.add(t);
            }
          }
        }
      }
    } catch (_) {
      // If native scene probe is unavailable, fall back smoothly
    }

    // Sort and deduplicate cut points within 1 second of each other
    candidatePoints.sort();
    final uniquePoints = <double>[];
    for (final pt in candidatePoints) {
      if (uniquePoints.isEmpty || (pt - uniquePoints.last).abs() > 1.5) {
        uniquePoints.add(pt);
      }
    }

    return uniquePoints;
  }

  /// Calculates optimal clip cut boundaries around target duration.
  /// Allowed target durations: 20s, 25s, 30s. Maximum clip duration: 30.0s.
  /// Snaps to natural scene changes or silence pauses within a tolerance window.
  static List<CutBoundary> calculateOptimalCuts({
    required Duration totalDuration,
    required int targetDurationSeconds,
    List<double> naturalCutPoints = const [],
  }) {
    final totalSec = totalDuration.inMilliseconds / 1000.0;
    if (totalSec <= 10.0) {
      // Entire video is very short, keep as single clip
      return [
        CutBoundary(
          start: Duration.zero,
          end: totalDuration,
          confidence: 1.0,
        ),
      ];
    }

    final targetSec = targetDurationSeconds.toDouble();
    const maxClipSec = 30.0; // Strict requirement: maximum clip duration is 30s
    const minClipSec = 10.0;

    final cuts = <CutBoundary>[];
    double currentStart = 0.0;

    while (currentStart < totalSec) {
      final idealEnd = currentStart + targetSec;
      final remaining = totalSec - currentStart;

      // If remaining time is shorter than minClipSec, handle final segment
      if (remaining <= maxClipSec) {
        if (remaining >= minClipSec || cuts.isEmpty) {
          cuts.add(CutBoundary(
            start: Duration(milliseconds: (currentStart * 1000).toInt()),
            end: Duration(milliseconds: (totalSec * 1000).toInt()),
            confidence: 0.8,
          ));
        } else {
          // If less than 10 seconds remaining and we have a previous clip,
          // extend previous clip if within 30s limit
          final lastCut = cuts.last;
          final combinedDuration = (totalSec - (lastCut.start.inMilliseconds / 1000.0));
          if (combinedDuration <= maxClipSec) {
            cuts[cuts.length - 1] = CutBoundary(
              start: lastCut.start,
              end: Duration(milliseconds: (totalSec * 1000).toInt()),
              confidence: lastCut.confidence,
            );
          } else {
            // Keep as separate clip
            cuts.add(CutBoundary(
              start: Duration(milliseconds: (currentStart * 1000).toInt()),
              end: Duration(milliseconds: (totalSec * 1000).toInt()),
              confidence: 0.5,
            ));
          }
        }
        break;
      }

      // Tolerance window around target: [currentStart + targetSec - 3.5s, currentStart + targetSec + 3.0s]
      // Capped so duration never exceeds 30.0s and never below 12.0s
      final minAllowedEnd = currentStart + 12.0;
      final maxAllowedEnd = (currentStart + maxClipSec).clamp(minAllowedEnd, totalSec);
      final searchWindowStart = (idealEnd - 3.5).clamp(minAllowedEnd, maxAllowedEnd);
      final searchWindowEnd = (idealEnd + 3.0).clamp(minAllowedEnd, maxAllowedEnd);

      // Find candidate natural cut point closest to idealEnd within window
      double? bestCut;
      double minDiff = double.infinity;

      for (final pt in naturalCutPoints) {
        if (pt >= searchWindowStart && pt <= searchWindowEnd) {
          final diff = (pt - idealEnd).abs();
          if (diff < minDiff) {
            minDiff = diff;
            bestCut = pt;
          }
        }
      }

      final chosenEnd = bestCut ?? idealEnd.clamp(minAllowedEnd, maxAllowedEnd);
      final confidence = bestCut != null ? 0.95 : 0.6;

      cuts.add(CutBoundary(
        start: Duration(milliseconds: (currentStart * 1000).toInt()),
        end: Duration(milliseconds: (chosenEnd * 1000).toInt()),
        confidence: confidence,
      ));

      currentStart = chosenEnd;
    }

    return cuts;
  }
}
