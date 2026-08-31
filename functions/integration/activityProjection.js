'use strict';

function activityDocumentId(sessionId) {
  return `runlinker_${sessionId}`;
}

function projectSession(sessionId, data) {
  const durationSec = Math.max(
    0,
    Math.round((data.endedAt.toMillis() - data.startedAt.toMillis()) / 1000)
  );
  const activity = {
    ownerUid: data.ownerUid,
    type: 'run',
    sourceApp: 'runlinker',
    sourceRecordId: sessionId,
    startedAt: data.startedAt,
    endedAt: data.endedAt,
    durationSec,
    visibility: 'linked_apps',
    summary: {
      distanceMeters: data.distanceMeters,
      avgPaceSecPerKm: data.averagePaceSecPerKm,
      mode: data.mode
    },
    schemaVersion: 1
  };
  if (Number.isInteger(data.syncScore)) {
    activity.summary.syncScore = data.syncScore;
  }
  return activity;
}

module.exports = {
  activityDocumentId,
  projectSession
};
