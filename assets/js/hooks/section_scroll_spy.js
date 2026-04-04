const ACTIVE_CLASSES = ["bg-primary-100", "text-primary-700"];
const TOP_OFFSET = 12;

const SectionScrollSpy = {
  mounted() {
    this.setup();
  },

  updated() {
    this.teardown();
    this.setup();
  },

  destroyed() {
    this.teardown();
  },

  setup() {
    this.scrollContainer = this.el.querySelector("[data-sections-scroll]");
    this.navContainer = this.el.querySelector("[data-sections-nav]");

    if (!this.scrollContainer || !this.navContainer) return;

    this.links = Array.from(this.navContainer.querySelectorAll("[data-section-link]"));
    this.sections = this.links
      .map((link) => {
        const id = link.getAttribute("data-section-link");
        const section = this.el.querySelector(`[data-section-id="${id}"]`);
        return section ? { id, link, section } : null;
      })
      .filter(Boolean);

    this.handleLinkClick = (event) => {
      const link = event.target.closest("[data-section-link]");
      if (!link) return;

      event.preventDefault();
      const id = link.getAttribute("data-section-link");
      const target = this.sections.find((entry) => entry.id === id);
      if (!target) return;

      const targetTop = this.getSectionTop(target.section);

      this.scrollContainer.scrollTo({
        top: Math.max(targetTop - TOP_OFFSET, 0),
        behavior: "smooth",
      });
      this.setActive(id);
    };

    this.handleScroll = () => this.updateActiveFromScroll();

    this.navContainer.addEventListener("click", this.handleLinkClick);
    this.scrollContainer.addEventListener("scroll", this.handleScroll);

    this.updateActiveFromScroll();
  },

  teardown() {
    if (this.navContainer && this.handleLinkClick) {
      this.navContainer.removeEventListener("click", this.handleLinkClick);
    }

    if (this.scrollContainer && this.handleScroll) {
      this.scrollContainer.removeEventListener("scroll", this.handleScroll);
    }

    this.handleLinkClick = null;
    this.handleScroll = null;
  },

  updateActiveFromScroll() {
    if (!this.sections || this.sections.length === 0) return;

    const probeLine = this.scrollContainer.scrollTop + 48;

    let active = this.sections[0];
    let minDistance = Number.POSITIVE_INFINITY;

    this.sections.forEach((entry) => {
      const sectionTop = this.getSectionTop(entry.section);
      const distance = Math.abs(sectionTop - probeLine);

      if (distance < minDistance) {
        minDistance = distance;
        active = entry;
      }
    });

    this.setActive(active.id);
  },

  getSectionTop(sectionEl) {
    const sectionRect = sectionEl.getBoundingClientRect();
    const containerRect = this.scrollContainer.getBoundingClientRect();
    return sectionRect.top - containerRect.top + this.scrollContainer.scrollTop;
  },

  setActive(id) {
    this.links.forEach((link) => {
      const linkId = link.getAttribute("data-section-link");
      const isActive = linkId === id;

      ACTIVE_CLASSES.forEach((className) => {
        if (isActive) {
          link.classList.add(className);
        } else {
          link.classList.remove(className);
        }
      });
    });
  },
};

export default SectionScrollSpy;
