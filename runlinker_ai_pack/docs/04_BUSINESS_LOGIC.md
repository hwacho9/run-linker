# RunLinker 비즈니스 로직

## 1. 계정 및 프로필
- 사용자는 이메일/소셜 로그인으로 계정을 생성한다.
- 프로필은 닉네임, 프로필 이미지, 소개글, 러너 성향을 가진다.
- 기본 프라이버시 설정이 계정 생성 시 함께 생성된다.

## 2. 친구 관계
- 친구는 상호 수락 기반으로 생성한다.
- 차단 관계가 있으면 친구 요청/초대/랜덤 매칭에서 제외한다.
- 즐겨찾기 친구는 UI 우선순위만 바꾸고 관계 자체를 바꾸지는 않는다.

## 3. 러닝 모드
### 3-1. Friend Mode
- 특정 친구와 세션을 생성
- exact location 공유 허용 가능
- 양측 동의가 있으면 더 상세한 지도 표시 가능

### 3-2. Random Match Mode
- 비슷한 페이스/목표를 기준으로 상대를 찾는다.
- exact location은 기본 비공개
- 시작점/종료점은 흐림 처리
- 세션 종료 시 live location 공유 자동 종료

### 3-3. Solo Mode
- 상대 없음
- Pair View는 숨기거나 solo friendly 대체 UI 사용
- Sync Score 없음

## 4. Match Setup 규칙
- 사용자는 목표 거리, 시간, 페이스를 설정할 수 있다.
- friend/random/solo에 따라 노출 필드가 다르다.
- random 매칭에서는 선호 조건을 과하게 세분화하지 않는다. MVP에서는:
  - 목표 거리 범위
  - 목표 페이스 범위
  - 공개 범위
만 우선 지원한다.

## 5. 랜덤 매칭 로직
### 입력값
- 목표 거리
- 목표 페이스 범위
- 최근 활동 가능 상태
- 차단 여부
- 공개 범위 호환성

### 매칭 기준
- 페이스 차이
- 거리 목표 유사성
- 현재 가용성
- 차단/신고 상태
- 지역/시간대 호환성(선택)

### 실패 처리
- 일정 시간 안에 후보가 없으면:
  - 재검색
  - 조건 완화
  - solo 전환 제안

## 6. Ready Room 로직
- 세션 참가자 상태는 `waiting / ready / countdown / live` 로 관리
- 모든 참가자가 ready 이거나 countdown 강제 시작 조건 충족 시 시작
- countdown 중 이탈하면 ready 상태로 롤백 또는 세션 취소

## 7. Live Run 로직
### 상태 수집
- 위치
- 시간
- 거리
- 현재 페이스
- 평균 페이스
- 연결 상태
- 일시정지 여부

### 업데이트 주기
- UI용 위치 업데이트와 서버 저장용 이벤트를 분리
- 서버 저장은 배터리/비용을 고려해 축약 저장
- route trace는 일정 거리 또는 시간 간격 단위로 샘플링

### Pair View 계산
- 실제 지도 좌표가 아니라 목표 대비 진행률 기반으로 시각화
- 두 사람이 다른 도시에 있어도 함께 달리는 느낌을 제공

## 8. Quick Cheer 로직
- 정해진 이모지/문구만 우선 지원
- 최근 1~3초 내 중복 반응은 rate limit
- Live Run 화면에서 짧은 배너/햅틱으로 반영

## 9. Sync Score 로직
### 목적
- 두 사람이 얼마나 함께 달렸는지 요약한다.

### 입력
- 진행률 차이
- 페이스 차이
- 동시 러닝 유지 시간
- pause/stop 불균형
- 종료 시점 차이

### 초기 산식 예시
- pace alignment 40%
- progress alignment 30%
- simultaneous activity 20%
- finish cohesion 10%

### 결과
- 0~100 점수
- 함께 잘 달렸는지 설명 텍스트 생성
- solo mode에서는 계산하지 않음

## 10. Results 생성 로직
- 세션 종료 후 최종 거리/시간/페이스 계산
- route trace 정리
- Sync Score 산출
- 회고 메시지 생성
- 세션 summary 저장
- Activity용 aggregate 업데이트

## 11. Activity 통계 집계
### Session History
- 세션 단위 summary를 조회
- 필터 friend/random/solo
- 정렬 latest/distance/duration

### My Stats
- 총 거리
- 총 시간
- 총 세션
- 평균 페이스
- 최고 페이스
- 최근 7일/30일 거리
- 평균 Sync Score
- together vs solo 비교
- top partner

## 12. 프라이버시 규칙
- random 모드 기본 exact location 비공개
- start/end blur 기본 on
- 세션 종료 즉시 live sharing off
- 사용자는 My에서 기본값을 바꿀 수 있지만, 안전 제한 상한은 남긴다

## 13. 알림 규칙
- 친구 초대 수신
- Ready Room 시작
- 세션 시작 직전
- 친구가 다시 함께 달리기 요청
- Weekly summary(선택)

## 14. 에러/예외 처리
- 상대 연결 끊김
- GPS 부정확
- 앱 백그라운드 전환
- 세션 중 이탈
- 위치 권한 거부
- 랜덤 매칭 타임아웃
- 종료 데이터 partial save

각 케이스에서 사용자에게는 기술적인 오류보다 행동 가능한 안내를 우선 제공한다.