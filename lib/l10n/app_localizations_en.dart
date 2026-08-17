// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ExifGone';

  @override
  String get subtitle => 'Protect your privacy, clean your data.';

  @override
  String get startBySelecting => 'Start by selecting a photo';

  @override
  String get selectPhoto => 'Select Photo';

  @override
  String get cleanAndShare => 'Clean & Share';

  @override
  String get processing => 'Processing...';

  @override
  String get selectAnother => 'Select Another Photo';

  @override
  String get deviceLocal => 'All operations are performed on your device.';

  @override
  String get cleanedWith => 'Cleaned with ExifGone ✨';

  @override
  String error(Object error) {
    return 'Error: $error';
  }

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System Default';

  @override
  String get english => 'English';

  @override
  String get turkish => 'Turkish';

  @override
  String get german => 'German';
}
