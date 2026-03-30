# AI 프롬프트 03 — Firebase 백엔드/계약 구현

다음 문서를 기준으로 Firebase 중심의 초기 백엔드 골격을 구현해줘.

참조 문서:
- docs/04_BUSINESS_LOGIC.md
- docs/05_DATA_MODEL.md
- docs/06_API_REALTIME_CONTRACTS.md
- docs/07_PRIVACY_AND_SAFETY.md
- docs/11_IOS_SWIFTUI_ARCHITECTURE.md

목표:
- Firestore 컬렉션 설계 반영
- Cloud Functions skeleton 생성
- iOS repository/service interface 생성
- mock 구현과 firebase 구현이 교체 가능하도록 추상화
- shared/contracts 에 payload 예시와 enum 사전을 정리

우선 구현할 기능:
1. auth bootstrap
2. list friends
3. create match request
4. cancel match request
5. random match assignment stub
6. create run session
7. update ready state
8. publish live sample
9. send reaction
10. finish session and create summary
11. fetch activity history
12. fetch my stats
13. fetch session detail
14. update privacy settings

보안 규칙에서 반드시 지킬 것:
- random 모드 exact location 기본 비공개
- blocked user 매칭 금지
- session 종료 후 live location write/read 차단
- session 참가자만 session 데이터 접근 가능

원하는 결과:
- 타입 안정성 있는 도메인 계약
- Swift DTO / domain mapper
- functions 디렉토리 구조
- repository interface
- mock repository와 firebase repository 둘 다 준비
