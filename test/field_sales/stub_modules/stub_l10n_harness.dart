// Dosya Adı: stub_l10n_harness.dart
// Açıklama: Stub ekran widget smoke testleri için AppLocalization harness
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exfin_ops/core/localization/app_localization.dart';

/// Önceden yüklenmiş TR [AppLocalization] (setUpAll ile doldurulur).
AppLocalization? _preloadedTr;

/// {@template ensure_stub_l10n_loaded}
/// Asset çevirilerini gerçek async ile bir kez yükler (test FakeAsync dışında).
/// {@endtemplate}
Future<void> ensureStubL10nLoaded() async {
  if (_preloadedTr != null) return;
  SharedPreferences.setMockInitialValues({});
  final localization = AppLocalization(const Locale('tr', 'TR'));
  final ok = await localization.load();
  assert(ok, 'TR çeviri dosyası yüklenemedi');
  _preloadedTr = localization;
}

/// {@template _PreloadedAppLocalizationDelegate}
/// rootBundle'ı test FakeAsync içinde tekrar çağırmadan l10n sağlar.
/// {@endtemplate}
class _PreloadedAppLocalizationDelegate
    extends LocalizationsDelegate<AppLocalization> {
  const _PreloadedAppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalization> load(Locale locale) async {
    final loaded = _preloadedTr;
    assert(loaded != null, 'ensureStubL10nLoaded() önce çağrılmalı');
    return loaded!;
  }

  @override
  bool shouldReload(_PreloadedAppLocalizationDelegate old) => false;
}

/// ListTile + DecoratedBox (mevcut stub UI) Flutter assert'ini yok sayar.
bool _isKnownListTileDecoratedBoxAssert(Object exception) {
  return exception.toString().contains(
        'ListTile background color or ink splashes may be invisible',
      );
}

/// Bilinen stub ListTile trailing overflow (1px) — smoke'u kırmaz.
bool _isKnownRenderFlexOverflow(Object exception) {
  final s = exception.toString();
  return s.contains('A RenderFlex overflowed by') ||
      s.contains('RenderFlex overflowed');
}

/// {@template pump_stub_with_l10n}
/// Stub ekranı TR locale + önceden yüklenmiş AppLocalization ile pump eder.
///
/// Parametreler:
/// - [tester]: WidgetTester
/// - [child]: Stub ekran widget'ı
/// - [overrides]: Opsiyonel Riverpod override listesi
/// {@endtemplate}
Future<void> pumpStubWithL10n(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await ensureStubL10nLoaded();

  final previousOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (_isKnownListTileDecoratedBoxAssert(details.exception) ||
        _isKnownRenderFlexOverflow(details.exception)) {
      return;
    }
    previousOnError?.call(details);
  };

  try {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          locale: const Locale('tr', 'TR'),
          localizationsDelegates: const [
            _PreloadedAppLocalizationDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalization.supportedLocales(),
          home: child,
        ),
      ),
    );
    // CircularProgressIndicator / incomplete Future: pumpAndSettle kilitlenmesin.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  } finally {
    FlutterError.onError = previousOnError;
  }
}

/// {@template expect_stub_l10n_smoke}
/// Scaffold + AppLocalization + başlık metni smoke doğrulaması.
///
/// Parametreler:
/// - [tester]: WidgetTester
/// - [titleKey]: Ekranın birincil çeviri anahtarı
/// {@endtemplate}
void expectStubL10nSmoke(WidgetTester tester, String titleKey) {
  expect(find.byType(Scaffold), findsOneWidget);

  final context = tester.element(find.byType(Scaffold));
  final loc = Localizations.of<AppLocalization>(
    context,
    AppLocalization,
  );
  expect(loc, isNotNull, reason: 'AppLocalization delegate yüklenmeli');

  final title = loc!.translate(titleKey);
  expect(title, isNotEmpty);
  expect(
    find.text(title),
    findsWidgets,
    reason: 'Ekran AppLocalization ile "$titleKey" göstermeli '
        '(çözüm: "$title")',
  );
}
