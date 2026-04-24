// Ініціалізація Firebase Firestore і створення window.QuizDB.
//
// Експортується:
//   window.QuizDBReady — Promise, що резолвиться в { enabled: bool, ... }
//                        після спроби підключитись до Firebase.
//   window.QuizDB      — те саме значення, після резолву.
//
// Якщо у firebase-config.js стоять REPLACE_ME — QuizDB.enabled = false,
// і додаток працюватиме на одному лише localStorage.

const FIREBASE_VERSION = "10.12.2";
const COLLECTION = "quiz_sessions";

function isConfigured(cfg) {
  if (!cfg || !cfg.apiKey || !cfg.projectId) return false;
  const vals = [cfg.apiKey, cfg.projectId];
  return vals.every((v) => v && !String(v).startsWith("REPLACE"));
}

window.QuizDBReady = (async () => {
  const cfg = window.FIREBASE_CONFIG;
  if (!isConfigured(cfg)) {
    window.QuizDB = { enabled: false, reason: "not-configured" };
    return window.QuizDB;
  }

  try {
    const { initializeApp } = await import(
      `https://www.gstatic.com/firebasejs/${FIREBASE_VERSION}/firebase-app.js`
    );
    const {
      getFirestore, collection, addDoc, getDocs,
      query, orderBy, writeBatch, serverTimestamp,
    } = await import(
      `https://www.gstatic.com/firebasejs/${FIREBASE_VERSION}/firebase-firestore.js`
    );

    const app = initializeApp(cfg);
    const db  = getFirestore(app);
    const col = collection(db, COLLECTION);

    window.QuizDB = {
      enabled: true,

      async saveSession(session) {
        await addDoc(col, {
          ts:      session.ts,
          score:   session.score,
          total:   session.total,
          answers: session.answers,
          serverTs: serverTimestamp(),
        });
      },

      async listSessions() {
        const q = query(col, orderBy("ts", "desc"));
        const snap = await getDocs(q);
        return snap.docs.map((d) => d.data());
      },

      async clearAll() {
        const snap = await getDocs(col);
        // Batch-и по 400 (ліміт Firestore — 500 операцій на batch).
        const docs = snap.docs;
        for (let i = 0; i < docs.length; i += 400) {
          const batch = writeBatch(db);
          for (const d of docs.slice(i, i + 400)) batch.delete(d.ref);
          await batch.commit();
        }
      },
    };
    return window.QuizDB;
  } catch (e) {
    console.warn("[Firebase] init failed:", e);
    window.QuizDB = { enabled: false, reason: "init-error", error: e };
    return window.QuizDB;
  }
})();
