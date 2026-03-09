# CLAUDE_MEMORY_SETUP.md

## 목적
이 프로젝트에서 OMC를 유지한 채 recall / sync-claude-sessions / Obsidian / QMD 기반 보조 기억 계층을 운영하는 방법을 설명한다.

## 역할 분리
- OMC = execution engine (주 실행 엔진, 변경 금지)
- recall = targeted recovery (상태 불명확 시에만)
- sync-claude-sessions = batch/session boundary persistence
- Obsidian/QMD = 장기 기억 / 검색 보조 계층

## source-of-truth priority
1. 코드 / DB / repo 문서
2. project execution docs / plans
3. `.omc/*`
4. Obsidian / recall 결과

## `.omc/notepad.md` 운영 원칙
- 항상 로드되는 메모리의 비대화 방지
- active batch, current blocker, next action만 유지
- 긴 세션 로그는 넣지 않는다

## global vs project-local 분리
- global `.claude`가 잘 동작하면 불필요하게 복제/덮어쓰지 않음
- project-local에는 hooks, local env, scripts, repo-specific rule만 둠

## recall 사용 규칙
- 세션 시작 시 상태가 불명확할 때만
- 실제 blocker가 있을 때만
- 주제 전환/문맥 복원이 필요할 때만
- 매 phase 호출 금지

## sync 사용 규칙
- batch CLOSED 경계 또는 SessionEnd 중심
- UserPromptSubmit 자동 sync 금지
- QMD/Obsidian 인덱스는 SessionEnd 또는 수동 maintenance 시점에만 갱신

## `VAULT_DIR` 설정
- 실제 Obsidian vault 루트 절대경로여야 함
- 프로젝트 docs 폴더를 vault처럼 사용하지 않음

## 현재 설정
- VAULT_DIR:
- recall 사용 여부:
- sync-claude-sessions 사용 여부:
- QMD 사용 여부:
- 마지막 점검일:
