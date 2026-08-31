'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { activityDocumentId, projectSession } = require('../integration/activityProjection');

function timestamp(milliseconds) {
  return { toMillis: () => milliseconds };
}

test('projectSession exposes summary fields but never route data', () => {
  const activity = projectSession('session-1', {
    ownerUid: 'user-1',
    mode: 'solo',
    startedAt: timestamp(1_000),
    endedAt: timestamp(62_000),
    distanceMeters: 1_250,
    averagePaceSecPerKm: 310,
    syncScore: 88,
    routePoints: [{ latitude: 35, longitude: 139 }]
  });

  assert.equal(activityDocumentId('session-1'), 'runlinker_session-1');
  assert.equal(activity.durationSec, 61);
  assert.equal(activity.summary.distanceMeters, 1_250);
  assert.equal(activity.summary.syncScore, 88);
  assert.equal('routePoints' in activity, false);
  assert.equal('routePoints' in activity.summary, false);
});
