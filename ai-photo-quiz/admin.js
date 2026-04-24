(function () {
  "use strict";

  const STORAGE_KEY = "aiQuiz.sessions.v1";
  const QUESTIONS = [...(window.QUIZ_QUESTIONS || [])].sort((a, b) => a.level - b.level);

  const els = {
    total:        document.getElementById("stat-total"),
    avgScore:     document.getElementById("stat-avg"),
    bestScore:    document.getElementById("stat-best"),
    lastPlayed:   document.getElementById("stat-last"),
    perQuestion:  document.getElementById("per-question"),
    sessionsTbl:  document.getElementById("sessions"),
    resetBtn:     document.getElementById("reset-btn"),
    exportBtn:    document.getElementById("export-btn"),
    emptyHint:    document.getElementById("empty"),
    content:      document.getElementById("content"),
  };

  function loadData() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return { sessions: [] };
      return JSON.parse(raw);
    } catch (e) {
      console.warn("Не вдалося прочитати статистику:", e);
      return { sessions: [] };
    }
  }

  function formatDate(ts) {
    const d = new Date(ts);
    const pad = (n) => String(n).padStart(2, "0");
    return `${pad(d.getDate())}.${pad(d.getMonth() + 1)}.${d.getFullYear()} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
  }

  function render() {
    const data = loadData();
    const sessions = data.sessions || [];
    const total = sessions.length;

    if (total === 0) {
      els.content.style.display = "none";
      els.emptyHint.style.display = "block";
      return;
    }
    els.content.style.display = "block";
    els.emptyHint.style.display = "none";

    // Загальні метрики
    const totalQuestions = sessions.reduce((s, x) => s + x.total, 0);
    const totalCorrect   = sessions.reduce((s, x) => s + x.score, 0);
    const avgPct         = totalQuestions ? Math.round((totalCorrect / totalQuestions) * 100) : 0;
    const bestPct        = Math.max(...sessions.map((x) => Math.round((x.score / x.total) * 100)));
    const lastTs         = Math.max(...sessions.map((x) => x.ts));

    els.total.textContent     = String(total);
    els.avgScore.textContent  = avgPct + "%";
    els.bestScore.textContent = bestPct + "%";
    els.lastPlayed.textContent = formatDate(lastTs);

    // Статистика по питаннях
    const perQ = new Map(); // qId -> { correct, total, level }
    for (const s of sessions) {
      for (const a of s.answers || []) {
        const cur = perQ.get(a.qId) || { correct: 0, total: 0, level: a.level };
        cur.total++;
        if (a.correct) cur.correct++;
        perQ.set(a.qId, cur);
      }
    }

    els.perQuestion.innerHTML = "";
    for (const q of QUESTIONS) {
      const stat = perQ.get(q.id);
      const row  = document.createElement("tr");
      if (!stat) {
        row.innerHTML = `<td>#${q.id}</td><td>${q.level}</td><td colspan="2" style="color:var(--muted)">Ще не відповідали</td>`;
        els.perQuestion.appendChild(row);
        continue;
      }
      const pct = Math.round((stat.correct / stat.total) * 100);
      const barCls = pct >= 60 ? "" : "bad";
      row.innerHTML = `
        <td>#${q.id}</td>
        <td>${q.level}</td>
        <td>${stat.correct} / ${stat.total} (${pct}%)</td>
        <td><div class="bar ${barCls}"><div style="width:${pct}%"></div></div></td>
      `;
      els.perQuestion.appendChild(row);
    }

    // Список сесій (останні зверху)
    els.sessionsTbl.innerHTML = "";
    const sorted = [...sessions].sort((a, b) => b.ts - a.ts);
    for (const s of sorted) {
      const pct = Math.round((s.score / s.total) * 100);
      const row = document.createElement("tr");
      row.innerHTML = `
        <td>${formatDate(s.ts)}</td>
        <td>${s.score} / ${s.total}</td>
        <td>${pct}%</td>
      `;
      els.sessionsTbl.appendChild(row);
    }
  }

  function reset() {
    const ok = confirm("Скинути всю статистику? Цю дію неможливо відмінити.");
    if (!ok) return;
    localStorage.removeItem(STORAGE_KEY);
    render();
  }

  function exportJson() {
    const data = loadData();
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `ai-quiz-stats-${new Date().toISOString().slice(0, 10)}.json`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }

  els.resetBtn.addEventListener("click", reset);
  els.exportBtn.addEventListener("click", exportJson);

  render();
})();
