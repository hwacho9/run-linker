'use strict';

function calculateStats(sessions, now = new Date()) {
  const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  let totalDistanceMeters = 0;
  let totalDurationSec = 0;
  let paceTotal = 0;
  let paceCount = 0;
  let bestPaceSecPerKm = null;
  let syncTotal = 0;
  let syncCount = 0;
  let soloSessionCount = 0;
  let togetherSessionCount = 0;
  let weeklyDistanceMeters = 0;
  let weeklyRunCount = 0;

  for (const session of sessions) {
    const distance = Math.max(0, Number(session.distanceMeters || 0));
    const pace = Math.max(0, Number(session.averagePaceSecPerKm || 0));
    const startedAt = session.startedAt?.toDate?.();
    const endedAt = session.endedAt?.toDate?.();
    totalDistanceMeters += distance;
    if (startedAt && endedAt) {
      totalDurationSec += Math.max(0, Math.round((endedAt - startedAt) / 1000));
    }
    if (pace > 0) {
      paceTotal += pace;
      paceCount += 1;
      bestPaceSecPerKm = bestPaceSecPerKm === null ? pace : Math.min(bestPaceSecPerKm, pace);
    }
    if (Number.isInteger(session.syncScore)) {
      syncTotal += session.syncScore;
      syncCount += 1;
    }
    if (session.mode === 'solo') soloSessionCount += 1;
    else togetherSessionCount += 1;
    if (startedAt && startedAt >= weekAgo) {
      weeklyDistanceMeters += distance;
      weeklyRunCount += 1;
    }
  }

  return {
    totalDistanceMeters,
    totalDurationSec,
    totalSessions: sessions.length,
    averagePaceSecPerKm: paceCount ? Math.round(paceTotal / paceCount) : 0,
    bestPaceSecPerKm: bestPaceSecPerKm || 0,
    averageSyncScore: syncCount ? Math.round(syncTotal / syncCount) : null,
    soloSessionCount,
    togetherSessionCount,
    weeklyDistanceMeters,
    weeklyRunCount
  };
}

module.exports = { calculateStats };
