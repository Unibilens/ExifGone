// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'ExifGone';

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
