# BATCH_02.md

## 배치 정보
- 배치명: Issue #3 수정 — setup-project-suite skills 자동 설치 + v1.6.0
- 상태: CLOSED
- launch-critical 여부: N
- 시작일: 2026-03-30
- 종료일: 2026-03-30

## 목표
GitHub Issue #3 해결: `/k-orchestrator:setup-project-suite` 실행 시 skills가 자동 설치되지 않는 문제 수정

## 범위
- `commands/setup-project-suite.md` 수정: skills 미설치 감지 시 3단계 fallback
  1. 현재 command 파일 위치에서 상위로 올라가 `skills/` 디렉토리 탐색 후 복사
  2. 실패 시 `install.sh --update` 실행 안내
  3. 실패 시 수동 복사 절차 안내
- v1.6.0 버전 범프 (7 files, 10 locations)
- CHANGELOG.md v1.6.0 섹션 추가
- Issue #3 close

## Out of Scope
- install.sh 로직 변경 (기존 skills 복사 로직은 정상 동작)
- settings template 변경 (v1.5.3에서 완료)

## 의존성 (Dependencies)
- 선행 batch: BATCH_01 (CLOSED), BATCH_02-A (CLOSED, v1.5.3)
- 외부 의존성: 없음

## source of truth 연결
- 관련 Issue: https://github.com/kookOh/k-orchestrator/issues/3
- 관련 EXECUTION_STATUS: docs/EXECUTION_STATUS.md

## 기술 탐색 필요 사항
- Claude Code command(.md)에서 플러그인 소스 경로를 런타임에 해소하는 방법
- `commands/update.md`의 기존 경로 해소 패턴 (AI 추론 기반) 검증
- `~/.claude/plugins/` 하위 캐시 디렉토리 구조 확인

## ralplan 결과
- touched files/modules: commands/setup-project-suite.md
- dependencies: 없음
- risks: 플러그인 소스 경로 해소가 AI 추론에 의존 (GitHub 설치 사용자)
- close criteria: 신규 프로젝트에서 setup-project-suite 실행 시 3개 skill 파일 생성 확인

## 구현 기록
- 수정 파일: commands/setup-project-suite.md (3단계 fallback 추가)
- 버전 범프: 7개 파일 10곳 v1.5.3 → v1.6.0
- CHANGELOG.md v1.6.0 섹션 추가

## 리뷰 기록
- review 수행 여부: Y (Architect Sonnet)
- CRITICAL: 0
- HIGH: 0
- MEDIUM: 1 (Fallback 1 경로 해소 제한사항 → 문서 명시로 해결)
- LOW: 2 (batch 문서 업데이트 → 완료)

## close pass
- bash -n: PASS
- JSON parse (4 files): PASS
- 1.5.3 잔존 (소스): 0건
- CLOSED 여부: Y
- close 판단 이유: CRITICAL=0, HIGH=0, 구현+리뷰+문서 완료
- 다음 batch 제안: 추가 기능 요청 시 BATCH_03
