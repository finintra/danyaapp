"""Constants for the Energy Meter integration."""

DOMAIN = "energy_meter"

# Config keys
CONF_TARIFF_TYPE = "tariff_type"
CONF_PHASE_COUNT = "phase_count"
CONF_DAY_RATE = "day_rate"
CONF_NIGHT_RATE = "night_rate"
CONF_SINGLE_RATE = "single_rate"
CONF_NIGHT_START_HOUR = "night_start_hour"
CONF_NIGHT_START_MINUTE = "night_start_minute"
CONF_NIGHT_END_HOUR = "night_end_hour"
CONF_NIGHT_END_MINUTE = "night_end_minute"
CONF_INITIAL_DAY = "initial_day"
CONF_INITIAL_NIGHT = "initial_night"
CONF_INITIAL_TOTAL = "initial_total"

# Source entities from Zigbee2MQTT
CONF_ENERGY_ENTITY = "energy_entity"
CONF_VOLTAGE_A_ENTITY = "voltage_a_entity"
CONF_VOLTAGE_B_ENTITY = "voltage_b_entity"
CONF_VOLTAGE_C_ENTITY = "voltage_c_entity"
CONF_POWER_ENTITY = "power_entity"
CONF_POWER_A_ENTITY = "power_a_entity"
CONF_POWER_B_ENTITY = "power_b_entity"
CONF_POWER_C_ENTITY = "power_c_entity"
CONF_CURRENT_A_ENTITY = "current_a_entity"
CONF_CURRENT_B_ENTITY = "current_b_entity"
CONF_CURRENT_C_ENTITY = "current_c_entity"

# Tariff types
TARIFF_SINGLE = "single"
TARIFF_DUAL = "dual"

# Phase counts
PHASE_1 = "1"
PHASE_2 = "2"
PHASE_3 = "3"

# Storage
STORAGE_KEY = "energy_meter_data"
STORAGE_VERSION = 1

# Services
SERVICE_RESET_READINGS = "reset_readings"
SERVICE_SNAPSHOT = "take_snapshot"
