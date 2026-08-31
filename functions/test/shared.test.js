'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  clampInteger,
  constantTimeEquals,
  extractBearerToken,
  isValidAuthorizationCode,
  isValidPKCEChallenge,
  isValidPKCEVerifier,
  isValidState,
  sha256,
  sha256Base64URL
} = require('../integration/shared');

test('extractBearerToken accepts a well-formed bearer header', () => {
  assert.equal(extractBearerToken({ authorization: 'Bearer token-value' }), 'token-value');
  assert.equal(extractBearerToken({ Authorization: 'bearer second-token' }), 'second-token');
});

test('extractBearerToken rejects missing and ambiguous headers', () => {
  assert.equal(extractBearerToken({}), null);
  assert.equal(extractBearerToken({ authorization: 'Basic abc' }), null);
  assert.equal(extractBearerToken({ authorization: 'Bearer one two' }), null);
});

test('state and authorization code validation reject unsafe values', () => {
  const valid = 'a'.repeat(43);
  assert.equal(isValidState(valid), true);
  assert.equal(isValidAuthorizationCode(valid), true);
  assert.equal(isValidState('short'), false);
  assert.equal(isValidAuthorizationCode('a'.repeat(32) + '?'), false);
});

test('PKCE validation accepts S256-compatible values only', () => {
  const verifier = 'v'.repeat(43);
  const challenge = sha256Base64URL(verifier);
  assert.equal(isValidPKCEVerifier(verifier), true);
  assert.equal(isValidPKCEChallenge(challenge), true);
  assert.equal(challenge.length, 43);
  assert.equal(isValidPKCEVerifier('short'), false);
  assert.equal(isValidPKCEChallenge(`${challenge}?`), false);
  assert.equal(constantTimeEquals(challenge, sha256Base64URL(verifier)), true);
  assert.equal(constantTimeEquals(challenge, sha256Base64URL('x'.repeat(43))), false);
});

test('sha256 is stable and clampInteger enforces API limits', () => {
  assert.equal(sha256('value'), sha256('value'));
  assert.notEqual(sha256('value'), sha256('other'));
  assert.equal(clampInteger('200', 30, 1, 100), 100);
  assert.equal(clampInteger('bad', 30, 1, 100), 30);
});
