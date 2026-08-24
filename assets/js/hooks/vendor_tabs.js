const VendorTabs = {
  mounted() {
    this.tabs = [];
    this.activeId = null;
    this.userChoseList = false;

    this.syncFromDOM();
    this.renderTabs();

    this.handleEvent("open_vendor_tab", ({ vendor }) => {
      this.openTab(vendor, { navigate: false });
    });

    this.el.addEventListener("click", (e) => {
      const addLink = e.target.closest(".add-vendor-link");
      if (addLink) {
        e.preventDefault();
        this.openTab({ id: "new", name: "New Vendor" }, { navigate: true });
        return;
      }

      const link = e.target.closest(".vendor-name-link");
      if (!link) return;
      e.preventDefault();
      e.stopPropagation();
      const id = link.getAttribute("data-vendor-id");
      const name = link.getAttribute("data-vendor-name") || "";
      if (!id) return;
      this.openTab({ id, name }, { navigate: true });
    });
  },

  updated() {
    if (this.userChoseList) {
      this.userChoseList = false;
      this.activeId = null;
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
    const isNewPage = pageNew === "true" || pageNew === "1" || pageNew === true;
    if (isNewPage) {
      this.ensureTab({ id: "new", name: "New Vendor" });
      this.activeId = "new";
      this.renderTabs();
      return;
    }

    const id = this.el.getAttribute("data-vendor-id");
    if (id != null && id !== "") {
      const tab = this.ensureTab({ id: id.trim(), name: "#" + id.trim() });
      this.activeId = tab.id;
      this.renderTabs();
    } else {
      this.activeId = null;
    }
  },

  ensureTab(vendor) {
    const isNew = vendor.id === "new" || String(vendor.id) === "new";
    const id = isNew ? "new" : Number(vendor.id);
    let tab = this.tabs.find((t) => t.id === id);
    if (!tab) {
      tab = { id, name: vendor.name || "New Vendor" };
      this.tabs.push(tab);
    }
    return tab;
  },

  openTab(vendor, opts) {
    const tab = this.ensureTab(vendor);
    this.activeId = tab.id;
    this.renderTabs();

    if (opts && opts.navigate) {
      if (tab.id === "new") {
        this.pushEvent("navigate_to", { id: "new" });
      } else {
        this.pushEvent("navigate_to", { id: String(tab.id) });
      }
    }
  },

  closeTab(id, e) {
    if (e) e.stopPropagation();
    this.tabs = this.tabs.filter((t) => t.id !== id);

    if (this.activeId === id) {
      if (this.tabs.length > 0) {
        const next = this.tabs[0];
        this.activeId = next.id;
        this.pushEvent("navigate_to", { id: String(next.id) });
      } else {
        this.activeId = null;
        this.pushEvent("navigate_to", { id: "list" });
      }
    }

    this.renderTabs();
  },

  switchToList() {
    this.activeId = null;
    this.userChoseList = true;
    this.renderTabs();
    this.pushEvent("navigate_to", { id: "list" });
  },

  switchTab(id) {
    this.activeId = id;
    this.renderTabs();
    this.pushEvent("navigate_to", { id: String(id) });
  },

  renderTabs() {
    const container = this.el.querySelector("#vendor-tabs");
    if (!container) return;

    const isListActive = this.activeId == null;
    const listClasses = isListActive
      ? "border-primary-600 text-primary-600 bg-white"
      : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300";

    const listBtn = `
      <button type="button" class="vendor-tab flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 whitespace-nowrap transition-colors ${listClasses}" data-list="true">
        <span>Vendors List</span>
      </button>
    `;

    const tabs = this.tabs
      .map((tab) => {
        const isActive = this.activeId === tab.id;
        const classes = isActive
          ? "border-primary-600 text-primary-600 bg-white"
          : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300";
        const name = (tab.name || "").slice(0, 20);

        return `
          <button type="button" class="vendor-tab vendor-parent-tab group flex items-center gap-2 pl-4 pr-2 py-2.5 text-sm font-medium border-b-2 whitespace-nowrap transition-colors ${classes}" data-tab-id="${tab.id}">
            <span class="max-w-[120px] truncate">${name}</span>
            <span class="close-tab ml-1 rounded p-0.5 text-gray-400 hover:bg-gray-200 hover:text-gray-600" data-tab-id="${tab.id}" aria-label="Close tab">
              <svg class="h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
            </span>
          </button>
        `;
      })
      .join("");

    container.innerHTML = `
      <div class="mt-4 vendor-tabs-root bg-white border-b border-gray-200">
        <div class="vendor-tabs-parent-row flex items-end overflow-x-auto" role="tablist">
          ${listBtn}${tabs}
        </div>
      </div>
    `;

    const listButton = container.querySelector('[data-list="true"]');
    if (listButton) listButton.addEventListener("click", () => this.switchToList());

    container.querySelectorAll(".vendor-parent-tab").forEach((btn) => {
      const idRaw = btn.getAttribute("data-tab-id");
      const id = idRaw === "new" ? "new" : Number(idRaw);
      btn.addEventListener("click", (e) => {
        if (e.target.closest(".close-tab")) return;
        this.switchTab(id);
      });
    });

    container.querySelectorAll(".close-tab").forEach((el) => {
      const idRaw = el.getAttribute("data-tab-id");
      const id = idRaw === "new" ? "new" : Number(idRaw);
      el.addEventListener("click", (e) => this.closeTab(id, e));
    });
  },
};

export default VendorTabs;

