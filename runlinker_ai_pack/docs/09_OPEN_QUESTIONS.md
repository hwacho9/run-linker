# RunLinker 오픈 질문

## 제품
1. 랜덤 매칭에서 상대 프로필 노출 범위는 어디까지 허용할까?
2. 친구 모드 exact location 기본값을 on으로 둘지, user setting 존중으로 둘지?
3. solo run 결과 화면에서 Sync Score 영역은 완전히 숨길지, solo summary 카드로 대체할지?

## iOS 구현
4. 최소 지원 iOS 버전을 16으로 둘지 17로 둘지?
5. XcodeGen을 필수로 둘지 선택으로 둘지?
6. mock data와 firebase repository 전환 지점을 어느 계층에 둘지?

## 백엔드
7. random match assignment를 Cloud Function에서 처리할지, client queue + function confirm 조합으로 처리할지?
8. live location sampling interval을 얼마로 둘지?
9. session summary aggregation을 realtime로 일부 계산할지 종료 후 계산만 할지?

## Android 2차
10. Jetpack Compose를 공식 방향으로 고정할지?
11. Android 착수 전에 enum/schema를 별도 json schema로 추출할지?
