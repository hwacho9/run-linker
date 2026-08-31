'use strict';

const { initializeApp, getApps } = require('firebase-admin/app');
const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');

if (getApps().length === 0) {
  initializeApp();
}

const accountBridge = require('./integration/accountBridge');
const runActivities = require('./integration/runActivities');
const matching = require('./matching');
const stats = require('./stats');

const REGION = 'asia-northeast1';

exports.createGymLinkerAuthorization = onRequest(
  { region: REGION, cors: false, timeoutSeconds: 30 },
  accountBridge.createAuthorization
);

exports.exchangeGymLinkerAuthorization = onRequest(
  { region: REGION, cors: false, timeoutSeconds: 30 },
  accountBridge.exchangeAuthorization
);

exports.getRunLinkerActivities = onRequest(
  { region: REGION, cors: false, timeoutSeconds: 30 },
  runActivities.getRunLinkerActivities
);

exports.projectRunSessionActivity = onDocumentWritten(
  { document: 'run_sessions/{sessionId}', region: REGION, retry: true },
  runActivities.projectRunSession
);

exports.assignRunMatch = onDocumentCreated(
  { document: 'match_requests/{requestId}', region: REGION, retry: true },
  matching.assignMatch
);

exports.aggregateRunnerStats = onDocumentWritten(
  { document: 'run_sessions/{sessionId}', region: REGION, retry: true },
  stats.aggregateRunnerStats
);
