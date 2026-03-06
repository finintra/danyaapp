# IMPLEMENTATION PLAN — Частина 1: Межі, моделі, поля

Ця частина витримана до 200 рядків і є витягом з загального плану реалізації `flf_performance`.

## 0) Межі проєкту та припущення
- Фокус v1: outgoing/incoming за «сьогодні», дедлайни партнерів, ризики, базові KPI, wallboard і персональна міні‑панель.
- Події: перший друк і перехід у Done.
- Атрибуція: хто перевів у Done — той відповідальний.
- Дедлайн партнера: дефолт 17:00 локального часу; індивідуально на партнері; база — `create_date`.
- «Мʼяке вікно» і «остання машина»: напр. 18:30 і 19:00; впливають на інтерпретацію прострочки.
- «Велике замовлення»: пороги рядків/qty на партнері; дефолти компанії.
- Початок збору: політика Draft vs Ready на партнері/компанії.
- Вхідні (Inbound) постачання: для партнерів задаємо SLA «макс. діб до валідації» — для контролю своєчасного підтвердження прийомок.

— Для демо/дев середовища використовується синтетичний «Minute Engine», що раз на хвилину додає/друкує/завершує частину відправок із реалістичними рухами складу.

## 1) Моделі та поля (витяг)
- Розширення `res.partner`:
  - `x_flf_deadline_hour` (0–23)
  - `x_flf_big_order_lines` (Int)
  - `x_flf_big_order_qty` (Int/Float)
  - `x_flf_collect_trigger` (draft|ready)
  - `x_flf_soft_window_minutes` (Int)
  - `x_flf_last_shipment_time` (Char/Time)
  - `x_flf_afterhours_credit` (Bool)
  - `x_flf_refresh_offset_sec` (Int)
  - `x_flf_responsible_user_ids` (M2M res.users)
  - `x_flf_inbound_max_days` (Int) — SLA прийомки: макс. діб між надходженням та валідацією (1–3 типово).
- Розширення `res.users`:
  - `x_flf_primary_partner_id` (M2O res.partner)
- Розширення `stock.picking`:
  - `x_flf_print_ts`, `x_flf_print_user_id`, `x_flf_done_user_id`
  - `x_flf_deadline_at`, `x_flf_in_deadline`
  - (опційно) `x_flf_ready_ts`, `x_flf_in_soft_window`, `x_flf_in_last_truck`, `x_flf_afterhours_transfer`
- Розширення `res.company`:
  - `x_flf_synt_weight` (Int) — ваговий коефіцієнт для синтетики (імітація великих/малих компаній у Minute Engine).
- Агрегаційна `flf.performance.kpi` (виміри: date, company, partner, user, flow; метрики: pickings_done, lines_done, qty_done, pct_in_deadline, avg_sec_print_to_done, pickings_risk_count, done_in_soft_window, done_in_last_truck, done_afterhours_transfer, offday_shipments).

## 2) Транспортні слоти
- `flf.truck.schedule` (weekday/date, active, примітка) і `flf.truck.slot` (HH:MM, is_weekend, sequence, active).
- Сценарій: будні — 12:30, 15:30, 19:00; субота — 14:00, 17:30; неділя — зазвичай вихідний, іноді винятки.

## 3) Дані для wallboard і персональної панелі
- Сьогоднішні KPI: «в дедлайні %», «avg sec print→done», «ризики (out)».
- Ряди по партнерах: нероздруковані / роздруковані не зібрані / Done / прострочені; час до дедлайну; waiting.
- Персональна панель: HUD‑стріп, док у «Складі» (пізніша ітерація).

## 4) Компанійність і конфігурація
- Параметри company‑dependent через `res.config.settings`.
- Видимість меню/реєстрів — у контексті поточної компанії.
- Cron обробляє `allowed_company_ids` або ітерує по компаніях.

## 5) Нотатки з продуктивності
- Індекси: `stock.picking(state, picking_type_code, partner_id, company_id, date_done, x_flf_print_ts, x_flf_deadline_at)`.
- Обмеження запитів «сьогоднішнім» інтервалом TZ користувача.

— Кінець частини 1 —
