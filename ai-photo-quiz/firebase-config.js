// Firebase config для спільного збору статистики.
//
// === ДЛЯ PRODUCTION (GitHub Pages) ===
// Цей файл містить плейсхолдери. Під час деплою GitHub Actions перезаписує
// його значеннями з repository secret FIREBASE_CONFIG_JSON (див. workflow
// .github/workflows/pages.yml). Тобто у git ключа немає — він живе тільки
// у секретах GitHub.
//
// === ДЛЯ ЛОКАЛЬНОЇ РОЗРОБКИ ===
// Поки тут стоять REPLACE_ME — додаток працює в режимі локального
// localStorage (як раніше). Нічого не ламається.
//
// Якщо хочеш локально тестувати зі справжнім Firebase — постав свої значення
// у цей файл, АЛЕ перед git commit верни плейсхолдери або виконай:
//     git update-index --skip-worktree ai-photo-quiz/firebase-config.js
// щоб git ігнорував твої локальні зміни.

window.FIREBASE_CONFIG = {
  apiKey:            "REPLACE_ME",
  authDomain:        "REPLACE_ME.firebaseapp.com",
  projectId:         "REPLACE_ME",
  storageBucket:     "REPLACE_ME.appspot.com",
  messagingSenderId: "REPLACE_ME",
  appId:             "REPLACE_ME",
};
