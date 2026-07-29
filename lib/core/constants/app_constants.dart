class AppConstants {
  // App identity
  static const String appName = 'Story Pals';
  static const String bundleId = 'com.storypals.app';

  // Freemium: chapters 1-2 are free, 3-5 require premium
  static const int freeChapterCount = 2;
  static const int totalChapters = 5;

  // Session limits (parent-configurable, these are defaults)
  static const int defaultSessionMinutes = 20;
  static const int minSessionMinutes = 5;
  static const int maxSessionMinutes = 60;

  // Puzzles per chapter
  static const int puzzlesPerChapter = 5;

  // Child profile limits per parent account
  static const int maxChildProfiles = 5;

  // Touch target minimums for accessibility (2–5 year olds need 80dp+)
  static const double minTouchTarget = 80.0;
  static const double kidButtonRadius = 20.0;

  // Learning weight slider defaults (0.0–1.0)
  static const double defaultCodingWeight = 0.5;
  static const double defaultMathWeight = 0.4;
  static const double defaultEnglishWeight = 0.4;
  static const double defaultLanguageWeight = 0.2; // legacy combined
  static const double defaultSpanishWeight = 0.25;
  static const double defaultTagalogWeight = 0.25;
  static const double defaultGeographyWeight = 0.1;

  // Supported locales
  static const List<String> supportedLocales = ['en', 'es', 'tl'];

  // Firestore collection names
  static const String colParents = 'parents';
  static const String colChildren = 'children';
  static const String colSessions = 'sessions';
  static const String colEmotions = 'emotions';

  // Shared prefs keys
  static const String prefParentLoggedIn = 'parent_logged_in';
  static const String prefSelectedChildId = 'selected_child_id';
  static const String prefConsentGiven = 'parental_consent_given';
  static const String prefAppLocale = 'app_locale';
}
