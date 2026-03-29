# RunLinker 정보 구조

## 1. 하단 탭
- Home
- Activity
- Friends
- My

## 2. 핵심 러닝 플로우
Home → Match Setup → Matching → Ready Room → Live Run → Results

## 3. 보조 진입 경로
### 3-1. Friends에서 진입
Friends → 특정 친구 선택 → 같이 달리기 → Match Setup

### 3-2. Activity에서 진입
Activity → Session Detail → 다시 함께 달리기 → Match Setup

### 3-3. Home에서 Solo Run
Home → 혼자 달리기 → Match Setup → Ready Room 또는 바로 Live Run

## 4. 화면 계층
### Onboarding
- Onboarding 1
- Onboarding 2
- Onboarding 3

### Main Tabs
- Home
- Activity
  - Session History
  - My Stats
  - Session Detail
- Friends
- My

### Run Flow
- Match Setup
- Matching
- Ready Room
- Live Run
- Results

## 5. 역할 분리
### Home
- 즉시 실행
- 요약 지표만 표시
- 최근 세션, 주간 거리, 최근 상대 등 “미리보기” 수준

### Activity
- 세션 목록
- 누적 데이터
- 세션 상세
- 성장과 리텐션을 만드는 데이터 허브

### Friends
- 친구 상태 확인
- 같이 달리기 초대
- 최근 함께 달린 친구 재접속

### My
- 프로필
- 목표
- 프라이버시/알림/계정

## 6. 명명 규칙
- 제품 탭명: **Activity**
- 내부 섹션:
  - Activity > Session History
  - Activity > My Stats
- 과거 산출물에 `Records` 표기가 있어도 최종 시스템 명칭은 `Activity`로 정규화