'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const { isCompatibleMatch } = require('../matching');

function request(overrides = {}) {
  return {
    requesterUid: 'runner-a',
    mode: 'random',
    status: 'finding',
    targetDistanceMeters: 5000,
    targetPaceSecPerKm: 330,
    ...overrides
  };
}

test('matches random runners with nearby goals', () => {
  assert.equal(isCompatibleMatch(
    request(),
    request({ requesterUid: 'runner-b', targetDistanceMeters: 6000, targetPaceSecPerKm: 390 })
  ), true);
});

test('rejects random runners whose pace differs by more than two minutes', () => {
  assert.equal(isCompatibleMatch(
    request(),
    request({ requesterUid: 'runner-b', targetPaceSecPerKm: 451 })
  ), false);
});

test('friend mode requires reciprocal invitations', () => {
  const left = request({ mode: 'friend', invitedUid: 'runner-b' });
  const right = request({ requesterUid: 'runner-b', mode: 'friend', invitedUid: 'runner-a' });
  assert.equal(isCompatibleMatch(left, right), true);
  assert.equal(isCompatibleMatch(left, { ...right, invitedUid: 'runner-c' }), false);
});

test('never matches a runner with their own request', () => {
  assert.equal(isCompatibleMatch(request(), request()), false);
});
