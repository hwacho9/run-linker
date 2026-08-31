'use strict';

const { getApp } = require('firebase-admin/app');
const { Timestamp, getFirestore } = require('firebase-admin/firestore');
const { logger } = require('firebase-functions');
const { clampInteger, parseDate, requirePost, sendJSON } = require('./shared');
const { verifyGymLinkerToken } = require('./accountBridge');
const { activityDocumentId, projectSession } = require('./activityProjection');

async function projectRunSession(event) {
  const db = getFirestore(getApp());
  const activityRef = db.collection('fitnessActivities').doc(activityDocumentId(event.params.sessionId));
  const after = event.data?.after;

  if (!after?.exists) {
    await activityRef.delete();
    return;
  }

  const projected = projectSession(event.params.sessionId, after.data());
  await activityRef.set({
    ...projected,
    createdAt: event.data.before?.exists
      ? event.data.before.data().createdAt || Timestamp.now()
      : after.data().createdAt || Timestamp.now(),
    updatedAt: Timestamp.now()
  }, { merge: true });
}

function serializeActivity(snapshot) {
  const data = snapshot.data();
  return {
    id: snapshot.id,
    type: data.type,
    sourceApp: data.sourceApp,
    startedAt: data.startedAt.toDate().toISOString(),
    endedAt: data.endedAt.toDate().toISOString(),
    durationSec: data.durationSec,
    summary: data.summary,
    schemaVersion: data.schemaVersion
  };
}

async function getRunLinkerActivities(request, response) {
  if (!requirePost(request, response)) return;

  try {
    const identity = await verifyGymLinkerToken(request);
    const now = new Date();
    const earliest = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
    const requestedSince = parseDate(request.body?.since, new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000));
    const since = requestedSince < earliest ? earliest : requestedSince;
    const limit = clampInteger(request.body?.limit, 30, 1, 100);

    const snapshot = await getFirestore(getApp())
      .collection('fitnessActivities')
      .where('ownerUid', '==', identity.uid)
      .where('startedAt', '>=', Timestamp.fromDate(since))
      .orderBy('startedAt', 'desc')
      .limit(limit)
      .get();

    return sendJSON(response, 200, {
      activities: snapshot.docs.map(serializeActivity)
    });
  } catch (error) {
    logger.warn('Failed to fetch RunLinker activities for GymLinker.', { error: error.message });
    const status = error.status || (error.code?.startsWith('auth/') ? 401 : 500);
    return sendJSON(response, status, { error: status === 500 ? 'internal' : error.message });
  }
}

module.exports = {
  activityDocumentId,
  getRunLinkerActivities,
  projectRunSession,
  projectSession,
  serializeActivity
};
