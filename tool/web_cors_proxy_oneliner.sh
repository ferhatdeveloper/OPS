#!/usr/bin/env sh
# Dosya Adı: web_cors_proxy_oneliner.sh
# Açıklama: PostgREST CORS proxy + Flutter Chrome WEB_SAAS_ORIGIN one-liner
# Kullanım: sh tool/web_cors_proxy_oneliner.sh
set -eu
cd "$(dirname "$0")/.."
dart run tool/postgrest_cors_proxy.dart &
PROXY_PID=$!
trap 'kill "$PROXY_PID" 2>/dev/null || true' EXIT INT TERM
sleep 1
flutter run -d chrome --web-port=8080 \
  --dart-define=WEB_SAAS_ORIGIN=http://127.0.0.1:8799
