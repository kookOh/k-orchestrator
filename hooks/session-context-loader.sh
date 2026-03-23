#!/usr/bin/env bash
# k-orchestrator SessionStart hook — advertise relevant vault context.

set +e -uo pipefail

echo "[k-orchestrator] SessionStart: CLAUDE.md 및 docs/EXECUTION_STATUS.md를 먼저 확인하세요."

VAULT_DIR="${VAULT_DIR:-}"
CLAUDEBOX_PROFILE="${CLAUDEBOX_PROFILE:-}"
CLAUDEBOX_USER="${CLAUDEBOX_USER:-unknown}"
CLAUDEBOX_WORKTREE_ID="${CLAUDEBOX_WORKTREE_ID:-unknown}"
CLAUDEBOX_BASE_BRANCH="${CLAUDEBOX_BASE_BRANCH:-unknown}"

if [ -z "$VAULT_DIR" ] || [ ! -d "$VAULT_DIR" ]; then
  echo "[k-orchestrator] VAULT_DIR 미설정 또는 디렉토리 없음 — vault 컨텍스트 안내 스킵"
  exit 0
fi
# VAULT_DIR canonicalization + 시스템 디렉토리 blocklist
VAULT_DIR="$(cd "$VAULT_DIR" 2>/dev/null && pwd -P)" || { echo "[k-orchestrator] VAULT_DIR 해소 실패"; exit 0; }
case "$VAULT_DIR" in
  /|/etc*|/usr*|/bin*|/sbin*|/var*|/tmp*|/proc*|/sys*|/dev*|/System*|/Library*)
    echo "[k-orchestrator] VAULT_DIR이 시스템 디렉토리 — 거부: $VAULT_DIR"
    exit 0;;
esac

echo ""
echo "[k-orchestrator] 📚 Obsidian vault 활성: $VAULT_DIR"

# 환경변수 sanitize — 영숫자, '.', '_', '-'만 허용 (path traversal 방지)
sanitize() { printf '%s' "$1" | tr -cd 'a-zA-Z0-9._-'; }
SAFE_PROFILE="$(sanitize "${CLAUDEBOX_PROFILE:-unknown}")"

if [ -n "$CLAUDEBOX_PROFILE" ]; then
  echo "[k-orchestrator] ClaudeBox 환경"
  echo "  - Profile: $CLAUDEBOX_PROFILE"
  echo "  - User: $CLAUDEBOX_USER"
  echo "  - Worktree: $CLAUDEBOX_WORKTREE_ID"
  echo "  - Base Branch: $CLAUDEBOX_BASE_BRANCH"
  SESSION_DIR="$VAULT_DIR/projects/$SAFE_PROFILE/sessions"
  PROJECT_DIR="$VAULT_DIR/projects/$SAFE_PROFILE"
else
  SESSION_DIR="$VAULT_DIR/sessions"
  PROJECT_DIR=""
fi

if [ -d "$SESSION_DIR" ]; then
  RECENT="$(find "$SESSION_DIR" -maxdepth 1 -type f -name '*.md' | sort -r | head -3)"
  if [ -n "$RECENT" ]; then
    echo "[k-orchestrator] 최근 세션 요약:"
    while IFS= read -r f; do
      [ -n "$f" ] && echo "  - $(basename "$f")"
    done <<EOF_RECENT
$RECENT
EOF_RECENT
  fi
fi

if [ -n "$PROJECT_DIR" ] && [ -d "$PROJECT_DIR" ]; then
  DOC_COUNT="$(find "$PROJECT_DIR" -maxdepth 3 -type f -name '*.md' | wc -l | tr -d ' ')"
  echo "[k-orchestrator] 프로젝트 문서: ${DOC_COUNT}건 (vault에서 직접 읽기 가능)"
fi

POLICY_DIR="$VAULT_DIR/team/policies"
if [ -d "$POLICY_DIR" ]; then
  POLICY_COUNT="$(find "$POLICY_DIR" -maxdepth 2 -type f -name '*.md' | wc -l | tr -d ' ')"
  echo "[k-orchestrator] 팀 정책 문서: ${POLICY_COUNT}건"
fi

exit 0
