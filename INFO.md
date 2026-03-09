# Energy Meter — Home Assistant Integration

Custom integration for Home Assistant that turns your Zigbee energy meter (Ourtop ATMS10013Z3 or similar) into a full-featured electricity accounting system with tariff calculation.

## Features

- **1/2/3-phase support** — works with single, dual, and three-phase meters
- **Dual tariff (Day/Night)** — automatic splitting of energy consumption by time of day
- **Single tariff** — simple flat rate calculation
- **Live voltage monitoring** — per-phase voltage display with visual bars
- **Power status indicator** — shows if electricity is available
- **Cost calculation** — automatic cost calculation based on configured rates (UAH)
- **Snapshot/Reset** — take snapshots of readings for billing period tracking
- **Custom Lovelace card** — beautiful dashboard card inspired by Gamma 100 meter display
- **Persistent storage** — readings survive Home Assistant restarts
- **Ukrainian localization** — full UI in Ukrainian

## Installation via HACS

1. Open HACS in Home Assistant
2. Go to **Integrations** → **Custom repositories**
3. Add this repository URL
4. Install **Energy Meter**
5. Restart Home Assistant
6. Go to **Settings** → **Devices & Services** → **Add Integration** → **Energy Meter**

## Configuration

The setup wizard will guide you through:

1. **Tariff type** — Single or Dual (Day/Night)
2. **Phase count** — 1, 2, or 3 phases
3. **Source entities** — Select your Zigbee2MQTT sensors:
   - Energy sensor (kWh total)
   - Power sensor (W)
   - Voltage sensors per phase (V)
4. **Tariff rates** — Cost per kWh in UAH
5. **Night schedule** (dual tariff) — Start/end time for night rate
6. **Initial readings** — Starting meter values

## Dashboard Card

Add the custom card to any dashboard:

```yaml
type: custom:energy-meter-card
entity: sensor.energy_meter_total
title: Лічильник
```

The card will automatically load from `custom_components/energy_meter/www/energy-meter-card.js`.

To register the card resource, add to your Lovelace configuration:

```yaml
resources:
  - url: /local/community/energy_meter/energy-meter-card.js
    type: module
```

Or via HACS Frontend → Add custom repository (type: Lovelace).

## Services

- `energy_meter.reset_readings` — Reset readings for new billing period
- `energy_meter.take_snapshot` — Save current readings snapshot

## Supported Devices

Tested with:
- **Ourtop ATMS10013Z3** (3-phase, Zigbee2MQTT)

Should work with any Zigbee energy meter that exposes `energy`, `power`, `voltage_a/b/c` entities via Zigbee2MQTT.

## Created Sensors

| Sensor | Description |
|--------|-------------|
| `sensor.energy_meter_total` | Total energy reading with day/night breakdown in attributes |
| `sensor.energy_cost` | Cost since last snapshot in UAH |
| `sensor.power_status` | Electricity availability (on/off) with per-phase voltage |

### Key Attributes on `sensor.energy_meter_total`

- `reading_day` / `reading_night` / `reading_total` — Current readings
- `delta_day` / `delta_night` / `delta_total` — Difference since snapshot
- `cost_day` / `cost_night` / `cost_total` — Cost breakdown
- `voltage_a` / `voltage_b` / `voltage_c` — Phase voltages
- `power` — Current power consumption
- `current_tariff` — Active tariff zone (day/night)
- `power_available` — Is electricity on
