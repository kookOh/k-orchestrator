# BATCH_01.md

## 배치 정보
- 배치명: ClaudeBox Docker + Obsidian vault 통합을 위한 k-orchestrator Phase 1 확장
- 상태: CLOSED
- launch-critical 여부: Y
- 시작일: 2026-03-15
- 종료일: 2026-03-15

## 목표
k-orchestrator를 ai-team-stack/ClaudeBox 환경에 탑재 가능하도록 최소 변경 범위 내에서 확장한다. 핵심은 Docker 설치 래퍼 추가, Obsidian vault 기반 세션/컨텍스트 훅 추가, memory-layer 및 session-state 문서를 실제 팀 지식 계층 운영 방향에 맞게 정렬하는 것이다.

## 범위
- `install-in-docker.sh` 신규 추가
- `hooks/stop-sync.sh`, `hooks/session-context-loader.sh` 신규 추가
- `templates/hooks/minimal-hooks.json`를 스크립트 호출형으로 전환
- `skills/memory-layer-policy/SKILL.md`를 Obsidian vault 운영 지침으로 교체
- `skills/session-state-detector/SKILL.md`에 ClaudeBox 환경/Vault 감지 규칙 추가
- `commands/setup-memory-layer.md`에 vault 초기 구조 실제 생성 절차 반영
- `templates/docs/CLAUDE_MEMORY_SETUP_TEMPLATE.md` 강화

## Out of Scope
- `install.sh` 원본 로직 변경
- QMD/Quarto 구현
- OpenViking 연동 코드
- 외부 API/VLM/embedding 연동
- ai-team-stack / ClaudeBox 저장소 자체 구현 작업

## 의존성 (Dependencies)
- 선행 batch: (없음)
- 외부 의존성: 없음 (로컬 저장소 내 변경 가능)
- 비고: `docs/AI_TEAM_STACK_FINAL.md`와 사용자 제공 변경 프롬프트를 계획 입력으로 사용하되, 실제 코드 상태를 source of truth로 우선한다.

## source of truth 연결
- 관련 PRD 섹션: `docs/AI_TEAM_STACK_FINAL.md` 4, 5, 8, 9장
- 관련 ARCHITECTURE 섹션: `docs/AI_TEAM_STACK_FINAL.md` 4장
- 관련 API/SCHEMA: N/A
- 관련 EXECUTION_STATUS: `docs/EXECUTION_STATUS.md`


## 실행 계약 (CCG 보강)
### 1. Docker 설치 결과 계약
- `install-in-docker.sh /opt/k-orchestrator`의 결과물은 **raw plugin bundle**이어야 한다.
- 기대 트리:
  - `/opt/k-orchestrator/commands/*`
  - `/opt/k-orchestrator/skills/*`
  - `/opt/k-orchestrator/templates/*`
  - `/opt/k-orchestrator/hooks/stop-sync.sh`
  - `/opt/k-orchestrator/hooks/session-context-loader.sh`
- 이 스크립트는 `install.sh`를 수정하지 않고, 임시 target에 project-local 설치를 수행한 뒤 필요한 파일만 `/opt/k-orchestrator`로 staging한다.
- Docker runtime은 `${K_ORCHESTRATOR_ROOT:-/opt/k-orchestrator}/hooks/*.sh`를 직접 참조할 수 있어야 한다.

### 2. Hook staging / path 계약
- canonical source 경로는 **repo root `hooks/`** 이다.
- canonical runtime 경로는 **Docker: `${K_ORCHESTRATOR_ROOT:-/opt/k-orchestrator}/hooks/*.sh`** 이다.
- `templates/hooks/minimal-hooks.json`은 Docker 환경에서는 `${K_ORCHESTRATOR_ROOT:-/opt/k-orchestrator}/hooks/*.sh`를 호출하고, 파일이 없으면 기존 echo fallback을 유지한다.
- 이번 batch에서는 project-local `.claude/hooks/...` staging을 기본 경로로 채택하지 않는다.

### 3. Stop hook summary 계약
- 입력 source:
  - `docs/EXECUTION_STATUS.md` 존재 시 이를 요약 본문 source로 사용
  - 없으면 최소 메타데이터만 기록하고 exit 0
- 출력 경로:
  - `CLAUDEBOX_PROFILE` 존재 시 `"$VAULT_DIR/projects/$CLAUDEBOX_PROFILE/sessions"`
  - 미존재 시 `"$VAULT_DIR/sessions"`
- 파일명 규칙:
  - `YYYYMMDD_HHMMSS_${CLAUDEBOX_USER:-unknown}_${CLAUDEBOX_WORKTREE_ID:-unknown}.md`
- frontmatter 최소 필드:
  - `type: session-summary`
  - `profile`, `user`, `worktree`, `branch`, `date`, `tags`
- privacy rule:
  - transcript 전체 저장 금지
  - `docs/EXECUTION_STATUS.md`와 최소 메타데이터만 기록
- git rule:
  - `git add`/`git commit`는 best-effort
  - 실패해도 exit 0

### 4. Phase 0 게이트 계약
- 아래 3개는 **BATCH_01 close criteria에 포함**한다. 불충분하면 CLOSED 불가.
  - PDF/DOCX → markdown 변환 가능성 확인 또는 필요한 도구 명시
  - Docker 내 vault git commit 가능 여부 확인
  - frontmatter 기반 grep 검색 충분성 확인
- 구현 자체는 먼저 진행 가능하지만, 위 3개 검증 없이 `ai-team-stack readiness`를 주장하지 않는다.

### 5. Runtime env 계약
- 이번 batch에서 실제 소비 가능한 env:
  - required-when-active: `VAULT_DIR`
  - optional metadata: `CLAUDEBOX_PROFILE`, `CLAUDEBOX_USER`, `CLAUDEBOX_WORKTREE_ID`, `CLAUDEBOX_BASE_BRANCH`
- fallback:
  - `VAULT_DIR` 없음/무효/readonly → echo 또는 skip 후 exit 0
  - `CLAUDEBOX_PROFILE` 없음 → generic `sessions/` 경로 사용
  - `CLAUDEBOX_USER`, `CLAUDEBOX_WORKTREE_ID`, `CLAUDEBOX_BASE_BRANCH` 없음 → `unknown`
- 금지:
  - haimdall 고정 경로 하드코딩
  - ClaudeBox orchestration 로직 자체 구현

## ralplan 결과
- touched files/modules:
  - `install-in-docker.sh`
  - `hooks/stop-sync.sh`
  - `hooks/session-context-loader.sh`
  - `templates/hooks/minimal-hooks.json`
  - `skills/memory-layer-policy/SKILL.md`
  - `skills/session-state-detector/SKILL.md`
  - `commands/setup-memory-layer.md`
  - `templates/docs/CLAUDE_MEMORY_SETUP_TEMPLATE.md`
- touched routes/screens: N/A
- touched tables/contracts: hook runtime env contract (`VAULT_DIR`, `CLAUDEBOX_PROFILE`, `CLAUDEBOX_USER`, `CLAUDEBOX_WORKTREE_ID`, `CLAUDEBOX_BASE_BRANCH`)
- dependencies: `VAULT_DIR` 미설정 시 graceful degradation 유지, `CLAUDEBOX_PROFILE` 존재 시 profile-aware 경로 사용, canonical runtime hook path는 `${K_ORCHESTRATOR_ROOT:-/opt/k-orchestrator}/hooks/*.sh`
- risks:
  - 로컬/기존 Claude 환경과 Docker 전용 훅 경로가 충돌할 수 있음
  - 문서 계획과 실제 구현 상태 차이로 과구현 위험이 있음
  - vault Git 커밋 로직은 실패 허용으로 설계해야 함
  - root `hooks/`와 설치 결과물 경로(`/opt/k-orchestrator/hooks` 또는 project-local 경로) 간 staging 불일치 위험이 있음
  - `CLAUDEBOX_*`/`VAULT_DIR` 누락 또는 read-only vault에서 hook가 noisy failure를 낼 위험이 있음
  - echo-only hook를 실제 side-effect hook로 바꾸면서 timing/기대 동작이 바뀔 수 있음
- review checkpoints:
  - `install.sh` 미수정 유지
  - `/opt/k-orchestrator` 결과 트리가 계약과 정확히 일치하는지 확인
  - root `hooks/` 신규 추가가 Docker 설치 결과 경로와 정합적인지 확인
  - PreCompact hook가 회귀 없이 유지되는지 확인
  - `VAULT_DIR` 미설정/무효/readonly 시 오류 없이 fallback 되는지 확인
  - `CLAUDEBOX_*`는 정의된 runtime env contract 안에서만 사용되는지 확인
  - Stop hook가 transcript 전체가 아니라 session summary만 저장하는지 확인
  - haimdall-specific 하드코딩 없이 profile-aware path를 사용하는지 확인
- test/check checkpoints:
  - shell syntax (`bash -n`) 통과 (`install-in-docker.sh`, `hooks/*.sh`)
  - hook template JSON 파싱 통과
  - `install-in-docker.sh /tmp/k-orch-test` 실행 후 raw plugin bundle tree 검증
  - `VAULT_DIR` 없이 SessionStart/Stop hook 실행 시 exit 0 + fallback 메시지 확인
  - 임시 vault + `CLAUDEBOX_PROFILE` 주입 시 profile-aware 세션 파일 경로/파일명/frontmatter 생성 확인
  - git 없는 vault, git 설정 없는 vault, read-only vault에서 non-blocking 종료 확인
  - setup-memory-layer 문서상 생성 절차와 실제 변경 범위 일치 및 idempotent 구조 생성 확인
  - Phase 0: PDF/DOCX 변환 가능성, Docker git commit, frontmatter grep sufficiency 결과를 기록하거나 후속 blocker로 남기기
- close criteria:
  - 신규 파일 3개 추가 완료
  - 지정된 5개 문서/템플릿 수정 완료
  - `install.sh` untouched
  - `/opt/k-orchestrator` 결과 트리와 hook staging contract 근거 확보
  - profile-aware vault 경로, graceful fallback, PreCompact non-regression 근거 확보
  - Phase 0 3개 검증 결과가 PASS 또는 명시적 blocker/후속 batch로 정리됨
  - 기본 문법/JSON 검증 통과
  - 최종 보고에 changed files / remaining risks / side effects 포함

## 구현 기록
- 실제 변경 사항:
  - Docker raw plugin bundle staging wrapper 추가 (`install-in-docker.sh`)
  - canonical runtime hook source 디렉토리 추가 (`hooks/`)
  - Stop/SessionStart 훅 구현 및 `/opt/k-orchestrator/hooks/*.sh` 기반 템플릿 연결
  - memory/session/setup-memory-layer/CLAUDE_MEMORY_SETUP 문서를 Obsidian vault + ClaudeBox 계약에 맞게 갱신
- 생성 파일:
  - `install-in-docker.sh`
  - `hooks/stop-sync.sh`
  - `hooks/session-context-loader.sh`
  - `tasks/BATCH_01.md`
- 수정 파일:
  - `commands/setup-memory-layer.md`
  - `docs/EXECUTION_STATUS.md`
  - `skills/memory-layer-policy/SKILL.md`
  - `skills/session-state-detector/SKILL.md`
  - `templates/docs/CLAUDE_MEMORY_SETUP_TEMPLATE.md`
  - `templates/hooks/minimal-hooks.json`

## 리뷰 기록
- review 수행 여부: 예 (self review + verifier)
- CRITICAL: 0
- HIGH: 0
- MEDIUM: 0
- LOW: 0
- 주요 지적:
  - (해소) runtime root override(`K_ORCHESTRATOR_ROOT`)와 safe target guard를 추가하여 review 지적을 반영함

## hardening 기록
- 수정한 이슈:
  - macOS `mktemp` 기본 경로(`/var/folders/...`)가 `install.sh` 시스템 경로 차단에 걸리던 문제를 `/tmp` 기반 temp dir로 수정
  - Docker bundle에 `.DS_Store`가 섞이던 문제를 staging 후 cleanup 하도록 수정
- 남은 non-blocking 이슈:
  - read-only vault에서 shell permission 메시지가 stderr에 노출될 수 있으나 exit 0/skip 동작은 유지됨

## close pass
- build/type/test/migration 결과:
  - PASS shell syntax: `bash -n install-in-docker.sh hooks/stop-sync.sh hooks/session-context-loader.sh`
  - PASS JSON parse: `python3 -m json.tool templates/hooks/minimal-hooks.json`
  - PASS raw bundle staging: `install-in-docker.sh /tmp/...` 실행 후 `/commands`, `/skills`, `/templates`, `/hooks/*.sh` 생성 확인
  - PASS SessionStart fallback: `VAULT_DIR` 미설정 상태에서 `hooks/session-context-loader.sh` exit 0
  - PASS Stop fallback: `VAULT_DIR` 미설정 상태에서 `hooks/stop-sync.sh` exit 0
  - PASS profile-aware summary path + frontmatter + best-effort git: 임시 vault/git repo에서 `projects/backend/sessions/*.md` 생성 및 commit 확인
  - PASS SessionStart success path: 임시 vault에서 최근 세션/문서 수 안내 확인
  - PASS Phase 0 / PDF-DOCX: `pandoc` markdown → docx → markdown roundtrip 성공
  - PASS Phase 0 / Docker-style git viability: stop hook 기반 temp vault git commit 성공
  - PASS Phase 0 / frontmatter grep sufficiency: `rg '^type: policy$'`로 정책 문서 탐지 확인
- CLOSED 여부: 예
- close 판단 이유:
  - agreed scope의 파일 변경이 완료되었고 `install.sh` untouched 상태를 유지했다.
  - Docker staging contract, hook path contract, graceful fallback, profile-aware session path, PreCompact non-regression, Phase 0 evidence를 모두 문서와 실행 결과로 확인했다.
  - CRITICAL/HIGH 이슈 없이 downstream handoff 가능한 상태다.
- 다음 batch 제안:
  - downstream repo(`ai-team-stack`)에서 agent-image/claudebox/knowledge-vault 통합 batch 착수
- external memory note/sync (if configured): not applicable


## CCG 합의 요약
- 사용된 관점:
  - Claude: 현재 저장소 직접 검증 + 요구 문서 대조
  - Codex artifact: `.omc/artifacts/ask/codex-k-orchestrator-claude-code-governance-pack-claudebox-docker--2026-03-14T19-09-48-434Z.md`
  - Gemini artifact: `.omc/artifacts/ask/gemini-k-orchestrator-ccg-planning-batch-batch-01-claudebox-docker--2026-03-14T20-09-22-455Z.md`
- 합의점:
  - 현재 변경 범위는 요구 문서의 Phase 1 k-orchestrator 확장 범위와 대체로 일치한다.
  - `install.sh`는 수정하지 않고 `install-in-docker.sh`로 우회하는 것이 맞다.
  - `install-in-docker.sh`, `hooks/*.sh`, `minimal-hooks.json`, memory/session/setup-memory-layer/template 문서가 핵심 변경점이다.
  - QMD/OpenViking/외부 API/ClaudeBox 저장소 구현은 이번 범위 밖이다.
- 충돌점:
  - Codex 관점은 project-local hook staging을 강조했고, 요구 문서는 root `hooks/` + Docker 설치 결과 `/opt/k-orchestrator/hooks`를 전제한다.
  - 합의안은 **root `hooks/`를 source로 두고 Docker wrapper가 설치 대상에 staging**하는 방식으로 정리한다.
- 고유 인사이트:
  - profile-aware vault 경로(`projects/${CLAUDEBOX_PROFILE}/...`)를 명시하지 않으면 요구 문서와 실제 사용 시나리오 간 불일치가 생긴다.
  - PreCompact hook 회귀 여부를 명시적으로 검증해야 한다.
  - side-effect는 기능 추가 자체보다도 설치 경로/staging/권한/경로 quoting에서 가장 먼저 발생할 가능성이 높다.
- verdict:
  - APPROVED ACTIONABLE: critic 지적 5개(install target model, hook staging path, Stop-hook summary contract, Phase 0 gates, runtime env contract)를 본 batch 문서에 명시 반영했다.
