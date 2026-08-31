'use strict';

const { initializeApp, getApp, getApps } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { FieldValue, Timestamp, getFirestore } = require('firebase-admin/firestore');
const { logger } = require('firebase-functions');
const {
  constantTimeEquals,
  extractBearerToken,
  isValidAuthorizationCode,
  isValidPKCEChallenge,
  isValidPKCEVerifier,
  isValidState,
  randomBase64URL,
  requirePost,
  sendJSON,
  sha256,
  sha256Base64URL
} = require('./shared');

const GYMLINKER_PROJECT_ID = process.env.GYMLINKER_PROJECT_ID || 'gymroutine-b7b6c';
const AUTHORIZATION_TTL_MS = 5 * 60 * 1000;
const AUTHORIZATION_COOLDOWN_MS = 3 * 1000;

function getRunLinkerApp() {
  return getApps().find((app) => app.name === '[DEFAULT]') || initializeApp();
}

function getGymLinkerVerifierApp() {
  const existing = getApps().find((app) => app.name === 'gymlinker-token-verifier');
  return existing || initializeApp(
    { projectId: GYMLINKER_PROJECT_ID },
    'gymlinker-token-verifier'
  );
}

function safeIdentity(decodedToken) {
  return {
    uid: decodedToken.uid,
    email: typeof decodedToken.email === 'string' ? decodedToken.email : '',
    emailVerified: decodedToken.email_verified === true,
    displayName: typeof decodedToken.name === 'string' ? decodedToken.name : '',
    picture: typeof decodedToken.picture === 'string' ? decodedToken.picture : ''
  };
}

async function verifyGymLinkerToken(request) {
  const token = extractBearerToken(request.headers);
  if (!token) {
    const error = new Error('missing-bearer-token');
    error.status = 401;
    throw error;
  }

  const decoded = await getAuth(getGymLinkerVerifierApp()).verifyIdToken(token);
  return safeIdentity(decoded);
}

async function createAuthorization(request, response) {
  if (!requirePost(request, response)) return;

  try {
    const state = request.body?.state;
    const codeChallenge = request.body?.codeChallenge;
    const codeChallengeMethod = request.body?.codeChallengeMethod;
    if (!isValidState(state) ||
        !isValidPKCEChallenge(codeChallenge) ||
        codeChallengeMethod !== 'S256') {
      return sendJSON(response, 400, { error: 'invalid-authorization-request' });
    }

    const identity = await verifyGymLinkerToken(request);
    const code = randomBase64URL();
    const codeHash = sha256(code);
    const now = Timestamp.now();
    const expiresAt = Timestamp.fromMillis(now.toMillis() + AUTHORIZATION_TTL_MS);
    const db = getFirestore(getRunLinkerApp());
    const authorizationRef = db.collection('accountLinkAuthorizations').doc(codeHash);
    const rateLimitRef = db.collection('accountLinkRateLimits').doc(identity.uid);

    await db.runTransaction(async (transaction) => {
      const rateLimitSnapshot = await transaction.get(rateLimitRef);
      const lastIssuedAt = rateLimitSnapshot.data()?.lastIssuedAt;
      if (lastIssuedAt && now.toMillis() - lastIssuedAt.toMillis() < AUTHORIZATION_COOLDOWN_MS) {
        const error = new Error('too-many-requests');
        error.status = 429;
        throw error;
      }

      transaction.set(authorizationRef, {
        gymLinkerUid: identity.uid,
        email: identity.email,
        emailVerified: identity.emailVerified,
        displayName: identity.displayName,
        photoURL: identity.picture,
        stateHash: sha256(state),
        codeChallenge,
        codeChallengeMethod: 'S256',
        issuedAt: now,
        expiresAt,
        consumedAt: null,
        schemaVersion: 1
      });
      transaction.set(rateLimitRef, { lastIssuedAt: now }, { merge: true });
    });

    logger.info('Issued GymLinker authorization code.', { gymLinkerUid: identity.uid });
    return sendJSON(response, 200, {
      code,
      expiresInSeconds: AUTHORIZATION_TTL_MS / 1000
    });
  } catch (error) {
    logger.warn('Failed to issue GymLinker authorization code.', { error: error.message });
    const status = error.status || (error.code?.startsWith('auth/') ? 401 : 500);
    return sendJSON(response, status, { error: status === 500 ? 'internal' : error.message });
  }
}

async function ensureLinkedRunLinkerUser(runAuth, identity) {
  let userRecord;
  try {
    userRecord = await runAuth.getUser(identity.gymLinkerUid);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    userRecord = await runAuth.createUser({
      uid: identity.gymLinkerUid,
      displayName: identity.displayName || undefined,
      photoURL: identity.photoURL || undefined
    });
  }

  const customClaims = {
    ...(userRecord.customClaims || {}),
    gymLinkerLinked: true,
    identitySource: 'gymlinker'
  };
  await runAuth.setCustomUserClaims(identity.gymLinkerUid, customClaims);
}

async function exchangeAuthorization(request, response) {
  if (!requirePost(request, response)) return;

  try {
    const code = request.body?.code;
    const state = request.body?.state;
    const codeVerifier = request.body?.codeVerifier;
    if (!isValidAuthorizationCode(code) ||
        !isValidState(state) ||
        !isValidPKCEVerifier(codeVerifier)) {
      return sendJSON(response, 400, { error: 'invalid-authorization' });
    }

    const runApp = getRunLinkerApp();
    const db = getFirestore(runApp);
    const authorizationRef = db.collection('accountLinkAuthorizations').doc(sha256(code));
    const identity = await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(authorizationRef);
      if (!snapshot.exists) {
        const error = new Error('authorization-not-found');
        error.status = 404;
        throw error;
      }

      const data = snapshot.data();
      if (data.consumedAt) {
        const error = new Error('authorization-already-used');
        error.status = 409;
        throw error;
      }
      if (data.expiresAt.toMillis() <= Date.now()) {
        const error = new Error('authorization-expired');
        error.status = 410;
        throw error;
      }
      if (data.stateHash !== sha256(state)) {
        const error = new Error('state-mismatch');
        error.status = 403;
        throw error;
      }
      if (data.codeChallengeMethod !== 'S256' ||
          !constantTimeEquals(data.codeChallenge, sha256Base64URL(codeVerifier))) {
        const error = new Error('pkce-verification-failed');
        error.status = 403;
        throw error;
      }

      transaction.update(authorizationRef, { consumedAt: FieldValue.serverTimestamp() });
      return {
        gymLinkerUid: data.gymLinkerUid,
        email: data.email || '',
        emailVerified: data.emailVerified === true,
        displayName: data.displayName || '',
        photoURL: data.photoURL || ''
      };
    });

    const runAuth = getAuth(runApp);
    await ensureLinkedRunLinkerUser(runAuth, identity);
    const customToken = await runAuth.createCustomToken(identity.gymLinkerUid, {
      gymLinkerLinked: true,
      identitySource: 'gymlinker'
    });

    await db.collection('accountLinks').doc(identity.gymLinkerUid).set({
      globalUid: identity.gymLinkerUid,
      gymLinkerUid: identity.gymLinkerUid,
      runLinkerUid: identity.gymLinkerUid,
      status: 'active',
      consentVersion: '2026-08-30',
      linkedAt: FieldValue.serverTimestamp(),
      lastAuthenticatedAt: FieldValue.serverTimestamp(),
      schemaVersion: 1
    }, { merge: true });

    logger.info('Exchanged GymLinker authorization.', { gymLinkerUid: identity.gymLinkerUid });
    return sendJSON(response, 200, {
      customToken,
      profile: {
        uid: identity.gymLinkerUid,
        email: identity.email,
        emailVerified: identity.emailVerified,
        displayName: identity.displayName,
        photoURL: identity.photoURL
      }
    });
  } catch (error) {
    logger.warn('Failed to exchange GymLinker authorization.', { error: error.message });
    return sendJSON(response, error.status || 500, {
      error: error.status ? error.message : 'internal'
    });
  }
}

module.exports = {
  createAuthorization,
  exchangeAuthorization,
  safeIdentity,
  verifyGymLinkerToken
};
