---
description: 3-모델 합의 계획 — CCG 기반 ralplan 프로토콜로 approved planning artifact 생성
argument-hint: [batch 작업 설명]
allowed-tools: Read, Write, Bash, Glob
---

당신은 이 저장소에서 CCG 기반 계획 수립기로 동작하는 Claude Code입니다.

작업 설명:
$ARGUMENTS

목표:
3개 AI 모델(Claude, Codex, Gemini)의 독립 계획을 수집하고,
교차 모델 검증을 거쳐 approved planning artifact를 생성하십시오.

## 프로토콜 (CCG-Ralplan)

### 1단계: 3-모델 병렬 계획 (Planner)

아래 3개 모델에게 동일한 계획 요청을 보내되, 각각 독립적으로 수행:

**Claude (직접 수행):**
- 현재 저장소 상태와 source of truth를 분석하여 계획 작성
- 아래 출력 스키마를 준수

**Codex (omc ask codex):**
```bash
omc ask codex "다음 batch 작업에 대한 구현 계획을 작성하시오.
작업: {작업 설명}
출력 형식: scope, touched_files, risks, review_checkpoints, test_checkpoints, close_criteria 섹션을 반드시 포함"
```

**Gemini (omc ask gemini):**
```bash
omc ask gemini "다음 batch 작업에 대한 구현 계획을 작성하시오.
작업: {작업 설명}
출력 형식: scope, touched_files, risks, review_checkpoints, test_checkpoints, close_criteria 섹션을 반드시 포함"
```

두 외부 모델은 병렬로 호출하십시오.

### 출력 스키마 (각 모델 공통)

각 모델의 계획은 반드시 아래 섹션을 포함해야 합니다:
- **scope**: 작업 범위 (포함/제외 명시)
- **touched_files**: 수정 예상 파일/모듈 목록
- **risks**: 식별된 위험 요소
- **review_checkpoints**: 리뷰 시 확인할 항목
- **test_checkpoints**: 테스트/검증 항목
- **close_criteria**: batch 종료 기준

### 2단계: 합성 (Claude 수행)

3개 모델의 계획 아티팩트를 수집한 후:
1. `.omc/artifacts/ask/codex-*.md`와 `.omc/artifacts/ask/gemini-*.md`에서 최신 결과 읽기
2. 아래 구조로 합성:
   - **합의점**: 3개 모델이 동의한 항목
   - **충돌점**: 모델간 의견이 다른 항목 (각 모델 입장 명시)
   - **고유 인사이트**: 특정 모델만 제시한 가치 있는 항목
3. 초안 계획(draft plan) 작성

### 3단계: Architect 검증

기본: Claude Opus가 직접 검증
--architect codex 지정 시: `omc ask codex "다음 계획을 검증하시오: {초안 계획}"`
--architect gemini 지정 시: `omc ask gemini "다음 계획을 검증하시오: {초안 계획}"`

Architect 검증 항목:
- 구조적 건전성
- 반론(antithesis) — 이 계획의 가장 강한 반대 논거
- tradeoff tension — 최소 1개의 실질적 상충 관계
- scope 누락 여부

### 4단계: Critic 비평 (교차 모델)

Critic은 반드시 Architect와 다른 모델이 수행:
- Architect가 Claude → Critic은 Codex (`omc ask codex`)
- Architect가 Codex → Critic은 Claude (직접)
- Architect가 Gemini → Critic은 Claude (직접)

Critic 검증 범위 (좁은 역할):
- batch close criteria 충족 가능성
- 식별되지 않은 위험
- test/review checkpoint 누락
- dependency 미확인 항목

Critic 판정:
- APPROVE: 계획 승인
- ITERATE: 특정 쟁점 재검토 필요 (피드백 명시)
- REJECT: 근본적 재계획 필요

### 5단계: 반복 (max 3회)

ITERATE 또는 REJECT 시:
1. Critic 피드백을 포함하여 1단계로 돌아감
2. 미해결 치명 쟁점이 남아있을 때만 반복
3. 3회 도달 시 최선 버전을 사용자에게 제시

### 6단계: 최종 산출물

승인된 계획을 `tasks/BATCH_XX.md`에 반영:
- scope, touched_files, risks, review_checkpoints, test_checkpoints, close_criteria 필수 포함
- 사용된 모델과 합의/충돌 요약을 계획 문서 하단에 기록

batch 상태를 NOT STARTED → OPEN으로 전환.

### 7단계: 실행 경로 안내

계획 승인 후 실행 방법 안내:
- launch-critical 또는 대규모 batch → `team ralph` 권장
- 일반 batch → `ralph` 권장
- 또는 `/k-orchestrator:orchestrate-run`으로 전체 루프 실행

## 실패 처리

- Codex CLI 불가: Claude + Gemini 2-모델로 진행, 제한 명시
- Gemini CLI 불가: Claude + Codex 2-모델로 진행, 제한 명시
- 둘 다 불가: Claude 단독 계획 (ralplan 대체)
- timeout/빈 응답: 1회 재시도 후 실패 시 가용 모델로 진행
