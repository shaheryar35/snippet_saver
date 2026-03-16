const EmployeeTabs = {
  mounted() {
    this.tabs = [];
    this.activeTab = null;
    this.syncFromDOM();
    this.renderTabs();

    this.handleEvent("open_employee_tab", ({ employee }) => {
      this.openTab(employee, { navigate: false });
    });

    // Intercept "Add Employee" link: open tab and tell server to load new form (navigate: true)
    this.el.addEventListener("click", (e) => {
      const addLink = e.target.closest(".add-employee-link");
      if (addLink) {
        e.preventDefault();
        this.openTab({ id: "new", name: "New Employee" }, { navigate: true });
        return;
      }
      // Intercept employee name links (table is inside LiveComponent so phx-click never reaches Index)
      const link = e.target.closest(".employee-name-link");
      if (!link) return;
      e.preventDefault();
      e.stopPropagation();
      const id = link.getAttribute("data-employee-id");
      const name = link.getAttribute("data-employee-name") || "";
      if (!id) return;
      this.openTab({ id, name }, { navigate: true });
    });
  },

  updated() {
    const self = this;
    // If user just clicked "Employee List", honour that and don't let syncFromDOM overwrite with stale DOM
    if (this.userChoseList) {
      this.userChoseList = false;
      this.activeTab = null;
      this.renderTabs();
      return;
    }
    setTimeout(function () {
      self.syncFromDOM();
      self.renderTabs();
    }, 0);
  },

  // Sync tab state from DOM (data-employee-id, data-employee-name, data-page-new)
  syncFromDOM() {
    const pageNew = this.el.getAttribute("data-page-new");
    const isNewPage = pageNew === "true" || pageNew === "1" || pageNew === true;
    if (isNewPage) {
      this.openTab({ id: "new", name: "New Employee" });
      return;
    }
    const id = this.el.getAttribute("data-employee-id");
    const name = this.el.getAttribute("data-employee-name");
    if (id != null && id !== "" && (name == null ? false : String(name).trim() !== "")) {
      this.openTab({ id: id.trim(), name: (name || "").trim() });
    } else {
      // Don't clear if "New Employee" tab is active (DOM may not have data-page-new yet after patch)
      if (this.activeTab !== "new") this.activeTab = null;
    }
  },

  openTab(employee, opts) {
    const isNew = employee.id === "new" || String(employee.id) === "new";
    const id = isNew ? "new" : Number(employee.id);
    const existing = this.tabs.find((t) => t.id === id);
    if (!existing) {
      this.tabs.push({ id, name: employee.name || "New Employee" });
    }
    this.activeTab = id;
    this.renderTabs();
    if (opts && opts.navigate) {
      this.pushEvent("navigate_to", { id: String(id) });
    }
  },

  closeTab(id, e) {
    if (e) e.stopPropagation();
    const isNew = id === "new";
    const numId = isNew ? "new" : Number(id);
    this.tabs = this.tabs.filter((t) => t.id !== numId);
    if (this.activeTab === numId) {
      this.activeTab = this.tabs.length ? this.tabs[0].id : null;
      this.pushEvent("navigate_to", { id: this.activeTab != null ? String(this.activeTab) : "list" });
    }
    this.renderTabs();
  },

  switchTab(id) {
    this.activeTab = id === "list" ? null : (id === "new" ? "new" : Number(id));
    if (id === "list") this.userChoseList = true;
    this.renderTabs();
    this.pushEvent("navigate_to", { id: id === "list" ? "list" : String(id) });
  },

  renderTabs() {
    const container = this.el.querySelector("#employee-tabs");
    if (!container) return;

    const listActive = (this.activeTab == null || this.activeTab === "list") ? "border-primary-600 text-primary-600 bg-white" : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300";
    const listBtn = `<button type="button" class="employee-tab flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 whitespace-nowrap transition-colors ${listActive}" data-id="list">
      <svg class="h-4 w-4 shrink-0" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M8.25 6.75h12M8.25 12h12m-12 5.25h12M3.75 6.75h.007v.008H3.75V6.75Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0ZM3.75 12h.007v.008H3.75V12Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm-.375 5.25h.007v.008H3.75v-.008Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z" /></svg>
      <span>Employee List</span>
    </button>`;

    const employeeTabs = this.tabs
      .map((tab) => {
        const active = (this.activeTab !== null && this.activeTab === tab.id) ? "border-primary-600 text-primary-600 bg-white" : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300";
        const name = (tab.name || "").slice(0, 20);
        return `<button type="button" class="employee-tab group flex items-center gap-2 pl-4 pr-2 py-2.5 text-sm font-medium border-b-2 whitespace-nowrap transition-colors ${active}" data-id="${tab.id}">
        <span class="max-w-[120px] truncate">${name}</span>
        <span class="close-tab ml-1 rounded p-0.5 text-gray-400 hover:bg-gray-200 hover:text-gray-600" data-id="${tab.id}" aria-label="Close tab">
          <svg class="h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
        </span>
      </button>`;
      })
      .join("");

    container.innerHTML = `<div class="mt-4 flex items-end border-b border-gray-200 bg-white"><div class="flex flex-1 overflow-x-auto" role="tablist">${listBtn}${employeeTabs}</div></div>`;

    container.querySelectorAll(".employee-tab").forEach((btn) => {
      const id = btn.getAttribute("data-id");
      if (id === "list") {
        btn.addEventListener("click", () => this.switchTab("list"));
      } else {
        btn.addEventListener("click", (e) => {
          if (e.target.closest(".close-tab")) return;
          this.switchTab(id);
        });
      }
    });

    container.querySelectorAll(".close-tab").forEach((el) => {
      el.addEventListener("click", (e) => this.closeTab(el.getAttribute("data-id"), e));
    });
  },
};

export default EmployeeTabs;
