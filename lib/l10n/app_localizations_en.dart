// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Exifgone';

  @override
  String get subtitle => 'Protect your privacy, clean your data.';

  @override
  String get startBySelecting => 'Start by selecting a photo';

  @override
  String get selectPhoto => 'Select Photos';

  @override
  String photosSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Photos Selected',
      one: '1 Photo Selected',
    );
    return '$_temp0';
  }

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
  String get privacyReport => 'Privacy Report';

  @override
  String privacyScore(Object level, Object score) {
    return 'Privacy Score: $score% ($level)';
  }

  @override
  String get gpsFound => 'GPS location';

  @override
  String deviceFound(Object device) {
    return '$device info';
  }

  @override
  String get timeFound => 'creation time';

  @override
  String foundInPhoto(Object details) {
    return 'Found in this photo: $details.';
  }

  @override
  String get summaryReport => 'Summary Report';

  @override
  String totalAnalysis(Object count) {
    return '$count photos analyzed';
  }

  @override
  String totalGps(Object count) {
    return '$count GPS locations found';
  }

  @override
  String totalDevices(Object count) {
    return '$count device info found';
  }

  @override
  String totalTimes(Object count) {
    return '$count timestamps found';
  }

  @override
  String get critical => 'Critical';

  @override
  String get fair => 'Fair';

  @override
  String get good => 'Good';

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
