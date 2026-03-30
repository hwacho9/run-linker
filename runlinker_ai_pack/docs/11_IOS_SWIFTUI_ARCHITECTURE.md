# RunLinker iOS SwiftUI 아키텍처

## 1. 목표
- SwiftUI로 빠르게 MVP를 구현하되, 나중에 Android가 따라오기 쉬운 구조 유지
- 화면 계층은 SwiftUI답게 단순하게 유지
- 비즈니스 로직은 View에 흩어지지 않게 repository/service 계층으로 분리

## 2. 추천 구조
### 앱 레벨
- `RunLinkerApp.swift`: 앱 엔트리
- `RootTabView.swift`: Home / Activity / Friends / My
- `AppRouter.swift`: 탭 외 플로우 상태 관리

### Feature 레벨
각 기능은 다음 단위를 가진다.
- View
- ViewModel
- Model (필요 시)
- Supporting Components

예:
```text
Features/Home/
  HomeView.swift
  HomeViewModel.swift
  Components/
```

## 3. 상태 관리 원칙
- 화면 로컬 상태: `@State`
- 하위 뷰 전달: `@Binding`
- 화면 단위 로직: `ObservableObject` ViewModel
- 앱 전역 의존성: Environment injection 또는 단순 DI container
- 네트워크/실시간 데이터: repository + async stream / listener adapter

## 4. 네비게이션 원칙
- 루트 탭: `TabView`
- 각 탭 내부 세부 화면: `NavigationStack`
- 세션 플로우는 별도 route enum으로 관리
- Match Setup은 탭이 아니라 flow 화면

## 5. 실시간 러닝 화면 원칙
Live Run 화면은 다음 세 블록을 유지한다.
1. Session header
2. Pair View
3. Split Live Maps + dual stats + sync bar

친구 모드와 랜덤 모드는 같은 레이아웃을 쓰되, 위치 정밀도만 다르게 노출한다.

## 6. 테스트 전략
- ViewModel 단위 테스트 우선
- domain mapping test 추가
- privacy mode별 location redaction test 필수
- Live Run 요약 계산은 pure logic로 분리해서 테스트

## 7. AI 코드 생성 시 금지사항
- View 안에 Firebase 로직 직접 작성 금지
- Firestore document key를 View에서 직접 다루지 말 것
- 큰 singleton 남발 금지
- 모든 화면을 한 파일에 몰아넣지 말 것
