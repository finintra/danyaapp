# FLF Performance Synthetic Data — Dev Notes

## Справжня причина відсутності меню
- Кореневий пункт "Synthetic Data (Dev)" не відображався, бо `_visible_menu_ids()` приховує меню без доступу до моделі дії.
- Спочатку гілка містила лише `ir.actions.server` → у топ‑меню такі гілки не показуються.
- Після додавання візарда (`act_window`) меню все ще не було видно через відсутність ACL до моделі `flf.perf.synt.wizard` для групи `FLF Performance Manager`.
- Виправлено: додано візард + ACL. Перевірено: меню видиме для користувача Mitchell Admin.

## Де знайти в UI
- Inventory → FLF Performance → Synthetic Data (Dev)
- Потрібна група: FLF Performance Manager (`flf_performance.group_manager`).

## Що зроблено у модулі
- Додано візард керування даними: `flf.perf.synt.wizard` з кнопками:
  Generate Today, Tick Now, Backfill 30 days, Cleanup 45 days, Run Slot Waves.
- Прив’язано `act_window` до кореневого меню, sequence=15.
- Додано ACL: читання/створення для групи менеджера.
- Рефактор: винесено бекфіл у `models/backfill.py`, `demo_service.py` скорочено.
- Dev‑налаштування через `res.config.settings` (блок "Synthetic Data (Dev)"):
  - per_company_out/in, daily_per_company, keep_days
  - threshold_min, miss_ratio, ship_ratio, sample_limit
- Налаштування читаються через `ir.config_parameter` у `demo_service.py` та `slot_waves.py`.
- Тести модуля перезапущено — 0 failed, 0 errors (3 тести).

## Команди
- Оновлення модуля:
  /home/roman/odoo/odoo-venv/bin/python3 /home/roman/odoo/odoo-bin -c /home/roman/odoo/odoo-server.conf -d test55 -u flf_perfom_synt_data --stop-after-init
- Запуск сервера Odoo:
  cd /home/roman/odoo && /home/roman/odoo/odoo-venv/bin/python3 /home/roman/odoo/odoo-bin -c /home/roman/odoo/odoo-server.conf
- Запуск тестів для модуля:
  /home/roman/odoo/odoo-venv/bin/python3 /home/roman/odoo/odoo-bin -c /home/roman/odoo/odoo-server.conf -d test55 --no-http --test-enable --test-tags post_install,-at_install,/flf_perfom_synt_data -u flf_perfom_synt_data --stop-after-init

## Файли/зміни
- views/menu.xml — кореневе меню тепер з `action="...action_flf_perf_synt_wizard"`.
- wizards/demo_wizard.py, wizards/demo_wizard_views.xml — візард і форма.
- security/ir.model.access.csv — ACL для візарда.
- wizards/synt_settings.py, wizards/synt_settings_views.xml — Dev‑налаштування.
- models/backfill.py — винесений бекфіл.
- models/demo_service.py — читання ICP, делегування у backfill, скорочення.
- models/slot_waves.py — читання ICP параметрів для хвиль.
- __init__.py / models/__init__.py — підключення нових модулів.

## Очікувана поведінка
- Натиснення кнопок у візарді викликає відповідні методи сервісу і показує оновлені дані на Wallboard/KPI після наступного оновлення.
- Параметри у Settings впливають на обсяг генерації/хвиль негайно (через `ir.config_parameter`).
- Меню видиме лише для групи FLF Performance Manager. Для інших користувачів пункт прихований.

## Як протестувати (чекліст)
- Відкрити Inventory → FLF Performance → Synthetic Data (Dev) і натиснути:
  1) Generate Today Demo Now — має створити сьогоднішні DEMO‑пікинги; перевірити пошук по `origin = DEMO <today>`.
  2) Tick Now — частина нероздрукованих стає «роздрукованими», частині змінюються дедлайни/ризик.
  3) Backfill 30 days — з’являються DEMO на попередні дати.
  4) Cleanup 45 days — видаляє DEMO старші за 45 днів (або значення з Settings).
  5) Run Slot Waves — для найближчих слотів змінюються дедлайни/ризик згідно параметрів.
- В Settings → Synthetic Data (Dev) змінити параметри і повторити кроки (перевірити вплив).
- Запустити юніт‑тести модуля (див. Команди) — очікуємо 0 failed / 0 errors.

## Наступні кроки
- Перевірити UI в різних компаніях/групах (multi‑company) на видимість меню й роботу візарда.
- Додати переклади (i18n) та короткі підказки у форму візарда.
- Опційно: вивід результату останньої дії під кнопками (mini‑log).
- Документацію відокремлено на короткі файли ≤200 рядків; детальний план імплементації див. у `flf_performance/docs/*`.

## Архітектура і взаємодії
- **Основні модулі**: цей модуль генерує DEMO‑дані; відображення/агрегація — у `flf_performance` (Wallboard/KPI).
- **Ключові поля з `flf_performance`**:
  - `x_flf_ready_ts` — встановлюється при переході пікингу у `assigned` (Ready).
  - `x_flf_print_ts` — перший друк (`write({'printed': True})`).
  - `x_flf_deadline_at`, `x_flf_in_deadline` — дедлайн і індикатор у дедлайні.
  - `x_flf_risk_today` — ризик «сьогодні».
  - `x_flf_done_user_id` — користувач, що завершив (Done).

## Що саме генерується (run_daily_init)
- По‑компанійно: пропуск, якщо DEMO вже є сьогодні для цієї компанії (а не глобально).
- OUT/IN створюються серією. Кожен OUT:
  - має принаймні один `stock.move` і `stock.move.line` (qty_done=0).
  - якщо move не вийшло створити — пікинг видаляється (чисті DEMO).
  - для Ready‑партнера викликається `action_confirm()` і `action_assign()`.
  - за потреби ставиться `x_flf_print_ts` (лише якщо `assigned`).
  - `x_flf_deadline_at` заповнюється відносно «сьогодні» (± хвилини).

## Minute engine (minute_tick)
- Нові OUT створюються лише з реальною доступністю (якщо не «штучний дефіцит»).
- Кількість завжди обрізається до наявної (`qty ≤ available`), окрім випадків дефіциту за параметром.
- Друк (`printed=True`) робиться лише для `assigned` і не насильно для Draft‑партнерів.
- Частина надрукованих переходить у Done: виставляється `qty_done`, викликається `button_validate()` (обхід майстрів), фіксується `x_flf_done_user_id`.
- Інколи створюється IN (replenishment) і відразу валідовується, щоб зменшити дефіцити.

## Вибір продукту та джерел
- `available_product(company)` повертає `(product, available, src_location_id)` за квантом складу компанії.
- Пошук включає quants компанії і «спільні» (`company_id=False`), без серійних та партій (tracking=none).
- Якщо повернуто `src_location_id`, пікинг OUT синхронізує `location_id` перед створенням move.

## Outgoing helper
- `setup_outgoing()` використовує `available_product()` і:
  - пропускає створення, якщо `available < 1` (крім дефіцитних сценаріїв).
  - у дефіцитному випадку завищує кількість трохи понад доступність → стани `waiting/confirmed`.
  - інакше кількість — мінімум з `available` та випадкового {1,2,3}.
  - додає move line, якщо її немає.
  - для Ready‑партнера викликає `confirm/assign` (Draft‑партнери лишаються в `draft`).

## Політика Draft/Ready
- Прапорець партнера `x_flf_use_draft_trigger`:
  - `True` — «старт» дня = `create_date`; пікинг не переходить у Ready автоматично.
  - `False` — «старт» дня = `x_flf_ready_ts`; пікинг переводиться у Ready одразу після створення.
- Це впливає на Wallboard: які записи потрапляють у «сьогодні», як рахується час до друку, «new waiting» тощо.

## Логіка Wallboard (довідка)
- `Partners Today` збирає:
  - не‑done за сьогодні (Draft‑/Ready‑події відповідно до прапорця),
  - done за `date_done ∈ [start; end)`,
  - waiting/confirmed тільки з «подією старту» сьогодні.
- Час до друку рахується від `create_date` (Draft) або `x_flf_ready_ts` (Ready).

## Конфіг‑параметри (ICP)
- `flf_perf_synt.per_company_out`, `flf_perf_synt.per_company_in` — денні обсяги генерації.
- `flf_perf_synt.waiting_ratio` — частка дефіцитних OUT (типово 0.10).
- `flf_perf_synt.minute_new_per_company`, `flf_perf_synt.minute_print_ratio`, `flf_perf_synt.minute_done_ratio` — поведінка minute engine.

## Траблшутінг
- Партнери «сьогодні» порожні:
  - перевірити, що для Ready‑партнерів виставляється `x_flf_ready_ts` сьогодні (тобто був `assigned`),
  - переконатися у валідних типах пікингів/складі компанії та `allowed_company_ids`.
- Надлишок waiting:
  - зменшити `waiting_ratio`, або збільшити частоту IN через minute engine.

## Зміни по структурі коду
- Для дотримання обмеження ≤200 рядків:
  - Винесено хелпери в `models/minute_helpers.py` (`pick_actor`, `force_validate`).
  - Логіку генерації розбито на `daily_init`, `minute_tick`, `outgoing_helper`, `minute_utils`.
