# Dashboard API Implementation Notes

## Current State

The FLF Performance module currently uses **Odoo's internal RPC mechanism** (JavaScript `rpc.query`) for data retrieval. The main method is:

```python
# Model: flf.performance.wallboard
# Method: read_payload()
```

This method returns the complete wallboard data structure but is only accessible via Odoo's web interface.

## REST API Implementation Required

To build an external dashboard, you need to **expose these methods as REST API endpoints**. Here are the implementation options:

### Option 1: Create Custom REST Controller (Recommended)

Create a new controller file: `flf_performance/controllers/rest_api.py`

```python
# -*- coding: utf-8 -*-
from odoo import http
from odoo.http import request
import json
from datetime import datetime, date

class FLFPerformanceREST(http.Controller):
    
    @http.route('/flf/api/v1/wallboard/payload', 
                type='json', auth='user', methods=['POST'])
    def wallboard_payload(self, company_ids=None, date=None):
        """Main wallboard payload endpoint"""
        wallboard = request.env['flf.performance.wallboard']
        if company_ids:
            wallboard = wallboard.with_context(
                allowed_company_ids=company_ids
            )
        return wallboard.read_payload()
    
    @http.route('/flf/api/v1/wallboard/summary', 
                type='json', auth='user', methods=['GET', 'POST'])
    def wallboard_summary(self, company_ids=None, date=None):
        """Summary table endpoint"""
        wallboard = request.env['flf.performance.wallboard']
        if company_ids:
            wallboard = wallboard.with_context(
                allowed_company_ids=company_ids
            )
        payload = wallboard.read_payload()
        return {
            'summary': payload.get('summary', []),
            'generated_at': payload.get('generated_at'),
            'date': date or str(fields.Date.context_today(request.env['stock.picking']))
        }
    
    @http.route('/flf/api/v1/wallboard/partners', 
                type='json', auth='user', methods=['GET', 'POST'])
    def wallboard_partners(self, company_ids=None, flow=None, scope='today'):
        """Partners table endpoint"""
        wallboard = request.env['flf.performance.wallboard']
        if company_ids:
            wallboard = wallboard.with_context(
                allowed_company_ids=company_ids
            )
        payload = wallboard.read_payload()
        partners = payload.get('partners', [])
        
        if flow:
            partners = [p for p in partners if p.get('flow') == flow]
        
        return {
            'partners': partners,
            'generated_at': payload.get('generated_at')
        }
    
    @http.route('/flf/api/v1/wallboard/at-risk', 
                type='json', auth='user', methods=['GET', 'POST'])
    def wallboard_at_risk(self, company_ids=None, limit=12):
        """At-risk pickings endpoint"""
        wallboard = request.env['flf.performance.wallboard']
        if company_ids:
            wallboard = wallboard.with_context(
                allowed_company_ids=company_ids
            )
        payload = wallboard.read_payload()
        at_risk = payload.get('at_risk', [])[:limit]
        
        return {
            'at_risk': at_risk,
            'generated_at': payload.get('generated_at')
        }
    
    @http.route('/flf/api/v1/wallboard/tops', 
                type='json', auth='user', methods=['GET', 'POST'])
    def wallboard_tops(self, company_ids=None, period=None):
        """TOPs rankings endpoint"""
        wallboard = request.env['flf.performance.wallboard']
        if company_ids:
            wallboard = wallboard.with_context(
                allowed_company_ids=company_ids
            )
        payload = wallboard.read_payload()
        tops = payload.get('tops', {})
        
        if period:
            return {
                'tops': {period: tops.get(period, {})},
                'generated_at': payload.get('generated_at')
            }
        
        return {
            'tops': tops,
            'generated_at': payload.get('generated_at')
        }
    
    @http.route('/flf/api/v1/kpi/list', 
                type='json', auth='user', methods=['GET', 'POST'])
    def kpi_list(self, company_ids=None, date_from=None, date_to=None,
                 flow=None, partner_id=None, user_id=None, 
                 limit=100, offset=0):
        """KPI historical data endpoint"""
        KPI = request.env['flf.performance.kpi']
        domain = []
        
        if company_ids:
            domain.append(('company_id', 'in', company_ids))
        if date_from:
            domain.append(('date', '>=', date_from))
        if date_to:
            domain.append(('date', '<=', date_to))
        if flow:
            domain.append(('flow', '=', flow))
        if partner_id:
            domain.append(('partner_id', '=', partner_id))
        if user_id:
            domain.append(('user_id', '=', user_id))
        
        kpis = KPI.search(domain, limit=limit, offset=offset, 
                         order='date desc, flow')
        total = KPI.search_count(domain)
        
        result = []
        for kpi in kpis:
            result.append({
                'id': kpi.id,
                'date': str(kpi.date),
                'company_id': kpi.company_id.id,
                'company_name': kpi.company_id.name,
                'partner_id': kpi.partner_id.id if kpi.partner_id else None,
                'partner_name': kpi.partner_id.display_name if kpi.partner_id else None,
                'user_id': kpi.user_id.id if kpi.user_id else None,
                'user_name': kpi.user_id.name if kpi.user_id else None,
                'flow': kpi.flow,
                'pickings_done': kpi.pickings_done,
                'lines_done': kpi.lines_done,
                'qty_done': kpi.qty_done,
                'pct_in_deadline': kpi.pct_in_deadline,
                'avg_sec_print_to_done': kpi.avg_sec_print_to_done,
                'pickings_risk_count': kpi.pickings_risk_count,
                'done_in_soft_window': kpi.done_in_soft_window,
                'done_in_last_truck': kpi.done_in_last_truck,
                'done_afterhours_transfer': kpi.done_afterhours_transfer,
                'all_created_shipped_today': kpi.all_created_shipped_today,
                'effort_consolidation_score': kpi.effort_consolidation_score,
                'is_effort_consolidation_day': kpi.is_effort_consolidation_day,
                'offday_shipments': kpi.offday_shipments,
            })
        
        return {
            'kpis': result,
            'total': total,
            'limit': limit,
            'offset': offset
        }
```

### Option 2: Use Odoo's Built-in JSON-RPC

Odoo already provides JSON-RPC endpoints. You can call the model methods directly:

```python
# Endpoint: /jsonrpc
# Method: POST
# Body:
{
    "jsonrpc": "2.0",
    "method": "call",
    "params": {
        "service": "object",
        "method": "execute_kw",
        "args": [
            "database_name",
            uid,
            "password",
            "flf.performance.wallboard",
            "read_payload",
            [],
            {}
        ]
    },
    "id": 1
}
```

### Option 3: Use Odoo REST Framework (if available)

If you have `odoo-rest-api` or similar module installed, you can expose models directly.

## Required Files Structure

```
flf_performance/
├── controllers/
│   ├── __init__.py
│   └── rest_api.py          # NEW: REST API controller
├── models/
│   └── ... (existing)
└── __manifest__.py          # UPDATE: Add controllers
```

## Security Considerations

1. **Authentication**: All endpoints require `auth='user'` (Odoo session)
2. **Company Access**: Respect user's allowed companies
3. **Rate Limiting**: Implement rate limiting for production
4. **CORS**: Configure CORS if accessing from external domains

## Testing the API

### Using curl:

```bash
# Get session ID first
curl -X POST http://localhost:8069/web/session/authenticate \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "params": {
      "db": "odoo",
      "login": "admin",
      "password": "admin"
    }
  }'

# Then use session_id in cookie
curl -X POST http://localhost:8069/flf/api/v1/wallboard/payload \
  -H "Content-Type: application/json" \
  -H "Cookie: session_id=<session_id>" \
  -d '{"company_ids": [1]}'
```

### Using Python requests:

```python
import requests

session = requests.Session()
# Login
response = session.post('http://localhost:8069/web/login', data={
    'login': 'admin',
    'password': 'admin',
    'db': 'odoo'
})

# Get wallboard data
response = session.post('http://localhost:8069/flf/api/v1/wallboard/payload', 
                       json={'company_ids': [1]})
data = response.json()
```

## Next Steps

1. Create the REST controller file
2. Update `__manifest__.py` to include controllers
3. Test endpoints with curl/Postman
4. Build external dashboard consuming these endpoints
5. Implement caching layer (optional)
6. Add API documentation (Swagger/OpenAPI)

## Notes

- The `read_payload()` method already handles multi-company aggregation
- Timezone handling is built into the model methods
- Refresh intervals are configurable via `ir.config_parameter`
- All datetime fields are returned in UTC (convert to local time in frontend)

