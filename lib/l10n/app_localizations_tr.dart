// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Exifgone';

  @override
  String get subtitle => 'Gizliliğini koru, verilerini temizle.';

  @override
  String get startBySelecting => 'Bir fotoğraf seçerek başla';

  @override
  String get selectPhoto => 'Fotoğrafları Seç';

  @override
  String photosSelected(num count) {
    return '$count Fotoğraf Seçildi';
  }

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
  String get privacyReport => 'Gizlilik Analizi';

  @override
  String privacyScore(Object level, Object score) {
    return 'Gizlilik Skoru: %$score ($level)';
  }

  @override
  String get gpsFound => 'GPS konumu';

  @override
  String deviceFound(Object device) {
    return '$device cihaz bilgisi';
  }

  @override
  String get timeFound => 'çekim saati';

  @override
  String foundInPhoto(Object details) {
    return 'Bu fotoğrafta $details bulundu.';
  }

  @override
  String get summaryReport => 'Toplu Özet Raporu';

  @override
  String totalAnalysis(Object count) {
    return '$count fotoğraf analiz edildi';
  }

  @override
  String totalGps(Object count) {
    return '$count fotoğrafta konum bulundu';
  }

  @override
  String totalDevices(Object count) {
    return '$count fotoğrafta cihaz bilgisi bulundu';
  }

  @override
  String totalTimes(Object count) {
    return '$count fotoğrafta zaman bilgisi bulundu';
  }

  @override
  String get critical => 'Kritik';

  @override
  String get fair => 'Orta';

  @override
  String get good => 'İyi';

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
