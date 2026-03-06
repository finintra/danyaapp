# FLF Performance: Навігатор UI та чекліст

## Де змінювати дедлайн партнера
- **Partner SLA Registry**: Inventory → FLF Performance → Configuration → Partner SLA Registry → колонка `x_flf_deadline_hour` [✓]
- **Форма партнера**: Partner → вкладка "FLF Performance" → поле `FLF Deadline Hour (local)` [✓]

## Глобальні налаштування (компанія)
- Inventory → FLF Performance → Configuration → Settings (модальне вікно)
  - Effort Consolidation (X, Y, window) [✓] (напиши переклади цих полів і пояснення стисло що вони роблять!)
  - Flexible Saturday (backlog/surge пороги) [✓]
  - Refresh interval/offset [✓]
  - Off‑day shipments: увімкнення [✓]
  - Start Event Policy: Draft vs Ready [✓]

## Екрани та що показують
- **Wallboard**: Inventory → FLF Performance → Wallboard
  - «Сьогодні»: Flow, Pickings, Lines, Qty, % in deadline, Avg Sec Print→Done, Risk count, Off‑day [✓]
  - Ряди по партнерах (план): не роздруковані / роздруковані не зібрані / Done / прострочені; час до дедлайну; waiting (кількість, найстаріша дата, нові сьогодні); виконавці за сьогодні; червоний рядок «потрібна увага» [ ]
  - ТОПи: за товарами, рядками, замовленнями; перемикач періодів день/тиждень/місяць [ ]
  - Multi‑company: показ усіх компаній технічного користувача (allowed_company_ids) [✓]
- **FLF Performance KPIs**: Inventory → FLF Performance → KPIs
  - Колонки: `pickings_done`, `lines_done`, `qty_done`, `pct_in_deadline`, `avg_sec_print_to_done`, `pickings_risk_count`, `done_in_soft_window`, `done_in_last_truck`, `done_afterhours_transfer`, `offday_shipments` [✓]
- **At Risk Pickings Today**: Inventory → FLF Performance → At Risk Pickings Today
  - Домен: `x_flf_risk_today = True` (outgoing, створені сьогодні, до дедлайну < 60 хв) [✓]

## Synthetic Data (Dev) — швидкий доступ і тести
- **Візард**: Inventory → FLF Performance → Synthetic Data (Dev) [✓]
  - Кнопки: Generate Today, Tick Now, Backfill 30 days, Cleanup 45 days, Run Slot Waves.
  - Видимість: тільки для `FLF Performance Manager`.
- **Налаштування**: Settings → Synthetic Data (Dev) (модальне вікно) [✓]
- **Тест‑чекліст**:
  - Натиснути Generate Today → у `stock.picking` зʼявиться `origin = DEMO <today>`.
  - Натиснути Tick Now → частина записів отримає `x_flf_print_ts`/ризики.
  - Backfill 30 days → поява DEMO за попередні дати.
  - Cleanup 45 days → видалить DEMO старші за 45 (або значення з Settings).
  - Run Slot Waves → хвилі біля найближчих слотів (перевірити зміни дедлайнів/ризику).

## Як наповнюються метрики
- **Перший друк**: `em_custom` ставить `printed=True` → `x_flf_print_ts` + `x_flf_print_user_id` фіксуються автоматично [✓]
- **Дедлайн**: на `stock.picking` обчислюється `x_flf_deadline_at` з `partner.x_flf_deadline_hour` і локального дня створення; `x_flf_in_deadline = (date_done <= deadline)` [✓]
- **KPI сьогодні (cron кожні 2 хв)**: рахує `% в дедлайні`, `avg_sec_print_to_done`, `risk_count (out)` для Done пікингів за сьогодні [✓]

## Чекліст реалізації (1‑ша черга)
- [✓] Partner SLA Registry (редагування SLA у списку, inline editable)
- [✓] Поля на формі партнера (вкладка FLF Performance)
- [✓] Фіксація першого друку (print→ts,user)
- [✓] Дедлайн та in_deadline на `stock.picking`
- [✓] Cron «сьогодні»: pct_in_deadline, avg_sec_print_to_done, risk_count
- [✓] Меню: At Risk Pickings Today, KPIs, Settings
- [✓] Wallboard: показ базових KPI + % in deadline, avg sec print→done, risk count
- [ ] Wallboard: ряди по партнерах, waiting, «потрібна увага», топи з періодами
- [ ] Персональна міні‑панель (HUD) і правий док у "Складі"
- [ ] Менеджерський дашборд (графіки/піводи з пресетами)

## Підказки для тесту
- Надрукуйте Delivery Slip (`stock.report_picking`) → з’явиться `x_flf_print_ts` → переведіть у Done → KPI оновить `avg_sec_print_to_done`.
- Змініть `x_flf_deadline_hour` у реєстрі SLA → створіть/обробіть outgoing сьогодні → перевірте `x_flf_in_deadline` та KPIs.
