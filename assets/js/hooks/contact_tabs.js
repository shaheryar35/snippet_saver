const ContactTabs = {
  mounted() {
    this.tabs = [];
    this.activePath = { parentId: null, subtab: null };
    this.userChoseList = false;

    this.syncFromDOM();
    this.renderTabs();

    this.handleEvent("open_contact_tab", ({ contact }) => {
      this.openTab(contact, { navigate: false });
    });

    this.el.addEventListener("click", (e) => {
      const addLink = e.target.closest(".add-contact-link");
      if (addLink) {
        e.preventDefault();
        this.openTab({ id: "new", name: "New Contact" }, { navigate: true });
        return;
      }

      const link = e.target.closest(".contact-name-link");
      if (!link) return;
      e.preventDefault();
      e.stopPropagation();
      const id = link.getAttribute("data-contact-id");
      const name = link.getAttribute("data-contact-name") || "";
      if (!id) return;
      this.openTab({ id, name }, { navigate: true });
    });
  },

  updated() {
    const self = this;
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

  syncFromDOM() {
    const pageNew = this.el.getAttribute("data-page-new");
    const isNewPage = pageNew === "true" || pageNew === "1" || pageNew === true;
    if (isNewPage) {
      this.ensureParent({ id: "new", name: "New Contact" });
      this.activePath = { parentId: "new", subtab: "details" };
      this.renderTabs();
      return;
    }

    const id = this.el.getAttribute("data-contact-id");
    const name = this.el.getAttribute("data-contact-name");
    const subtabAttr = this.el.getAttribute("data-contact-subtab");

    if (id != null && id !== "" && (name == null ? false : String(name).trim() !== "")) {
      const parent = this.ensureParent({ id: id.trim(), name: (name || "").trim() });
      const subtab = subtabAttr === "details" ? "details" : "details";
      this.activePath = { parentId: parent.id, subtab };
      this.renderTabs();
    } else {
      if (this.activePath.parentId !== "new") {
        this.activePath = { parentId: null, subtab: null };
      }
    }
  },

  ensureParent(contact) {
    const isNew = contact.id === "new" || String(contact.id) === "new";
    const id = isNew ? "new" : Number(contact.id);
    let parent = this.tabs.find((t) => t.id === id);
    if (!parent) {
      parent = {
        id,
        name: contact.name || "New Contact",
      };
      this.tabs.push(parent);
    }
    return parent;
  },

  openTab(contact, opts) {
    const parent = this.ensureParent(contact);
    this.activePath = { parentId: parent.id, subtab: "details" };
    this.renderTabs();

    if (opts && opts.navigate) {
      const isNew = parent.id === "new";
      if (isNew) {
        this.pushEvent("navigate_to", { id: "new" });
      } else {
        this.pushEvent("navigate_to", { contact_id: String(parent.id), subtab: "details" });
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
          this.pushEvent("navigate_to", { contact_id: String(next.id), subtab: "details" });
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
      this.pushEvent("navigate_to", { contact_id: String(parentId), subtab: "details" });
    }
  },

  switchToSubtab(parentId, subtabId) {
    if (subtabId !== "details") return;
    this.activePath = { parentId, subtab: "details" };
    this.renderTabs();

    if (parentId === "new") {
      this.pushEvent("navigate_to", { id: "new" });
    } else {
      this.pushEvent("navigate_to", { contact_id: String(parentId), subtab: "details" });
    }
  },

  renderTabs() {
    const container = this.el.querySelector("#contact-tabs");
    if (!container) return;

    const isListActive = this.activePath.parentId == null;
    const listActiveClasses = isListActive
      ? "border-primary-600 text-primary-600 bg-white"
      : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300";

    const listBtn = `
      <button type="button" class="contact-tab flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 whitespace-nowrap transition-colors ${listActiveClasses}" data-list="true">
        <svg class="h-4 w-4 shrink-0" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M8.25 6.75h12M8.25 12h12m-12 5.25h12M3.75 6.75h.007v.008H3.75V6.75Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0ZM3.75 12h.007v.008H3.75V12Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm-.375 5.25h.007v.008H3.75v-.008Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z" /></svg>
        <span>Contact List</span>
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
          <button type="button" class="contact-tab contact-parent-tab group flex items-center gap-2 pl-4 pr-2 py-2.5 text-sm font-medium border-b-2 whitespace-nowrap transition-colors ${parentClasses}" data-parent-id="${tab.id}">
            <span class="max-w-[120px] truncate">${name}</span>
            <span class="inline-flex items-center text-xs text-gray-400 group-hover:text-gray-600">
              <svg class="h-3 w-3 ml-0.5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 10.94l3.71-3.71a.75.75 0 111.06 1.06l-4.24 4.25a.75.75 0 01-1.06 0L5.21 8.29a.75.75 0 01.02-1.08z" clip-rule="evenodd" /></svg>
            </span>
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
      const isActive = this.activePath.subtab === "details";
      const childClasses = isActive
        ? "border-primary-600 text-primary-600 bg-primary-50"
        : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300";

      childRow = `
        <div class="contact-tabs-child-row flex items-center gap-1 border-b border-gray-100 bg-gray-50 px-3">
          <button type="button" class="contact-tab contact-child-tab group flex items-center gap-2 px-3 py-2 text-xs font-medium border-b-2 whitespace-nowrap transition-colors ${childClasses}" data-parent-id="${activeParent.id}" data-subtab-id="details">
            <span>Details</span>
          </button>
        </div>
      `;
    }

    container.innerHTML = `
      <div class="mt-4 contact-tabs-root bg-white border-b border-gray-200">
        <div class="contact-tabs-parent-row flex items-end overflow-x-auto" role="tablist">
          ${listBtn}${parentTabs}
        </div>
        ${childRow}
      </div>
    `;

    const listButton = container.querySelector('[data-list="true"]');
    if (listButton) listButton.addEventListener("click", () => this.switchToList());

    container.querySelectorAll(".contact-parent-tab").forEach((btn) => {
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

    container.querySelectorAll(".contact-child-tab").forEach((btn) => {
      const parentIdRaw = btn.getAttribute("data-parent-id");
      const parentId = parentIdRaw === "new" ? "new" : Number(parentIdRaw);
      const subtabId = btn.getAttribute("data-subtab-id");
      btn.addEventListener("click", () => this.switchToSubtab(parentId, subtabId));
    });

  },
};

export default ContactTabs;
