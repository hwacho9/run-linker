# AI 프롬프트 04 — 정합성 점검 및 리팩터링

현재 RunLinker 저장소 전체를 검토하고 아래 항목을 정리해줘.

검토 기준:
- docs와 code의 명칭 일관성
- Activity 용어 통일 여부
- 탭 구조와 실제 라우팅 일치 여부
- Home / Activity / Friends / My 역할 분리 명확성
- Live Run의 Pair View + Split Live Maps 반영 여부
- random 모드 privacy 기본값 반영 여부
- mock mode에서 앱이 실제로 동작 가능한지
- 중복 타입 / 중복 컴포넌트 / 과한 추상화 여부
- README 실행 가이드 정확성
- SwiftUI View와 ViewModel 경계가 적절한지

실행 작업:
1. 불일치 수정
2. 불필요한 복잡성 제거
3. naming 정리
4. UI 텍스트/화면 라벨 재점검
5. TODO 정리
6. 위험한 기본값 제거

마지막 보고:
- 수정한 파일 목록
- 핵심 수정 이유
- 남은 오픈 이슈
- 다음 개발 우선순위 5개
