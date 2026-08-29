(async () => {
  const parts = location.pathname.split("/").filter(Boolean);
  const routeIndex = parts.findIndex((part) => part === "ru" || part === "ro");
  const locale = routeIndex >= 0 ? parts[routeIndex] : "ru";
  const documentKey = routeIndex >= 0 ? parts[routeIndex + 1] : "support";
  const response = await fetch("/legal/legal_content.json", { cache: "no-cache" });
  if (!response.ok) throw new Error("legal_content_unavailable");
  const data = await response.json();
  const documentData = data.locales?.[locale]?.[documentKey];
  if (!documentData) throw new Error("legal_route_not_found");

  document.documentElement.lang = locale;
  document.title = documentData.title;
  document.querySelector("h1").textContent = documentData.title;
  document.querySelector(".intro").textContent = documentData.intro;

  const nav = document.querySelector("nav");
  const labels = locale === "ro"
    ? { privacy: "Confidențialitate", terms: "Termeni", support: "Asistență", "privacy-choices": "Opțiuni" }
    : { privacy: "Конфиденциальность", terms: "Условия", support: "Поддержка", "privacy-choices": "Настройки" };
  for (const [key, label] of Object.entries(labels)) {
    const link = document.createElement("a");
    link.href = `/${locale}/${key}`;
    link.textContent = label;
    if (key === documentKey) link.setAttribute("aria-current", "page");
    nav.append(link);
  }
  const switcher = document.querySelector(".language-switch");
  const otherLocale = locale === "ru" ? "ro" : "ru";
  switcher.href = `/${otherLocale}/${documentKey}`;
  switcher.textContent = otherLocale.toUpperCase();

  const content = document.querySelector("main");
  for (const section of documentData.sections) {
    const block = document.createElement("section");
    const heading = document.createElement("h2");
    heading.textContent = section.heading;
    block.append(heading);
    for (const paragraph of section.paragraphs || []) {
      const element = document.createElement("p");
      element.textContent = paragraph;
      block.append(element);
    }
    if (section.bullets?.length) {
      const list = document.createElement("ul");
      for (const item of section.bullets) {
        const element = document.createElement("li");
        element.textContent = item;
        list.append(element);
      }
      block.append(list);
    }
    if (section.links?.length) {
      const list = document.createElement("ul");
      for (const key of section.links) {
        const item = document.createElement("li");
        const link = document.createElement("a");
        link.href = `/${locale}/${key}`;
        link.textContent = labels[key];
        item.append(link);
        list.append(item);
      }
      block.append(list);
    }
    content.append(block);
  }

  if (documentKey === "support" || documentKey === "privacy-choices") {
    const email = window.CARZON_LEGAL_CONFIG?.supportEmail?.trim();
    const contact = document.createElement("aside");
    contact.className = "contact";
    if (email) {
      const link = document.createElement("a");
      link.href = `mailto:${email}`;
      link.textContent = email;
      contact.append(link);
    } else {
      contact.textContent = "Support contact unavailable";
    }
    content.prepend(contact);
  }

  if (documentKey === "privacy" || documentKey === "terms") {
    const operatorName = window.CARZON_LEGAL_CONFIG?.operatorLegalName?.trim();
    if (!operatorName) {
      const ownerConfig = document.createElement("aside");
      ownerConfig.className = "contact";
      ownerConfig.textContent = "Operator identity unavailable";
      content.prepend(ownerConfig);
    }
  }

  document.querySelector(".version").textContent = `${locale === "ro" ? "Versiune" : "Версия"}: ${data.version}`;
})().catch(() => {
  document.querySelector("main").textContent = "Legal content is temporarily unavailable.";
});
