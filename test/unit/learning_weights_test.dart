import 'package:flutter_test/flutter_test.dart';
import 'package:story_pals/core/constants/app_constants.dart';

void main() {
  group('Learning weight defaults', () {
    test('all default weights are between 0 and 1', () {
      expect(AppConstants.defaultCodingWeight, inInclusiveRange(0.0, 1.0));
      expect(AppConstants.defaultMathWeight, inInclusiveRange(0.0, 1.0));
      expect(AppConstants.defaultEnglishWeight, inInclusiveRange(0.0, 1.0));
      expect(AppConstants.defaultLanguageWeight, inInclusiveRange(0.0, 1.0));
      expect(AppConstants.defaultGeographyWeight, inInclusiveRange(0.0, 1.0));
    });

    test('free chapter count is less than total chapters', () {
      expect(AppConstants.freeChapterCount,
          lessThan(AppConstants.totalChapters));
    });

    test('session limits are sane', () {
      expect(AppConstants.minSessionMinutes,
          lessThan(AppConstants.defaultSessionMinutes));
      expect(AppConstants.defaultSessionMinutes,
          lessThanOrEqualTo(AppConstants.maxSessionMinutes));
    });

    test('supported locales contains required languages', () {
      expect(AppConstants.supportedLocales, contains('en'));
      expect(AppConstants.supportedLocales, contains('es'));
      expect(AppConstants.supportedLocales, contains('tl'));
    });
  });
}
