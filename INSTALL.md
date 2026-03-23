# 설치 가이드

## 1. OMC 준비 (필수)
```bash
npx oh-my-claudecode@latest init
```

## 2. personal-os-skills (선택)
memory skill 계층이 필요하면 설치하십시오.

## 3. 설치
```bash
./install.sh [target-project-dir]
# 생략 시 현재 디렉토리
```

설치 시 생성되는 파일:

| 위치 | 파일 | 용도 |
|---|---|---|
| `docs/` | CC_ORCHESTRATOR.md | 운영 정책 |
| `docs/` | EXECUTION_STATUS.md | 실행 상태 원장 |
| `docs/` | PROJECT_FOUNDATION.md | foundation 요약 |
| `docs/` | PLUGIN_DIAGNOSTIC.md | 진단 기록 |
| `docs/` | CLAUDE_MEMORY_SETUP.md | memory 설정 |
| `tasks/` | BATCH_TEMPLATE.md | batch 작성 템플릿 |
| `qa/` | BATCH_TEMPLATE_QA.md | QA 작성 템플릿 |
| `.claude/commands/k-orchestrator/` | *.md (14개) | 실행 명령 |
| `.claude/skills/k-orchestrator/` | */SKILL.md (3개) | skill (2 policy + 1 감지) |
| `.claude/` | settings.json | 프로젝트 권한 |
| `.claude/` | settings.local.json | hooks |
| 루트 | CLAUDE.md | import 추가 |

기존 파일이 있으면 모두 스킵합니다. 덮어쓰기는 발생하지 않습니다.

## 4. 설치 후 첫 실행
```
/k-orchestrator:setup-project-suite
```

## 이후 운영 흐름

| 상황 | 명령 |
|---|---|
| 새 프로젝트 | foundation-pack → bootstrap-ops → orchestrate-run |
| 새 프로젝트 (대규모) | ccg-plan → team ralph → orchestrate-run |
| 진행 중 프로젝트 | bootstrap-ops → orchestrate-run |
| 세션 재개 | resume-run |
| 신규 기능 | change-impact → make-extension-block |
| 단일 batch 착수 | next-batch |
| 구조 검증 | normalize-repo |
| 도움말 | help |
| 진행 현황 확인 | dashboard |
| 플러그인 업데이트 | update (또는 update --check) |

## settings 구조

| 파일 | 역할 | 관계 |
|---|---|---|
| `.claude/settings.json` | 프로젝트 권한 범위 (permissions, env) | 프로젝트 전역 |
| `.claude/settings.local.json` | hooks (SessionStart, PreCompact, Stop) | 로컬 전용, git 제외 가능 |

hooks는 lightweight guardrail 역할만 합니다. per-prompt auto sync 금지.

## 주의사항
- `CLAUDE.md`는 덮어쓰지 않고 import 추가만 수행
- OMC agent 역할명(planner/architect/executor/verifier 등)과 동일한 subagent 정의는 충돌 유발
- hooks는 minimal-hooks.json (matcher 포함) 형식만 사용
- 기존 프로젝트 적용은 MIGRATION.md 참고
