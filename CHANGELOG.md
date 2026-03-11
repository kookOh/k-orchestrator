# CHANGELOG

## [1.3.2] - Documentation Modernization

### 개선
- 상태머신 정의에 `ralplan (/omc-plan --consensus)` 병기 (orchestrate-run, CC_ORCHESTRATOR_TEMPLATE, batch-execution-policy)
- help.md: OMC 알림 시스템(v4.5.0+) 활용 팁 추가
- help.md: 대규모 batch에서 `/team` 선택적 활용 경로 언급

### 호환성
- OMC 4.1.x ~ 4.7.9 환경에서 동작 확인

## [1.3.1] - OMC 4.7.9 Compatibility Patch

### 수정
- `code-review` skill 참조를 OMC-agnostic 자연어로 변경
  (OMC 4.7.8에서 thin wrapper skill 제거에 따름, 4개 파일 5곳)
- session-state-detector skill 설치 확인 목록 누락 반영 (setup-project-suite, MIGRATION)
- "policy skill" 라벨을 "skill (2 policy + 1 감지)"로 정정

### 개선
- CC_ORCHESTRATOR_TEMPLATE: agent 충돌 방지 규칙을 hybrid 방식으로 변경
  (핵심 4종 명시 + OMC 전체 agent 포괄 규칙)
- setup-project-suite: 기존 프로젝트의 stale `code-review` 참조 감지 경고 추가

### 호환성
- OMC 4.1.x ~ 4.7.9 환경에서 동작 확인

## [1.3.0] - Operational Visibility Release

### 신규 기능
- session-state-detector skill: 세션 시작 시 프로젝트 오케스트레이션 상태 자동 감지 (resume-run 수동 호출 대체)
- dashboard: 모든 batch 파일을 파싱하여 진행 현황 단일 뷰 대시보드 제공 (진행 바, blocker 요약 포함)

### 개선
- Glob 추가: setup-project-suite, normalize-repo, resume-run, bootstrap-ops
- Grep 추가: normalize-repo, resume-run
- BATCH_TEMPLATE에 선택적 의존성(Dependencies) 섹션 추가
- 명령 수 13개, skill 수 3개로 반영

### 수정
- project-settings.json K_ORCHESTRATOR_VERSION: 1.1.0 -> 1.3.0
- claude-settings.example.json version: 1.1.0 -> 1.3.0

## [1.2.0] - Usability Release

### 신규 기능
- help: 상황별 명령 가이드 (8개 시나리오, 12개 명령 빠른 참조표, 워크플로우 다이어그램)
- update: 자체 업데이트 — GitHub에서 최신 버전 확인 및 안전한 적용 (--check, --force 지원)

### 개선
- install.sh --update 플래그 추가: 기존 파일 덮어쓰기 업데이트 모드
- install.sh --force 플래그 추가: 사용자 수정 파일 강제 업데이트
- 명령 수 12개로 반영 (install.sh, README, INSTALL, MIGRATION)

## [1.1.0] - Hardening Release

### 신규 기능
- next-batch: 다음 batch 식별 및 OPEN 준비 (orchestrate-run 전체 루프 없이 단일 batch 착수)
- normalize-repo: 파일 구조 정합성 검증 및 교정

### 개선
- 작업 상태 분류 체계 도입: READY / BLOCKED / DEFERRED / OPTIONAL
  - 큰 작업(L effort)만으로 BLOCKED 분류 금지 규칙 명시
  - BLOCKED는 저장소 밖 이유(외부 승인, credential, 콘솔, 법무/사업 결정)에만 사용
- 종료 판정 2단 구조 도입: Primary + Secondary termination status
- install.sh v1.1.0: skills 설치 지원, BATCH_TEMPLATE 경로 수정 (docs/ → tasks/)
- CC_ORCHESTRATOR_TEMPLATE: 상태 분류표, 종료 판정 체계, 상태머신 전환 규칙 추가
- EXECUTION_STATUS_TEMPLATE: 작업 상태 분류 섹션, 종료 판정 섹션 추가
- setup-project-suite: skills 설치 확인 항목 추가
- project-settings.json: .claude/skills/* 경로 권한 추가

### 수정
- BATCH_TEMPLATE.md → tasks/ (기존 docs/에서 이동)
- BATCH_TEMPLATE_QA.md → qa/ (기존 docs/에서 이동)
- install.sh가 policy skills를 .claude/skills/k-orchestrator/에 복사하도록 수정
- README/INSTALL/MIGRATION 문서와 install.sh 동작 일치시킴

## [1.0.0] - 초기 릴리스
- setup-project-suite: 저장소 감사 + 전체 bootstrap 통합 진입점
- foundation-pack: foundation 문서 세트 생성
- bootstrap-ops: 운영 구조 정렬 + 상태 부트스트랩
- orchestrate-run: batch 기반 자동 실행 오케스트레이터 (상태머신 전환 규칙 포함)
- resume-run: 세션 재개
- change-impact: 신규 기능/변경 요청 영향 분석 (Type A/B/C)
- make-extension-block: PROJECT EXTENSION BLOCK 생성
- setup-memory-layer: 선택형 memory 계층 설정
- batch-execution-policy skill: 배치 실행 정책 강제
- memory-layer-policy skill: 보조 기억 계층 사용 정책 강제
- CC_ORCHESTRATOR 템플릿: 금지사항/재개규칙/OMC충돌/batch규칙/문서업데이트규칙 포함
- EXECUTION_STATUS 템플릿: 인간작업/병렬안전작업/마지막실행기록 섹션 포함
- PLUGIN_DIAGNOSTIC_TEMPLATE: 설치 직후 진단 결과 기록용
- MIGRATION.md: 기존 프로젝트 적용 가이드
- team-settings: 팀 배포용 .claude/settings.json 예시
- install.sh: 자동 설치 스크립트
- project-settings.json: 프로젝트 권한 범위 템플릿
- command 파일명: k- prefix 제거, /k-orchestrator:command-name namespace 호출
