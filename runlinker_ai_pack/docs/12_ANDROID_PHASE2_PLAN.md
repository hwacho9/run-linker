# RunLinker Android 2차 개발 계획

## 1. 전략
Android는 iOS 출시 또는 iOS MVP 안정화 이후 착수한다.
핵심은 iOS 코드를 그대로 옮기는 것이 아니라, 아래를 재사용하는 것이다.
- 제품 개요
- 정보 구조
- 사용자 흐름
- 비즈니스 로직
- 데이터 모델
- API / 실시간 계약
- 프라이버시 규칙
- 디자인 토큰과 Stitch 레퍼런스

## 2. 권장 스택
- Kotlin
- Jetpack Compose 권장
- Navigation Compose
- Coroutines + Flow
- Firebase Android SDK
- Retrofit은 필수 아님 (MVP는 Firebase 중심)

## 3. iOS와 맞춰야 하는 것
- 탭명: Home / Activity / Friends / My
- 모드: friend / random / solo
- Live Run 구조: Pair View + Split Live Maps
- Sync Score 정의
- privacy redaction 규칙
- Firestore 문서 구조와 enum 값

## 4. Android에서 달라질 수 있는 것
- UI 구현 방식
- navigation API
- lifecycle 처리 방식
- map rendering detail

## 5. 착수 조건
- iOS에서 화면명/도메인명 확정
- Firestore 구조 안정화
- Match / Session / Activity / Privacy 계약 확정
- Stitch 레퍼런스 반영 완료
