/**
 * Energy Meter Card for Home Assistant
 * Displays energy readings like a Gamma 100 meter display
 */

class EnergyMeterCard extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: "open" });
  }

  setConfig(config) {
    if (!config.entity) {
      throw new Error("Please define an entity");
    }
    this._config = config;
    this._render();
  }

  set hass(hass) {
    this._hass = hass;
    this._render();
  }

  _render() {
    if (!this._hass || !this._config) return;

    const entityId = this._config.entity;
    const state = this._hass.states[entityId];
    if (!state) {
      this.shadowRoot.innerHTML = `<ha-card><div style="padding:16px">Entity not found: ${entityId}</div></ha-card>`;
      return;
    }

    const a = state.attributes;
    const tariffType = a.tariff_type || "single";
    const isDual = tariffType === "dual";
    const phaseCount = a.phase_count || 3;
    const powerAvailable = a.power_available;

    // Power status indicator
    const powerIcon = powerAvailable ? "🟢" : "🔴";
    const powerText = powerAvailable ? "Електрика є" : "Електрики немає";

    // Tariff info
    const currentTariff = a.current_tariff || "";
    const tariffIcon = currentTariff === "night" ? "🌙" : "☀️";

    // Build voltage bars
    let voltageHTML = "";
    const phaseLabels = ["A", "B", "C"];
    for (let i = 0; i < phaseCount; i++) {
      const vKey = `voltage_${phaseLabels[i].toLowerCase()}`;
      const voltage = a[vKey];
      const v = voltage !== null && voltage !== undefined ? voltage : "—";
      const phaseStatus = a[`phase_${phaseLabels[i].toLowerCase()}_status`];

      // Color: green if voltage > 200, yellow if 100-200, red if < 100 or off
      let barColor = "#4caf50";
      let barWidth = 0;
      if (voltage !== null && voltage !== undefined) {
        barWidth = Math.min((voltage / 250) * 100, 100);
        if (voltage < 100) barColor = "#f44336";
        else if (voltage < 200) barColor = "#ff9800";
      } else {
        barColor = "#9e9e9e";
      }

      voltageHTML += `
        <div class="phase-row">
          <span class="phase-label">L${i + 1}</span>
          <div class="voltage-bar-bg">
            <div class="voltage-bar" style="width:${barWidth}%;background:${barColor}"></div>
          </div>
          <span class="voltage-value">${typeof v === "number" ? v.toFixed(1) : v} V</span>
        </div>
      `;
    }

    // Readings section
    let readingsHTML = "";
    if (isDual) {
      readingsHTML = `
        <div class="readings-grid">
          <div class="reading-item">
            <div class="reading-label">☀️ День</div>
            <div class="reading-value">${(a.reading_day || 0).toFixed(2)}</div>
            <div class="reading-unit">кВт·год</div>
          </div>
          <div class="reading-item">
            <div class="reading-label">🌙 Ніч</div>
            <div class="reading-value">${(a.reading_night || 0).toFixed(2)}</div>
            <div class="reading-unit">кВт·год</div>
          </div>
          <div class="reading-item total">
            <div class="reading-label">Σ Всього</div>
            <div class="reading-value">${(a.reading_total || 0).toFixed(2)}</div>
            <div class="reading-unit">кВт·год</div>
          </div>
        </div>
      `;
    } else {
      readingsHTML = `
        <div class="readings-grid single">
          <div class="reading-item total">
            <div class="reading-label">Σ Всього</div>
            <div class="reading-value">${(a.reading_total || 0).toFixed(2)}</div>
            <div class="reading-unit">кВт·год</div>
          </div>
        </div>
      `;
    }

    // Delta section
    let deltaHTML = "";
    if (isDual) {
      deltaHTML = `
        <div class="delta-grid">
          <div class="delta-item">
            <span class="delta-label">Δ День</span>
            <span class="delta-value">+${(a.delta_day || 0).toFixed(2)} кВт·год</span>
          </div>
          <div class="delta-item">
            <span class="delta-label">Δ Ніч</span>
            <span class="delta-value">+${(a.delta_night || 0).toFixed(2)} кВт·год</span>
          </div>
          <div class="delta-item total">
            <span class="delta-label">Δ Всього</span>
            <span class="delta-value">+${(a.delta_total || 0).toFixed(2)} кВт·год</span>
          </div>
        </div>
      `;
    } else {
      deltaHTML = `
        <div class="delta-grid">
          <div class="delta-item total">
            <span class="delta-label">Δ Різниця</span>
            <span class="delta-value">+${(a.delta_total || 0).toFixed(2)} кВт·год</span>
          </div>
        </div>
      `;
    }

    // Cost section
    let costHTML = "";
    if (isDual) {
      costHTML = `
        <div class="cost-section">
          <div class="cost-row">
            <span>День (${a.day_rate || 0} грн/кВт)</span>
            <span class="cost-value">${(a.cost_day || 0).toFixed(2)} грн</span>
          </div>
          <div class="cost-row">
            <span>Ніч (${a.night_rate || 0} грн/кВт)</span>
            <span class="cost-value">${(a.cost_night || 0).toFixed(2)} грн</span>
          </div>
          <div class="cost-row total">
            <span>Всього</span>
            <span class="cost-value">${(a.cost_total || 0).toFixed(2)} грн</span>
          </div>
        </div>
      `;
    } else {
      costHTML = `
        <div class="cost-section">
          <div class="cost-row total">
            <span>Вартість (${a.single_rate || 0} грн/кВт)</span>
            <span class="cost-value">${(a.cost_total || 0).toFixed(2)} грн</span>
          </div>
        </div>
      `;
    }

    // Current power
    const power = a.power !== null && a.power !== undefined ? a.power : 0;

    // Snapshot info
    const lastSnapshot = a.last_snapshot
      ? new Date(a.last_snapshot).toLocaleString("uk-UA")
      : "—";

    this.shadowRoot.innerHTML = `
      <style>
        :host {
          --card-bg: var(--ha-card-background, var(--card-background-color, #fff));
          --text-primary: var(--primary-text-color, #212121);
          --text-secondary: var(--secondary-text-color, #727272);
          --divider: var(--divider-color, #e0e0e0);
        }
        ha-card {
          padding: 0;
          overflow: hidden;
        }
        .meter-header {
          background: linear-gradient(135deg, #1a237e, #283593);
          color: white;
          padding: 16px 20px;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        .meter-title {
          font-size: 16px;
          font-weight: 600;
          display: flex;
          align-items: center;
          gap: 8px;
        }
        .meter-model {
          font-size: 11px;
          opacity: 0.7;
        }
        .power-status {
          display: flex;
          align-items: center;
          gap: 6px;
          font-size: 13px;
          padding: 4px 10px;
          border-radius: 12px;
          background: ${powerAvailable ? "rgba(76,175,80,0.25)" : "rgba(244,67,54,0.25)"};
        }
        .power-badge {
          font-size: 10px;
        }

        .meter-display {
          background: #0d1117;
          color: #00e676;
          font-family: "Courier New", "Lucida Console", monospace;
          padding: 16px 20px;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        .lcd-total {
          font-size: 32px;
          font-weight: bold;
          letter-spacing: 2px;
        }
        .lcd-unit {
          font-size: 12px;
          color: #66bb6a;
        }
        .lcd-right {
          text-align: right;
        }
        .lcd-power {
          font-size: 18px;
          color: #ffab00;
        }
        .lcd-power-unit {
          font-size: 11px;
          color: #ff8f00;
        }
        .lcd-tariff {
          font-size: 12px;
          color: #80cbc4;
          margin-top: 4px;
        }

        .section {
          padding: 12px 20px;
          border-bottom: 1px solid var(--divider);
        }
        .section-title {
          font-size: 11px;
          text-transform: uppercase;
          color: var(--text-secondary);
          margin-bottom: 8px;
          font-weight: 600;
          letter-spacing: 0.5px;
        }

        /* Voltage bars */
        .phase-row {
          display: flex;
          align-items: center;
          gap: 8px;
          margin-bottom: 6px;
        }
        .phase-row:last-child { margin-bottom: 0; }
        .phase-label {
          font-size: 12px;
          font-weight: 600;
          color: var(--text-secondary);
          min-width: 24px;
        }
        .voltage-bar-bg {
          flex: 1;
          height: 8px;
          background: var(--divider);
          border-radius: 4px;
          overflow: hidden;
        }
        .voltage-bar {
          height: 100%;
          border-radius: 4px;
          transition: width 0.5s ease;
        }
        .voltage-value {
          font-size: 12px;
          min-width: 60px;
          text-align: right;
          font-weight: 500;
          color: var(--text-primary);
        }

        /* Readings */
        .readings-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 8px;
        }
        .readings-grid.single {
          grid-template-columns: 1fr;
        }
        .reading-item {
          background: var(--divider);
          border-radius: 8px;
          padding: 10px 12px;
          text-align: center;
        }
        .reading-item.total {
          grid-column: 1 / -1;
          background: rgba(25, 118, 210, 0.1);
        }
        .reading-label {
          font-size: 12px;
          color: var(--text-secondary);
          margin-bottom: 4px;
        }
        .reading-value {
          font-size: 20px;
          font-weight: 700;
          color: var(--text-primary);
          font-family: "Courier New", monospace;
        }
        .reading-unit {
          font-size: 10px;
          color: var(--text-secondary);
        }

        /* Delta */
        .delta-grid {
          display: flex;
          flex-direction: column;
          gap: 4px;
        }
        .delta-item {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 4px 0;
        }
        .delta-item.total {
          font-weight: 600;
        }
        .delta-label {
          font-size: 13px;
          color: var(--text-secondary);
        }
        .delta-value {
          font-size: 13px;
          color: #2e7d32;
          font-weight: 500;
        }

        /* Cost */
        .cost-section {
          display: flex;
          flex-direction: column;
          gap: 4px;
        }
        .cost-row {
          display: flex;
          justify-content: space-between;
          align-items: center;
          font-size: 13px;
          color: var(--text-secondary);
          padding: 3px 0;
        }
        .cost-row.total {
          color: var(--text-primary);
          font-weight: 600;
          font-size: 15px;
          padding-top: 6px;
          border-top: 1px solid var(--divider);
        }
        .cost-value {
          font-weight: 600;
          color: var(--text-primary);
        }
        .cost-row.total .cost-value {
          color: #e65100;
          font-size: 16px;
        }

        .footer {
          padding: 8px 20px;
          font-size: 10px;
          color: var(--text-secondary);
          text-align: right;
        }
      </style>

      <ha-card>
        <!-- Header -->
        <div class="meter-header">
          <div>
            <div class="meter-title">⚡ ${this._config.title || "Лічильник"}</div>
            <div class="meter-model">${phaseCount}-фазний${isDual ? " • 2-зонний" : ""}</div>
          </div>
          <div class="power-status">
            <span class="power-badge">${powerIcon}</span>
            ${powerText}
          </div>
        </div>

        <!-- LCD Display -->
        <div class="meter-display">
          <div>
            <div class="lcd-total">${state.state}</div>
            <div class="lcd-unit">кВт·год (всього)</div>
          </div>
          <div class="lcd-right">
            <div class="lcd-power">${power.toFixed(0)} <span class="lcd-power-unit">Вт</span></div>
            ${isDual ? `<div class="lcd-tariff">${tariffIcon} ${currentTariff === "night" ? "Нічний" : "Денний"} тариф</div>` : ""}
          </div>
        </div>

        <!-- Voltage -->
        <div class="section">
          <div class="section-title">Напруга по фазах</div>
          ${voltageHTML}
        </div>

        <!-- Readings -->
        <div class="section">
          <div class="section-title">Показання</div>
          ${readingsHTML}
        </div>

        <!-- Delta -->
        <div class="section">
          <div class="section-title">Різниця з попереднього зняття</div>
          ${deltaHTML}
        </div>

        <!-- Cost -->
        <div class="section">
          <div class="section-title">Вартість</div>
          ${costHTML}
        </div>

        <div class="footer">
          Останнє зняття: ${lastSnapshot}
        </div>
      </ha-card>
    `;
  }

  getCardSize() {
    return 6;
  }

  static getConfigElement() {
    return document.createElement("energy-meter-card-editor");
  }

  static getStubConfig() {
    return { entity: "" };
  }
}

/**
 * Card Editor
 */
class EnergyMeterCardEditor extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: "open" });
  }

  setConfig(config) {
    this._config = config;
    this._render();
  }

  set hass(hass) {
    this._hass = hass;
    this._render();
  }

  _render() {
    if (!this._hass) return;

    this.shadowRoot.innerHTML = `
      <style>
        .editor { padding: 16px; }
        .row { margin-bottom: 12px; }
        label { display: block; font-size: 12px; margin-bottom: 4px; color: var(--secondary-text-color); }
        input, select {
          width: 100%;
          padding: 8px;
          border: 1px solid var(--divider-color, #ccc);
          border-radius: 4px;
          background: var(--card-background-color, #fff);
          color: var(--primary-text-color);
          box-sizing: border-box;
        }
      </style>
      <div class="editor">
        <div class="row">
          <label>Entity (Energy Meter Total sensor)</label>
          <input type="text" id="entity" value="${this._config?.entity || ""}" />
        </div>
        <div class="row">
          <label>Title</label>
          <input type="text" id="title" value="${this._config?.title || "Лічильник"}" />
        </div>
      </div>
    `;

    this.shadowRoot.getElementById("entity").addEventListener("change", (e) => {
      this._config = { ...this._config, entity: e.target.value };
      this._fireChanged();
    });
    this.shadowRoot.getElementById("title").addEventListener("change", (e) => {
      this._config = { ...this._config, title: e.target.value };
      this._fireChanged();
    });
  }

  _fireChanged() {
    const event = new CustomEvent("config-changed", {
      detail: { config: this._config },
      bubbles: true,
      composed: true,
    });
    this.dispatchEvent(event);
  }
}

customElements.define("energy-meter-card", EnergyMeterCard);
customElements.define("energy-meter-card-editor", EnergyMeterCardEditor);

window.customCards = window.customCards || [];
window.customCards.push({
  type: "energy-meter-card",
  name: "Energy Meter Card",
  description: "Displays energy meter readings like Gamma 100",
  preview: true,
});
