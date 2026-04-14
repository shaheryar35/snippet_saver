import CalendarHooks from "calendar_component/hooks";

const LiveCalendar = CalendarHooks.LiveCalendar;

function parseJsCallbacks(el) {
  try {
    return JSON.parse(el.dataset.jsCallbacks || "{}");
  } catch {
    return {};
  }
}

function pushDateClicked(view, isoDate, isoEnd) {
  if (!isoDate || !view.pushEvent) return;
  const onDateClickName =
    (() => {
      try {
        const opts = JSON.parse(view.el.dataset.options || "{}");
        return (opts.lv && opts.lv.onDateClick) || "date_clicked";
      } catch {
        return "date_clicked";
      }
    })();
  const payload =
    isoEnd && isoEnd !== isoDate ? { date: isoDate, end: isoEnd } : { date: isoDate };
  view.pushEvent(onDateClickName, payload);
}

function applyInitialViewFromOptions(view) {
  if (!view._ec) return;
  let opts;
  try {
    opts = JSON.parse(view.el.dataset.options || "{}");
  } catch {
    return;
  }
  // EventCalendar's State only reads `input.view`, not FullCalendar's `initialView`.
  // LiveCalendar sets `initialView` only; with list+dayGrid+timeGrid plugins loaded,
  // the default `view` becomes the list plugin's `listWeek` — wrong for month-first UIs.
  const v = opts.view || opts.initialView;
  if (!v) return;
  try {
    view._ec.setOption("view", v);
  } catch (_) {}
}

/**
 * Same idea as date clicks: avoid execJS on the ignored calendar subtree; the
 * server opens the view drawer via `push_event("appointment_show_view_drawer", …)`.
 */
function replaceEventClickPushOnly(view) {
  if (!view._ec || typeof view._ec.setOption !== "function" || !view.pushEvent) return;
  view._ec.setOption("eventClick", (info) => {
    let onEventClickName;
    try {
      const opts = JSON.parse(view.el.dataset.options || "{}");
      onEventClickName = (opts.lv && opts.lv.onEventClick) || "event_clicked";
    } catch {
      onEventClickName = "event_clicked";
    }
    const ev = info && info.event;
    const rawId =
      ev &&
      (ev.id != null && ev.id !== ""
        ? ev.id
        : ev.extendedProps && (ev.extendedProps.id ?? ev.extendedProps.appointment_id));
    if (rawId == null || rawId === "") return;
    view.pushEvent(onEventClickName, { id: String(rawId) });
  });
}

/**
 * LiveCalendar's default dateClick runs execJS on the hook element. Under
 * `phx-update="ignore"` that often fails to open the drawer; the server sends
 * `push_event("appointment_show_new_drawer", …)` instead. Only push here.
 */
function replaceDateClickPushOnly(view) {
  if (!view._ec || typeof view._ec.setOption !== "function" || !view.pushEvent) return;
  view._ec.setOption("dateClick", (arg) => {
    const onDateClickName = (() => {
      try {
        const opts = JSON.parse(view.el.dataset.options || "{}");
        return (opts.lv && opts.lv.onDateClick) || "date_clicked";
      } catch {
        return "date_clicked";
      }
    })();
    const date =
      arg.date && typeof arg.date.toISOString === "function"
        ? arg.date.toISOString()
        : arg.dateStr || null;
    view.pushEvent(onDateClickName, { date });
  });
}

/**
 * Ensures `--event-color` is on the DOM node for color-mix() pastel CSS (popover clones,
 * etc.). Server also sends `styles: ["--event-color: #hex"]` on each event.
 */
function applyEventColorVariable(info) {
  const el = info && info.el;
  if (!el || !el.style) return;
  const ev = info.event;
  if (!ev) return;
  const ext = ev.extendedProps || {};
  const fromExt =
    ext.calendarAccentHex != null && String(ext.calendarAccentHex).trim();
  const fromColor = ev.color != null && String(ev.color).trim();
  const raw = fromExt || fromColor || "#64748b";
  const lower = raw.toLowerCase();
  if (lower !== "transparent" && lower !== "inherit") {
    el.style.setProperty("--event-color", raw);
  }
}

function bindEventDidMount(view) {
  if (!view._ec || typeof view._ec.setOption !== "function") return;
  view._ec.setOption("eventDidMount", (info) => {
    applyEventColorVariable(info);
  });
}

function formatDate(date, opts) {
  return new Intl.DateTimeFormat(undefined, opts).format(date);
}

function monthShort(date) {
  return formatDate(date, { month: "short" }).toUpperCase();
}

function viewLabel(viewName) {
  switch (viewName) {
    case "timeGridWeek":
      return "Week view";
    case "timeGridDay":
      return "Day view";
    case "listWeek":
      return "List view";
    case "dayGridMonth":
    default:
      return "Month view";
  }
}

function rangeFor(date, view) {
  const d = new Date(date);
  if (view === "timeGridDay") return { start: d, end: d };
  if (view === "timeGridWeek" || view === "listWeek") {
    const day = d.getDay();
    const mondayShift = day === 0 ? -6 : 1 - day;
    const start = new Date(d);
    start.setDate(d.getDate() + mondayShift);
    const end = new Date(start);
    end.setDate(start.getDate() + 6);
    return { start, end };
  }
  const start = new Date(d.getFullYear(), d.getMonth(), 1);
  const end = new Date(d.getFullYear(), d.getMonth() + 1, 0);
  return { start, end };
}

function emitToolbarState(view) {
  const state = view._toolbarState || { date: new Date(), view: "dayGridMonth" };
  const { start, end } = rangeFor(state.date, state.view);
  window.dispatchEvent(
    new CustomEvent("appointment-calendar-toolbar-state", {
      detail: {
        title:
          state.view === "dayGridMonth"
            ? formatDate(state.date, { month: "long", year: "numeric" })
            : formatDate(start, { month: "long", day: "numeric", year: "numeric" }),
        range:
          state.view === "timeGridDay"
            ? formatDate(start, { month: "short", day: "numeric", year: "numeric" })
            : `${formatDate(start, { month: "short", day: "numeric", year: "numeric" })} \u2013 ${formatDate(end, { month: "short", day: "numeric", year: "numeric" })}`,
        monthShort: monthShort(state.date),
        dayNum: String(state.date.getDate()),
        view: state.view,
        viewLabel: viewLabel(state.view),
      },
    }),
  );
}

function readCalendarState(view) {
  let nextDate = view._toolbarState?.date || new Date();
  let nextView = view._toolbarState?.view || "dayGridMonth";
  if (view._ec && typeof view._ec.getOption === "function") {
    try {
      const d = view._ec.getOption("date");
      if (d) nextDate = new Date(d);
    } catch (_) {}
  }
  if (view._ec && typeof view._ec.getView === "function") {
    try {
      const v = view._ec.getView();
      if (v && v.type) nextView = v.type;
    } catch (_) {}
  }
  return { date: nextDate, view: nextView };
}

function syncToolbarFromCalendar(view) {
  view._toolbarState = readCalendarState(view);
  emitToolbarState(view);
}

function clickInternalToolbar(view, token) {
  if (!view || !view.el) return false;
  const btn = view.el.querySelector(`.ec-${token}`);
  if (!btn) return false;
  try {
    btn.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true }));
    return true;
  } catch (_) {
    return false;
  }
}

function stepDate(state, direction) {
  const date = new Date(state.date);
  const k = direction === "prev" ? -1 : 1;
  switch (state.view) {
    case "timeGridWeek":
    case "listWeek":
      date.setDate(date.getDate() + 7 * k);
      break;
    case "timeGridDay":
      date.setDate(date.getDate() + 1 * k);
      break;
    case "dayGridMonth":
    default:
      date.setMonth(date.getMonth() + 1 * k);
      break;
  }
  return date;
}

function bindToolbarControls(view) {
  if (!view._ec || view._toolbarBound) return;
  view._toolbarBound = true;
  view._toolbarState = readCalendarState(view);
  emitToolbarState(view);

  view.el.addEventListener("appointment-calendar-request-state", () => {
    syncToolbarFromCalendar(view);
  });

  view.el.addEventListener("appointment-calendar-control", (evt) => {
    const action = evt && evt.detail && evt.detail.action;
    if (!action) return;
    if (action === "goto-date" && evt.detail.value) {
      const dt = new Date(`${evt.detail.value}T00:00:00`);
      if (!Number.isNaN(dt.getTime())) {
        if (typeof view._ec.setOption === "function") {
          try {
            view._ec.setOption("date", dt);
          } catch (_) {}
        }
        syncToolbarFromCalendar(view);
      }
      return;
    }
    if (action === "view" && evt.detail.value) {
      if (!clickInternalToolbar(view, evt.detail.value)) {
        view._toolbarState = { ...view._toolbarState, view: evt.detail.value };
      }
      syncToolbarFromCalendar(view);
      return;
    }
    if (action === "today") {
      if (!clickInternalToolbar(view, "today")) {
        view._toolbarState = { ...view._toolbarState, date: new Date() };
      }
      syncToolbarFromCalendar(view);
      return;
    }
    if (action === "prev" || action === "next") {
      if (!clickInternalToolbar(view, action)) {
        view._toolbarState = {
          ...view._toolbarState,
          date: stepDate(view._toolbarState, action),
        };
      }
      syncToolbarFromCalendar(view);
    }
  });
}

function bindSelectForCreate(view) {
  if (!view._ec) return;

  view._ec.setOption("selectable", true);
  view._ec.setOption("select", (info) => {
    // Clicks are handled by dateClick; select is for drag ranges only (avoids double events).
    if (
      info.start &&
      info.end &&
      info.start.getTime() === info.end.getTime()
    ) {
      return;
    }
    const start =
      info.startStr ||
      (info.start && info.start.toISOString && info.start.toISOString());
    if (!start) return;
    const end =
      info.endStr ||
      (info.end && info.end.toISOString && info.end.toISOString());
    pushDateClicked(view, start, end);
    try {
      view._ec.unselect();
    } catch (_) {}
  });
}

export const AppointmentScheduleCalendar = {
  mounted() {
    LiveCalendar.mounted.call(this);
    applyInitialViewFromOptions(this);
    replaceDateClickPushOnly(this);
    replaceEventClickPushOnly(this);
    bindSelectForCreate(this);
    bindEventDidMount(this);
    bindToolbarControls(this);
  },

  updated() {
    if (!this._ec) return;

    const el = this.el;
    const optionsSnapshot = el.dataset.options ?? "";
    let stripped = false;

    // Re-applying `view` / `initialView` on every LiveView patch makes EventCalendar
    // re-enter month setup and can clear the grid (blank calendar) after prev/next month.
    try {
      const opts = JSON.parse(optionsSnapshot || "{}");
      if (
        Object.prototype.hasOwnProperty.call(opts, "view") ||
        Object.prototype.hasOwnProperty.call(opts, "initialView")
      ) {
        const rest = { ...opts };
        delete rest.view;
        delete rest.initialView;
        el.dataset.options = JSON.stringify(rest);
        stripped = true;
      }
    } catch (_) {}

    try {
      LiveCalendar.updated.call(this);
    } finally {
      if (stripped) el.dataset.options = optionsSnapshot;
    }

    bindSelectForCreate(this);
    replaceDateClickPushOnly(this);
    replaceEventClickPushOnly(this);
    bindEventDidMount(this);
    bindToolbarControls(this);
  },

  destroyed() {
    LiveCalendar.destroyed.call(this);
  },
};

export const AppointmentCalendarToolbar = {
  mounted() {
    this.calendarId = this.el.dataset.calendarId;
    this.resolveCalendar = () => document.getElementById(this.calendarId);
    this.titleEl = this.el.querySelector("[data-calendar-title]");
    this.rangeEl = this.el.querySelector("[data-calendar-range]");
    this.monthShortEl = this.el.querySelector("[data-calendar-month-short]");
    this.dayNumEl = this.el.querySelector("[data-calendar-day-num]");
    this.viewSelect = this.el.querySelector('[data-calendar-action="view-select"]');
    this.dateInput = this.el.querySelector('[data-calendar-action="pick-date-input"]');

    this.onToolbarState = ({ detail }) => {
      if (!detail) return;
      if (this.titleEl) this.titleEl.textContent = detail.title || "Calendar";
      if (this.rangeEl) this.rangeEl.textContent = detail.range || "";
      if (this.monthShortEl) this.monthShortEl.textContent = detail.monthShort || "---";
      if (this.dayNumEl) this.dayNumEl.textContent = detail.dayNum || "--";
      if (this.viewSelect && detail.view) this.viewSelect.value = detail.view;
    };
    window.addEventListener("appointment-calendar-toolbar-state", this.onToolbarState);
    setTimeout(() => {
      const cal = this.resolveCalendar();
      if (cal) cal.dispatchEvent(new CustomEvent("appointment-calendar-request-state"));
    }, 0);

    this.el.addEventListener("click", (e) => {
      const btn = e.target.closest("[data-calendar-action]");
      if (!btn) return;
      const action = btn.dataset.calendarAction;
      if (action === "pick-date") {
        if (this.dateInput) {
          if (typeof this.dateInput.showPicker === "function") {
            this.dateInput.showPicker();
          } else {
            this.dateInput.click();
          }
        }
        return;
      }
      if (action === "search") return;
      if (action === "view-select") return;
      const cal = this.resolveCalendar();
      if (!cal) return;
      cal.dispatchEvent(
        new CustomEvent("appointment-calendar-control", { detail: { action } }),
      );
    });

    if (this.viewSelect) {
      this.viewSelect.addEventListener("change", (e) => {
        const cal = this.resolveCalendar();
        if (!cal) return;
        cal.dispatchEvent(
          new CustomEvent("appointment-calendar-control", {
            detail: { action: "view", value: e.target.value },
          }),
        );
      });
    }
    if (this.dateInput) {
      this.dateInput.addEventListener("change", (e) => {
        const value = e.target.value;
        const cal = this.resolveCalendar();
        if (!cal || !value) return;
        cal.dispatchEvent(
          new CustomEvent("appointment-calendar-control", {
            detail: { action: "goto-date", value },
          }),
        );
      });
    }
  },

  destroyed() {
    window.removeEventListener("appointment-calendar-toolbar-state", this.onToolbarState);
  },
};

export default AppointmentScheduleCalendar;
