# migrations_tr

## Açıklama
Bu klasör, migration yönetim kodlarını içerir. Projedeki tüm tablo oluşturma, değiştirme, silme ve veri ekleme gibi işlemler sadece `SqlQuerys.dart` dosyasındaki sorgular üzerinden yönetilir. Kod içinde migration veya SQL sorgusu kullanılmaz, tüm işlemler merkezi olarak bu dosyadan alınır.

## Dosyalar
- `SqlQuerys.dart`: Migration ve tüm SQL sorgularını merkezi olarak tutan dosya
- `migration_manager_tr.dart`: Migration yönetim kodu

## Kullanım
Migration işlemleri için ilgili SQL sorguları `SqlQuerys.dart` dosyasına eklenir. Uygulama başlatılırken veya güncellenirken migration_manager_tr.dart dosyası bu sorguları sıralı çalıştırır.

## Bağımlılıklar
- sqflite
- path_provider
- (varsa ek migration yönetim paketleri) 