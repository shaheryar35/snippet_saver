const PatientTabs = {
  mounted() {
    this.tabs = [];
    this.activePath = { parentId: null, subtab: null };
    this.userChoseList = false;

    this.syncFromDOM();
    this.renderTabs();

    this.handleEvent("open_patient_tab", ({ patient }) => {
      this.openTab(patient, { navigate: false });
    });

    this.el.addEventListener("click", (e) => {
      const addLink = e.target.closest(".add-patient-link");
      if (addLink) {
        e.preventDefault();
        this.openTab({ id: "new", name: "New Patient" }, { navigate: true });
        return;
      }

      const link = e.target.closest(".patient-name-link");
      if (!link) return;
      e.preventDefault();
      e.stopPropagation();
      const id = link.getAttribute("data-patient-id");
      const name = link.getAttribute("data-patient-name") || "";
      if (!id) return;
      this.openTab({ id, name }, { navigate: true });
    });
  },

  updated() {
    if (this.userChoseList) {
      this.userChoseList = false;
      this.activePath = { parentId: null, subtab: null };
      this.renderTabs();
      return;
    }

    setTimeout(() => {
      this.syncFromDOM();
      this.renderTabs();
    }, 0);
  },

  syncFromDOM() {
    const pageNew = this.el.getAttribute("data-page-new");
    const path = window.location.pathname || "";
    const isNewPath = /^\/patients\/new\/?$/.test(path);
    const isNewPage = isNewPath || pageNew === "true" || pageNew === "1" || pageNew === true;
    if (isNewPage) {
      this.ensureParent({ id: "new", name: "New Patient" });
      this.activePath = { parentId: "new", subtab: "details" };
      this.renderTabs();
      return;
    }

    const id = this.el.getAttribute("data-patient-id");
    const name = this.el.getAttribute("data-patient-name");
    const subtabAttr = this.el.getAttribute("data-patient-subtab");

    if (id != null && id !== "" && (name == null ? false : String(name).trim() !== "")) {
      const parent = this.ensureParent({ id: id.trim(), name: (name || "").trim() });
      const subtab = subtabAttr === "details" ? "details" : "details";
      this.activePath = { parentId: parent.id, subtab };
      this.renderTabs();
    } else {
      this.activePath = { parentId: null, subtab: null };
    }
  },

  ensureParent(patient) {
    const isNew = patient.id === "new" || String(patient.id) === "new";
    const id = isNew ? "new" : Number(patient.id);

    // If we were on "New Patient" and server now opened a real patient,
    // reuse that same tab by converting it from "new" -> actual id.
    if (!isNew && this.activePath.parentId === "new") {
      const existingNew = this.tabs.find((t) => t.id === "new");
      if (existingNew) {
        const alreadyExists = this.tabs.find((t) => t.id === id);
        if (alreadyExists) {
          this.tabs = this.tabs.filter((t) => t.id !== "new");
          return alreadyExists;
        }

        existingNew.id = id;
        existingNew.name = patient.name || existingNew.name || "Patient";
        return existingNew;
      }
    }

    let parent = this.tabs.find((t) => t.id === id);
    if (!parent) {
      parent = { id, name: patient.name || "New Patient" };
      this.tabs.push(parent);
    }
    return parent;
  },

  openTab(patient, opts) {
    const parent = this.ensureParent(patient);
    this.activePath = { parentId: parent.id, subtab: "details" };
    this.renderTabs();

    if (opts && opts.navigate) {
      if (parent.id === "new") {
        this.pushEvent("navigate_to", { id: "new" });
      } else {
        this.pushEvent("navigate_to", { patient_id: String(parent.id), subtab: "details" });
      }
    }
  },

  closeParent(parentId, e) {
    if (e) e.stopPropagation();
    this.tabs = this.tabs.filter((t) => t.id !== parentId);

    if (this.activePath.parentId === parentId) {
      if (this.tabs.length > 0) {
        const next = this.tabs[0];
        this.activePath = { parentId: next.id, subtab: "details" };

        if (next.id === "new") {
          this.pushEvent("navigate_to", { id: "new" });
        } else {
          this.pushEvent("navigate_to", { patient_id: String(next.id), subtab: "details" });
        }
      } else {
        this.activePath = { parentId: null, subtab: null };
        this.pushEvent("navigate_to", { id: "list" });
      }
    }

    this.renderTabs();
  },

  switchToList() {
    this.activePath = { parentId: null, subtab: null };
    this.userChoseList = true;
    this.renderTabs();
    this.pushEvent("navigate_to", { id: "list" });
  },

  switchParent(parentId) {
    const parent = this.tabs.find((t) => t.id === parentId);
    if (!parent) return;

    this.activePath = { parentId, subtab: "details" };
    this.renderTabs();

    if (parentId === "new") {
      this.pushEvent("navigate_to", { id: "new" });
    } else {
      this.pushEvent("navigate_to", { patient_id: String(parentId), subtab: "details" });
    }
  },

  renderTabs() {
    const container = this.el.querySelector("#patient-tabs");
    if (!container) return;

    const isListActive = this.activePath.parentId == null;
    const listActiveClasses = isListActive
      ? "border-primary-600 text-primary-600 bg-white"
      : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300";

    const listBtn = `
      <button type="button" class="patient-tab flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 whitespace-nowrap transition-colors ${listActiveClasses}" data-list="true">
        <span>Patient List</span>
      </button>
    `;

    const parentTabs = this.tabs
      .map((tab) => {
        const isActive = this.activePath.parentId === tab.id;
        const parentClasses = isActive
          ? "border-primary-600 text-primary-600 bg-white"
          : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300";
        const name = (tab.name || "").slice(0, 20);

        return `
          <button type="button" class="patient-tab patient-parent-tab group flex items-center gap-2 pl-4 pr-2 py-2.5 text-sm font-medium border-b-2 whitespace-nowrap transition-colors ${parentClasses}" data-parent-id="${tab.id}">
            <span class="max-w-[120px] truncate">${name}</span>
            <span class="close-parent-tab ml-1 rounded p-0.5 text-gray-400 hover:bg-gray-200 hover:text-gray-600" data-parent-id="${tab.id}" aria-label="Close tab">
              <svg class="h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
            </span>
          </button>
        `;
      })
      .join("");

    let childRow = "";
    const activeParent = this.activePath.parentId != null ? this.tabs.find((t) => t.id === this.activePath.parentId) : null;
    if (activeParent) {
      const childClasses =
        this.activePath.subtab === "details"
          ? "border-primary-600 text-primary-600 bg-primary-50"
          : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300";

      childRow = `
        <div class="patient-tabs-child-row flex items-center gap-1 border-b border-gray-100 bg-gray-50 px-3">
          <button type="button" class="patient-tab patient-child-tab group flex items-center gap-2 px-3 py-2 text-xs font-medium border-b-2 whitespace-nowrap transition-colors ${childClasses}" data-parent-id="${activeParent.id}" data-subtab-id="details">
            <span>Details</span>
          </button>
        </div>
      `;
    }

    container.innerHTML = `
      <div class="mt-4 patient-tabs-root bg-white border-b border-gray-200">
        <div class="patient-tabs-parent-row flex items-end overflow-x-auto" role="tablist">
          ${listBtn}${parentTabs}
        </div>
        ${childRow}
      </div>
    `;

    const listButton = container.querySelector('[data-list="true"]');
    if (listButton) listButton.addEventListener("click", () => this.switchToList());

    container.querySelectorAll(".patient-parent-tab").forEach((btn) => {
      const parentIdRaw = btn.getAttribute("data-parent-id");
      const parentId = parentIdRaw === "new" ? "new" : Number(parentIdRaw);
      btn.addEventListener("click", (e) => {
        if (e.target.closest(".close-parent-tab")) return;
        this.switchParent(parentId);
      });
    });

    container.querySelectorAll(".close-parent-tab").forEach((el) => {
      const parentIdRaw = el.getAttribute("data-parent-id");
      const parentId = parentIdRaw === "new" ? "new" : Number(parentIdRaw);
      el.addEventListener("click", (e) => this.closeParent(parentId, e));
    });

    container.querySelectorAll(".patient-child-tab").forEach((btn) => {
      const parentIdRaw = btn.getAttribute("data-parent-id");
      const parentId = parentIdRaw === "new" ? "new" : Number(parentIdRaw);
      btn.addEventListener("click", () => {
        if (parentId === "new") {
          this.pushEvent("navigate_to", { id: "new" });
        } else {
          this.pushEvent("navigate_to", { patient_id: String(parentId), subtab: "details" });
        }
      });
    });
  },
};

export default PatientTabs;
