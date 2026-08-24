// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import hooks_default from "../../deps/live_table/priv/static/live-table.js";
import EmployeeTabs from "./hooks/employee_tabs.js";
import ContactTabs from "./hooks/contact_tabs.js";
import PatientTabs from "./hooks/patient_tabs.js";
import SectionScrollSpy from "./hooks/section_scroll_spy.js";
import HearAboutOptionTabs from "./hooks/hear_about_option_tabs.js";
import VendorTabs from "./hooks/vendor_tabs.js";
import AppointmentScheduleCalendar, {
  AppointmentCalendarToolbar,
} from "./hooks/appointment_schedule_calendar.js";
/* JS only — calendar styles live in css/app.css (Tailwind) */
import CalendarHooks from "calendar_component/hooks";

const hooks = Object.assign({}, hooks_default, CalendarHooks, {
  AppointmentScheduleCalendar,
  AppointmentCalendarToolbar,
  EmployeeTabs,
  ContactTabs,
  PatientTabs,
  SectionScrollSpy,
  HearAboutOptionTabs,
  VendorTabs,
});

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// Appointments: open new-appointment drawer after server handles calendar click.
// execJS from the `phx-update="ignore"` calendar node is unreliable; the server sends
// serialized `show_drawer` JS and we run it from the LiveView root.
function execPhxDrawerJs(detail, label) {
  const js = detail && detail.js;
  const root = document.querySelector("[data-phx-session]");
  if (!js || !root || !window.liveSocket) return;
  try {
    window.liveSocket.execJS(root, js, "click");
  } catch (e) {
    console.error(`${label} execJS failed`, e);
  }
}

window.addEventListener("phx:appointment_show_new_drawer", ({ detail }) => {
  execPhxDrawerJs(detail, "appointment_show_new_drawer");
});

window.addEventListener("phx:appointment_show_view_drawer", ({ detail }) => {
  execPhxDrawerJs(detail, "appointment_show_view_drawer");
});

window.addEventListener("phx:appointment_hide_new_drawer", ({ detail }) => {
  execPhxDrawerJs(detail, "appointment_hide_new_drawer");
});

window.addEventListener("phx:appointment_hide_view_drawer", ({ detail }) => {
  execPhxDrawerJs(detail, "appointment_hide_view_drawer");
});

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
