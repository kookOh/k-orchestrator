#!/usr/bin/env bash
# k-orchestrator plugin installer v1.5.0
# Usage: ./install.sh [--update] [--force] [target-project-dir]

set -euo pipefail

UPDATE_MODE=false
FORCE_MODE=false
POSITIONAL_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --update) UPDATE_MODE=true ;;
    --force) FORCE_MODE=true ;;
    *) POSITIONAL_ARGS+=("$arg") ;;
  esac
done

TARGET="${POSITIONAL_ARGS[0]:-.}"

# TARGET 경로 검증
if [ ! -d "$TARGET" ]; then
  echo "ERROR: 대상 디렉토리가 존재하지 않습니다: $TARGET"
  exit 1
fi
TARGET="$(cd "$TARGET" && pwd)"
case "$TARGET" in
  /etc*|/usr*|/bin*|/sbin*|/var*|/System*|/Library*)
    echo "ERROR: 시스템 디렉토리에는 설치할 수 없습니다: $TARGET"
    exit 1;;
esac

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$PLUGIN_DIR/templates"

# 템플릿 디렉토리 존재 확인
if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "ERROR: 템플릿 디렉토리를 찾을 수 없습니다: $TEMPLATE_DIR"
  exit 1
fi

echo "▶ k-orchestrator installer v1.5.0"
echo "  target: $TARGET"
echo ""

# 1. 디렉토리 생성
mkdir -p "$TARGET/docs" \
         "$TARGET/tasks" \
         "$TARGET/qa" \
         "$TARGET/.claude/commands/k-orchestrator" \
         "$TARGET/.claude/skills/k-orchestrator/batch-execution-policy" \
         "$TARGET/.claude/skills/k-orchestrator/memory-layer-policy" \
         "$TARGET/.claude/skills/k-orchestrator/session-state-detector"

# 2. 핵심 운영 문서 (없을 때만 생성)
for f in CC_ORCHESTRATOR EXECUTION_STATUS PROJECT_FOUNDATION; do
  DEST="$TARGET/docs/${f}.md"
  SRC="$TEMPLATE_DIR/docs/${f}_TEMPLATE.md"
  if [ ! -f "$DEST" ]; then
    if [ -f "$SRC" ]; then
      cp "$SRC" "$DEST"
      echo "  ✅ 생성: docs/${f}.md"
    else
      echo "  ⚠️  템플릿 없음: $SRC"
    fi
  else
    echo "  ⏭  스킵(존재): docs/${f}.md"
  fi
done

# 2-1. BATCH_TEMPLATE → tasks/ (실제 사용 위치)
BATCH_DEST="$TARGET/tasks/BATCH_TEMPLATE.md"
BATCH_SRC="$TEMPLATE_DIR/docs/BATCH_TEMPLATE.md"
if [ ! -f "$BATCH_DEST" ]; then
  if [ -f "$BATCH_SRC" ]; then
    cp "$BATCH_SRC" "$BATCH_DEST"
    echo "  ✅ 생성: tasks/BATCH_TEMPLATE.md"
  fi
else
  echo "  ⏭  스킵(존재): tasks/BATCH_TEMPLATE.md"
fi

# 2-2. BATCH_TEMPLATE_QA → qa/ (실제 사용 위치)
QA_DEST="$TARGET/qa/BATCH_TEMPLATE_QA.md"
QA_SRC="$TEMPLATE_DIR/docs/BATCH_TEMPLATE_QA.md"
if [ ! -f "$QA_DEST" ]; then
  if [ -f "$QA_SRC" ]; then
    cp "$QA_SRC" "$QA_DEST"
    echo "  ✅ 생성: qa/BATCH_TEMPLATE_QA.md"
  fi
else
  echo "  ⏭  스킵(존재): qa/BATCH_TEMPLATE_QA.md"
fi

# 2-3. PLUGIN_DIAGNOSTIC_TEMPLATE → docs/PLUGIN_DIAGNOSTIC.md
DIAG_DEST="$TARGET/docs/PLUGIN_DIAGNOSTIC.md"
DIAG_SRC="$TEMPLATE_DIR/docs/PLUGIN_DIAGNOSTIC_TEMPLATE.md"
if [ ! -f "$DIAG_DEST" ]; then
  if [ -f "$DIAG_SRC" ]; then
    cp "$DIAG_SRC" "$DIAG_DEST"
    echo "  ✅ 생성: docs/PLUGIN_DIAGNOSTIC.md"
  fi
fi

# 2-4. CLAUDE_MEMORY_SETUP (선택적 — 없을 때만)
MEMORY_DEST="$TARGET/docs/CLAUDE_MEMORY_SETUP.md"
MEMORY_SRC="$TEMPLATE_DIR/docs/CLAUDE_MEMORY_SETUP_TEMPLATE.md"
if [ ! -f "$MEMORY_DEST" ]; then
  if [ -f "$MEMORY_SRC" ]; then
    cp "$MEMORY_SRC" "$MEMORY_DEST"
    echo "  ✅ 생성: docs/CLAUDE_MEMORY_SETUP.md"
  fi
fi

# 3. CLAUDE.md — 없으면 생성, 있으면 import만 추가
CLAUDE_MD="$TARGET/CLAUDE.md"
if [ ! -f "$CLAUDE_MD" ]; then
  if [ -f "$TEMPLATE_DIR/docs/CLAUDE_IMPORTS.md" ]; then
    cp "$TEMPLATE_DIR/docs/CLAUDE_IMPORTS.md" "$CLAUDE_MD"
    echo "  ✅ 생성: CLAUDE.md"
  else
    echo "  ERROR: CLAUDE_IMPORTS.md 템플릿을 찾을 수 없습니다"
    exit 1
  fi
else
  if ! grep -q "CC_ORCHESTRATOR" "$CLAUDE_MD"; then
    printf '\n# k-orchestrator imports\n@docs/CC_ORCHESTRATOR.md\n@docs/PROJECT_FOUNDATION.md\n' >> "$CLAUDE_MD"
    echo "  ✅ CLAUDE.md에 import 추가"
  else
    echo "  ⏭  스킵: CLAUDE.md import 이미 존재"
  fi
fi

# 4. project-local commands 복사
for cmd in "$PLUGIN_DIR/commands/"*.md; do
  [ -f "$cmd" ] || continue
  BASENAME="$(basename "$cmd")"
  DEST="$TARGET/.claude/commands/k-orchestrator/$BASENAME"
  if [ ! -f "$DEST" ]; then
    cp "$cmd" "$DEST"
    echo "  ✅ 생성: .claude/commands/k-orchestrator/$BASENAME"
  else
    echo "  ⏭  스킵(존재): .claude/commands/k-orchestrator/$BASENAME"
  fi
done

# 5. skills 복사 (2 policy + 1 감지)
for skill_dir in "$PLUGIN_DIR/skills/"*/; do
  [ -d "$skill_dir" ] || continue
  SKILL_NAME="$(basename "$skill_dir")"
  SKILL_SRC="$skill_dir/SKILL.md"
  SKILL_DEST="$TARGET/.claude/skills/k-orchestrator/$SKILL_NAME/SKILL.md"
  if [ -f "$SKILL_SRC" ]; then
    if [ ! -f "$SKILL_DEST" ]; then
      cp "$SKILL_SRC" "$SKILL_DEST"
      echo "  ✅ 생성: .claude/skills/k-orchestrator/$SKILL_NAME/SKILL.md"
    else
      echo "  ⏭  스킵(존재): .claude/skills/k-orchestrator/$SKILL_NAME/SKILL.md"
    fi
  fi
done

# 6. hooks (없을 때만)
HOOKS_DEST="$TARGET/.claude/settings.local.json"
if [ ! -f "$HOOKS_DEST" ]; then
  cp "$TEMPLATE_DIR/hooks/minimal-hooks.json" "$HOOKS_DEST"
  echo "  ✅ 생성: .claude/settings.local.json"
else
  echo "  ⏭  스킵: settings.local.json 이미 존재"
  echo "  ℹ️  아래 hooks를 settings.local.json에 수동 병합하세요:"
  echo ""
  cat "$TEMPLATE_DIR/hooks/minimal-hooks.json"
  echo ""
fi

# 7. project-settings.json (없을 때만)
SETTINGS_DEST="$TARGET/.claude/settings.json"
if [ ! -f "$SETTINGS_DEST" ]; then
  if [ -f "$TEMPLATE_DIR/settings/project-settings.json" ]; then
    cp "$TEMPLATE_DIR/settings/project-settings.json" "$SETTINGS_DEST"
    echo "  ✅ 생성: .claude/settings.json"
  fi
else
  echo "  ⏭  스킵: settings.json 이미 존재"
fi

# --- UPDATE MODE: overwrite existing files ---
if [ "$UPDATE_MODE" = true ]; then
  echo ""
  echo "▶ 업데이트 모드: 기존 파일을 최신 버전으로 교체합니다"
  echo ""

  # Update commands (overwrite)
  for cmd in "$PLUGIN_DIR/commands/"*.md; do
    [ -f "$cmd" ] || continue
    BASENAME="$(basename "$cmd")"
    DEST="$TARGET/.claude/commands/k-orchestrator/$BASENAME"
    if [ -f "$DEST" ]; then
      if [ "$FORCE_MODE" = true ]; then
        cp "$cmd" "$DEST"
        echo "  ✅ 덮어쓰기(force): .claude/commands/k-orchestrator/$BASENAME"
      else
        if diff -q "$cmd" "$DEST" > /dev/null 2>&1; then
          echo "  ⏭  동일: .claude/commands/k-orchestrator/$BASENAME"
        else
          cp "$cmd" "$DEST"
          echo "  ✅ 업데이트: .claude/commands/k-orchestrator/$BASENAME"
        fi
      fi
    else
      cp "$cmd" "$DEST"
      echo "  ✅ 신규: .claude/commands/k-orchestrator/$BASENAME"
    fi
  done

  # Update skills (overwrite)
  for skill_dir in "$PLUGIN_DIR/skills/"*/; do
    [ -d "$skill_dir" ] || continue
    SKILL_NAME="$(basename "$skill_dir")"
    SKILL_SRC="$skill_dir/SKILL.md"
    SKILL_DEST="$TARGET/.claude/skills/k-orchestrator/$SKILL_NAME/SKILL.md"
    if [ -f "$SKILL_SRC" ]; then
      mkdir -p "$(dirname "$SKILL_DEST")"
      cp "$SKILL_SRC" "$SKILL_DEST"
      echo "  ✅ 업데이트: .claude/skills/k-orchestrator/$SKILL_NAME/SKILL.md"
    fi
  done

  # Templates in docs/ tasks/ qa/ are NOT overwritten (user project files)
  echo ""
  echo "  ℹ️  프로젝트 문서(docs/, tasks/, qa/)는 업데이트하지 않습니다"
  echo "  ℹ️  필요 시 수동으로 비교하십시오"
fi

echo ""
echo "✅ k-orchestrator 설치 완료 (v1.5.0)"
echo ""
echo "설치된 구조:"
echo "  docs/CC_ORCHESTRATOR.md          — 운영 정책"
echo "  docs/EXECUTION_STATUS.md         — 실행 상태 원장"
echo "  docs/PROJECT_FOUNDATION.md       — foundation 요약"
echo "  tasks/BATCH_TEMPLATE.md          — batch 템플릿"
echo "  qa/BATCH_TEMPLATE_QA.md          — QA 템플릿"
echo "  .claude/commands/k-orchestrator/ — 14개 command"
echo "  .claude/skills/k-orchestrator/   — 3개 skill (2 policy + 1 감지)"
echo "  .claude/settings.json            — 프로젝트 권한"
echo "  .claude/settings.local.json      — hooks"
echo ""
echo "다음 단계:"
echo "  /k-orchestrator:setup-project-suite"
