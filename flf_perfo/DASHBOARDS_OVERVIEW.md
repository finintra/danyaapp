# FLF Performance Dashboards - Overview

## Summary

The FLF Performance module provides **5 main dashboards/tables** for warehouse fulfillment performance monitoring:

1. **Wallboard Summary Table** - High-level metrics by flow (out/in)
2. **Partners Performance Table** - Detailed per-partner metrics
3. **At Risk Pickings Table** - Urgent pickings near deadline
4. **TOPs Rankings** - Top performers (users & partners)
5. **KPI Historical Data** - Historical trends and analytics

---

## Dashboard 1: Wallboard Summary

**Purpose**: Quick overview of today's performance

**Key Metrics**:
- Pickings done (count)
- Lines done (count)
- Quantity done (sum)
- % In deadline
- Average time: Print → Done
- At-risk count
- Off-day shipments

**Data Scope**: Today only, aggregated by flow (outgoing/incoming)

**Update Frequency**: Real-time (30s refresh)

---

## Dashboard 2: Partners Performance

**Purpose**: Detailed partner-level tracking

**Key Metrics per Partner**:
- Order status: Unprinted | Printed | Done | Overdue
- Time to deadline (minutes)
- Average print latency
- Waiting orders (new/total, oldest)
- Active users today

**Data Scope**: All active partners, today's operations

**Visual Indicators**:
- 🔴 Red: Overdue
- 🟡 Yellow: < 1 hour to deadline
- 🟢 Green: OK

**Sorting**: By deadline urgency, then waiting count

---

## Dashboard 3: At Risk Pickings

**Purpose**: Urgent alerts for pickings near deadline

**Key Information**:
- Picking reference
- Partner name
- Deadline time
- Minutes until deadline

**Risk Criteria**: 
- Created today
- Not done
- 0-60 minutes until deadline

**Display**: Top 12 most urgent (sorted by deadline)

---

## Dashboard 4: TOPs Rankings

**Purpose**: Performance leaderboards

**Categories**:
- **By Orders**: Most pickings completed
- **By Lines**: Most move lines completed
- **By Quantity**: Highest quantity completed

**Periods**:
- Day (today)
- Week (last 7 days)
- Month (last 30 days)

**Rankings**: Separate for Users and Partners (top 5 each)

---

## Dashboard 5: KPI Historical Data

**Purpose**: Trend analysis and reporting

**Granularity**: Daily aggregates

**Dimensions**:
- Date
- Company
- Partner (optional)
- User (optional)
- Flow (out/in)

**Metrics**: All KPI fields (pickings, lines, qty, percentages, etc.)

**Use Cases**:
- Historical trends
- Comparative analysis
- Performance reports
- Data export

---

## Data Flow

```
Odoo Database (stock.picking, flf.performance.kpi)
         ↓
Model Methods (wallboard.read_payload, compute_summary, etc.)
         ↓
REST API Endpoints (to be implemented)
         ↓
External Dashboard (React/Vue/Angular/etc.)
```

---

## Key Data Models

### stock.picking (Extended)
- `x_flf_done_user_id` - Who completed
- `x_flf_print_ts` - When printed
- `x_flf_deadline_at` - Calculated deadline
- `x_flf_risk_today` - At risk flag
- `x_flf_in_deadline` - Met deadline flag

### res.partner (Extended)
- `x_flf_deadline_hour` - Deadline hour (17.0 = 17:00)
- `x_flf_soft_window_minutes` - Grace period
- `x_flf_last_shipment_hour` - Last truck time
- `x_flf_use_draft_trigger` - Draft triggers work
- `x_flf_responsible_user_ids` - Assigned users

### flf.performance.kpi
- Daily aggregated metrics
- Company/Partner/User levels
- Historical data storage

---

## API Endpoints (To Be Implemented)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/flf/api/v1/wallboard/payload` | POST | Complete wallboard data |
| `/flf/api/v1/wallboard/summary` | GET | Summary table only |
| `/flf/api/v1/wallboard/partners` | GET | Partners table only |
| `/flf/api/v1/wallboard/at-risk` | GET | At-risk pickings |
| `/flf/api/v1/wallboard/tops` | GET | TOPs rankings |
| `/flf/api/v1/kpi/list` | GET | Historical KPI data |

---

## Implementation Priority

### Phase 1: Core Dashboards
1. ✅ Wallboard Summary (already implemented in Odoo)
2. ✅ Partners Performance (already implemented)
3. ✅ At Risk Pickings (already implemented)
4. ⚠️ REST API endpoints (needs implementation)

### Phase 2: External Dashboard
1. Build REST API controller
2. Create external dashboard UI
3. Implement real-time updates
4. Add filtering and export

### Phase 3: Advanced Features
1. Historical trend charts
2. Custom date ranges
3. Export to Excel/PDF
4. Email reports

---

## Technical Details

- **Backend**: Odoo 15 (Python)
- **Frontend**: Odoo Web (JavaScript/OWL) - can be replaced with external
- **Database**: PostgreSQL
- **Authentication**: Odoo session or API key
- **Update Frequency**: 30 seconds (configurable)
- **Multi-company**: Supported (aggregates across companies)

---

## Documentation Files

1. **TECHNICAL_REQUIREMENTS_DASHBOARDS.md** - Complete API specification
2. **DASHBOARD_API_IMPLEMENTATION_NOTES.md** - Implementation guide
3. **DASHBOARDS_OVERVIEW.md** - This file (high-level overview)

---

## Quick Start

1. Read `TECHNICAL_REQUIREMENTS_DASHBOARDS.md` for detailed API specs
2. Follow `DASHBOARD_API_IMPLEMENTATION_NOTES.md` to create REST endpoints
3. Build external dashboard consuming the APIs
4. Test with sample data

---

**For detailed technical specifications, see:**
- `TECHNICAL_REQUIREMENTS_DASHBOARDS.md` - Complete API documentation
- `DASHBOARD_API_IMPLEMENTATION_NOTES.md` - Implementation guide

