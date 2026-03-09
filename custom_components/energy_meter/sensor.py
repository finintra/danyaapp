"""Sensor platform for Energy Meter integration."""
from __future__ import annotations

import logging
from datetime import datetime
from typing import Any

from homeassistant.components.sensor import (
    SensorDeviceClass,
    SensorEntity,
    SensorStateClass,
)
from homeassistant.config_entries import ConfigEntry
from homeassistant.const import UnitOfEnergy
from homeassistant.core import HomeAssistant, callback
from homeassistant.helpers.entity_platform import AddEntitiesCallback
from homeassistant.helpers.event import async_track_state_change_event
from homeassistant.helpers.restore_state import RestoreEntity

from .const import (
    DOMAIN,
    CONF_TARIFF_TYPE,
    CONF_PHASE_COUNT,
    CONF_DAY_RATE,
    CONF_NIGHT_RATE,
    CONF_SINGLE_RATE,
    CONF_NIGHT_START_HOUR,
    CONF_NIGHT_START_MINUTE,
    CONF_NIGHT_END_HOUR,
    CONF_NIGHT_END_MINUTE,
    CONF_INITIAL_DAY,
    CONF_INITIAL_NIGHT,
    CONF_INITIAL_TOTAL,
    CONF_ENERGY_ENTITY,
    CONF_VOLTAGE_A_ENTITY,
    CONF_VOLTAGE_B_ENTITY,
    CONF_VOLTAGE_C_ENTITY,
    CONF_POWER_ENTITY,
    TARIFF_SINGLE,
    TARIFF_DUAL,
    PHASE_1,
)

_LOGGER = logging.getLogger(__name__)

# Voltage entity keys in order of phases
VOLTAGE_KEYS = [CONF_VOLTAGE_A_ENTITY, CONF_VOLTAGE_B_ENTITY, CONF_VOLTAGE_C_ENTITY]
VOLTAGE_ATTRS = ["voltage_a", "voltage_b", "voltage_c"]


def _is_night_time(
    now: datetime,
    night_start_h: int,
    night_start_m: int,
    night_end_h: int,
    night_end_m: int,
) -> bool:
    """Check if current time falls within night tariff period."""
    current = now.hour * 60 + now.minute
    start = night_start_h * 60 + night_start_m
    end = night_end_h * 60 + night_end_m

    if start > end:
        return current >= start or current < end
    return start <= current < end


async def async_setup_entry(
    hass: HomeAssistant,
    entry: ConfigEntry,
    async_add_entities: AddEntitiesCallback,
) -> None:
    """Set up Energy Meter sensors."""
    config = entry.data
    entry_data = hass.data[DOMAIN][entry.entry_id]
    stored = entry_data["stored"]
    store = entry_data["store"]

    entities: list[SensorEntity] = [
        EnergyMeterMainSensor(entry, config, stored, store),
        EnergyMeterCostSensor(entry, config, stored),
        EnergyMeterPowerStatusSensor(entry, config),
    ]

    async_add_entities(entities, True)


class EnergyMeterMainSensor(RestoreEntity, SensorEntity):
    """Main energy meter sensor — tracks day/night/total readings."""

    _attr_device_class = SensorDeviceClass.ENERGY
    _attr_state_class = SensorStateClass.TOTAL_INCREASING
    _attr_native_unit_of_measurement = UnitOfEnergy.KILO_WATT_HOUR
    _attr_has_entity_name = True
    _attr_icon = "mdi:flash-triangle-outline"

    def __init__(self, entry: ConfigEntry, config: dict, stored: dict, store) -> None:
        """Initialize."""
        self._entry = entry
        self._config = config
        self._stored = stored
        self._store = store
        self._attr_unique_id = f"{entry.entry_id}_main"
        self._attr_name = "Energy Meter Total"
        self._phase_count = int(config.get(CONF_PHASE_COUNT, 3))

        self._reading_day: float = stored.get("reading_day", config.get(CONF_INITIAL_DAY, 0.0))
        self._reading_night: float = stored.get("reading_night", config.get(CONF_INITIAL_NIGHT, 0.0))
        self._reading_total: float = stored.get("reading_total", config.get(CONF_INITIAL_TOTAL, 0.0))
        self._snapshot_day: float = stored.get("snapshot_day", 0.0)
        self._snapshot_night: float = stored.get("snapshot_night", 0.0)
        self._snapshot_total: float = stored.get("snapshot_total", 0.0)
        self._snapshot_time: str | None = stored.get("snapshot_time")
        self._last_energy: float | None = stored.get("last_energy")

        self._voltages: dict[str, float | None] = {k: None for k in VOLTAGE_ATTRS[:self._phase_count]}
        self._power: float | None = None
        self._unsub_listeners: list = []

    @property
    def device_info(self):
        """Return device info."""
        return {
            "identifiers": {(DOMAIN, self._entry.entry_id)},
            "name": "Energy Meter",
            "manufacturer": "Ourtop",
            "model": f"ATMS10013Z3 ({self._phase_count}P)",
        }

    @property
    def native_value(self) -> float:
        """Return total reading."""
        if self._config.get(CONF_TARIFF_TYPE) == TARIFF_DUAL:
            return round(self._reading_day + self._reading_night, 2)
        return round(self._reading_total, 2)

    @property
    def extra_state_attributes(self) -> dict[str, Any]:
        """Return detailed attributes."""
        attrs: dict[str, Any] = {
            "tariff_type": self._config.get(CONF_TARIFF_TYPE, TARIFF_SINGLE),
            "phase_count": self._phase_count,
        }

        if self._config.get(CONF_TARIFF_TYPE) == TARIFF_DUAL:
            attrs["reading_day"] = round(self._reading_day, 2)
            attrs["reading_night"] = round(self._reading_night, 2)
            attrs["reading_total"] = round(self._reading_day + self._reading_night, 2)
            attrs["delta_day"] = round(self._reading_day - self._snapshot_day, 2)
            attrs["delta_night"] = round(self._reading_night - self._snapshot_night, 2)
            attrs["delta_total"] = round(
                (self._reading_day + self._reading_night) - (self._snapshot_day + self._snapshot_night), 2
            )
            day_rate = self._config.get(CONF_DAY_RATE, 0)
            night_rate = self._config.get(CONF_NIGHT_RATE, 0)
            attrs["cost_day"] = round(attrs["delta_day"] * day_rate, 2)
            attrs["cost_night"] = round(attrs["delta_night"] * night_rate, 2)
            attrs["cost_total"] = round(attrs["cost_day"] + attrs["cost_night"], 2)
            attrs["day_rate"] = day_rate
            attrs["night_rate"] = night_rate

            now = datetime.now()
            is_night = _is_night_time(
                now,
                int(self._config.get(CONF_NIGHT_START_HOUR, 23)),
                int(self._config.get(CONF_NIGHT_START_MINUTE, 0)),
                int(self._config.get(CONF_NIGHT_END_HOUR, 7)),
                int(self._config.get(CONF_NIGHT_END_MINUTE, 0)),
            )
            attrs["current_tariff"] = "night" if is_night else "day"
            attrs["night_start"] = f"{int(self._config.get(CONF_NIGHT_START_HOUR, 23)):02d}:{int(self._config.get(CONF_NIGHT_START_MINUTE, 0)):02d}"
            attrs["night_end"] = f"{int(self._config.get(CONF_NIGHT_END_HOUR, 7)):02d}:{int(self._config.get(CONF_NIGHT_END_MINUTE, 0)):02d}"
        else:
            attrs["reading_total"] = round(self._reading_total, 2)
            attrs["delta_total"] = round(self._reading_total - self._snapshot_total, 2)
            rate = self._config.get(CONF_SINGLE_RATE, 0)
            attrs["cost_total"] = round(attrs["delta_total"] * rate, 2)
            attrs["single_rate"] = rate

        # Voltage info per configured phase
        for attr_name in VOLTAGE_ATTRS[:self._phase_count]:
            attrs[attr_name] = self._voltages.get(attr_name)

        attrs["power"] = self._power

        if self._snapshot_time:
            attrs["last_snapshot"] = self._snapshot_time

        # Power available if any voltage > 50V
        power_on = any(
            v is not None and v > 50
            for v in self._voltages.values()
        )
        attrs["power_available"] = power_on

        return attrs

    async def async_added_to_hass(self) -> None:
        """Subscribe to source entity changes."""
        await super().async_added_to_hass()

        last_state = await self.async_get_last_state()
        if last_state and last_state.attributes:
            a = last_state.attributes
            self._reading_day = a.get("reading_day", self._reading_day)
            self._reading_night = a.get("reading_night", self._reading_night)
            self._reading_total = a.get("reading_total", self._reading_total)
            for attr_name in VOLTAGE_ATTRS[:self._phase_count]:
                if attr_name in a:
                    self._voltages[attr_name] = a[attr_name]

        # Build list of entities to track
        entities_to_track = [self._config[CONF_ENERGY_ENTITY]]
        if CONF_POWER_ENTITY in self._config:
            entities_to_track.append(self._config[CONF_POWER_ENTITY])
        for i, key in enumerate(VOLTAGE_KEYS[:self._phase_count]):
            if key in self._config:
                entities_to_track.append(self._config[key])

        self._unsub_listeners.append(
            async_track_state_change_event(
                self.hass, entities_to_track, self._async_source_changed
            )
        )

        # Read initial values
        for i, key in enumerate(VOLTAGE_KEYS[:self._phase_count]):
            entity_id = self._config.get(key)
            if entity_id:
                state = self.hass.states.get(entity_id)
                if state and state.state not in ("unknown", "unavailable"):
                    try:
                        self._voltages[VOLTAGE_ATTRS[i]] = float(state.state)
                    except (ValueError, TypeError):
                        pass

        power_entity = self._config.get(CONF_POWER_ENTITY)
        if power_entity:
            state = self.hass.states.get(power_entity)
            if state and state.state not in ("unknown", "unavailable"):
                try:
                    self._power = float(state.state)
                except (ValueError, TypeError):
                    pass

        energy_state = self.hass.states.get(self._config[CONF_ENERGY_ENTITY])
        if energy_state and energy_state.state not in ("unknown", "unavailable"):
            try:
                self._last_energy = float(energy_state.state)
            except (ValueError, TypeError):
                pass

    async def async_will_remove_from_hass(self) -> None:
        """Unsubscribe."""
        for unsub in self._unsub_listeners:
            unsub()
        self._unsub_listeners.clear()

    @callback
    def _async_source_changed(self, event) -> None:
        """Handle source entity state changes."""
        entity_id = event.data["entity_id"]
        new_state = event.data.get("new_state")
        if new_state is None or new_state.state in ("unknown", "unavailable"):
            return

        try:
            value = float(new_state.state)
        except (ValueError, TypeError):
            return

        # Check which entity changed
        for i, key in enumerate(VOLTAGE_KEYS[:self._phase_count]):
            if entity_id == self._config.get(key):
                self._voltages[VOLTAGE_ATTRS[i]] = value
                self.async_write_ha_state()
                return

        if entity_id == self._config.get(CONF_POWER_ENTITY):
            self._power = value
        elif entity_id == self._config[CONF_ENERGY_ENTITY]:
            self._process_energy(value)

        self.async_write_ha_state()

    def _process_energy(self, new_energy: float) -> None:
        """Process energy reading — split into day/night if dual tariff."""
        if self._last_energy is None:
            self._last_energy = new_energy
            return

        delta = new_energy - self._last_energy
        if delta <= 0:
            self._last_energy = new_energy
            return

        self._last_energy = new_energy
        tariff_type = self._config.get(CONF_TARIFF_TYPE, TARIFF_SINGLE)

        if tariff_type == TARIFF_DUAL:
            now = datetime.now()
            is_night = _is_night_time(
                now,
                int(self._config.get(CONF_NIGHT_START_HOUR, 23)),
                int(self._config.get(CONF_NIGHT_START_MINUTE, 0)),
                int(self._config.get(CONF_NIGHT_END_HOUR, 7)),
                int(self._config.get(CONF_NIGHT_END_MINUTE, 0)),
            )
            if is_night:
                self._reading_night += delta
            else:
                self._reading_day += delta
        else:
            self._reading_total += delta

        # Persist
        self._stored["reading_day"] = self._reading_day
        self._stored["reading_night"] = self._reading_night
        self._stored["reading_total"] = self._reading_total
        self._stored["last_energy"] = self._last_energy
        self.hass.async_create_task(self._store.async_save(dict(self._stored)))


class EnergyMeterCostSensor(SensorEntity):
    """Sensor showing cost since last snapshot."""

    _attr_device_class = SensorDeviceClass.MONETARY
    _attr_state_class = SensorStateClass.TOTAL
    _attr_native_unit_of_measurement = "UAH"
    _attr_has_entity_name = True
    _attr_icon = "mdi:currency-uah"

    def __init__(self, entry: ConfigEntry, config: dict, stored: dict) -> None:
        """Initialize."""
        self._entry = entry
        self._config = config
        self._stored = stored
        self._attr_unique_id = f"{entry.entry_id}_cost"
        self._attr_name = "Energy Cost"

    @property
    def device_info(self):
        """Return device info."""
        return {"identifiers": {(DOMAIN, self._entry.entry_id)}}

    @property
    def native_value(self) -> float:
        """Calculate cost from stored data."""
        tariff = self._config.get(CONF_TARIFF_TYPE, TARIFF_SINGLE)
        snap_day = self._stored.get("snapshot_day", 0)
        snap_night = self._stored.get("snapshot_night", 0)
        snap_total = self._stored.get("snapshot_total", 0)
        cur_day = self._stored.get("reading_day", 0)
        cur_night = self._stored.get("reading_night", 0)
        cur_total = self._stored.get("reading_total", 0)

        if tariff == TARIFF_DUAL:
            day_rate = self._config.get(CONF_DAY_RATE, 0)
            night_rate = self._config.get(CONF_NIGHT_RATE, 0)
            return round(
                (cur_day - snap_day) * day_rate + (cur_night - snap_night) * night_rate, 2
            )
        rate = self._config.get(CONF_SINGLE_RATE, 0)
        return round((cur_total - snap_total) * rate, 2)


class EnergyMeterPowerStatusSensor(SensorEntity):
    """Sensor showing if electricity is available per phase."""

    _attr_has_entity_name = True
    _attr_icon = "mdi:transmission-tower"

    def __init__(self, entry: ConfigEntry, config: dict) -> None:
        """Initialize."""
        self._entry = entry
        self._config = config
        self._phase_count = int(config.get(CONF_PHASE_COUNT, 3))
        self._attr_unique_id = f"{entry.entry_id}_power_status"
        self._attr_name = "Power Status"
        self._power_available: bool | None = None
        self._unsub = None

    @property
    def device_info(self):
        """Return device info."""
        return {"identifiers": {(DOMAIN, self._entry.entry_id)}}

    @property
    def native_value(self) -> str:
        """Return power status."""
        if self._power_available is None:
            return "unknown"
        return "on" if self._power_available else "off"

    @property
    def icon(self) -> str:
        """Return icon based on status."""
        if self._power_available:
            return "mdi:transmission-tower"
        return "mdi:transmission-tower-off"

    @property
    def extra_state_attributes(self) -> dict[str, Any]:
        """Return voltage details per phase."""
        attrs: dict[str, Any] = {}
        for i, key in enumerate(VOLTAGE_KEYS[:self._phase_count]):
            entity_id = self._config.get(key)
            if entity_id:
                state = self.hass.states.get(entity_id)
                if state and state.state not in ("unknown", "unavailable"):
                    try:
                        attrs[VOLTAGE_ATTRS[i]] = round(float(state.state), 1)
                    except (ValueError, TypeError):
                        attrs[VOLTAGE_ATTRS[i]] = None
                else:
                    attrs[VOLTAGE_ATTRS[i]] = None

        # Per-phase status
        for attr_name in VOLTAGE_ATTRS[:self._phase_count]:
            v = attrs.get(attr_name)
            phase_label = attr_name.replace("voltage_", "phase_") + "_status"
            attrs[phase_label] = "on" if (v is not None and v > 50) else "off"

        return attrs

    async def async_added_to_hass(self) -> None:
        """Track voltage entities."""
        entities = []
        for key in VOLTAGE_KEYS[:self._phase_count]:
            if key in self._config:
                entities.append(self._config[key])

        if entities:
            self._unsub = async_track_state_change_event(
                self.hass, entities, self._async_voltage_changed
            )
        self._update_power_status()

    async def async_will_remove_from_hass(self) -> None:
        """Unsubscribe."""
        if self._unsub:
            self._unsub()

    @callback
    def _async_voltage_changed(self, event) -> None:
        """Handle voltage change."""
        self._update_power_status()
        self.async_write_ha_state()

    def _update_power_status(self) -> None:
        """Update power availability based on voltages."""
        self._power_available = False
        for key in VOLTAGE_KEYS[:self._phase_count]:
            entity_id = self._config.get(key)
            if entity_id:
                state = self.hass.states.get(entity_id)
                if state and state.state not in ("unknown", "unavailable"):
                    try:
                        if float(state.state) > 50:
                            self._power_available = True
                            return
                    except (ValueError, TypeError):
                        pass
