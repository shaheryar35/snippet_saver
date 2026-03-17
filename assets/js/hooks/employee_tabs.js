const EmployeeTabs = {
  mounted() {
    // tabs: [{ id, name, children: [{ id, label }] }]
    this.tabs = [];
    // activePath: { parentId: number | "new" | null, subtab: string | null }
    this.activePath = { parentId: null, subtab: null };
    // Remember last active subtab per parent so switching employees restores where you left off
    this.lastSubtabByParent = {};
    this.userChoseList = false;

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
      this.activePath = { parentId: null, subtab: null };
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
      // New employee page: ensure "new" parent exists and activate its default subtab
      this.ensureParent({ id: "new", name: "New Employee" });
      this.activePath = { parentId: "new", subtab: "details" };
      this.renderTabs();
      return;
    }

    const id = this.el.getAttribute("data-employee-id");
    const name = this.el.getAttribute("data-employee-name");
    const subtabAttr = this.el.getAttribute("data-employee-subtab");

    if (id != null && id !== "" && (name == null ? false : String(name).trim() !== "")) {
      const parent = this.ensureParent({ id: id.trim(), name: (name || "").trim() });

      let subtab = "details";
      if (typeof subtabAttr === "string" && subtabAttr.length > 0) {
        const allowed = ["details", "activity", "permissions"];
        if (allowed.includes(subtabAttr)) {
          subtab = subtabAttr;
        }
      }

      this.activePath = { parentId: parent.id, subtab };
      this.lastSubtabByParent[parent.id] = subtab;
      this.renderTabs();
    } else {
      // Don't clear if "New Employee" tab is active (DOM may not have data-page-new yet after patch)
      if (this.activePath.parentId !== "new") {
        this.activePath = { parentId: null, subtab: null };
      }
    }
  },

  ensureParent(employee) {
    const isNew = employee.id === "new" || String(employee.id) === "new";
    const id = isNew ? "new" : Number(employee.id);
    let parent = this.tabs.find((t) => t.id === id);
    if (!parent) {
      parent = {
        id,
        name: employee.name || "New Employee",
        children: [
          { id: "details", label: "Details" },
          { id: "activity", label: "Activity" },
          { id: "permissions", label: "Permissions" },
        ],
      };
      this.tabs.push(parent);
    }
    if (!this.lastSubtabByParent[id]) {
      this.lastSubtabByParent[id] = "details";
    }
    return parent;
  },

  openTab(employee, opts) {
    const parent = this.ensureParent(employee);
    const defaultSubtab = "details";
    this.activePath = { parentId: parent.id, subtab: defaultSubtab };
    this.lastSubtabByParent[parent.id] = defaultSubtab;
    this.renderTabs();

    if (opts && opts.navigate) {
      const isNew = parent.id === "new";
      if (isNew) {
        this.pushEvent("navigate_to", { id: "new" });
      } else {
        this.pushEvent("navigate_to", {
          employee_id: String(parent.id),
          subtab: defaultSubtab,
        });
      }
    }
  },

  openSubtab(parentId, subtabId, opts) {
    const parent = this.tabs.find((t) => t.id === parentId);
    if (!parent) return;

    const exists = parent.children.find((c) => c.id === subtabId);
    if (!exists) {
      parent.children.push({ id: subtabId, label: subtabId });
    }

    this.activePath = { parentId, subtab: subtabId };
    this.lastSubtabByParent[parentId] = subtabId;
    this.renderTabs();

    if (opts && opts.navigate) {
      this.pushEvent("navigate_to", {
        employee_id: String(parentId),
        subtab: subtabId,
      });
    }
  },

  closeParent(parentId, e) {
    if (e) e.stopPropagation();
    this.tabs = this.tabs.filter((t) => t.id !== parentId);
    delete this.lastSubtabByParent[parentId];

    if (this.activePath.parentId === parentId) {
      // If there are still tabs, activate the first parent; otherwise go back to list.
      if (this.tabs.length > 0) {
        const next = this.tabs[0];
        const nextSubtab =
          this.lastSubtabByParent[next.id] ||
          (next.children[0] && next.children[0].id) ||
          "details";

        this.activePath = { parentId: next.id, subtab: nextSubtab };
        this.lastSubtabByParent[next.id] = nextSubtab;

        if (next.id === "new") {
          this.pushEvent("navigate_to", { id: "new" });
        } else {
          this.pushEvent("navigate_to", {
            employee_id: String(next.id),
            subtab: nextSubtab,
          });
        }
      } else {
        this.activePath = { parentId: null, subtab: null };
        this.pushEvent("navigate_to", { id: "list" });
      }
    }

    this.renderTabs();
  },

  closeSubtab(parentId, subtabId, e) {
    if (e) e.stopPropagation();
    const parent = this.tabs.find((t) => t.id === parentId);
    if (!parent) return;

    parent.children = parent.children.filter((c) => c.id !== subtabId);

    const isActive =
      this.activePath.parentId === parentId &&
      this.activePath.subtab === subtabId;

    if (parent.children.length === 0) {
      // No children left; close the parent tab entirely.
      this.closeParent(parentId);
      return;
    }

    if (isActive) {
      const next = parent.children[0];
      this.activePath = { parentId, subtab: next.id };
      this.lastSubtabByParent[parentId] = next.id;
      this.pushEvent("navigate_to", {
        employee_id: String(parentId),
        subtab: next.id,
      });
    }

    // If the closed subtab was remembered as last active, update or clear it
    if (this.lastSubtabByParent[parentId] === subtabId) {
      const fallback = parent.children[0] && parent.children[0].id;
      if (fallback) {
        this.lastSubtabByParent[parentId] = fallback;
      } else {
        delete this.lastSubtabByParent[parentId];
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

    // Prefer remembered subtab; fall back to current activePath or first child
    let nextSubtab = this.lastSubtabByParent[parentId];

    if (!nextSubtab) {
      nextSubtab =
        (this.activePath.parentId === parentId && this.activePath.subtab) ||
        (parent.children[0] && parent.children[0].id) ||
        "details";
    }

    this.activePath = { parentId, subtab: nextSubtab };
    this.lastSubtabByParent[parentId] = nextSubtab;
    this.renderTabs();

    if (parentId === "new") {
      this.pushEvent("navigate_to", { id: "new" });
    } else {
      this.pushEvent("navigate_to", {
        employee_id: String(parentId),
        subtab: nextSubtab,
      });
    }
  },

  switchToSubtab(parentId, subtabId) {
    const parent = this.tabs.find((t) => t.id === parentId);
    if (!parent) return;

    this.activePath = { parentId, subtab: subtabId };
    this.lastSubtabByParent[parentId] = subtabId;
    this.renderTabs();

    if (parentId === "new") {
      this.pushEvent("navigate_to", { id: "new" });
    } else {
      this.pushEvent("navigate_to", {
        employee_id: String(parentId),
        subtab: subtabId,
      });
    }
  },

  renderTabs() {
    const container = this.el.querySelector("#employee-tabs");
    if (!container) return;

    const isListActive = this.activePath.parentId == null;
    const listActiveClasses = isListActive
      ? "border-primary-600 text-primary-600 bg-white"
      : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300";

    const listBtn = `
      <button
        type="button"
        class="employee-tab flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 whitespace-nowrap transition-colors ${listActiveClasses}"
        data-list="true"
      >
        <svg class="h-4 w-4 shrink-0" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M8.25 6.75h12M8.25 12h12m-12 5.25h12M3.75 6.75h.007v.008H3.75V6.75Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0ZM3.75 12h.007v.008H3.75V12Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm-.375 5.25h.007v.008H3.75v-.008Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z" /></svg>
        <span>Employee List</span>
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
          <button
            type="button"
            class="employee-tab employee-parent-tab group flex items-center gap-2 pl-4 pr-2 py-2.5 text-sm font-medium border-b-2 whitespace-nowrap transition-colors ${parentClasses}"
            data-parent-id="${tab.id}"
          >
            <span class="max-w-[120px] truncate">${name}</span>
            <span class="inline-flex items-center text-xs text-gray-400 group-hover:text-gray-600">
              <svg class="h-3 w-3 ml-0.5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 10.94l3.71-3.71a.75.75 0 111.06 1.06l-4.24 4.25a.75.75 0 01-1.06 0L5.21 8.29a.75.75 0 01.02-1.08z" clip-rule="evenodd" /></svg>
            </span>
            <span
              class="close-parent-tab ml-1 rounded p-0.5 text-gray-400 hover:bg-gray-200 hover:text-gray-600"
              data-parent-id="${tab.id}"
              aria-label="Close tab"
            >
              <svg class="h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
            </span>
          </button>
        `;
      })
      .join("");

    let childRow = "";
    const activeParent =
      this.activePath.parentId != null
        ? this.tabs.find((t) => t.id === this.activePath.parentId)
        : null;

    if (activeParent && activeParent.children.length > 0) {
      const childTabs = activeParent.children
        .map((child) => {
          const isActive =
            this.activePath.parentId === activeParent.id &&
            this.activePath.subtab === child.id;
          const childClasses = isActive
            ? "border-primary-600 text-primary-600 bg-primary-50"
            : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300";

          return `
            <button
              type="button"
              class="employee-tab employee-child-tab group flex items-center gap-2 px-3 py-2 text-xs font-medium border-b-2 whitespace-nowrap transition-colors ${childClasses}"
              data-parent-id="${activeParent.id}"
              data-subtab-id="${child.id}"
            >
              <span>${child.label}</span>
              <span
                class="close-child-tab ml-1 rounded p-0.5 text-gray-400 hover:bg-gray-200 hover:text-gray-600"
                data-parent-id="${activeParent.id}"
                data-subtab-id="${child.id}"
                aria-label="Close subtab"
              >
                <svg class="h-3 w-3" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
              </span>
            </button>
          `;
        })
        .join("");

      childRow = `
        <div class="employee-tabs-child-row flex items-center gap-1 border-b border-gray-100 bg-gray-50 px-3">
          ${childTabs}
        </div>
      `;
    }

    container.innerHTML = `
      <div class="mt-4 employee-tabs-root bg-white border-b border-gray-200">
        <div class="employee-tabs-parent-row flex items-end overflow-x-auto" role="tablist">
          ${listBtn}${parentTabs}
        </div>
        ${childRow}
      </div>
    `;

    // List button
    const listButton = container.querySelector('[data-list="true"]');
    if (listButton) {
      listButton.addEventListener("click", () => this.switchToList());
    }

    // Parent tabs
    container.querySelectorAll(".employee-parent-tab").forEach((btn) => {
      const parentIdRaw = btn.getAttribute("data-parent-id");
      const parentId = parentIdRaw === "new" ? "new" : Number(parentIdRaw);

      btn.addEventListener("click", (e) => {
        if (e.target.closest(".close-parent-tab")) return;
        this.switchParent(parentId);
      });
    });

    // Close parent
    container.querySelectorAll(".close-parent-tab").forEach((el) => {
      const parentIdRaw = el.getAttribute("data-parent-id");
      const parentId = parentIdRaw === "new" ? "new" : Number(parentIdRaw);
      el.addEventListener("click", (e) => this.closeParent(parentId, e));
    });

    // Child tabs
    container.querySelectorAll(".employee-child-tab").forEach((btn) => {
      const parentIdRaw = btn.getAttribute("data-parent-id");
      const parentId = parentIdRaw === "new" ? "new" : Number(parentIdRaw);
      const subtabId = btn.getAttribute("data-subtab-id");
      btn.addEventListener("click", (e) => {
        if (e.target.closest(".close-child-tab")) return;
        this.switchToSubtab(parentId, subtabId);
      });
    });

    // Close child tabs
    container.querySelectorAll(".close-child-tab").forEach((el) => {
      const parentIdRaw = el.getAttribute("data-parent-id");
      const parentId = parentIdRaw === "new" ? "new" : Number(parentIdRaw);
      const subtabId = el.getAttribute("data-subtab-id");
      el.addEventListener("click", (e) =>
        this.closeSubtab(parentId, subtabId, e)
      );
    });
  },
};

export default EmployeeTabs;
