# PLUGIN_DIAGNOSTIC.md
> 진단일: 2026-03-15 | setup-project-suite 실행 결과

## 1. 환경 진단

| 항목 | 상태 | 비고 |
|---|---|---|
| OMC 설치 | O | `.omc/` 존재, project-memory.json 확인 |
| personal-os-skills | O | global settings에 `recall-skill@personal-os-skills` 활성 |
| CLAUDE.md | **신규 생성** | @import 방식 (CC_ORCHESTRATOR, PROJECT_FOUNDATION) |
| docs/CC_ORCHESTRATOR.md | **신규 생성** | 템플릿 기반, 프로젝트 맞춤 수정 |
| docs/PROJECT_FOUNDATION.md | **신규 생성** | 플러그인 프로젝트 맞춤 작성 |
| docs/EXECUTION_STATUS.md | **신규 생성** | 초기 상태 기록 |
| tasks/BATCH_TEMPLATE.md | **신규 생성** | 템플릿 복사 |
| qa/BATCH_TEMPLATE_QA.md | **신규 생성** | 템플릿 복사 |
| .omc/notepad.md | X | 미존재 (필요 시 생성) |
| .claude/commands/ | X | 불필요 — 플러그인 시스템이 `commands/`에서 직접 로드 |
| .claude/skills/ | X | 불필요 — 플러그인 시스템이 `skills/`에서 직접 로드 |
| .claude/agents/ | X | OMC agent 중복 없음 (정상) |
| Obsidian/QMD | 미확인 | 필요 시 `/k-orchestrator:setup-memory-layer` |

## 2. Skills 설치 상태

| Skill | 소스 위치 | 상태 |
|---|---|---|
| batch-execution-policy | `skills/batch-execution-policy/SKILL.md` | O (소스 존재) |
| memory-layer-policy | `skills/memory-layer-policy/SKILL.md` | O (소스 존재) |
| session-state-detector | `skills/session-state-detector/SKILL.md` | O (소스 존재) |

> 이 프로젝트는 플러그인 소스 저장소이므로 `.claude/skills/k-orchestrator/`에 별도 설치 불필요.
> 플러그인 시스템이 `skills/` 디렉토리에서 직접 로드함.

## 3. OMC 호환성

| 검증 항목 | 결과 |
|---|---|
| `code-review` backtick 참조 | 없음 (정상) |
| `.claude/agents/` OMC 중복 | 없음 (정상) |
| OMC agent 역할명 충돌 | 없음 (정상) |

## 4. 판정

| 판정 항목 | 결과 |
|---|---|
| 구조 유형 | **HYBRID** (global OMC + project-local k-orchestrator) |
| OMC + personal-os-skills | **READY** |
| Memory bootstrap 필요 | **OPTIONAL** (장기 세션 재개 필요 시) |
| 초기 작업 상태 | **READY** (운영 구조 적용 완료, batch 대기) |
