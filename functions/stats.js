'use strict';

const { getApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { calculateStats } = require('./statsCalculation');

async function aggregateRunnerStats(event) {
  const before = event.data?.before;
  const after = event.data?.after;
  const ownerUid = after?.data()?.ownerUid || before?.data()?.ownerUid;
  if (!ownerUid) return;

  const db = getFirestore(getApp());
  const snapshot = await db.collection('run_sessions')
    .where('ownerUid', '==', ownerUid)
    .get();
  const stats = calculateStats(snapshot.docs.map((document) => document.data()));

  const batch = db.batch();
  batch.set(db.collection('activity_stats').doc(ownerUid), {
    userId: ownerUid,
    ...stats,
    updatedAt: FieldValue.serverTimestamp()
  }, { merge: true });
  batch.set(db.collection('public_profiles').doc(ownerUid), {
    averagePaceSecPerKm: stats.averagePaceSecPerKm,
    weeklyRunCount: stats.weeklyRunCount,
    weeklyDistanceMeters: stats.weeklyDistanceMeters,
    updatedAt: FieldValue.serverTimestamp()
  }, { merge: true });
  await batch.commit();
}

module.exports = {
  aggregateRunnerStats
};
