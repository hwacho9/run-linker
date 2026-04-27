# GymLinker x RunLinker 연동 로드맵

## 목표

RunLinker에서 달린 기록을 GymLinker에서도 확인할 수 있게 한다. 두 앱은 같은 사용자를 식별하고, RunLinker가 저장한 러닝 기록을 GymLinker가 안전하게 조회한다.

## 권장 방향

가장 단순하고 안정적인 방식은 두 앱이 같은 Firebase Auth 사용자 `uid`를 공유하는 것이다. 같은 Firebase 프로젝트를 쓰기 어렵다면 GymLinker 사용자와 RunLinker 사용자를 연결하는 별도 계정 링크 테이블을 둔다.

```text
RunLinker iOS
  -> RunSessionRepository
  -> Firebase 또는 공통 API
  -> fitnessActivities

GymLinker
  -> FitnessActivityRepository
  -> 같은 uid 또는 linked uid 기준으로 RunLinker 기록 조회
```

## 공통 데이터 모델

```text
users/{uid}

fitnessActivities/{activityId}
  ownerUid: string
  sourceApp: "runlinker"
  sourceSessionId: string
  type: "run"
  startedAt: timestamp
  endedAt: timestamp
  distanceKm: number
  durationSec: number
  avgPaceSecPerKm: number
  syncScore: number?
  visibility: "private" | "linked_apps"
  createdAt: timestamp
  updatedAt: timestamp

fitnessActivities/{activityId}/routePoints/{pointId}
  lat: number
  lng: number
  timestamp: timestamp
```

GymLinker 첫 버전에서는 경로 좌표까지 보여주지 말고 요약 정보만 조회한다. routePoints는 민감 정보라 별도 권한 정책을 둔다.

## 연동 단계

1. 유저 식별 방식 결정
   - 1순위: GymLinker와 RunLinker가 같은 Firebase Auth 프로젝트 사용
   - 2순위: `linkedAccounts/{linkId}`로 `gymLinkerUid`, `runLinkerUid` 매핑
   - 앱 내 동의 문구 추가: RunLinker 기록을 GymLinker에 표시

2. Firestore 스키마 확정
   - `fitnessActivities`를 공통 활동 테이블로 사용
   - 러닝 전용 필드는 optional 또는 `runMetadata`로 분리
   - `sourceApp + sourceSessionId`로 중복 저장 방지

3. RunLinker 저장 구현
   - `SessionRepositoryProtocol.saveSession(_:routePoints:)`에서 Firestore 저장
   - 솔로 달리기 종료 시 `fitnessActivities`에 기록 생성
   - 친구/랜덤 달리기도 결과 저장 시 같은 스키마 사용

4. GymLinker 조회 구현
   - `FitnessActivityRepository` 추가
   - `ownerUid == currentUser.uid`, `sourceApp == "runlinker"`, `type == "run"` 조건으로 조회
   - 홈 또는 운동 기록 화면에 최근 러닝/주간 러닝 거리 표시

5. 보안 규칙
   - 기본은 본인만 읽기/쓰기
   - GymLinker는 같은 uid 또는 linked uid만 읽기 가능
   - routePoints는 summary와 분리해 더 강한 권한 적용

6. 마이그레이션
   - 기존 RunLinker 세션을 `fitnessActivities`로 백필
   - 중복 방지를 위해 `sourceSessionId`를 반드시 저장

7. 운영 안정화
   - 오프라인 저장 큐
   - 저장 실패 재시도
   - App Check 적용
   - 삭제/숨김/연동 해제 정책 정리

## 구현 우선순위

1. RunLinker `FirebaseSessionService.saveSession` 실제 구현
2. GymLinker `FitnessActivityRepository` 조회 구현
3. GymLinker UI에 RunLinker 러닝 기록 섹션 추가
4. linked account 또는 shared uid 정책 확정
5. routePoints 공유 여부와 개인정보 설정 추가
