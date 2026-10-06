import 'package:flutter_test/flutter_test.dart';
import 'package:autoclip/models/clip_segment.dart';
import 'package:autoclip/models/editing_style.dart';

void main() {
  group('EditingStyle Presets and File Naming', () {
    test('Contains exactly 5 ready-made styles', () {
      expect(EditingStyle.all.length, equals(5));
      final names = EditingStyle.all.map((s) => s.name).toList();
      expect(names, containsAll(['Clean', 'Fast', 'Gaming', 'Dynamic', 'Minimal']));
    });

    test('Style 1 Clean matches specifications', () {
      final clean = EditingStyle.clean;
      expect(clean.zoomIntensity, equals(1.05));
      expect(clean.zoomMode, equals('subtle'));
      expect(clean.captionStyleKey, equals('clean'));
      expect(clean.enableAudioEnhance, isTrue);
    });

    test('Style 2 Fast matches specifications', () {
      final fast = EditingStyle.fast;
      expect(fast.zoomIntensity, equals(1.12));
      expect(fast.zoomMode, equals('fast'));
      expect(fast.playbackSpeed, greaterThan(1.0));
      expect(fast.captionStyleKey, equals('fast'));
    });

    test('Style 3 Gaming matches specifications', () {
      final gaming = EditingStyle.gaming;
      expect(gaming.zoomIntensity, equals(1.18));
      expect(gaming.zoomMode, equals('punch'));
      expect(gaming.captionStyleKey, equals('gaming'));
      expect(gaming.enableActionTransitions, isTrue);
    });

    test('Style 4 Dynamic matches specifications', () {
      final dynamicStyle = EditingStyle.dynamicPreset;
      expect(dynamicStyle.zoomIntensity, equals(1.08));
      expect(dynamicStyle.zoomMode, equals('smooth_wave'));
      expect(dynamicStyle.captionStyleKey, equals('dynamic'));
    });

    test('Style 5 Minimal matches specifications', () {
      final minimal = EditingStyle.minimal;
      expect(minimal.zoomIntensity, equals(1.0));
      expect(minimal.zoomMode, equals('static'));
      expect(minimal.colorFilter, isEmpty);
      expect(minimal.captionStyleKey, equals('minimal'));
    });

    test('ClipSegment generates correct filenames as required by spec', () {
      final clip1 = ClipSegment(
        id: 'c1',
        cutIndex: 1,
        startTime: Duration.zero,
        endTime: const Duration(seconds: 25),
        duration: const Duration(seconds: 25),
        style: EditingStyle.clean,
      );
      expect(clip1.fileName, equals('Clean_01.mp4'));

      final clip2 = ClipSegment(
        id: 'c2',
        cutIndex: 2,
        startTime: const Duration(seconds: 25),
        endTime: const Duration(seconds: 50),
        duration: const Duration(seconds: 25),
        style: EditingStyle.gaming,
      );
      expect(clip2.fileName, equals('Gaming_02.mp4'));
    });
  });
}
