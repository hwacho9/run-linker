# AI 프롬프트 05 — Stitch 산출물 반영

Stitch 디자인 산출물을 참조 자료로 사용해 RunLinker 모바일 화면을 다듬어줘.

중요한 이름 규칙:
- Stitch source에 Records가 있어도 최종 제품 이름은 Activity다.
- 최종 라우트, 화면 제목, 탭 라벨, 문서, 컴포넌트 이름에서 Activity로 통일한다.

목표:
1. Stitch 화면의 레이아웃/계층/카피 톤을 참조
2. Expo + React Native 구조에 맞게 유지보수 가능한 컴포넌트로 재구성
3. raw Stitch export는 별도 보존하고, RN adaptation을 분리
4. Live Run / Activity / My / Friends 화면 완성도를 우선 향상

검토 포인트:
- Home은 시작 액션이 가장 먼저 보이는가?
- Activity는 Session History와 My Stats가 분리되는가?
- Friends는 피드처럼 보이지 않는가?
- My는 analytics-heavy 하지 않은가?
- Live Run은 함께 달리는 감정이 전달되는가?
- random 모드 privacy 표현이 충분히 분명한가?

원하는 결과:
- Stitch를 그대로 복붙한 코드가 아니라
- RN 앱 구조에 맞는 재사용 가능한 컴포넌트와 화면 조합
- 디자인 근거와 코드 구조가 함께 설명된 변경 요약