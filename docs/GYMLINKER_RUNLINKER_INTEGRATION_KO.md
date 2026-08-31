# GymLinker × RunLinker 분리 Firebase 연동 가이드 — RunLinker 측

RunLinker 내부의 실제 데이터 구현·배포 방법은 [RUNLINKER_FIREBASE_IMPLEMENTATION_KO.md](./RUNLINKER_FIREBASE_IMPLEMENTATION_KO.md)를 함께 참고한다.

최종 업데이트: 2026-08-30

> 현재 상태: 이 문서와 구현은 RunLinker 저장소에만 존재한다. GymLinker 저장소의 앱, Functions, 화면은 변경하지 않았으며 별도 승인 전까지 연동 기능을 활성화하지 않는다. RunLinker의 `GymLinkerIntegrationEnabled` 기본값은 `false`다.

## 1. 결정 사항

GymLinker와 RunLinker는 서로 다른 Firebase 프로젝트를 유지한다.

| 구분 | GymLinker | RunLinker |
|---|---|---|
| Firebase Project ID | `gymroutine-b7b6c` | `runlinker-d8b2e` |
| Bundle ID | `com.siproject.gymroutine-mobile` | `com.valetudo.run-linker` |
| Authentication | GymLinker 회원 원본 | 독립 Auth + GymLinker SSO |
| Firestore | 근력운동 원본 | 러닝·경로 원본 |
| Analytics | GymLinker 전용 GA4 | RunLinker 전용 GA4 |

두 프로젝트 사이의 Firestore 직접 접근은 허용하지 않는다. 계정 연결과 운동 요약 조회는 HTTPS API를 통해서만 처리한다.

## 2. 전체 구조

```text
GymLinker iOS (향후 구현)                RunLinker iOS
    │                                      │
    │ GymLinker Firebase ID Token          │ 일회용 code + state + PKCE verifier
    ▼                                      ▼
createGymLinkerAuthorization ──딥링크──> exchangeGymLinkerAuthorization
      (RunLinker Functions)                  (RunLinker Functions)
                                                │
                                                ▼
                                      RunLinker Custom Token

GymLinker Firestore                    RunLinker Firestore
Result/{uid}/{month}/{id}              run_sessions/{sessionId}
        │                                      │
        ▼ 최소 요약 API                        ▼ 서버 투영
getGymLinkerActivities                 fitnessActivities/{activityId}
                                               │
                                               ▼ 최소 요약 API
                                      getRunLinkerActivities
```

## 3. 목표 계정 연결 흐름

1. 사용자가 RunLinker 로그인 화면에서 `GymLinker로 계속하기`를 누른다.
2. RunLinker가 256비트 랜덤 `state`와 PKCE `code_verifier`를 생성해 로컬에 저장한다.
3. SHA-256으로 만든 `code_challenge`와 함께 `gymlinker://runlinker-auth/authorize?...`를 연다.
4. GymLinker는 현재 GymLinker 사용자의 Firebase ID Token을 HTTPS Authorization 헤더로 RunLinker Functions에 전송한다.
5. 서버는 토큰의 서명, 발급자와 대상 프로젝트를 검증하고 `code_challenge`에 묶인 5분짜리 일회용 코드를 저장한다.
6. GymLinker는 토큰이 아니라 코드만 `runlinker://gymlinker-auth/callback`으로 돌려준다.
7. RunLinker는 원래 저장한 `state`를 검증하고, 서버는 `code_verifier`를 S256 방식으로 상수 시간 비교한 뒤 코드를 한 번만 소비한다.
8. RunLinker Functions가 GymLinker UID와 같은 UID의 RunLinker Custom Token을 발급한다.
9. 연결 문서는 `accountLinks/{uid}`에 서버 전용으로 기록된다.

Firebase ID Token, Custom Token, PKCE `code_verifier`를 URL query, 로그, Firestore 문서에 저장하면 안 된다. PKCE는 커스텀 URL 스킴 콜백이 가로채져도 일회용 코드가 다른 앱에서 교환되는 것을 방지한다.

현재는 RunLinker 측 단계만 준비되어 있다. 위 4번과 6번을 수행하는 GymLinker 딥링크 처리는 구현하지 않았다.

## 4. 구현 상태

모든 엔드포인트는 `asia-northeast1` 리전에 배포한다.

### RunLinker 프로젝트

| 함수 | 인증 | 용도 |
|---|---|---|
| `createGymLinkerAuthorization` | GymLinker Bearer ID Token | 일회용 연결 코드 발급 |
| `exchangeGymLinkerAuthorization` | 일회용 code + state | RunLinker Custom Token 교환 |
| `getRunLinkerActivities` | GymLinker Bearer ID Token | 본인의 러닝 요약 조회 |
| `projectRunSessionActivity` | Firestore 2세대 트리거 | 러닝 원본을 공유 요약으로 투영 |

### GymLinker 프로젝트 — 미구현

| 함수 | 인증 | 용도 |
|---|---|---|
| `getGymLinkerActivities` | 연결된 RunLinker Bearer ID Token | 향후 본인의 근력운동 요약 조회 |

위 함수와 GymLinker 화면·딥링크 코드는 GymLinker 저장소에 추가하지 않았다. 향후 구현할 때 RunLinker ID Token의 `gymLinkerLinked`와 `identitySource` claim을 확인해야 한다.

## 5. 공유 데이터 범위

### RunLinker → GymLinker

공유한다.

- 시작·종료 시각
- 러닝 시간
- 거리
- 평균 페이스
- 러닝 모드
- Sync Score

공유하지 않는다.

- GPS 좌표와 전체 경로
- 정확한 출발·종료 지점
- 친구 프로필 상세
- 기기 및 위치 진단 정보

### GymLinker → RunLinker

공유한다.

- 운동 일시
- 운동명
- 운동 시간
- 종목 수
- 세트 수
- 총 볼륨
- 주요 운동 부위

공유하지 않는다.

- 메모
- 사진과 사진 ID
- 세트별 상세 중량·횟수
- 체중, 생년월일, 성별
- 친구 및 소셜 정보

## 6. Firestore 구조와 권한

RunLinker 프로젝트:

```text
users/{uid}
profiles/{uid}
run_sessions/{sessionId}
  route_points/{sequence}
fitnessActivities/runlinker_{sessionId}
accountLinks/{uid}
accountLinkAuthorizations/{sha256(code)}
accountLinkRateLimits/{uid}
```

- `run_sessions`: 소유자만 읽기·쓰기
- `route_points`: 부모 세션 소유자만 읽기·쓰기
- `fitnessActivities`: 소유자 읽기, 클라이언트 쓰기 금지
- `accountLinks`, 인증 코드, rate limit: Admin SDK만 쓰기

Firebase Console에서 `accountLinkAuthorizations.expiresAt`에 Firestore TTL 정책을 설정한다. TTL이 없어도 만료된 코드는 교환할 수 없지만 자동 정리를 위해 권장한다.

## 7. 배포 절차

### RunLinker

```sh
cd /Users/chosunghwa/Desktop/workspace/run-linker
npm --prefix functions install
npm --prefix functions test
firebase deploy \
  --project runlinker-d8b2e \
  --only functions,firestore:rules,firestore:indexes
```

로컬 테스트는 Node.js 22.12 이상을 사용한다. 배포 전 Functions 런타임과 로컬 Node 버전을 맞춘다.

Firebase Functions 런타임 서비스 계정에 Custom Token 서명 권한이 없다는 오류가 나면 해당 서비스 계정에 `iam.serviceAccounts.signBlob` 권한을 부여한다. 서비스 계정 키 JSON을 앱이나 저장소에 추가하지 않는다.

### GymLinker

현재 배포 대상이 없다. GymLinker 저장소에는 이 연동을 위한 코드나 설정을 추가하지 않는다.

### iOS 설정 확인

- RunLinker는 계속 `runlinker-d8b2e`용 `GoogleService-Info.plist`를 사용한다.
- GymLinker는 계속 `gymroutine-b7b6c`용 `GoogleService-Info.plist`를 사용한다.
- GymLinker URL scheme: `gymlinker`
- RunLinker callback URL scheme: `runlinker`
- 두 프로젝트의 GA4, Crashlytics, Remote Config, App Check는 서로 독립적으로 설정한다.

## 8. 기존 사용자 마이그레이션

새로 GymLinker SSO로 들어온 사용자는 GymLinker UID와 같은 RunLinker UID를 사용한다.

기존 RunLinker 계정이 이미 있다면 이메일만 보고 자동 병합하지 않는다. 다음 순서로 별도 마이그레이션한다.

1. 사용자가 기존 RunLinker 계정과 GymLinker 계정을 각각 재인증한다.
2. 서버가 두 토큰을 모두 검증한다.
3. 기존 러닝 데이터의 `ownerUid`를 GymLinker 기준 UID로 백필한다.
4. 중복 데이터와 소셜 관계를 검토한다.
5. 감사 로그를 남긴 뒤 기존 RunLinker Auth 계정을 비활성화한다.

Apple 비공개 릴레이 이메일과 미인증 이메일은 자동 동일인 판정에 사용하지 않는다.

## 9. 운영 체크리스트

- [ ] 두 Firebase 프로젝트에 Blaze 요금제와 예산 알림 설정
- [ ] 양쪽 ID Token의 `aud`, `iss`가 각 프로젝트와 일치하는지 검증
- [ ] 인증 코드 5분 만료 및 1회 사용 테스트
- [ ] `state` 불일치·재사용·만료 및 PKCE verifier 불일치 테스트
- [ ] Firestore Rules Emulator 테스트 추가
- [ ] 인증 및 활동 API에 rate limit 모니터링 추가
- [ ] GPS·사진·메모가 API 응답에 없는지 회귀 테스트
- [ ] 계정 연결 해제 및 데이터 삭제 API 구현 전 공개 출시 금지
- [ ] 개인정보 처리방침에 앱 간 운동 요약 공유 목적과 보유 기간 반영
- [ ] 공개 출시 전 커스텀 URL 스킴을 Universal Link 기반 콜백으로 전환 검토

## 10. 현재 구현 경계

RunLinker 저장소에는 다음 기반만 준비되어 있다.

- RunLinker 러닝 원본 저장 및 공유용 최소 요약 투영
- GymLinker 토큰 검증, 일회용 코드, PKCE 기반 인증 브리지 서버
- GymLinker가 호출할 수 있는 RunLinker 러닝 요약 API
- 향후 GymLinker 근력운동 요약을 받을 RunLinker 클라이언트·화면 기반
- `GymLinkerIntegrationEnabled=false`로 로그인 버튼과 외부 데이터 요청 비활성화

GymLinker 저장소에는 관련 코드·Functions·화면이 없다. 따라서 현재 상태에서는 실제 회원 연결과 양방향 기록 조회가 동작하지 않는다.

다음 항목은 운영 출시 전에 추가해야 한다.

- 연결 해제 및 공유 중지 UI/API
- 기존 RunLinker 계정 병합 도구
- Emulator 기반 통합 테스트
- 앱이 로그아웃 상태일 때 GymLinker 연결 요청을 로그인 후 재개하는 UX
- 별도 승인 후 GymLinker 측 딥링크, 최소 요약 API와 기록 화면 구현
