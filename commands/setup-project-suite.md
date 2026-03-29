---
description: 현재 저장소를 감사하고 k-orchestrator 운영 구조를 안전하게 적용하는 전체 bootstrap 진입점
argument-hint: [optional notes]
allowed-tools: Read, Write, Bash, Glob, Grep
---

당신은 현재 이 프로젝트 저장소 안에서 작업하는 Claude Code입니다.

추가 메모:
$ARGUMENTS

목표:
이 저장소에 k-orchestrator 운영 구조를 안전하게 적용하십시오.

## 반드시 점검할 항목
1. OMC 설치/사용 여부 (`which omc` 또는 `.omc/` 디렉토리 유무)
2. personal-os-skills 사용 가능 여부
3. 기존 `CLAUDE.md` 존재 여부 및 내용
4. `docs/CC_ORCHESTRATOR.md` 존재 여부
5. `docs/PROJECT_FOUNDATION.md` 존재 여부
6. `docs/EXECUTION_STATUS.md` 존재 여부
7. `tasks/` 및 `qa/` 구조 존재 여부
   - `tasks/BATCH_TEMPLATE.md` 존재 확인
   - `qa/BATCH_TEMPLATE_QA.md` 존재 확인
8. `.omc/` 존재 여부 및 notepad.md 크기
9. `.claude/commands/k-orchestrator/` 존재 여부
10. `.claude/skills/k-orchestrator/` 존재 여부 (skills 설치 확인)
11. `.claude/settings.local.json` 존재 여부 (hooks)
12. `.claude/settings.json` 존재 여부 (permissions)
13. Obsidian 또는 QMD 사용 여부
14. global `.claude` / project-local `.claude` / hybrid 판정

## 처리 규칙
- 기존 OMC `CLAUDE.md`는 절대 덮어쓰지 않음
- `CLAUDE.md`가 있으면 `@path` import 방식으로만 확장
- 없으면 새로 생성하되 기존 구조 먼저 진단
- 다음 파일이 없으면 생성:
  - `docs/CC_ORCHESTRATOR.md`
  - `docs/EXECUTION_STATUS.md`
  - `tasks/BATCH_TEMPLATE.md` (tasks/ 디렉토리에 위치)
  - `qa/BATCH_TEMPLATE_QA.md` (qa/ 디렉토리에 위치)
- `docs/PROJECT_FOUNDATION.md`가 없으면 placeholder 생성 + Foundation Pack 필요 여부 명시
- OMC agent 역할명 (planner/architect/executor/verifier 등) 중복 정의 금지 — OMC가 제공하는 모든 agent 해당
- `docs/PLUGIN_DIAGNOSTIC.md` 생성 — 진단 결과를 기록

## skills 설치 확인 및 자동 복구

다음 3개 skill 파일의 존재 여부를 확인하십시오:
- `.claude/skills/k-orchestrator/batch-execution-policy/SKILL.md`
- `.claude/skills/k-orchestrator/memory-layer-policy/SKILL.md`
- `.claude/skills/k-orchestrator/session-state-detector/SKILL.md`

누락된 skill이 있으면 아래 3단계 fallback을 순서대로 시도하십시오:

### Fallback 1: 플러그인 소스에서 직접 복사 (경로 해소 실패 시 Fallback 2로 자동 이행)
이 명령 파일이 위치한 디렉토리(commands/)의 상위로 올라가 `skills/` 디렉토리를 찾으십시오.
해당 디렉토리에서 `.claude-plugin/plugin.json`이 존재하면 그곳이 플러그인 소스 루트입니다.
`skills/*/SKILL.md` 파일을 `.claude/skills/k-orchestrator/*/SKILL.md`로 복사하십시오.
대상 디렉토리가 없으면 먼저 생성합니다:
```bash
mkdir -p .claude/skills/k-orchestrator/batch-execution-policy
mkdir -p .claude/skills/k-orchestrator/memory-layer-policy
mkdir -p .claude/skills/k-orchestrator/session-state-detector
```
각 skill의 `SKILL.md`를 읽고 대상 경로에 Write로 생성하십시오.

### Fallback 2: install.sh --update 실행
플러그인 소스 디렉토리를 찾을 수 없는 경우, 사용자에게 다음을 안내하십시오:
"skills가 설치되지 않았습니다. 다음 명령으로 설치할 수 있습니다:"
```
/k-orchestrator:update
```

### Fallback 3: 수동 복사 안내
위 두 방법이 모두 실패하면 수동 복사 절차를 안내하십시오:
"k-orchestrator 플러그인 소스의 skills/ 디렉토리에서 다음 파일을 수동으로 복사하십시오:"
```
skills/batch-execution-policy/SKILL.md → .claude/skills/k-orchestrator/batch-execution-policy/SKILL.md
skills/memory-layer-policy/SKILL.md    → .claude/skills/k-orchestrator/memory-layer-policy/SKILL.md
skills/session-state-detector/SKILL.md → .claude/skills/k-orchestrator/session-state-detector/SKILL.md
```

## OMC 호환성 검증
- 프로젝트의 `docs/CC_ORCHESTRATOR.md`에서 `code-review` backtick 참조가 남아 있으면 경고
  (OMC 4.7.8에서 `code-review` skill wrapper가 제거됨 — "code review" 자연어로 변경 필요)
- `.claude/agents/`에 OMC agent 역할명과 중복되는 정의가 없는지 확인

## 반드시 판정
- GLOBAL / LOCAL / HYBRID 여부
- OMC + personal-os-skills 준비 상태
- memory bootstrap 필요 여부
- 작업 상태 분류 (READY/BLOCKED/DEFERRED/OPTIONAL) 초기 판정

## 출력 형식 (한국어)
1. 현재 상태 진단
2. 적용/생성한 파일 목록
3. skills 설치 상태
4. 남은 수동 작업
5. 바로 다음 액션 (1개 명확한 권고)
