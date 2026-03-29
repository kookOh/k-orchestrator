#!/usr/bin/env bash
# k-orchestrator PreCompact hook — 컨텍스트 압축 전 현재 작업 상태를 안내한다.
# 세션을 막지 않도록 set +e.

set +e -uo pipefail

# 환경변수 sanitize — 영숫자, '.', '_', '-'만 허용 (path traversal 방지)
sanitize() {
  local val
  val="$(printf '%s' "$1" | tr -cd 'a-zA-Z0-9._-' | cut -c1-64)"
  case "$val" in ..|.) val="invalid" ;; esac
  printf '%s' "$val"
}

VAULT_DIR="${VAULT_DIR:-}"
SAFE_PROFILE="$(sanitize "${CLAUDEBOX_PROFILE:-unknown}")"

if [ -z "$VAULT_DIR" ] || [ ! -d "$VAULT_DIR" ]; then
  exit 0
fi
VAULT_DIR="$(cd "$VAULT_DIR" 2>/dev/null && pwd -P)" || exit 0
if [ -z "$VAULT_DIR" ]; then
  exit 0
fi
case "$VAULT_DIR" in
  /|/etc*|/usr*|/bin*|/sbin*|/var*|/tmp*|/proc*|/sys*|/dev*|/System*|/Library*|/private*|/run*|/boot*)
    echo "[k-orchestrator] VAULT_DIR이 시스템 디렉토리 — 거부"
    exit 0;;
esac

echo "[k-orchestrator] PreCompact: 현재 작업 상태 요약"
echo "  현재 프로필: $SAFE_PROFILE"
echo "  vault 경로: $(basename "$VAULT_DIR")"

exit 0
