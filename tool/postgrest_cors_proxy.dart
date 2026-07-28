// Dosya Adı: postgrest_cors_proxy.dart
// Açıklama: Flutter web (localhost) için PostgREST CORS geliştirme proxy’si
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28
//
// Dokümantasyon: docs/plans/2026-07-28-postgrest-web-cors-dev.md
// Login CORS mesajı: auth.postgrest_web_cors
//
// Kullanım:
//   dart run tool/postgrest_cors_proxy.dart
//   # varsayılan: http://127.0.0.1:8799 → https://api.retailex.app
//
// Login’de dişli → SaaS Kök Adresi → http://127.0.0.1:8799
// veya: flutter run -d chrome --web-port=8080 \
//          --dart-define=WEB_SAAS_ORIGIN=http://127.0.0.1:8799
// (veya uzun basış dialog). Sonra kiracı kodu ile Bağlan.
//
// Sunucu tarafı kalıcı çözüm: Caddy Access-Control-Allow-Origin’e
// http://localhost:8080 (ve prod web origin) eklemek.

import 'dart:async';
import 'dart:io';

const String kDefaultUpstream = 'https://api.retailex.app';
/// 8787 çoğu ortamda Cursor msgsrvr; geliştirme proxy varsayılanı 8799.
const int kDefaultPort = 8799;

Future<void> main(List<String> args) async {
  final upstream = Uri.parse(
    Platform.environment['POSTGREST_UPSTREAM']?.trim().isNotEmpty == true
        ? Platform.environment['POSTGREST_UPSTREAM']!.trim()
        : kDefaultUpstream,
  );
  final port = int.tryParse(
        Platform.environment['POSTGREST_PROXY_PORT'] ?? '',
      ) ??
      kDefaultPort;

  final client = HttpClient();
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln(
    'PostgREST CORS proxy: http://127.0.0.1:$port → $upstream',
  );
  stdout.writeln(
    'Login SaaS kökünü http://127.0.0.1:$port yapın, sonra Bağlan.',
  );

  await for (final request in server) {
    unawaited(_handle(request, client, upstream));
  }
}

Future<void> _handle(
  HttpRequest request,
  HttpClient client,
  Uri upstream,
) async {
  final response = request.response;
  _cors(response);

  if (request.method == 'OPTIONS') {
    response.statusCode = HttpStatus.noContent;
    await response.close();
    return;
  }

  try {
    final target = upstream.replace(
      path: _joinPath(upstream.path, request.uri.path),
      query: request.uri.hasQuery ? request.uri.query : null,
    );
    final upstreamReq = await client.openUrl(request.method, target);
    request.headers.forEach((name, values) {
      final lower = name.toLowerCase();
      if (lower == 'host' || lower == 'origin' || lower.startsWith('sec-')) {
        return;
      }
      for (final v in values) {
        upstreamReq.headers.add(name, v);
      }
    });
    await upstreamReq.addStream(request);
    final upstreamRes = await upstreamReq.close();
    response.statusCode = upstreamRes.statusCode;
    upstreamRes.headers.forEach((name, values) {
      final lower = name.toLowerCase();
      if (lower == 'access-control-allow-origin' ||
          lower == 'access-control-allow-headers' ||
          lower == 'access-control-allow-methods' ||
          lower == 'transfer-encoding' ||
          lower == 'content-encoding' ||
          lower == 'content-length') {
        // HttpClient gövdeyi decode eder; encoding header’ı iletme
        return;
      }
      for (final v in values) {
        response.headers.add(name, v);
      }
    });
    _cors(response);
    await response.addStream(upstreamRes);
    await response.close();
  } catch (e, st) {
    stderr.writeln('proxy error: $e\n$st');
    response.statusCode = HttpStatus.badGateway;
    response.write('proxy error: $e');
    await response.close();
  }
}

void _cors(HttpResponse response) {
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set(
    'Access-Control-Allow-Methods',
    'GET,POST,PUT,PATCH,DELETE,OPTIONS',
  );
  response.headers.set(
    'Access-Control-Allow-Headers',
    'Authorization,Content-Type,apikey,Prefer,Accept,Origin,'
        'Content-Profile,Accept-Profile',
  );
  response.headers.set('Access-Control-Max-Age', '86400');
}

String _joinPath(String basePath, String reqPath) {
  final a = basePath.endsWith('/')
      ? basePath.substring(0, basePath.length - 1)
      : basePath;
  final b = reqPath.startsWith('/') ? reqPath : '/$reqPath';
  if (a.isEmpty || a == '/') return b;
  return '$a$b';
}
