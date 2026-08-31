'use strict';

const crypto = require('crypto');

const STATE_PATTERN = /^[A-Za-z0-9_-]{32,160}$/;
const CODE_PATTERN = /^[A-Za-z0-9_-]{32,160}$/;
const PKCE_CHALLENGE_PATTERN = /^[A-Za-z0-9_-]{43}$/;
const PKCE_VERIFIER_PATTERN = /^[A-Za-z0-9_-]{43,128}$/;

function extractBearerToken(headers = {}) {
  const authorization = headers.authorization || headers.Authorization;
  if (typeof authorization !== 'string') {
    return null;
  }

  const match = authorization.match(/^Bearer\s+([^\s]+)$/i);
  return match?.[1] || null;
}

function isValidState(value) {
  return typeof value === 'string' && STATE_PATTERN.test(value);
}

function isValidAuthorizationCode(value) {
  return typeof value === 'string' && CODE_PATTERN.test(value);
}

function isValidPKCEChallenge(value) {
  return typeof value === 'string' && PKCE_CHALLENGE_PATTERN.test(value);
}

function isValidPKCEVerifier(value) {
  return typeof value === 'string' && PKCE_VERIFIER_PATTERN.test(value);
}

function randomBase64URL(bytes = 32) {
  return crypto.randomBytes(bytes).toString('base64url');
}

function sha256(value) {
  return crypto.createHash('sha256').update(value, 'utf8').digest('hex');
}

function sha256Base64URL(value) {
  return crypto.createHash('sha256').update(value, 'utf8').digest('base64url');
}

function constantTimeEquals(left, right) {
  if (typeof left !== 'string' || typeof right !== 'string') return false;
  const leftBuffer = Buffer.from(left, 'utf8');
  const rightBuffer = Buffer.from(right, 'utf8');
  return leftBuffer.length === rightBuffer.length && crypto.timingSafeEqual(leftBuffer, rightBuffer);
}

function parseDate(value, fallback) {
  if (typeof value !== 'string') {
    return fallback;
  }
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? fallback : date;
}

function clampInteger(value, fallback, minimum, maximum) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed)) {
    return fallback;
  }
  return Math.min(maximum, Math.max(minimum, parsed));
}

function setNoStoreJSONHeaders(response) {
  response.set('Content-Type', 'application/json; charset=utf-8');
  response.set('Cache-Control', 'no-store');
  response.set('Pragma', 'no-cache');
}

function sendJSON(response, status, body) {
  setNoStoreJSONHeaders(response);
  response.status(status).send(JSON.stringify(body));
}

function requirePost(request, response) {
  if (request.method === 'OPTIONS') {
    response.set('Access-Control-Allow-Origin', '*');
    response.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    response.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    response.status(204).send('');
    return false;
  }

  if (request.method !== 'POST') {
    sendJSON(response, 405, { error: 'method-not-allowed' });
    return false;
  }

  return true;
}

module.exports = {
  clampInteger,
  constantTimeEquals,
  extractBearerToken,
  isValidAuthorizationCode,
  isValidPKCEChallenge,
  isValidPKCEVerifier,
  isValidState,
  parseDate,
  randomBase64URL,
  requirePost,
  sendJSON,
  setNoStoreJSONHeaders,
  sha256,
  sha256Base64URL
};
