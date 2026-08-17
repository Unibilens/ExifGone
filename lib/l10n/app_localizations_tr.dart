// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'ExifGone';

  @override
  String get subtitle => 'Gizliliğini koru, verilerini temizle.';

  @override
  String get startBySelecting => 'Bir fotoğraf seçerek başla';

  @override
  String get selectPhoto => 'Fotoğraf Seç';

  @override
  String get cleanAndShare => 'Temizle ve Paylaş';

  @override
  String get processing => 'Temizleniyor...';

  @override
  String get selectAnother => 'Başka Bir Fotoğraf Seç';

  @override
  String get deviceLocal => 'Tüm işlemler cihazında yapılır.';

  @override
  String get cleanedWith => 'ExifGone ile temizlendi ✨';

  @override
  String error(Object error) {
    return 'Hata: $error';
  }

  @override
  String get settings => 'Ayarlar';

  @override
  String get language => 'Dil';

  @override
  String get systemDefault => 'Sistem Varsayılanı';

  @override
  String get english => 'İngilizce';

  @override
  String get turkish => 'Türkçe';

  @override
  String get german => 'Almanca';
}
