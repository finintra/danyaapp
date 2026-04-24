(function () {
  "use strict";

  const STORAGE_KEY = "aiQuiz.sessions.v1";

  // Сортуємо питання по рівню (від найпростішого до найскладнішого).
  const QUESTIONS = [...(window.QUIZ_QUESTIONS || [])].sort((a, b) => a.level - b.level);
  const TOTAL = QUESTIONS.length;

  const state = {
    index: 0,
    correct: 0,
    answers: [],  // [{ qId, level, correct }]
    locked: false,
    // для кожного питання — де буде AI (left/right). Розіграємо один раз.
    sides: QUESTIONS.map(() => (Math.random() < 0.5 ? "left" : "right")),
  };

  // --- DOM ---
  const els = {
    start:    document.getElementById("screen-start"),
    quiz:     document.getElementById("screen-quiz"),
    finish:   document.getElementById("screen-finish"),
    startBtn: document.getElementById("start-btn"),
    leftBtn:  document.getElementById("choice-left"),
    rightBtn: document.getElementById("choice-right"),
    leftImg:  document.getElementById("img-left"),
    rightImg: document.getElementById("img-right"),
    progress: document.getElementById("progress-bar"),
    qCounter: document.getElementById("q-counter"),
    levelInd: document.getElementById("level-indicator"),
    feedback: document.getElementById("feedback"),
    nextBtn:  document.getElementById("next-btn"),
    scoreBig: document.getElementById("score-big"),
    scoreSub: document.getElementById("score-sub"),
    scoreMsg: document.getElementById("score-message"),
    restartBtn: document.getElementById("restart-btn"),
  };

  function show(screen) {
    for (const s of [els.start, els.quiz, els.finish]) s.style.display = "none";
    screen.style.display = "block";
  }

  function renderLevels(level) {
    els.levelInd.innerHTML = "";
    for (let i = 1; i <= 5; i++) {
      const span = document.createElement("span");
      if (i <= level) span.className = "active";
      els.levelInd.appendChild(span);
    }
  }

  function loadQuestion() {
    if (state.index >= TOTAL) return finish();

    const q = QUESTIONS[state.index];
    const aiOn = state.sides[state.index]; // "left" | "right"
    const leftSrc  = aiOn === "left"  ? q.ai   : q.real;
    const rightSrc = aiOn === "right" ? q.ai   : q.real;

    els.leftImg.src  = leftSrc;
    els.rightImg.src = rightSrc;
    els.leftImg.alt  = "Варіант 1";
    els.rightImg.alt = "Варіант 2";

    // Reset visual state
    for (const btn of [els.leftBtn, els.rightBtn]) {
      btn.classList.remove("correct", "wrong", "revealed", "dim", "locked");
      const badge = btn.querySelector(".badge");
      if (badge) badge.textContent = "";
    }
    els.feedback.classList.remove("show", "good", "bad");
    els.feedback.innerHTML = "";

    const pct = Math.round((state.index / TOTAL) * 100);
    els.progress.style.width = pct + "%";
    els.qCounter.textContent = `Питання ${state.index + 1} з ${TOTAL}`;
    renderLevels(q.level);

    state.locked = false;
  }

  function onChoose(side) {
    if (state.locked) return;
    state.locked = true;

    const q = QUESTIONS[state.index];
    const aiOn = state.sides[state.index];
    const correct = side === aiOn;

    const chosenBtn   = side === "left" ? els.leftBtn  : els.rightBtn;
    const otherBtn    = side === "left" ? els.rightBtn : els.leftBtn;
    const aiBtn       = aiOn === "left" ? els.leftBtn  : els.rightBtn;
    const realBtn     = aiOn === "left" ? els.rightBtn : els.leftBtn;

    // Позначки «AI» / «реальне»
    aiBtn.classList.add("revealed");
    realBtn.classList.add("revealed");
    aiBtn.querySelector(".badge").textContent   = "AI-згенероване";
    realBtn.querySelector(".badge").textContent = "Справжнє фото";

    chosenBtn.classList.add(correct ? "correct" : "wrong");
    if (!correct) aiBtn.classList.add("correct");
    otherBtn.classList.add("locked");
    chosenBtn.classList.add("locked");

    // Feedback
    els.feedback.classList.add("show", correct ? "good" : "bad");
    const title = correct ? "Правильно!" : "Не вгадав(-ла)";
    els.feedback.innerHTML =
      `<h3>${title}</h3><p>${q.hint || ""}</p>`;

    state.answers.push({ qId: q.id, level: q.level, correct });
    if (correct) state.correct++;

    // Оновимо прогрес на завершене питання.
    const pct = Math.round(((state.index + 1) / TOTAL) * 100);
    els.progress.style.width = pct + "%";

    els.nextBtn.textContent = state.index + 1 === TOTAL ? "Побачити результат" : "Далі →";
    els.nextBtn.style.display = "inline-block";
  }

  function next() {
    state.index++;
    els.nextBtn.style.display = "none";
    loadQuestion();
  }

  function finish() {
    show(els.finish);
    const pct = Math.round((state.correct / TOTAL) * 100);
    els.scoreBig.textContent = `${state.correct} / ${TOTAL}`;
    els.scoreSub.textContent = `Правильних відповідей: ${pct}%`;

    let msg;
    if (pct >= 90)      msg = "Шикарно! Ти справжній AI-детектив 🔍";
    else if (pct >= 70) msg = "Добре! Ти вже вмієш ловити AI на дрібницях.";
    else if (pct >= 50) msg = "Непогано. Але AI тебе ще плутає — подивись уважніше на підказки.";
    else                msg = "AI сьогодні перемогло. Нічого — з досвідом око натренується!";
    els.scoreMsg.textContent = msg;

    saveSession();
  }

  async function saveSession() {
    const session = {
      ts: Date.now(),
      score: state.correct,
      total: TOTAL,
      answers: state.answers,
    };

    // 1) Локальний fallback — пишемо завжди, навіть якщо Firebase є.
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      const data = raw ? JSON.parse(raw) : { sessions: [] };
      data.sessions.push(session);
      localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
    } catch (e) {
      console.warn("Локально зберегти не вдалося:", e);
    }

    // 2) Спільна статистика у Firestore (якщо налаштована).
    if (window.QuizDBReady) {
      try {
        await window.QuizDBReady;
        if (window.QuizDB && window.QuizDB.enabled) {
          await window.QuizDB.saveSession(session);
        }
      } catch (e) {
        console.warn("У Firebase зберегти не вдалося:", e);
      }
    }
  }

  function start() {
    state.index = 0;
    state.correct = 0;
    state.answers = [];
    state.sides = QUESTIONS.map(() => (Math.random() < 0.5 ? "left" : "right"));
    show(els.quiz);
    els.nextBtn.style.display = "none";
    loadQuestion();
  }

  function restart() {
    show(els.start);
  }

  // --- Bindings ---
  els.startBtn.addEventListener("click", start);
  els.leftBtn.addEventListener("click",  () => onChoose("left"));
  els.rightBtn.addEventListener("click", () => onChoose("right"));
  els.nextBtn.addEventListener("click", next);
  els.restartBtn.addEventListener("click", restart);

  // Клавіатура: 1 — ліве, 2 — праве, Enter — далі
  document.addEventListener("keydown", (e) => {
    if (els.quiz.style.display === "none") return;
    if (e.key === "1" && !state.locked) onChoose("left");
    else if (e.key === "2" && !state.locked) onChoose("right");
    else if (e.key === "Enter" && state.locked) next();
  });

  // Старт із стартового екрана
  show(els.start);
})();
