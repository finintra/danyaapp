"""Config flow for Energy Meter integration."""
from __future__ import annotations

from typing import Any

import voluptuous as vol

from homeassistant.config_entries import ConfigFlow, OptionsFlow, ConfigEntry
from homeassistant.core import callback
from homeassistant.data_entry_flow import FlowResult
from homeassistant.helpers import selector

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
    PHASE_2,
    PHASE_3,
)

SENSOR_SELECTOR = selector.EntitySelector(
    selector.EntitySelectorConfig(domain="sensor")
)


class EnergyMeterConfigFlow(ConfigFlow, domain=DOMAIN):
    """Handle a config flow for Energy Meter."""

    VERSION = 1

    def __init__(self) -> None:
        """Initialize the config flow."""
        self._data: dict[str, Any] = {}

    async def async_step_user(
        self, user_input: dict[str, Any] | None = None
    ) -> FlowResult:
        """Step 1: Choose tariff type and phase count."""
        if user_input is not None:
            self._data.update(user_input)
            return await self.async_step_entities()

        return self.async_show_form(
            step_id="user",
            data_schema=vol.Schema(
                {
                    vol.Required(CONF_TARIFF_TYPE, default=TARIFF_DUAL): selector.SelectSelector(
                        selector.SelectSelectorConfig(
                            options=[
                                selector.SelectOptionDict(value=TARIFF_SINGLE, label="single_tariff"),
                                selector.SelectOptionDict(value=TARIFF_DUAL, label="dual_tariff"),
                            ],
                            translation_key=CONF_TARIFF_TYPE,
                        )
                    ),
                    vol.Required(CONF_PHASE_COUNT, default=PHASE_3): selector.SelectSelector(
                        selector.SelectSelectorConfig(
                            options=[
                                selector.SelectOptionDict(value=PHASE_1, label="1_phase"),
                                selector.SelectOptionDict(value=PHASE_2, label="2_phases"),
                                selector.SelectOptionDict(value=PHASE_3, label="3_phases"),
                            ],
                            translation_key=CONF_PHASE_COUNT,
                        )
                    ),
                }
            ),
        )

    async def async_step_entities(
        self, user_input: dict[str, Any] | None = None
    ) -> FlowResult:
        """Step 2: Select source entities from Zigbee2MQTT."""
        if user_input is not None:
            self._data.update(user_input)
            if self._data[CONF_TARIFF_TYPE] == TARIFF_DUAL:
                return await self.async_step_dual_tariff()
            return await self.async_step_single_tariff()

        phase_count = int(self._data.get(CONF_PHASE_COUNT, 3))

        schema_dict: dict = {
            vol.Required(CONF_ENERGY_ENTITY): SENSOR_SELECTOR,
            vol.Required(CONF_POWER_ENTITY): SENSOR_SELECTOR,
            vol.Required(CONF_VOLTAGE_A_ENTITY): SENSOR_SELECTOR,
        }

        if phase_count >= 2:
            schema_dict[vol.Required(CONF_VOLTAGE_B_ENTITY)] = SENSOR_SELECTOR

        if phase_count >= 3:
            schema_dict[vol.Required(CONF_VOLTAGE_C_ENTITY)] = SENSOR_SELECTOR

        return self.async_show_form(
            step_id="entities",
            data_schema=vol.Schema(schema_dict),
        )

    async def async_step_dual_tariff(
        self, user_input: dict[str, Any] | None = None
    ) -> FlowResult:
        """Step 3a: Dual tariff rates and schedule."""
        if user_input is not None:
            self._data.update(user_input)
            return await self.async_step_initial_readings()

        return self.async_show_form(
            step_id="dual_tariff",
            data_schema=vol.Schema(
                {
                    vol.Required(CONF_DAY_RATE, default=2.64): selector.NumberSelector(
                        selector.NumberSelectorConfig(
                            min=0, max=100, step=0.01, mode="box",
                            unit_of_measurement="UAH/kWh",
                        )
                    ),
                    vol.Required(CONF_NIGHT_RATE, default=1.32): selector.NumberSelector(
                        selector.NumberSelectorConfig(
                            min=0, max=100, step=0.01, mode="box",
                            unit_of_measurement="UAH/kWh",
                        )
                    ),
                    vol.Required(CONF_NIGHT_START_HOUR, default=23): selector.NumberSelector(
                        selector.NumberSelectorConfig(
                            min=0, max=23, step=1, mode="box",
                        )
                    ),
                    vol.Required(CONF_NIGHT_START_MINUTE, default=0): selector.NumberSelector(
                        selector.NumberSelectorConfig(
                            min=0, max=59, step=1, mode="box",
                        )
                    ),
                    vol.Required(CONF_NIGHT_END_HOUR, default=7): selector.NumberSelector(
                        selector.NumberSelectorConfig(
                            min=0, max=23, step=1, mode="box",
                        )
                    ),
                    vol.Required(CONF_NIGHT_END_MINUTE, default=0): selector.NumberSelector(
                        selector.NumberSelectorConfig(
                            min=0, max=59, step=1, mode="box",
                        )
                    ),
                }
            ),
        )

    async def async_step_single_tariff(
        self, user_input: dict[str, Any] | None = None
    ) -> FlowResult:
        """Step 3b: Single tariff rate."""
        if user_input is not None:
            self._data.update(user_input)
            return await self.async_step_initial_readings()

        return self.async_show_form(
            step_id="single_tariff",
            data_schema=vol.Schema(
                {
                    vol.Required(CONF_SINGLE_RATE, default=2.64): selector.NumberSelector(
                        selector.NumberSelectorConfig(
                            min=0, max=100, step=0.01, mode="box",
                            unit_of_measurement="UAH/kWh",
                        )
                    ),
                }
            ),
        )

    async def async_step_initial_readings(
        self, user_input: dict[str, Any] | None = None
    ) -> FlowResult:
        """Step 4: Initial meter readings."""
        if user_input is not None:
            self._data.update(user_input)
            phase_count = self._data.get(CONF_PHASE_COUNT, PHASE_3)
            tariff = self._data.get(CONF_TARIFF_TYPE, TARIFF_SINGLE)
            title = f"Energy Meter ({phase_count}P"
            if tariff == TARIFF_DUAL:
                title += ", Day/Night)"
            else:
                title += ")"
            return self.async_create_entry(title=title, data=self._data)

        if self._data.get(CONF_TARIFF_TYPE) == TARIFF_DUAL:
            schema = vol.Schema(
                {
                    vol.Required(CONF_INITIAL_DAY, default=0.0): selector.NumberSelector(
                        selector.NumberSelectorConfig(
                            min=0, max=999999, step=0.01, mode="box",
                            unit_of_measurement="kWh",
                        )
                    ),
                    vol.Required(CONF_INITIAL_NIGHT, default=0.0): selector.NumberSelector(
                        selector.NumberSelectorConfig(
                            min=0, max=999999, step=0.01, mode="box",
                            unit_of_measurement="kWh",
                        )
                    ),
                }
            )
        else:
            schema = vol.Schema(
                {
                    vol.Required(CONF_INITIAL_TOTAL, default=0.0): selector.NumberSelector(
                        selector.NumberSelectorConfig(
                            min=0, max=999999, step=0.01, mode="box",
                            unit_of_measurement="kWh",
                        )
                    ),
                }
            )

        return self.async_show_form(
            step_id="initial_readings",
            data_schema=schema,
        )

    @staticmethod
    @callback
    def async_get_options_flow(config_entry: ConfigEntry) -> OptionsFlow:
        """Get the options flow."""
        return EnergyMeterOptionsFlow(config_entry)


class EnergyMeterOptionsFlow(OptionsFlow):
    """Handle options flow — update tariff rates."""

    def __init__(self, config_entry: ConfigEntry) -> None:
        """Initialize."""
        self._config_entry = config_entry

    async def async_step_init(
        self, user_input: dict[str, Any] | None = None
    ) -> FlowResult:
        """Manage tariff rate options."""
        if user_input is not None:
            return self.async_create_entry(title="", data=user_input)

        data = self._config_entry.data
        tariff_type = data.get(CONF_TARIFF_TYPE, TARIFF_SINGLE)

        if tariff_type == TARIFF_DUAL:
            schema = vol.Schema(
                {
                    vol.Required(CONF_DAY_RATE, default=data.get(CONF_DAY_RATE, 2.64)): selector.NumberSelector(
                        selector.NumberSelectorConfig(
                            min=0, max=100, step=0.01, mode="box",
                            unit_of_measurement="UAH/kWh",
                        )
                    ),
                    vol.Required(CONF_NIGHT_RATE, default=data.get(CONF_NIGHT_RATE, 1.32)): selector.NumberSelector(
                        selector.NumberSelectorConfig(
                            min=0, max=100, step=0.01, mode="box",
                            unit_of_measurement="UAH/kWh",
                        )
                    ),
                }
            )
        else:
            schema = vol.Schema(
                {
                    vol.Required(CONF_SINGLE_RATE, default=data.get(CONF_SINGLE_RATE, 2.64)): selector.NumberSelector(
                        selector.NumberSelectorConfig(
                            min=0, max=100, step=0.01, mode="box",
                            unit_of_measurement="UAH/kWh",
                        )
                    ),
                }
            )

        return self.async_show_form(step_id="init", data_schema=schema)
