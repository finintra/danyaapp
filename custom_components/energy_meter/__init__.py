"""Energy Meter integration for Home Assistant."""
from __future__ import annotations

import logging
from datetime import datetime

import voluptuous as vol

from homeassistant.config_entries import ConfigEntry
from homeassistant.core import HomeAssistant, ServiceCall
from homeassistant.helpers import config_validation as cv
from homeassistant.helpers.storage import Store

from .const import (
    DOMAIN,
    STORAGE_KEY,
    STORAGE_VERSION,
    SERVICE_RESET_READINGS,
    SERVICE_SNAPSHOT,
)

_LOGGER = logging.getLogger(__name__)

PLATFORMS = ["sensor"]


async def async_setup_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    """Set up Energy Meter from a config entry."""
    hass.data.setdefault(DOMAIN, {})

    store = Store(hass, STORAGE_VERSION, f"{STORAGE_KEY}_{entry.entry_id}")
    stored = await store.async_load() or {}

    hass.data[DOMAIN][entry.entry_id] = {
        "config": dict(entry.data),
        "store": store,
        "stored": stored,
    }

    await hass.config_entries.async_forward_entry_setups(entry, PLATFORMS)

    # Register services
    async def handle_reset(call: ServiceCall) -> None:
        """Reset readings — save current as snapshot and start new period."""
        for eid, data in hass.data[DOMAIN].items():
            stored = data["stored"]
            stored["snapshot_day"] = stored.get("reading_day", 0)
            stored["snapshot_night"] = stored.get("reading_night", 0)
            stored["snapshot_total"] = stored.get("reading_total", 0)
            stored["snapshot_time"] = datetime.now().isoformat()
            await data["store"].async_save(stored)

    async def handle_snapshot(call: ServiceCall) -> None:
        """Take a snapshot of current readings."""
        for eid, data in hass.data[DOMAIN].items():
            stored = data["stored"]
            stored["snapshot_day"] = stored.get("reading_day", 0)
            stored["snapshot_night"] = stored.get("reading_night", 0)
            stored["snapshot_total"] = stored.get("reading_total", 0)
            stored["snapshot_time"] = datetime.now().isoformat()
            await data["store"].async_save(stored)

    if not hass.services.has_service(DOMAIN, SERVICE_RESET_READINGS):
        hass.services.async_register(DOMAIN, SERVICE_RESET_READINGS, handle_reset)
        hass.services.async_register(DOMAIN, SERVICE_SNAPSHOT, handle_snapshot)

    entry.async_on_unload(entry.add_update_listener(async_update_options))

    return True


async def async_update_options(hass: HomeAssistant, entry: ConfigEntry) -> None:
    """Handle options update."""
    await hass.config_entries.async_reload(entry.entry_id)


async def async_unload_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    """Unload a config entry."""
    unload_ok = await hass.config_entries.async_unload_platforms(entry, PLATFORMS)
    if unload_ok:
        hass.data[DOMAIN].pop(entry.entry_id, None)
    return unload_ok
