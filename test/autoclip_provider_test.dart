import 'package:flutter_test/flutter_test.dart';
import 'package:autoclip/models/editing_style.dart';
import 'package:autoclip/providers/autoclip_provider.dart';

void main() {
  group('AutoClipProvider Validation and Logic', () {
    test('Initial state has CREATE CLIPS button disabled', () {
      final provider = AutoClipProvider();

      expect(provider.canCreateClips, isFalse);
      expect(provider.selectedClipDurationSec, equals(25));
      expect(provider.selectedStyles, contains(StyleType.clean));
      expect(provider.phase, equals(ProcessingPhase.idle));
    });

    test('Clip length setter allows only 20, 25, 30', () {
      final provider = AutoClipProvider();

      provider.setClipDuration(20);
      expect(provider.selectedClipDurationSec, equals(20));

      provider.setClipDuration(30);
      expect(provider.selectedClipDurationSec, equals(30));

      // Attempt invalid duration should be ignored
      provider.setClipDuration(45);
      expect(provider.selectedClipDurationSec, equals(30));
    });

    test('Toggling styles supports multiple selections and preserves at least one', () {
      final provider = AutoClipProvider();

      // Initially has clean
      expect(provider.selectedStyles.length, equals(1));

      // Add gaming
      provider.toggleStyle(StyleType.gaming);
      expect(provider.selectedStyles, containsAll([StyleType.clean, StyleType.gaming]));

      // Add dynamic
      provider.toggleStyle(StyleType.dynamicStyle);
      expect(provider.selectedStyles.length, equals(3));

      // Deselect clean
      provider.toggleStyle(StyleType.clean);
      expect(provider.selectedStyles, isNot(contains(StyleType.clean)));
      expect(provider.selectedStyles.length, equals(2));
    });

    test('Reset clears clip state cleanly', () {
      final provider = AutoClipProvider();
      provider.resetForNewClips();

      expect(provider.phase, equals(ProcessingPhase.idle));
      expect(provider.overallProgress, equals(0.0));
      expect(provider.generatedClips, isEmpty);
    });
  });
}
