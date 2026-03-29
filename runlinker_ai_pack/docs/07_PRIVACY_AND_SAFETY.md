# RunLinker 프라이버시 및 안전 정책

## 1. 기본 원칙
- 위치 정보는 기능이 아니라 민감 정보다.
- 랜덤 매칭은 “안전 기본값”이 우선이다.
- 사용자는 설정을 바꿀 수 있지만, 위험한 기본값은 제공하지 않는다.

## 2. 모드별 공개 범위
### Friend Mode
- 정확 위치 공유 가능
- exact route 표시 가능
- 사용자의 기본값과 세션 설정을 모두 반영

### Random Match Mode
- exact location 기본 비공개
- approximate region 또는 privacy-safe map 표시
- start/end point blur 기본 on
- session 종료 후 live location 즉시 종료
- profile 노출도 제한 가능

### Solo Mode
- 타인 공유 없음

## 3. 세션 중 프라이버시
- 서버는 sharePrecision 필드를 기준으로 데이터를 정제해서 내린다.
- 클라이언트는 받은 데이터보다 더 자세한 위치를 재구성하려고 하면 안 된다.
- 세션 종료 후 location publishing 중단

## 4. 차단/신고
- 차단한 사용자는:
  - 친구 검색 제외
  - 매칭 제외
  - 초대/재초대 제외
- 신고 누적 시 moderation 검토 대상으로 표시

## 5. 권한 요청 UX
- 위치 권한은 러닝 시작 맥락에서 요청
- 알림 권한은 초대/시작 알림 가치와 함께 설명
- 거부 시 degraded experience를 안내

## 6. 안전 UX 예시
- 랜덤 매칭 화면에서 “정확 위치는 공유되지 않아요”
- Ready Room에서 현재 공개 범위 재확인
- My에서 시작/종료 지점 흐리기 설정 제공