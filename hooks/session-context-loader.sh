#!/usr/bin/env bash
# k-orchestrator SessionStart hook — advertise relevant vault context.

set +e -uo pipefail

# 환경변수 sanitize — 영숫자, '.', '_', '-'만 허용 (path traversal 방지)
sanitize() {
  local val
  val="$(printf '%s' "$1" | tr -cd 'a-zA-Z0-9._-' | cut -c1-64)"
  case "$val" in ..|.) val="invalid" ;; esac
  printf '%s' "$val"
}

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
VAULT_DIR="$(cd "$VAULT_DIR" 2>/dev/null && pwd -P)" || { echo "[k-orchestrator] VAULT_DIR 해소 실패"; exit 0; }
case "$VAULT_DIR" in
  /|/etc*|/usr*|/bin*|/sbin*|/var*|/tmp*|/proc*|/sys*|/dev*|/System*|/Library*|/private*|/run*|/boot*)
    echo "[k-orchestrator] VAULT_DIR이 시스템 디렉토리 — 거부"
    exit 0;;
esac

echo ""
echo "[k-orchestrator] Obsidian vault 활성: $(basename "$VAULT_DIR")"

SAFE_PROFILE="$(sanitize "${CLAUDEBOX_PROFILE:-unknown}")"

SAFE_USER="$(sanitize "${CLAUDEBOX_USER:-unknown}")"
SAFE_WORKTREE="$(sanitize "${CLAUDEBOX_WORKTREE_ID:-unknown}")"
SAFE_BRANCH="$(sanitize "${CLAUDEBOX_BASE_BRANCH:-unknown}")"

if [ -n "$SAFE_PROFILE" ] && [ "$SAFE_PROFILE" != "unknown" ]; then
  echo "[k-orchestrator] ClaudeBox 환경"
  echo "  - Profile: $SAFE_PROFILE"
  echo "  - User: $SAFE_USER"
  echo "  - Worktree: $SAFE_WORKTREE"
  echo "  - Base Branch: $SAFE_BRANCH"
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
