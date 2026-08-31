'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const { calculateStats } = require('../statsCalculation');

function timestamp(date) {
  return { toDate: () => date };
}

test('calculates activity and public profile aggregates from completed sessions', () => {
  const now = new Date('2026-08-30T12:00:00Z');
  const sessions = [
    {
      mode: 'solo',
      startedAt: timestamp(new Date('2026-08-30T10:00:00Z')),
      endedAt: timestamp(new Date('2026-08-30T10:30:00Z')),
      distanceMeters: 5000,
      averagePaceSecPerKm: 360
    },
    {
      mode: 'friend',
      startedAt: timestamp(new Date('2026-08-25T10:00:00Z')),
      endedAt: timestamp(new Date('2026-08-25T10:45:00Z')),
      distanceMeters: 7000,
      averagePaceSecPerKm: 385,
      syncScore: 90
    }
  ];

  assert.deepEqual(calculateStats(sessions, now), {
    totalDistanceMeters: 12000,
    totalDurationSec: 4500,
    totalSessions: 2,
    averagePaceSecPerKm: 373,
    bestPaceSecPerKm: 360,
    averageSyncScore: 90,
    soloSessionCount: 1,
    togetherSessionCount: 1,
    weeklyDistanceMeters: 12000,
    weeklyRunCount: 2
  });
});

test('returns explicit zero values for an empty history', () => {
  const stats = calculateStats([]);
  assert.equal(stats.totalSessions, 0);
  assert.equal(stats.averagePaceSecPerKm, 0);
  assert.equal(stats.averageSyncScore, null);
});
