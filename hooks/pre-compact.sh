#!/usr/bin/env bash
# k-orchestrator PreCompact hook — 컨텍스트 압축 전 현재 작업 상태를 안내한다.
# 세션을 막지 않도록 set +e.

set +e

VAULT_DIR="${VAULT_DIR:-}"
CLAUDEBOX_PROFILE="${CLAUDEBOX_PROFILE:-default}"

# VAULT_DIR 미설정 시 조용히 종료
if [ -z "$VAULT_DIR" ]; then
  exit 0
fi

echo "[k-orchestrator] PreCompact: 현재 작업 상태 요약"
echo "  현재 프로필: $CLAUDEBOX_PROFILE"
echo "  vault 경로: $VAULT_DIR"

exit 0
