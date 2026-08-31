'use strict';

const { getFirestore, FieldValue } = require('firebase-admin/firestore');

function isCompatibleMatch(left, right, now = new Date()) {
  if (!left || !right || left.status !== 'finding' || right.status !== 'finding') return false;
  if (!left.requesterUid || !right.requesterUid || left.requesterUid === right.requesterUid) return false;
  if (left.mode !== right.mode || !['friend', 'random'].includes(left.mode)) return false;
  if (left.expiresAt?.toDate && (left.expiresAt.toDate() <= now || right.expiresAt?.toDate() <= now)) return false;

  if (left.mode === 'friend') {
    return left.invitedUid === right.requesterUid && right.invitedUid === left.requesterUid;
  }

  const leftDistance = Number(left.targetDistanceMeters || 0);
  const rightDistance = Number(right.targetDistanceMeters || 0);
  const distanceTolerance = Math.max(2000, Math.max(leftDistance, rightDistance) * 0.4);
  if (leftDistance && rightDistance && Math.abs(leftDistance - rightDistance) > distanceTolerance) return false;

  const leftPace = Number(left.targetPaceSecPerKm || 0);
  const rightPace = Number(right.targetPaceSecPerKm || 0);
  if (leftPace && rightPace && Math.abs(leftPace - rightPace) > 120) return false;
  return true;
}

async function assignMatch(event) {
  const createdSnapshot = event.data;
  if (!createdSnapshot?.exists) return;

  const request = createdSnapshot.data();
  if (request.status !== 'finding' || !['friend', 'random'].includes(request.mode)) return;

  const db = getFirestore();
  const candidateSnapshot = await db.collection('match_requests')
    .where('mode', '==', request.mode)
    .where('status', '==', 'finding')
    .limit(50)
    .get();

  const candidate = candidateSnapshot.docs.find((document) =>
    document.id !== createdSnapshot.id && isCompatibleMatch(request, document.data())
  );
  if (!candidate) return;

  const liveSessionReference = db.collection('live_sessions').doc();
  await db.runTransaction(async (transaction) => {
    const [freshLeft, freshRight] = await Promise.all([
      transaction.get(createdSnapshot.ref),
      transaction.get(candidate.ref)
    ]);
    if (!freshLeft.exists || !freshRight.exists) return;

    const left = freshLeft.data();
    const right = freshRight.data();
    if (!isCompatibleMatch(left, right)) return;

    const participantUids = [left.requesterUid, right.requesterUid];
    const distances = [left.targetDistanceMeters, right.targetDistanceMeters]
      .map(Number)
      .filter((value) => Number.isFinite(value) && value > 0);
    const targetDistanceMeters = distances.length
      ? Math.round(distances.reduce((total, value) => total + value, 0) / distances.length)
      : 5000;

    transaction.set(liveSessionReference, {
      participantUids,
      sourceMatchRequestIds: [freshLeft.id, freshRight.id],
      mode: left.mode,
      status: 'ready',
      targetDistanceMeters,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });
    transaction.update(freshLeft.ref, {
      status: 'matched',
      matchedUid: right.requesterUid,
      sessionId: liveSessionReference.id,
      updatedAt: FieldValue.serverTimestamp()
    });
    transaction.update(freshRight.ref, {
      status: 'matched',
      matchedUid: left.requesterUid,
      sessionId: liveSessionReference.id,
      updatedAt: FieldValue.serverTimestamp()
    });
  });
}

module.exports = {
  assignMatch,
  isCompatibleMatch
};
