# EXECUTION_STATUS.md

## 프로젝트 개요
- 프로젝트명:
- 제품 유형:
- 현재 목표:
- 현재 플랫폼 전제:
- 현재 launch target:

## 현재 상태 요약
- 현재 상태 분류: [STATE_0 / STATE_1 / STATE_2 / STATE_3 / STATE_4 / STATE_5]
- 현재 진행 단계:
- 현재 전체 진척 요약:
- 현재 launch-critical 기준 요약:

## source of truth 확인 결과
- 코드 상태 기준 확인일:
- 주요 기준 문서:
- 문서/코드 충돌 여부:
- 충돌이 있다면 요약:

## batch 상태 요약
| Batch | 상태 | launch-critical | 목표 | 마지막 업데이트 | 메모 |
|---|---|---|---|---|---|
| Batch 00 | NOT STARTED | Y/N |  |  |  |

## 작업 상태 분류
| 작업/항목 | 상태 | 판정 근거 |
|---|---|---|
|  | READY / BLOCKED / DEFERRED / OPTIONAL |  |

상태 판정 규칙:
- READY: 즉시 실행 가능, 외부 의존 없음
- BLOCKED: 저장소 밖 이유로 진행 불가 (외부 승인, credential, 콘솔 수동작업, 법무/사업 결정, 환경 제약)
- DEFERRED: 의도적으로 미룸 (현재 launch scope 밖, 별도 batch 분리 예정)
- OPTIONAL: nice-to-have, launch 필수 아님
- 큰 작업(L effort)이라는 이유만으로 BLOCKED 금지

## 현재 활성 batch
- 배치명:
- 상태: OPEN / REVIEW / HARDENING / CLOSE PASS / BLOCKED
- 목표:
- 범위:
- out of scope:
- 현재 남은 핵심 작업:
- closure blocker:
- 관련 문서:
- 관련 QA 문서:

## 최근 완료 batch
- 최근 CLOSED batch:
- 구현 요약:
- 리뷰 요약:
- 남은 non-blocking 이슈:

## 알려진 blocker
| 유형 | 내용 | 실제 blocker 여부 | 인간 작업 필요 여부 | unblock 후 재개 batch |
|---|---|---|---|---|

## 다음 추천 실행 순서
1.
2.
3.

## 인간이 해야 할 작업
-

## 인간 작업 없이도 병렬로 가능한 안전 작업
-

## 마지막 실행 기록
- 마지막 실행 일시:
- 마지막 실행 요약:
- 생성된 파일:
- 수정된 파일:
- 마지막 close 결과:
- 다음 세션 시작 시 가장 먼저 할 일:

## 종료 판정 (Termination Status)
- Primary: [ALL_LAUNCH_CRITICAL_DONE / BLOCKED_ON_CRITICAL_PATH / OPEN_BATCH_REMAINS / NEXT_BATCH_READY]
- Secondary: [해당하는 것 모두 기재]
  - NON_CRITICAL_BATCHES_READY
  - DEFERRED_WORK_REMAINS
  - SOME_FEATURES_BLOCKED_EXTERNALLY
  - EXTERNAL_TASKS_PENDING
  - HANDOFF_READY
  - SAFE_PARALLEL_WORK_REMAINS
- 판정 근거:
