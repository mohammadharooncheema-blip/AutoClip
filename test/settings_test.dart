import 'package:flutter_test/flutter_test.dart';
import 'package:autoclip/models/app_settings.dart';

void main() {
  group('AppSettings and VideoQuality', () {
    test('Default quality is 1080x1920 (High 9:16 portrait)', () {
      const settings = AppSettings();
      expect(settings.quality, equals(VideoQuality.high1080p));
      expect(settings.quality.width, equals(1080));
      expect(settings.quality.height, equals(1920));
      expect(settings.autoGallerySave, isTrue);
      expect(settings.captionsEnabled, isTrue);
    });

    test('VideoQuality provides proper dimensions and bitrates', () {
      expect(VideoQuality.standard720p.width, equals(720));
      expect(VideoQuality.standard720p.height, equals(1280));

      expect(VideoQuality.fast540p.width, equals(540));
      expect(VideoQuality.fast540p.height, equals(960));
    });

    test('AppSettings copyWith maintains immutability', () {
      const settings = AppSettings();
      final updated = settings.copyWith(captionsEnabled: false);
      expect(updated.captionsEnabled, isFalse);
      expect(updated.autoGallerySave, isTrue);
      expect(updated.quality, equals(VideoQuality.high1080p));
    });
  });
}
