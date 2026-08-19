// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Exifgone';

  @override
  String get subtitle => 'Schütze deine Privatsphäre, bereinige deine Daten.';

  @override
  String get startBySelecting => 'Wähle ein Foto aus, um zu beginnen';

  @override
  String get selectPhoto => 'Fotos auswählen';

  @override
  String photosSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos ausgewählt',
      one: '1 Foto ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get cleanAndShare => 'Bereinigen & Teilen';

  @override
  String get processing => 'Verarbeitung...';

  @override
  String get selectAnother => 'Anderes Foto auswählen';

  @override
  String get deviceLocal => 'Alle Vorgänge werden auf Ihrem Gerät ausgeführt.';

  @override
  String get cleanedWith => 'Mit ExifGone bereinigt ✨';

  @override
  String error(Object error) {
    return 'Fehler: $error';
  }

  @override
  String get privacyReport => 'Datenschutzbericht';

  @override
  String privacyScore(Object level, Object score) {
    return 'Datenschutz-Score: $score% ($level)';
  }

  @override
  String get gpsFound => 'GPS-Standort';

  @override
  String deviceFound(Object device) {
    return '$device-Geräteinfo';
  }

  @override
  String get timeFound => 'Erstellungszeit';

  @override
  String foundInPhoto(Object details) {
    return 'In diesem Foto gefunden: $details.';
  }

  @override
  String get summaryReport => 'Zusammenfassender Bericht';

  @override
  String totalAnalysis(Object count) {
    return '$count Fotos analysiert';
  }

  @override
  String totalGps(Object count) {
    return '$count GPS-Standorte gefunden';
  }

  @override
  String totalDevices(Object count) {
    return '$count Geräteinfos gefunden';
  }

  @override
  String totalTimes(Object count) {
    return '$count Zeitstempel gefunden';
  }

  @override
  String get critical => 'Kritisch';

  @override
  String get fair => 'Mittel';

  @override
  String get good => 'Gut';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get english => 'Englisch';

  @override
  String get turkish => 'Türkisch';

  @override
  String get german => 'Deutsch';
}
