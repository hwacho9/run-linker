# RunLinker API 및 실시간 계약

## 1. 개요
MVP 기준으로 Firebase Auth + Firestore + Cloud Functions 조합을 사용한다.  
실시간 화면은 Firestore subscription 또는 socket-like abstraction으로 구현하되, 클라이언트에는 repository/service 계층을 둔다.

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

## 3. 예시 TypeScript 계약
```ts
type HomeSummaryResponse = {
  recentSession?: SessionSummary;
  weeklyDistanceMeters: number;
  averagePaceSecPerKm?: number;
  streakDays: number;
  recentPartner?: {
    userId: string;
    nickname: string;
    avatarUrl?: string;
  };
};

type CreateMatchRequestInput = {
  mode: "friend" | "random" | "solo";
  invitedUserId?: string;
  targetDistanceKm?: number;
  targetDurationMin?: number;
  targetPaceSecPerKm?: number;
  voiceEnabled: boolean;
  cheerEnabled: boolean;
  locationShareLevel: "exact" | "approx" | "hidden";
};

type CreateMatchRequestResponse = {
  matchRequestId: string;
  status: "open" | "matched";
};

type ReadyStateInput = {
  sessionId: string;
  ready: boolean;
};

type PublishLiveSampleInput = {
  sessionId: string;
  distanceMeters: number;
  durationSec: number;
  currentPaceSecPerKm?: number;
  lat?: number;
  lng?: number;
  sharePrecision: "exact" | "approx" | "hidden";
};

type SendReactionInput = {
  sessionId: string;
  receiverUserId: string;
  type: "fight" | "nice" | "keep_going" | "together";
};

type FinishSessionInput = {
  sessionId: string;
};

type ActivityHistoryResponse = {
  items: SessionHistoryItem[];
  nextCursor?: string;
};

type SessionHistoryItem = {
  sessionId: string;
  startedAt?: string;
  mode: "friend" | "random" | "solo";
  partnerName?: string;
  distanceMeters: number;
  durationSec: number;
  avgPaceSecPerKm?: number;
  syncScore?: number;
  mapThumbnailUrl?: string;
};
```

## 4. 실시간 구독 채널 개념
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

## 5. 서버 권장 책임
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

## 6. 보안 규칙 핵심
- 사용자는 자신이 속한 session만 구독 가능
- random match partner의 exact location은 읽기 금지
- blocked relationship이면 matchmaking 제외
- session ended 이후 live location write/read 금지