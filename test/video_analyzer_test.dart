import 'package:flutter_test/flutter_test.dart';
import 'package:autoclip/services/video_analyzer_service.dart';

void main() {
  group('VideoAnalyzerService Cut Boundary Logic', () {
    test('Splits 100-second video into ~4 clips for 25s mode', () {
      final totalDuration = const Duration(seconds: 100);
      final cuts = VideoAnalyzerService.calculateOptimalCuts(
        totalDuration: totalDuration,
        targetDurationSeconds: 25,
      );

      expect(cuts.length, equals(4));
      // First cut should be ~25s
      expect(cuts[0].duration.inSeconds, equals(25));
      // None of the cuts should exceed 30 seconds
      for (final cut in cuts) {
        expect(cut.duration.inMilliseconds / 1000.0, lessThanOrEqualTo(30.0));
      }
      // Total coverage should span entire video
      expect(cuts.first.start, equals(Duration.zero));
      expect(cuts.last.end, equals(totalDuration));
    });

    test('Snaps to natural cut points within tolerance window', () {
      final totalDuration = const Duration(seconds: 100);
      // Suppose natural scene change was detected at 23.5s and 51.0s
      final naturalCutPoints = [23.5, 51.0, 76.2];

      final cuts = VideoAnalyzerService.calculateOptimalCuts(
        totalDuration: totalDuration,
        targetDurationSeconds: 25,
        naturalCutPoints: naturalCutPoints,
      );

      // First cut should snap to 23.5s instead of exactly 25.0s
      final firstEndSec = cuts[0].end.inMilliseconds / 1000.0;
      expect(firstEndSec, closeTo(23.5, 0.1));
      expect(cuts[0].confidence, greaterThan(0.9));
    });

    test('Strictly enforces 30 second maximum clip duration', () {
      final totalDuration = const Duration(seconds: 90);
      final naturalCutPoints = [35.0, 68.0]; // Cut points beyond 30s window

      final cuts = VideoAnalyzerService.calculateOptimalCuts(
        totalDuration: totalDuration,
        targetDurationSeconds: 30,
        naturalCutPoints: naturalCutPoints,
      );

      for (final cut in cuts) {
        final sec = cut.duration.inMilliseconds / 1000.0;
        expect(sec, lessThanOrEqualTo(30.0));
      }
    });

    test('Handles short videos (< 10s) as single clip', () {
      final totalDuration = const Duration(seconds: 8);
      final cuts = VideoAnalyzerService.calculateOptimalCuts(
        totalDuration: totalDuration,
        targetDurationSeconds: 25,
      );

      expect(cuts.length, equals(1));
      expect(cuts[0].start, equals(Duration.zero));
      expect(cuts[0].end, equals(totalDuration));
    });

    test('Supports 20s, 25s, and 30s target durations', () {
      final totalDuration = const Duration(seconds: 60);

      final cuts20 = VideoAnalyzerService.calculateOptimalCuts(
        totalDuration: totalDuration,
        targetDurationSeconds: 20,
      );
      expect(cuts20.length, equals(3));

      final cuts30 = VideoAnalyzerService.calculateOptimalCuts(
        totalDuration: totalDuration,
        targetDurationSeconds: 30,
      );
      expect(cuts30.length, equals(2));
    });
  });
}
