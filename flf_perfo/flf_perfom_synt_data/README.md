# FLF Performance Synthetic Data

Генератори синтетичних даних для розробки та демо `flf_performance` (wallboard, KPI).

## Цілі
- Постійно наповнювати дашборди/КРІ без ручних дій.
- Емулювати реальний потік: unprinted → printed → done; ризики біля дедлайнів; слот‑хвилі.
- Бути ізольованими й придатними до очищення (мітка `DEMO YYYY-MM-DD`).

## Компоненти та точки входу
- `models.demo_service.FlfPerfSyntData` (AbstractModel): фасад публічних дій
  - `demo_daily_init(per_company_out=8, per_company_in=2, force=False)` — делегує в `models.daily_init.run_daily_init`, створює сьогоднішні IN/OUT пікинги з origin = `DEMO <today>`.
  - `demo_tick(max_updates=10)` — делегує в `models.minute_tick` (імітація принту/валідації/ризиків протягом дня).
  - `demo_backfill(days=30, daily_per_company=6)` — одномоментне наповнення історичних днів.
- `models.daily_init.run_daily_init(env, ...)` — основна логіка створення сьогоднішніх IN/OUT пікингів.
- `models.outgoing_helper.setup_outgoing(env, picking, partner, company, type_rec)` — створює `stock.move`, забезпечує лінії та застосовує політику Draft/Ready.
- `models.outgoing_helper.resolve_locations(env, type_rec, company)` — стабільне визначення локацій (fallback по складу/типових локаціях).
- `models.minute_tick.*` — «двигун хвилинок»: часткові оновлення протягом дня.
- `wizards/demo_wizard.*` — кнопки: Generate Today, Tick Now, Backfill 30 days, Cleanup N days, Run Slot Waves.
- `res.config.settings` → «Synthetic Data (Dev)»: параметри генерації, частки, прибирання.

Усі методи враховують `allowed_company_ids` і торкаються лише записів з `origin` = `DEMO ...`.

## Логіка та правила (узгоджено з wallboard)
- Генерація лише для типів пікингів компаній з `allowed_company_ids`.
- Усі записи маркуються `origin = DEMO <YYYY-MM-DD>` для відокремлення та безпечного cleanup.
- OUT пікинги завжди мають `stock.move` і хоча б одну `stock.move.line` (qty_done = 0.0).
- Політика Draft/Ready (керується прапорцем партнера `x_flf_use_draft_trigger`):
  - Якщо `True` → пікинг залишається у Draft (не Assigned); події «сьогодні» рахуються за `create_date`.
  - Якщо `False` → після створення: `action_confirm()` і `action_assign()` (Ready). Модуль `flf_performance` автоматично виставляє `x_flf_ready_ts` при переході в `assigned`. Події «сьогодні» рахуються за `x_flf_ready_ts`.
- «Waiting» і дефіцит:
  - Частка дефіциту керується ICP `flf_perf_synt.waiting_ratio` (дефолт 0.10). Для такої частки OUT рухів кількість попиту перевищує доступну, що веде до `state='waiting'`.
  - На стіні «Waiting» відображається як `new/total`, де `new` — за тим самим правилом «старт‑події» (Draft: `create_date`, Ready: `x_flf_ready_ts`).
- «Printed»/«Done»:
  - `x_flf_print_ts` виставляється при першому друці (у `flf_performance` це робиться через `write({'printed': True})`).
  - Валідація робиться через стандартний `button_validate()`; `x_flf_done_user_id` фіксує того, хто натиснув Done.
- Дедлайни й ризики:
  - `x_flf_deadline_at` обчислюється на основі `partner.x_flf_deadline_hour` і `create_date` (див. `flf_performance`).
  - «At Risk» — коли до локального дедлайну ≤ 60 хв (реалізовано в `flf_performance`).
- IN пікинги використовуються для балансування запасів (імітація вхідних поставок).
- Двигун хвилинок (`minute_tick`) періодично друкує/валідовує частину OUT, змінює ризики та фіналізує сценарій дня.

### Конфіг‑параметри (ICP)
- `flf_perf_synt.per_company_out` — скільки OUT створювати на компанію за день (дефолт 8).
- `flf_perf_synt.per_company_in` — скільки IN створювати на компанію за день (дефолт 2).
- `flf_perf_synt.waiting_ratio` — частка дефіцитних OUT (дефолт 0.10).
- Параметри cleanup днів — через налаштування в Settings (зберігаються в ICP).

### Дані та безпека
- Генератор не змінює «реальні» дані: працює лише з DEMO‑записами.
- Multi‑company: генерація/очищення відбувається в межах переданих компаній.
- Видимість меню «Synthetic Data (Dev)» — лише група `FLF Performance Manager`.

## Як протестувати
1) Inventory → FLF Performance → Synthetic Data (Dev):
   - Натиснути Generate Today Demo Now → у `stock.picking` зʼявляться записи з `origin = DEMO <today>`.
   - Натиснути Tick Now → частина записів отримає `x_flf_print_ts`/ризики/оновлення дедлайнів.
   - Натиснути Backfill 30 days → зʼявляться DEMO за попередні дати.
   - Натиснути Cleanup 45 days → видалить DEMO старші за 45 днів (або значення з Settings).
   - Натиснути Run Slot Waves → для найближчих слотів будуть змінені дедлайни/ризики.
2) Settings → Synthetic Data (Dev): змінити параметри і повторити пункт (1) для перевірки впливу.
3) Прогнати тести модуля — очікуємо 0 failed / 0 errors.

## Наступні кроки
- Перевірити multi‑company видимість меню та роботу візарда під різними групами.
- Додати i18n переклади і короткі підказки у форму візарда.
- (Опційно) вивід короткого логу під кнопками візарда.

## Деталі реалізації
- **Multi-company та вибір компаній**
  - Усі дії обмежені `allowed_company_ids` (контекст/права користувача).
  - Для зручності розробки до множини додаються тестові компанії `FLF Test Co*` (див. `minute_utils.allowed_companies`).
- **Маркування DEMO**
  - Усі створені записи (переважно `stock.picking`) мають `origin = DEMO <YYYY-MM-DD>` — це дозволяє безпечний cleanup та аналіз.
- **Типи пікингів і локації**
  - Джерела/призначення визначаються через `resolve_locations()` з fallback на склад компанії (stock, supplier, customer).
  - Вихідний `location_id` для OUT синхронізується з локацією обраного кванта, щоб `action_assign()` працював стабільно (резервація з правильного місця).
- **Вибір продукту та наявності**
  - `available_product(company)` повертає трійку `(product, available_qty, src_location_id)` на базі `stock.quant` (включно з розшареними (company_id=False) квантами).
  - Якщо доступності немає (`available_qty < 1`) і це не «штучний дефіцит», OUT не створюється (менше «зайвих» waiting/confirmed).
- **Створення OUT і захист від помилок**
  - `setup_outgoing()` створює `stock.move` і, за потреби, `stock.move.line` з `qty_done=0`.
  - Якщо move неможливо створити (немає продукту/локейшну) — пікинг видаляється відразу (атомарність і чисті DEMO-дані).
- **Політика Draft/Ready (прапорець партнера `x_flf_use_draft_trigger`)**
  - `True` (Draft-тригер): пікинг лишається у `draft`. «Сьогоднішня подія» для метрик — `create_date`.
  - `False` (Ready-процес): після створення викликаються `action_confirm()` та `action_assign()`. Перехід у `assigned` фіксує `x_flf_ready_ts`. «Сьогоднішня подія» — `x_flf_ready_ts`.
- **Printed / Done**
  - `printed`: виставляється через `write({'printed': True})` лише коли пікинг у `assigned` (для Draft-тригерів не насильно).
  - `done`: валідація через `button_validate()` з обходом майстрів (`immediate`, `backorder`). Виконавець зберігається у `x_flf_done_user_id`.
- **Waiting і дефіцит**
  - «Штучний» дефіцит контролюється `flf_perf_synt.waiting_ratio` (деф. 0.10). У таких випадках запитувана кількість трохи перевищує наявність.
  - В інших випадках кількість завжди обрізається до `available_qty` (немає «фальшивих» waiting).
- **Minute engine (`minute_tick`)**
  - Кожен цикл: створення нових OUT (з урахуванням наявності), частковий друк, часткова валідація (Done), іноді — IN для поповнення.
  - Вибір «актора» для друку/валідації — відповідальний користувач партнера або користувач компанії.
- **Daily init (`run_daily_init`)**
  - Перевірка «вже створено сьогодні» виконується по‑компанійно (кожна компанія генерує самостійно).
  - OUT/IN створюються серією; кожен OUT гарантовано має move/line або видаляється.

## Нюанси логіки (узгодження з Wallboard)
- **Визначення «сьогодні» для Partners Today**
  - Draft-тригер: `create_date ∈ [start; end)`.
  - Ready-процес: `x_flf_ready_ts ∈ [start; end)`.
- **Waiting на панелі**
  - Враховуються лише записи зі «старт‑подією» сьогодні (за політикою) та станами `waiting` або `confirmed`.
- **Облік друку**
  - В середньому час до друку рахується від `create_date` (Draft) або від `x_flf_ready_ts` (Ready).

## Поради з налагодження
- Якщо Partners Today порожній:
  - Переконайтесь, що згенеровано сьогодні (`demo_daily_init(force=True)`), і що для Ready‑партнерів є `assigned` з `x_flf_ready_ts` сьогодні.
  - Перевірте `allowed_company_ids` у контексті користувача.
  - Перевірте наявність складу/типів пікингів у компанії.
- Занадто багато waiting:
  - Зменште `flf_perf_synt.waiting_ratio` або збільшіть наповнення IN (replenishment) через частоту `minute_tick`.

## Тести
- Юніт‑тест: `test_draft_trigger_policy.py` — гарантує, що для Draft‑тригерів не відбувається автопризначення на створенні.
- Базовий набір тестів модуля очікує 0 failed / 0 errors.

## Корисні команди
- Оновлення модуля:
  /home/roman/odoo/odoo-venv/bin/python3 /home/roman/odoo/odoo-bin -c /home/roman/odoo/odoo-server.conf -d test55 -u flf_perfom_synt_data --stop-after-init
- Запуск сервера Odoo:
  cd /home/roman/odoo && /home/roman/odoo/odoo-venv/bin/python3 /home/roman/odoo/odoo-bin -c /home/roman/odoo/odoo-server.conf
- Запуск тестів:
  /home/roman/odoo/odoo-venv/bin/python3 /home/roman/odoo/odoo-bin -c /home/roman/odoo/odoo-server.conf -d test55 --no-http --test-enable --test-tags post_install,-at_install,/flf_perfom_synt_data -u flf_perfom_synt_data --stop-after-init
