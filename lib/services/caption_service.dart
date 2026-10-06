import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:autoclip/models/editing_style.dart';

class CaptionService {
  /// Generate styled ASS (Advanced SubStation Alpha) subtitle file tailored for the selected editing style.
  /// This ensures safe margins (>120px from bottom) for vertical 9:16 mobile videos,
  /// high readability, and style-specific aesthetic typography.
  static Future<File> generateSubtitleFile({
    required String clipId,
    required EditingStyle style,
    required Duration duration,
    List<String>? wordsOrPhrases,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final subFile = File(p.join(tempDir.path, 'captions_${clipId}_${style.id}.ass'));

    final assContent = _buildAssSubtitleContent(
      style: style,
      duration: duration,
      wordsOrPhrases: wordsOrPhrases,
    );

    await subFile.writeAsString(assContent);
    return subFile;
  }

  static String _buildAssSubtitleContent({
    required EditingStyle style,
    required Duration duration,
    List<String>? wordsOrPhrases,
  }) {
    // Style-specific styling definitions
    // PlayResX=1080, PlayResY=1920 (Native 9:16 vertical)
    String fontName = 'Arial';
    int fontSize = 52;
    String primaryColour = '&H00FFFFFF'; // Default White (AABBGGRR)
    String outlineColour = '&H00000000'; // Default Black
    String backColour = '&H80000000'; // Translucent box
    int bold = 1;
    int outline = 3;
    int shadow = 2;
    int marginV = 220; // Safe area well above bottom navigation / social UI

    switch (style.type) {
      case StyleType.clean:
        fontName = 'Roboto';
        fontSize = 54;
        primaryColour = '&H00FFFFFF'; // Crisp white
        outlineColour = '&H00101010'; // Soft dark stroke
        backColour = '&H90101018'; // Rounded dark translucent backdrop
        bold = 1;
        outline = 2;
        shadow = 1;
        marginV = 240;
        break;

      case StyleType.fast:
        fontName = 'Impact';
        fontSize = 64;
        primaryColour = '&H0000E5FF'; // Vibrant electric yellow/cyan
        outlineColour = '&H00000000'; // Pure black heavy outline
        bold = 1;
        outline = 5;
        shadow = 3;
        marginV = 260;
        break;

      case StyleType.gaming:
        fontName = 'Arial Black';
        fontSize = 62;
        primaryColour = '&H0050FA7B'; // Neon Lime/Cyan
        outlineColour = '&H00000000'; // Bold dark border
        backColour = '&H60300060'; // Deep purple accent shadow
        bold = 1;
        outline = 6;
        shadow = 4;
        marginV = 230;
        break;

      case StyleType.dynamicStyle:
        fontName = 'Montserrat';
        fontSize = 58;
        primaryColour = '&H00FFFFFF';
        outlineColour = '&H007F00FF'; // Neon purple outline
        bold = 1;
        outline = 4;
        shadow = 2;
        marginV = 250;
        break;

      case StyleType.minimal:
        fontName = 'Helvetica';
        fontSize = 46;
        primaryColour = '&H00E0E0E0'; // Muted soft white
        outlineColour = '&H00181818';
        backColour = '&HA0000000';
        bold = 0;
        outline = 2;
        shadow = 0;
        marginV = 200;
        break;
    }

    final header = '''[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: AutoClipStyle,$fontName,$fontSize,$primaryColour,&H000000FF,$outlineColour,$backColour,$bold,0,0,0,100,100,0,0,1,$outline,$shadow,2,80,80,$marginV,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
''';

    final totalSeconds = duration.inMilliseconds / 1000.0;
    final eventsBuffer = StringBuffer(header);

    // Default engaging captions or transcribed lines
    final sampleLines = wordsOrPhrases ?? _getDefaultCaptionsForStyle(style.type);
    final lineDuration = 3.2; // Show each phrase for ~3.2 seconds
    double currentTime = 0.8; // Initial safe delay

    int index = 0;
    while (currentTime + 1.5 < totalSeconds && index < sampleLines.length) {
      final line = sampleLines[index % sampleLines.length];
      final endTime = (currentTime + lineDuration).clamp(0.0, totalSeconds - 0.2);

      final startStr = _formatAssTimestamp(currentTime);
      final endStr = _formatAssTimestamp(endTime);

      eventsBuffer.writeln(
        'Dialogue: 0,$startStr,$endStr,AutoClipStyle,,0,0,0,,$line',
      );

      currentTime = endTime + 0.3;
      index++;
    }

    return eventsBuffer.toString();
  }

  static List<String> _getDefaultCaptionsForStyle(StyleType type) {
    switch (type) {
      case StyleType.clean:
        return [
          'Key Highlight',
          'Notice this detail',
          'The best part',
          'Clean edit created with AutoClip',
        ];
      case StyleType.fast:
        return [
          'WATCH THIS!',
          'UNBELIEVABLE MOMENT',
          'DON\'T MISS THIS',
          'FAST PACED HIGHLIGHT',
        ];
      case StyleType.gaming:
        return [
          'INSANE PLAY!',
          'CLUTCH MOMENT',
          'PERFECT TIMING',
          'VICTORY RUN',
        ];
      case StyleType.dynamicStyle:
        return [
          'Here is the secret',
          'Watch what happens next',
          'Incredible transformation',
          'Created with AutoClip',
        ];
      case StyleType.minimal:
        return [
          'Featured moment',
          'Simple aesthetic',
          'Direct from source',
        ];
    }
  }

  static String _formatAssTimestamp(double seconds) {
    final h = (seconds / 3600).floor();
    final m = ((seconds % 3600) / 60).floor();
    final s = (seconds % 60).floor();
    final cs = ((seconds % 1) * 100).floor(); // Centiseconds

    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
  }
}
