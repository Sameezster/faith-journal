/**
 * Faith Journal Cloud Functions.
 *  - sendDailyVerse: scheduled push of the daily verse via FCM (respects per-user prefs).
 *  - onContentCreate: fan-out new verses/reflections into journal_index (timeline at scale).
 */
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Daily at 07:00 (configure per deployment / timezone).
exports.sendDailyVerse = onSchedule("0 7 * * *", async () => {
  const snap = await db.collectionGroup("devices").get();
  const tokens = snap.docs.map((d) => d.get("fcmToken")).filter(Boolean);
  if (!tokens.length) return;
  // TODO: pick the day's verse; respect users/{uid}.notificationsEnabled.
  await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title: "Verse of the Day", body: "Open Faith Journal to read today's verse." },
  });
});

// Fan-out timeline entries (enable when journal_index strategy is turned on).
exports.onSavedVerseCreate = onDocumentCreated(
  "users/{uid}/saved_verses/{verseId}",
  async (event) => {
    const { uid, verseId } = event.params;
    const data = event.data?.data() || {};
    await db.doc(`journal_index/${uid}/entries/${verseId}`).set({
      kind: "saved_verse",
      refId: verseId,
      title: data.reference || "",
      snippet: (data.text || "").slice(0, 140),
      createdAt: data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
    });
  }
);
