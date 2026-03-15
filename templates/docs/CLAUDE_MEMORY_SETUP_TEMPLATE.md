# CLAUDE_MEMORY_SETUP.md

## 목적
이 프로젝트에서 OMC를 유지한 채 Obsidian vault 기반 팀 기억 계층을 운영하는 방법을 설명한다.

## 역할 분리
- OMC = execution engine (주 실행 엔진, 변경 금지)
- recall = targeted recovery (상태 불명확 시에만)
- sync-claude-sessions = batch/session boundary persistence
- **Obsidian vault = 팀 공유 장기 기억/검색**

## source-of-truth priority
1. 코드 / DB / repo 문서
2. `docs/EXECUTION_STATUS.md`
3. `.omc/*`
4. **Obsidian vault**
5. recall 결과

## 현재 설정

### Vault
- VAULT_DIR: _____ (예: `/workspace/vault` 또는 `~/obsidian-vault`)
- Project slug: _____ (예: `CLAUDEBOX_PROFILE` 또는 로컬 프로젝트명)
- Git 연동: yes / no
- 구조 초기화 완료: yes / no

### Vault 구조
```text
$VAULT_DIR/
├── team/policies/
├── projects/<project-slug>/
│   ├── architecture.md
│   ├── planning/
│   ├── incidents/
│   └── sessions/          ← Stop 훅 자동 저장
└── unsorted/
```

### Hook 연동 상태
- SessionStart vault 안내: 활성 / 미활성
- Stop 훅 vault 저장: 활성 / 미활성
- Canonical runtime hook path: `${K_ORCHESTRATOR_ROOT:-/opt/k-orchestrator}/hooks/*.sh`
- 마지막 점검일: _____

## Runtime env 계약
- required-when-active: `VAULT_DIR`
- optional metadata: `CLAUDEBOX_PROFILE`, `CLAUDEBOX_USER`, `CLAUDEBOX_WORKTREE_ID`, `CLAUDEBOX_BASE_BRANCH`
- fallback:
  - `VAULT_DIR` 미설정/무효 → 훅은 skip + exit 0
  - `CLAUDEBOX_PROFILE` 미설정 → generic `sessions/` 사용
  - 기타 metadata 미설정 → `unknown`

## 읽기 방식
- Claude Code가 vault markdown을 직접 읽기 (`ripgrep` + 파일 탐색)
- 시맨틱 벡터 검색 없음 — 폴더 구조 + frontmatter 태그 기반
- 전체 로드 금지, 필요한 문서만 선택적 읽기

## 쓰기 방식
- Stop 훅은 `docs/EXECUTION_STATUS.md`와 최소 메타데이터만 요약 저장
- transcript 전체 저장 금지
- vault Git 작업은 best-effort이며 실패해도 작업을 중단하지 않음

## 범위 밖
- QMD/Quarto 자동 구축
- OpenViking / 벡터 DB / embedding / VLM 연동
- ClaudeBox orchestration 로직 자체 구현
