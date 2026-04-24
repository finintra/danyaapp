// Питання для тесту "AI vs реальне фото".
// level — складність від 1 (найлегше) до 5 (найважче).
// real — шлях/URL до реального фото; ai — до згенерованого.
// hint — коротке пояснення, що показати після відповіді.
//
// Щоб підставити свої фото, поклади їх у папку images/ і поміняй шляхи нижче.
// Поточні посилання на picsum.photos — це demo-заглушки (для запуску потрібен інтернет).

window.QUIZ_QUESTIONS = [
  // --- Рівень 1: найпростіше ---
  {
    id: 1,
    level: 1,
    real: "https://picsum.photos/seed/real-1/600/600",
    ai:   "https://picsum.photos/seed/ai-1/600/600",
    hint: "На простих AI-зображеннях часто буває «пластикова» шкіра і неприродне освітлення.",
  },
  {
    id: 2,
    level: 1,
    real: "https://picsum.photos/seed/real-2/600/600",
    ai:   "https://picsum.photos/seed/ai-2/600/600",
    hint: "Придивися до текстури: у реальному фото є дрібні деталі й випадковий шум.",
  },

  // --- Рівень 2 ---
  {
    id: 3,
    level: 2,
    real: "https://picsum.photos/seed/real-3/600/600",
    ai:   "https://picsum.photos/seed/ai-3/600/600",
    hint: "AI часто помиляється в руках — рахуй пальці і дивись, як вони тримають предмети.",
  },
  {
    id: 4,
    level: 2,
    real: "https://picsum.photos/seed/real-4/600/600",
    ai:   "https://picsum.photos/seed/ai-4/600/600",
    hint: "Текст і написи на фото — слабке місце AI: літери часто «пливуть».",
  },

  // --- Рівень 3 ---
  {
    id: 5,
    level: 3,
    real: "https://picsum.photos/seed/real-5/600/600",
    ai:   "https://picsum.photos/seed/ai-5/600/600",
    hint: "Перевір симетрію: сережки, очі, взуття — AI часто робить їх трохи різними.",
  },
  {
    id: 6,
    level: 3,
    real: "https://picsum.photos/seed/real-6/600/600",
    ai:   "https://picsum.photos/seed/ai-6/600/600",
    hint: "Фон: на AI-зображеннях предмети у фоні можуть бути дивно деформовані.",
  },

  // --- Рівень 4 ---
  {
    id: 7,
    level: 4,
    real: "https://picsum.photos/seed/real-7/600/600",
    ai:   "https://picsum.photos/seed/ai-7/600/600",
    hint: "Тіні й відблиски: джерела світла на AI-фото іноді суперечать одне одному.",
  },
  {
    id: 8,
    level: 4,
    real: "https://picsum.photos/seed/real-8/600/600",
    ai:   "https://picsum.photos/seed/ai-8/600/600",
    hint: "Волосся і хутро: AI згладжує дрібні волосинки в суцільну «масу».",
  },

  // --- Рівень 5: найважче ---
  {
    id: 9,
    level: 5,
    real: "https://picsum.photos/seed/real-9/600/600",
    ai:   "https://picsum.photos/seed/ai-9/600/600",
    hint: "Сучасні моделі (Midjourney v6, Flux) майже не мають явних помилок — дивись на «зайву досконалість».",
  },
  {
    id: 10,
    level: 5,
    real: "https://picsum.photos/seed/real-10/600/600",
    ai:   "https://picsum.photos/seed/ai-10/600/600",
    hint: "Коли сумнівно — перевіряй метадані фото (EXIF) або шукай джерело через пошук по зображенню.",
  },
];
