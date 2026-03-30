# RunLinker API 및 실시간 계약

## 1. 개요
MVP 기준으로 Firebase Auth + Firestore + Cloud Functions 조합을 사용한다.  
실시간 화면은 Firestore subscription 또는 socket-like abstraction으로 구현하되, 클라이언트에는 repository/service 계층을 둔다.

이 문서는 **플랫폼 중립적인 계약**을 정의한다.  
iOS는 Swift DTO / Domain Model로, Android는 Kotlin data class / Domain Model로 이 계약을 매핑한다.

## 2. 필수 기능 목록
- auth bootstrap
- home summary fetch
- friend list fetch
- create friend invitation / respond
- create match request
- cancel match request
- assign random match
- create run session
- ready state update
- live session subscription
- publish location sample
- publish stat sample
- send reaction
- finish session
- fetch activity history
- fetch my stats
- fetch session detail
- update privacy settings

## 3. 플랫폼 중립 JSON 계약 예시
### HomeSummaryResponse
```json
{
  "recentSession": {
    "sessionId": "sess_001",
    "mode": "friend",
    "distanceMeters": 4800,
    "durationSec": 1910,
    "avgPaceSecPerKm": 398,
    "syncScore": 87
  },
  "weeklyDistanceMeters": 14200,
  "averagePaceSecPerKm": 401,
  "streakDays": 3,
  "recentPartner": {
    "userId": "user_102",
    "nickname": "민수",
    "avatarUrl": "https://example.com/avatar.png"
  }
}
```

### CreateMatchRequestInput
```json
{
  "mode": "friend",
  "invitedUserId": "user_102",
  "targetDistanceKm": 5,
  "targetDurationMin": 30,
  "targetPaceSecPerKm": 360,
  "voiceEnabled": false,
  "cheerEnabled": true,
  "locationShareLevel": "exact"
}
```

### CreateMatchRequestResponse
```json
{
  "matchRequestId": "mr_001",
  "status": "open"
}
```

### PublishLiveSampleInput
```json
{
  "sessionId": "sess_001",
  "distanceMeters": 2100,
  "durationSec": 845,
  "currentPaceSecPerKm": 392,
  "lat": 37.5665,
  "lng": 126.9780,
  "sharePrecision": "approx"
}
```

### SessionHistoryItem
```json
{
  "sessionId": "sess_001",
  "startedAt": "2026-03-29T09:00:00Z",
  "mode": "friend",
  "partnerName": "민수",
  "distanceMeters": 5100,
  "durationSec": 1994,
  "avgPaceSecPerKm": 391,
  "syncScore": 84,
  "mapThumbnailUrl": "https://example.com/map_thumb.png"
}
```

## 4. Swift DTO 예시
```swift
struct CreateMatchRequestInput: Codable {
    let mode: RunMode
    let invitedUserId: String?
    let targetDistanceKm: Double?
    let targetDurationMin: Int?
    let targetPaceSecPerKm: Int?
    let voiceEnabled: Bool
    let cheerEnabled: Bool
    let locationShareLevel: LocationShareLevel
}

struct SessionHistoryItemDTO: Codable, Identifiable {
    let sessionId: String
    let startedAt: String?
    let mode: RunMode
    let partnerName: String?
    let distanceMeters: Double
    let durationSec: Int
    let avgPaceSecPerKm: Int?
    let syncScore: Int?
    let mapThumbnailUrl: String?

    var id: String { sessionId }
}
```

## 5. 실시간 구독 채널 개념
### Live Session Channel
전달 항목:
- session status
- participant stats
- partner presence
- reactions
- countdown state
- privacy-aware location data

### Ready Room Channel
전달 항목:
- participant ready states
- countdown start/cancel
- room info updates

## 6. 서버 권장 책임
### Cloud Functions
- random match assignment
- end session summary aggregation
- sync score computation
- privacy enforcement
- home/activity aggregation 업데이트

### Client
- optimistic UI
- map rendering
- cheer animation
- local sampling and batching
- DTO -> domain model mapping

## 7. 보안 규칙 핵심
- 사용자는 자신이 속한 session만 구독 가능
- random match partner의 exact location은 읽기 금지
- blocked relationship이면 matchmaking 제외
- session ended 이후 live location write/read 금지
