# IMPLEMENTATION PLAN — Частина 2: Інтеграції, KPI, інтерфейси

Цей файл — конденсований витяг (≤200 рядків) з розділів про події/інтеграції, KPI та UI.

## 2) Точки інтеграції (події)
- Друк документів: використовуємо існуючий модуль «першого друку». Беремо `x_flf_print_ts`/факт `printed`.
- `stock.picking.button_validate()`: після успішної валідації встановлюємо `x_flf_done_user_id` (якщо порожній).
- Обчислення дедлайну `x_flf_deadline_at`:
  - База — `create_date` + `partner.x_flf_deadline_hour`.
  - Soft window: `partner.x_flf_soft_window_minutes` після дедлайну.
  - Last truck: `partner.x_flf_last_shipment_time`.
  - After‑hours credit: якщо `True`, то оформлене після роботи, але до останньої машини — кращий статус, ніж повна прострочка.
- Політика старту (Draft vs Ready):
  - Якщо тригер Draft — фіксуємо час створення і (опційно) `ready_ts` для діагностики.
- Графік машин: `flf.truck.schedule` + `flf.truck.slot` (будні 2–3 слоти; субота інші; неділя — вихідний з винятками).

## 3) Обчислення та оновлення KPI
- Cron «сьогодні» (кожні N хв, конфіг.):
  - Інкрементальний перерахунок «сьогоднішніх» даних out/in за `write_date > last_run`.
  - Пише у `flf.performance.kpi` (виміри: `date, company, partner, user, flow`).
- Метрики (базові):
  - `pickings_done`, `lines_done`, `qty_done`.
  - `pct_in_deadline`, `avg_sec_print_to_done`.
  - `pickings_risk_count`, `done_in_soft_window`, `done_in_last_truck`, `done_afterhours_transfer`.
- Пер‑слотова аналітика: `created_since_prev_slot`, `shipped_in_slot`, `missed_in_slot`.
- Multi‑company: `allowed_company_ids`; company‑dependent конфіг через `res.config.settings`.

## 4) Інтерфейси (UI)
- Меню:
  - Inventory → Operations → FLF Performance → Wallboard (client action, автооновлення, повноекранний режим).
  - Inventory → FLF Performance → KPIs (tree/graph/pivot).
  - Inventory → FLF Performance → At Risk Pickings Today (tree з доменом ризику).
  - Inventory → FLF Performance → Configuration → Settings / Partner SLA Registry / User Assignments / Truck Schedules.
- Wallboard (базова версія):
  - Блок «Сьогодні»: загальні KPI.
  - Ряди по партнерах: стани, час до дедлайну, waiting.
  - ТОПи працівників і партнерів (списком; деталізація — у наступних ітераціях).
- Персональна панель (ітерація 2):
  - HUD‑стріп у верхній панелі, правий док у «Складі».
- Налаштування (компанія):
  - Effort Consolidation; Flexible Saturday; Refresh; Off‑day; Start Event Policy (Draft vs Ready).

## 5) Тести та валідація
- Юніт‑тести: дедлайн, in_deadline, print→done, інкремент KPI, пер‑слотові агрегації.
- Дані для ручної перевірки: кілька партнерів з різними SLA, кілька компаній, різні користувачі.
- Перевірка продуктивності: обробка «сьогоднішніх» даних за < 10 с при 5–20 тис. рядків.
