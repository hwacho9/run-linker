# RunLinker Firebase 실제 데이터 구현 문서

- 작성일: 2026-08-30
- 대상: RunLinker iOS 및 RunLinker 전용 Firebase 프로젝트
- 범위 제외: GymLinker 앱/저장소 변경

## 1. 구현 결과

RunLinker의 화면용 목 데이터와 비어 있던 저장 동작을 실제 Firebase 흐름으로 교체했다.

- Home: 최근 러닝, 이번 주 거리, 평균 페이스, 최근 파트너를 `run_sessions`에서 조회한다.
- Activity: 실제 기록/통계만 표시하며 전체·함께·솔로·최근 필터가 동작한다.
- Friends: 공개 프로필 검색, 친구 요청, 수락/거절, 즐겨찾기, 온라인 추정, 최근 파트너를 Firestore에서 관리한다.
- My: 개인정보·알림·음성 설정과 주간 목표를 `user_settings`에 저장하고 실제 러닝 통계를 표시한다.
- Friend/Random Run: `match_requests`를 생성하고 Cloud Function이 호환되는 두 요청을 트랜잭션으로 연결한다.
- Live Run: 모든 모드에서 Core Location으로 실제 거리·시간·페이스·경로를 측정한다. 함께 달리기는 3초 주기로 진행률을 동기화한다.
- Reaction: 함께 달리는 상대에게 응원을 `live_sessions/{id}/reactions`에 기록한다.
- Results: 완료 기록과 경로를 저장하며 실패 시 재시도할 수 있다.
- 비밀번호 재설정: Firebase Auth 이메일 재설정 메일을 발송한다.

프로덕션 화면에서 `MockSessionRepository`는 제거했다. 데이터가 없으면 샘플 숫자 대신 0, `--`, 빈 상태를 표시한다.

## 2. Firebase 컬렉션

| 컬렉션 | 작성 주체 | 읽기 범위 | 용도 |
|---|---|---|---|
| `users/{uid}` | 본인 앱 | 본인 | 인증 계정의 내부 정보 |
| `profiles/{uid}` | 본인 앱 | 본인 | 비공개 프로필 |
| `public_profiles/{uid}` | 본인 앱 + 집계 함수 | 로그인 사용자 | 이메일·정확 위치가 없는 친구 검색용 프로필 |
| `user_settings/{uid}` | 본인 앱 | 본인 | 개인정보, 알림, 음성, 주간 목표 |
| `friendships/{pairId}` | 요청자/수신자 | 관계 당사자 | 요청·수락·거절·차단·즐겨찾기 |
| `match_requests/{id}` | 요청자 앱 + 매칭 함수 | 요청·초대·매칭 당사자 | 친구/랜덤 매칭 요청 |
| `live_sessions/{id}` | 매칭 함수 | 참가자 | 함께 달리기 방과 목표 |
| `live_sessions/{id}/participants/{uid}` | 각 참가자 | 참가자 | 실제 거리·시간·페이스·일시정지 상태 |
| `live_sessions/{id}/reactions/{id}` | 참가자 | 참가자 | 빠른 응원 |
| `run_sessions/{id}` | 기록 소유자 | 소유자 | 완료된 러닝 요약 |
| `run_sessions/{id}/route_points/{seq}` | 기록 소유자 | 소유자 | GPS 경로 |
| `activity_stats/{uid}` | 집계 함수 | 본인 | 서버 집계 통계 |
| `fitnessActivities/{id}` | 투영 함수 | 본인 | 연결 앱에 제공할 최소 운동 요약 |

`run_sessions`는 사용자별 사본을 저장한다. 함께 달린 두 사용자가 같은 `liveSessionId`를 사용하더라도 완료 문서 ID에 각자의 UID를 붙여 서로 덮어쓰지 않는다.

## 3. 주요 흐름

### 친구

1. 로그인 시 `FirebaseUserRepository`가 비공개 프로필과 최소 공개 프로필을 갱신한다.
2. 사용자 검색은 `public_profiles`에서 수행한다.
3. 친구 요청은 UID 두 개로 만든 결정적 `pairId` 문서에 `pending`으로 저장한다.
4. 수신자가 수락하면 `accepted`가 되고 양쪽 친구 목록에 표시된다.
5. 거절·취소·차단된 같은 쌍은 자동 재요청하지 않는다. 스팸 방지를 위한 현재 정책이다.

### 친구 러닝

1. 초대자가 친구를 고르고 `mode=friend`, `invitedUid`가 있는 요청을 생성한다.
2. 수신자의 Friends 화면에 러닝 초대가 표시된다.
3. 수신자가 수락하면 반대 방향의 요청을 생성한다.
4. `assignRunMatch`가 두 요청의 상호 초대를 확인하고 하나의 `live_session`을 만든다.

### 랜덤 러닝

1. 앱이 목표 거리와 목표 페이스로 `finding` 요청을 만든다.
2. 매칭 함수는 상태, 모드, 만료 시각, 거리 차이, 페이스 차이를 검사한다.
3. 현재 허용 범위는 거리 차이 2km 또는 큰 목표의 40% 이내, 페이스 차이 120초/km 이내다.
4. 트랜잭션에서 두 요청을 `matched`로 바꾸고 참가자 전용 `live_session`을 만든다.

### 실제 러닝 및 저장

1. Ready Room의 3초 카운트다운 후 `SoloRunTracker`가 모든 모드의 실제 GPS를 측정한다.
2. 함께 달리기는 위치 좌표를 상대에게 보내지 않고 거리·시간·페이스만 전송한다.
3. Sync Score는 현재 목표 거리 대비 두 참가자의 진행률 차이로 계산한다.
4. 종료 시 요약과 소유자 전용 GPS 경로를 저장한다.
5. `aggregateRunnerStats`가 전체/주간 통계를 갱신하고 `projectRunSessionActivity`가 연결 앱용 최소 요약을 만든다.

## 4. 보안과 개인정보

- 공개 프로필에는 이메일과 정확 위치를 저장하지 않는다.
- 랜덤/친구 라이브 동기화는 현재 정확 좌표를 공유하지 않는다.
- GPS 원본 경로는 기록 소유자만 읽을 수 있다.
- 매칭 확정과 통계 집계는 Admin SDK 함수만 쓸 수 있다.
- 클라이언트는 자신의 매칭 요청 취소와 자신의 라이브 진행률만 쓸 수 있다.
- 설정 문서는 UID 소유자만 읽고 쓸 수 있다.

## 5. 배포 순서

RunLinker Firebase 프로젝트를 선택한 상태에서 저장소 루트에서 실행한다.

```bash
cd functions
npm ci
npm test
cd ..
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only functions
```

배포되는 신규 함수:

- `assignRunMatch`
- `aggregateRunnerStats`

기존 함수:

- `projectRunSessionActivity`
- `createGymLinkerAuthorization`
- `exchangeGymLinkerAuthorization`
- `getRunLinkerActivities`

## 6. 기존 사용자 마이그레이션

- 기존 사용자는 로그인 또는 My의 DEBUG 프로필 동기화를 한 번 실행해 `public_profiles`를 생성해야 친구 검색에 노출된다.
- 기존 `run_sessions`에 `participants` 스냅샷이 없으면 앱은 본인만 복원한다. 새 기록부터 파트너 이름과 아바타 스냅샷을 저장한다.
- 기존 기록의 서버 통계가 필요하면 해당 문서를 갱신하거나 별도 백필 스크립트를 실행해 `aggregateRunnerStats`를 트리거해야 한다.

## 7. 검증 결과

- iOS Simulator arm64 Debug 빌드 성공.
- 전체 Swift 파일 구문 검사 성공.
- Cloud Functions Node 단위 테스트 12개 성공.
- Firestore Emulator가 `firestore.rules`를 오류 없이 로드함.
- `firestore.indexes.json`과 `Localizable.xcstrings` JSON 검증 성공.

## 8. 현재 제한과 다음 운영 작업

- 푸시 알림은 아직 연결하지 않았다. 친구 요청과 러닝 초대는 Friends 화면을 새로고침할 때 확인한다.
- 매칭 상태는 1.5초 폴링, 라이브 진행률은 3초 폴링이다. 사용량이 늘면 Firestore snapshot listener로 전환할 수 있다.
- 백그라운드 장시간 위치 수집은 별도 권한/배터리 정책 검토 후 활성화해야 한다.
- 차단/신고 문서와 화면은 설계만 남아 있으며 이번 범위에서는 실제 관리 UI를 만들지 않았다.
- GymLinker 앱은 요청대로 수정하지 않았다. GymLinker 연동 기능 플래그는 기본 `false`이며, GymLinker 쪽 승인 구현 전에는 앱 간 기록 교환이 활성화되지 않는다.
