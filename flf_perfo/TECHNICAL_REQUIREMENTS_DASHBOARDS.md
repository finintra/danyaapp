# Technical Requirements Document: FLF Performance Dashboards
## REST API Integration Specification

**Version:** 1.0  
**Date:** 2025-12-03  
**Module:** flf_performance (Odoo 15)

---

## Table of Contents

1. [Overview](#overview)
2. [API Endpoint Structure](#api-endpoint-structure)
3. [Dashboard 1: Wallboard Summary Table](#dashboard-1-wallboard-summary-table)
4. [Dashboard 2: Partners Performance Table](#dashboard-2-partners-performance-table)
5. [Dashboard 3: At Risk Pickings Table](#dashboard-3-at-risk-pickings-table)
6. [Dashboard 4: TOPs Rankings](#dashboard-4-tops-rankings)
7. [Dashboard 5: KPI Historical Data](#dashboard-5-kpi-historical-data)
8. [Data Models Reference](#data-models-reference)
9. [API Authentication](#api-authentication)
10. [Error Handling](#error-handling)
11. [Performance Considerations](#performance-considerations)

---

## Overview

This document specifies the technical requirements for building external dashboards that consume data from the FLF Performance module via REST API. The module tracks warehouse fulfillment performance metrics including order completion rates, deadline compliance, and partner-specific SLAs.

### Key Concepts

- **Flow Types**: `out` (outgoing/shipments) and `in` (incoming/receipts)
- **Company Context**: Multi-company support - all queries must specify company_ids
- **Time Zones**: All datetime calculations respect user timezone, but API returns UTC
- **Today Range**: Calculated based on user timezone (00:00:00 to 23:59:59 local time)

---

## API Endpoint Structure

### Base Endpoint
```
POST /flf/api/v1/wallboard/payload
GET  /flf/api/v1/wallboard/summary
GET  /flf/api/v1/wallboard/partners
GET  /flf/api/v1/wallboard/at-risk
GET  /flf/api/v1/wallboard/tops
GET  /flf/api/v1/kpi/list
```

### Authentication
All endpoints require Odoo session authentication or API key. Include in headers:
```
Cookie: session_id=<session_id>
```
OR
```
X-API-Key: <api_key>
```

---

## Dashboard 1: Wallboard Summary Table

### Purpose
High-level summary metrics for today's operations, aggregated by flow type (outgoing/incoming).

### API Endpoint
```
GET /flf/api/v1/wallboard/summary
POST /flf/api/v1/wallboard/payload (returns summary in payload.summary)
```

### Request Parameters
```json
{
  "company_ids": [1, 2],  // Optional: defaults to user's allowed companies
  "date": "2025-12-03"    // Optional: defaults to today (user timezone)
}
```

### Response Structure
```json
{
  "summary": [
    {
      "flow": "out",
      "pickings_done": 45,
      "lines_done": 234,
      "qty_done": 567.0,
      "pct_in_deadline": 87.5,
      "avg_sec_print_to_done": 3420.0,
      "pickings_risk_count": 3,
      "offday_shipments": 0
    },
    {
      "flow": "in",
      "pickings_done": 12,
      "lines_done": 45,
      "qty_done": 234.0,
      "pct_in_deadline": 100.0,
      "avg_sec_print_to_done": 1800.0,
      "pickings_risk_count": 0,
      "offday_shipments": 0
    }
  ],
  "generated_at": "2025-12-03T13:56:37",
  "date": "2025-12-03"
}
```

### Field Definitions

| Field | Type | Description | Calculation |
|-------|------|-------------|-------------|
| `flow` | string | Flow type: "out" or "in" | - |
| `pickings_done` | integer | Count of completed pickings today | Count of `stock.picking` where `state='done'` and `date_done` in today range |
| `lines_done` | integer | Total move lines completed | Count of `stock.move` linked to done pickings |
| `qty_done` | float | Total quantity completed | Sum of `qty_done` from `stock.move.line` |
| `pct_in_deadline` | float | Percentage of pickings completed before deadline | `(in_deadline_count / pickings_done) * 100` |
| `avg_sec_print_to_done` | float | Average seconds from print to done | Average of `(date_done - x_flf_print_ts)` for pickings with both timestamps |
| `pickings_risk_count` | integer | Count of at-risk pickings (outgoing only) | Count where `x_flf_risk_today=True` |
| `offday_shipments` | integer | Shipments on Sunday (bonus metric) | `pickings_done` if today is Sunday, else 0 |

### Data Source
- **Model**: `stock.picking` (direct query, not from KPI table)
- **Filters**: 
  - `state = 'done'`
  - `date_done >= today_start AND date_done < today_end`
  - `picking_type_id.code IN ('outgoing', 'incoming')`
  - `company_id IN (company_ids)`

### Display Requirements
- Table with 2 rows (one per flow)
- Columns: Flow | Pickings | Lines | Qty | % In Deadline | Avg Min P→D | Risk | Off-day
- Format `pct_in_deadline` as percentage with 1 decimal
- Format `avg_sec_print_to_done` as minutes with 1 decimal (divide by 60)

---

## Dashboard 2: Partners Performance Table

### Purpose
Detailed per-partner metrics showing order status, deadlines, and performance indicators.

### API Endpoint
```
GET /flf/api/v1/wallboard/partners
POST /flf/api/v1/wallboard/payload (returns partners in payload.partners)
```

### Request Parameters
```json
{
  "company_ids": [1, 2],
  "date": "2025-12-03",
  "flow": "out",  // Optional: "out", "in", or null for both
  "scope": "today"  // Optional: "today", "week", "month"
}
```

### Response Structure
```json
{
  "partners": [
    {
      "flow": "out",
      "partner_id": 123,
      "partner_name": "EarlyBird LLC",
      "company_id": 1,
      "company_name": "FLF Test Co 1",
      "unprinted": 2,
      "printed_not_picked": 5,
      "done": 12,
      "overdue": 1,
      "time_to_deadline_sec": 1800,
      "waiting_count": 3,
      "waiting_oldest": "2025-12-03T08:00:00",
      "waiting_new_today": 2,
      "deadline_at": "2025-12-03T15:00:00",
      "soft_deadline_at": "2025-12-03T19:00:00",
      "print_sum_sec": 7200.0,
      "print_n": 5,
      "print_avg_min": 24.0,
      "users_today": [
        {"name": "Alice Carter", "count": 8},
        {"name": "Bob Smith", "count": 4}
      ]
    }
  ],
  "generated_at": "2025-12-03T13:56:37"
}
```

### Field Definitions

| Field | Type | Description | Calculation |
|-------|------|-------------|-------------|
| `flow` | string | "out" or "in" | - |
| `partner_id` | integer | Partner ID | - |
| `partner_name` | string | Partner display name | - |
| `company_id` | integer | Company ID | - |
| `company_name` | string | Company name | - |
| `unprinted` | integer | Unprinted pickings (not done) | Count where `state != 'done'` AND `x_flf_print_ts IS NULL` |
| `printed_not_picked` | integer | Printed but not picked | Count where `state != 'done'` AND `x_flf_print_ts IS NOT NULL` |
| `done` | integer | Completed pickings today | Count where `state='done'` AND `date_done` in today range |
| `overdue` | integer | Overdue pickings | Count where `soft_deadline_at <= now` AND `state != 'done'` |
| `time_to_deadline_sec` | integer/null | Seconds until nearest deadline | Minimum `(soft_deadline_at - now)` for all non-done pickings |
| `waiting_count` | integer | Total waiting/confirmed pickings | Count where `state IN ('waiting', 'confirmed')` |
| `waiting_oldest` | datetime/null | Oldest waiting scheduled_date | Minimum `scheduled_date` from waiting pickings |
| `waiting_new_today` | integer | New waiting pickings today | Count where created/ready today AND `state IN ('waiting', 'confirmed')` |
| `deadline_at` | datetime/null | Hard deadline (UTC) | From `x_flf_deadline_at` field |
| `soft_deadline_at` | datetime/null | Soft deadline with window (UTC) | `deadline_at + soft_window_minutes` |
| `print_sum_sec` | float | Sum of print latencies | Sum of `(x_flf_print_ts - base_ts)` for today's pickings |
| `print_n` | integer | Count of printed pickings today | Count with `x_flf_print_ts` in today range |
| `print_avg_min` | float | Average print latency (minutes) | `(print_sum_sec / print_n) / 60` |
| `users_today` | array | Users who completed pickings today | Aggregated from `x_flf_done_user_id` |

### Data Source
- **Model**: `stock.picking`
- **Key Logic**:
  - **Outgoing**: Uses `x_flf_use_draft_trigger` to determine "today" start (create_date vs x_flf_ready_ts)
  - **Incoming**: Uses `create_date` for "today" calculation
  - **Deadline Calculation**: 
    - Outgoing: `partner.x_flf_deadline_hour` applied to `create_date` (local timezone)
    - Incoming: `scheduled_date + x_flf_inbound_max_days`
  - **Soft Window**: `deadline_at + partner.x_flf_soft_window_minutes`

### Display Requirements
- Table with columns: Flow | Co | Unprinted | Printed | Done | Overdue | →Deadline(m) | →Print(m) | Waiting (new/total) | Oldest | Users Today
- Row coloring:
  - **Red**: `overdue > 0`
  - **Yellow**: `time_to_deadline_sec <= 3600` (1 hour)
  - **Green**: Otherwise
- Format `time_to_deadline_sec` as minutes: `Math.round(sec / 60)`
- Format `waiting_oldest` as date/time
- Display up to 4 user badges, then "+N" for additional

### Sorting
- Primary: `time_to_deadline_sec` (ascending, nulls last)
- Secondary: `waiting_count` (descending)

---

## Dashboard 3: At Risk Pickings Table

### Purpose
List of pickings that are at risk of missing their deadline (within 60 minutes).

### API Endpoint
```
GET /flf/api/v1/wallboard/at-risk
POST /flf/api/v1/wallboard/payload (returns at_risk in payload.at_risk)
```

### Request Parameters
```json
{
  "company_ids": [1, 2],
  "limit": 12  // Optional: default 12, max 30
}
```

### Response Structure
```json
{
  "at_risk": [
    {
      "id": 456,
      "name": "WH/OUT/00123",
      "partner": "Electrinics LTD",
      "company": "FLF Test Co 1",
      "deadline": "2025-12-03T17:30:00",
      "time_to_deadline_sec": 1800
    }
  ],
  "generated_at": "2025-12-03T13:56:37"
}
```

### Field Definitions

| Field | Type | Description | Calculation |
|-------|------|-------------|-------------|
| `id` | integer | Picking ID | - |
| `name` | string | Picking name/reference | - |
| `partner` | string | Partner display name | May include "+N" suffix if multiple pickings grouped |
| `company` | string | Company name | - |
| `deadline` | datetime | Soft deadline (UTC) | `x_flf_deadline_at + soft_window_minutes` |
| `time_to_deadline_sec` | integer | Seconds until deadline | `(deadline - now)` |

### Data Source
- **Model**: `stock.picking`
- **Filters**:
  - `state != 'done'`
  - `picking_type_id.code = 'outgoing'`
  - `x_flf_risk_today = True` (primary)
  - OR `x_flf_deadline_at IS NOT NULL` AND created today (fallback)
  - `company_id IN (company_ids)`
- **Ordering**: `x_flf_deadline_at ASC`
- **Limit**: 12 (default), max 30

### Risk Calculation
A picking is "at risk" if:
- Created today (in user timezone)
- Not done
- Outgoing flow
- `0 <= (deadline - now) <= 60 minutes`

### Display Requirements
- Table with columns: Partner | Co | Deadline | →(m)
- Row coloring:
  - **Red**: `time_to_deadline_sec < 0` (overdue)
  - **Yellow**: `0 <= time_to_deadline_sec <= 3600` (at risk)
  - **Green**: Otherwise
- Format `time_to_deadline_sec` as minutes: `Math.round(sec / 60)`
- Show deadline as local time with timezone hint

---

## Dashboard 4: TOPs Rankings

### Purpose
Top performers by orders, lines, and quantity for day/week/month periods.

### API Endpoint
```
GET /flf/api/v1/wallboard/tops
POST /flf/api/v1/wallboard/payload (returns tops in payload.tops)
```

### Request Parameters
```json
{
  "company_ids": [1, 2],
  "period": "day"  // Optional: "day", "week", "month", or null for all
}
```

### Response Structure
```json
{
  "tops": {
    "day": {
      "users": {
        "orders": [
          {"name": "Alice Carter", "orders": 45, "lines": 234, "qty": 567.0}
        ],
        "lines": [
          {"name": "Bob Smith", "orders": 32, "lines": 289, "qty": 456.0}
        ],
        "qty": [
          {"name": "Alice Carter", "orders": 45, "lines": 234, "qty": 567.0}
        ]
      },
      "partners": {
        "orders": [
          {"name": "EarlyBird LLC", "orders": 23, "lines": 145, "qty": 234.0}
        ],
        "lines": [...],
        "qty": [...]
      }
    },
    "week": {...},
    "month": {...}
  },
  "generated_at": "2025-12-03T13:56:37"
}
```

### Field Definitions

| Field | Type | Description | Calculation |
|-------|------|-------------|-------------|
| `name` | string | User or partner name | - |
| `orders` | integer | Count of completed pickings | From `flf.performance.kpi.pickings_done` or direct count |
| `lines` | integer | Total move lines | From `flf.performance.kpi.lines_done` or direct count |
| `qty` | float | Total quantity | From `flf.performance.kpi.qty_done` or direct count |

### Data Source
- **Primary**: `flf.performance.kpi` model (aggregated daily data)
- **Fallback**: Direct `stock.picking` query if KPI data unavailable
- **Periods**:
  - **Day**: Today only
  - **Week**: Last 7 days (today - 6 days to today)
  - **Month**: Last 30 days (today - 29 days to today)
- **Filters**:
  - `flow = 'out'` (outgoing only)
  - `date >= period_start AND date <= today`
  - `company_id IN (company_ids)`

### Ranking Logic
- Top 5 per category
- Sort by primary metric (orders/lines/qty) descending
- Secondary sort by `orders` descending
- Separate rankings for users and partners

### Display Requirements
- Three sections: Day | Week | Month
- Each section shows: Users (orders) | Partners (orders)
- Display top 5 entries per category
- Format: "Name — Count"

---

## Dashboard 5: KPI Historical Data

### Purpose
Historical KPI data for trend analysis, reporting, and detailed analytics.

### API Endpoint
```
GET /flf/api/v1/kpi/list
```

### Request Parameters
```json
{
  "company_ids": [1, 2],
  "date_from": "2025-12-01",
  "date_to": "2025-12-03",
  "flow": "out",  // Optional: "out", "in", or null
  "partner_id": 123,  // Optional
  "user_id": 45,  // Optional
  "limit": 100,
  "offset": 0
}
```

### Response Structure
```json
{
  "kpis": [
    {
      "id": 789,
      "date": "2025-12-03",
      "company_id": 1,
      "company_name": "FLF Test Co 1",
      "partner_id": 123,
      "partner_name": "EarlyBird LLC",
      "user_id": 45,
      "user_name": "Alice Carter",
      "flow": "out",
      "pickings_done": 12,
      "lines_done": 67,
      "qty_done": 234.0,
      "pct_in_deadline": 91.7,
      "avg_sec_print_to_done": 3420.0,
      "pickings_risk_count": 1,
      "done_in_soft_window": 10,
      "done_in_last_truck": 8,
      "done_afterhours_transfer": 2,
      "all_created_shipped_today": true,
      "effort_consolidation_score": 0.85,
      "is_effort_consolidation_day": false,
      "offday_shipments": 0
    }
  ],
  "total": 150,
  "limit": 100,
  "offset": 0
}
```

### Field Definitions

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | KPI record ID |
| `date` | date | KPI date |
| `company_id` | integer | Company ID |
| `company_name` | string | Company name |
| `partner_id` | integer/null | Partner ID (null for company-level) |
| `partner_name` | string/null | Partner name |
| `user_id` | integer/null | User ID (null for partner/company-level) |
| `user_name` | string/null | User name |
| `flow` | string | "out" or "in" |
| `pickings_done` | integer | Completed pickings |
| `lines_done` | integer | Completed move lines |
| `qty_done` | float | Completed quantity |
| `pct_in_deadline` | float | Percentage in deadline |
| `avg_sec_print_to_done` | float | Average seconds print to done |
| `pickings_risk_count` | integer | At-risk pickings count |
| `done_in_soft_window` | integer | Done within soft window |
| `done_in_last_truck` | integer | Done in last truck slot |
| `done_afterhours_transfer` | integer | Done via afterhours transfer |
| `all_created_shipped_today` | boolean | All created today were shipped |
| `effort_consolidation_score` | float | Consolidation effort score (0-1) |
| `is_effort_consolidation_day` | boolean | Was consolidation day |
| `offday_shipments` | integer | Sunday shipments |

### Data Source
- **Model**: `flf.performance.kpi`
- **Granularity**: Daily aggregates
- **Levels**: Company, Partner, User (hierarchical)

### Display Requirements
- Support tree, graph, pivot, and form views
- Filterable by date range, company, partner, user, flow
- Exportable to CSV/Excel
- Chart support: line, bar, pie

---

## Data Models Reference

### stock.picking (Extended Fields)

| Field | Type | Description |
|-------|------|-------------|
| `x_flf_done_user_id` | Many2one | User who validated (button_validate) |
| `x_flf_risk_today` | Boolean | Computed: at risk today (0-60 min to deadline) |
| `x_flf_print_ts` | Datetime | First print timestamp |
| `x_flf_print_user_id` | Many2one | User who printed |
| `x_flf_deadline_at` | Datetime | Computed deadline (UTC) |
| `x_flf_in_deadline` | Boolean | Computed: completed before deadline |

### res.partner (Extended Fields)

| Field | Type | Description |
|-------|------|-------------|
| `x_flf_deadline_hour` | Float | Deadline hour (local, e.g., 17.0 = 17:00) |
| `x_flf_soft_window_minutes` | Integer | Soft window after deadline (computed) |
| `x_flf_last_shipment_hour` | Float | Last shipment hour (e.g., 19.0) |
| `x_flf_afterhours_credit` | Boolean | Credit afterhours transfers |
| `x_flf_use_draft_trigger` | Boolean | Draft state triggers work |
| `x_flf_big_order_line_count` | Integer | Big order threshold (lines) |
| `x_flf_big_order_qty` | Integer | Big order threshold (quantity) |
| `x_flf_responsible_user_ids` | Many2many | Responsible users |
| `x_flf_inbound_max_days` | Integer | Max days for inbound (default: 2) |

### flf.performance.kpi

| Field | Type | Description |
|-------|------|-------------|
| `date` | Date | KPI date |
| `company_id` | Many2one | Company |
| `partner_id` | Many2one | Partner (optional) |
| `user_id` | Many2one | User (optional) |
| `flow` | Selection | "out" or "in" |
| `pickings_done` | Integer | Completed pickings |
| `lines_done` | Integer | Completed lines |
| `qty_done` | Float | Completed quantity |
| `pct_in_deadline` | Float | Percentage in deadline |
| `avg_sec_print_to_done` | Float | Average seconds |
| `pickings_risk_count` | Integer | Risk count |
| `offday_shipments` | Integer | Sunday shipments |

---

## API Authentication

### Method 1: Session Cookie
```
Cookie: session_id=<odoo_session_id>
```

### Method 2: API Key (if implemented)
```
X-API-Key: <api_key>
Authorization: Bearer <token>
```

### Method 3: Basic Auth (Odoo standard)
```
Authorization: Basic <base64(username:password)>
```

### Company Context
- Default: User's allowed companies from session
- Override: Pass `company_ids` in request
- Multi-company: API aggregates data across specified companies

---

## Error Handling

### Standard Error Response
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {}
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `AUTH_REQUIRED` | 401 | Authentication required |
| `INVALID_COMPANY` | 403 | Company not accessible |
| `INVALID_DATE` | 400 | Invalid date format |
| `INVALID_PARAMETER` | 400 | Invalid request parameter |
| `SERVER_ERROR` | 500 | Internal server error |

---

## Performance Considerations

### Caching
- Wallboard payload: Cache for 30 seconds (configurable via `flf_performance.refresh_interval_sec`)
- KPI data: Cache for 2 minutes (cron updates every 2 minutes)
- Partner data: Real-time (no cache)

### Pagination
- Partners table: Client-side pagination (page size calculated from viewport)
- KPI list: Server-side pagination (limit/offset)

### Optimization
- Use `read_payload` method for combined data (single request)
- Filter by company_ids to reduce dataset
- Use date ranges for historical queries
- Indexed fields: `date_done`, `x_flf_deadline_at`, `x_flf_print_ts`, `state`, `company_id`

### Rate Limiting
- Recommended: 1 request per 5 seconds per client
- Wallboard auto-refresh: 30 seconds (configurable)

---

## Example API Implementation (Python)

```python
import requests
import json

class FLFPerformanceAPI:
    def __init__(self, base_url, session_id):
        self.base_url = base_url
        self.session_id = session_id
        self.headers = {
            'Cookie': f'session_id={session_id}',
            'Content-Type': 'application/json'
        }
    
    def get_wallboard_payload(self, company_ids=None):
        """Get complete wallboard payload"""
        url = f"{self.base_url}/flf/api/v1/wallboard/payload"
        data = {}
        if company_ids:
            data['company_ids'] = company_ids
        response = requests.post(url, json=data, headers=self.headers)
        return response.json()
    
    def get_summary(self, company_ids=None, date=None):
        """Get summary table data"""
        url = f"{self.base_url}/flf/api/v1/wallboard/summary"
        params = {}
        if company_ids:
            params['company_ids'] = company_ids
        if date:
            params['date'] = date
        response = requests.get(url, params=params, headers=self.headers)
        return response.json()
    
    def get_partners(self, company_ids=None, flow=None):
        """Get partners performance data"""
        url = f"{self.base_url}/flf/api/v1/wallboard/partners"
        params = {}
        if company_ids:
            params['company_ids'] = company_ids
        if flow:
            params['flow'] = flow
        response = requests.get(url, params=params, headers=self.headers)
        return response.json()
    
    def get_at_risk(self, company_ids=None, limit=12):
        """Get at-risk pickings"""
        url = f"{self.base_url}/flf/api/v1/wallboard/at-risk"
        params = {'limit': limit}
        if company_ids:
            params['company_ids'] = company_ids
        response = requests.get(url, params=params, headers=self.headers)
        return response.json()
    
    def get_tops(self, company_ids=None, period=None):
        """Get TOPs rankings"""
        url = f"{self.base_url}/flf/api/v1/wallboard/tops"
        params = {}
        if company_ids:
            params['company_ids'] = company_ids
        if period:
            params['period'] = period
        response = requests.get(url, params=params, headers=self.headers)
        return response.json()
    
    def get_kpi_list(self, company_ids=None, date_from=None, date_to=None, 
                     flow=None, partner_id=None, user_id=None, 
                     limit=100, offset=0):
        """Get KPI historical data"""
        url = f"{self.base_url}/flf/api/v1/kpi/list"
        params = {'limit': limit, 'offset': offset}
        if company_ids:
            params['company_ids'] = company_ids
        if date_from:
            params['date_from'] = date_from
        if date_to:
            params['date_to'] = date_to
        if flow:
            params['flow'] = flow
        if partner_id:
            params['partner_id'] = partner_id
        if user_id:
            params['user_id'] = user_id
        response = requests.get(url, params=params, headers=self.headers)
        return response.json()
```

---

## Example Dashboard Implementation (React)

```jsx
import React, { useState, useEffect } from 'react';
import { FLFPerformanceAPI } from './api';

function WallboardDashboard() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const api = new FLFPerformanceAPI(process.env.REACT_APP_ODOO_URL, sessionId);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const payload = await api.get_wallboard_payload();
        setData(payload);
      } catch (error) {
        console.error('Error fetching wallboard:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
    const interval = setInterval(fetchData, 30000); // Refresh every 30s
    return () => clearInterval(interval);
  }, []);

  if (loading) return <div>Loading...</div>;
  if (!data) return <div>Error loading data</div>;

  return (
    <div className="wallboard">
      <SummaryTable data={data.summary} />
      <PartnersTable data={data.partners} />
      <AtRiskTable data={data.at_risk} />
      <TopsSection data={data.tops} />
    </div>
  );
}
```

---

## Appendix: Odoo Model Method Reference

### flf.performance.wallboard.read_payload()

**Method**: `read_payload()`  
**Model**: `flf.performance.wallboard`  
**Returns**: Complete wallboard payload

**Implementation Notes**:
- Respects user timezone for "today" calculation
- Aggregates across multiple companies if specified
- Returns refresh interval configuration

**Python Call Example**:
```python
env['flf.performance.wallboard'].with_context(
    allowed_company_ids=[1, 2]
).read_payload()
```

---

**Document End**

