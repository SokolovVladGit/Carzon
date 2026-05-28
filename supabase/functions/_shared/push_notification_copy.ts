/**
 * Localized FCM notification title/body for Carzon push workers.
 * Privacy-safe generic copy only — no message/listing private fields.
 */

export type PushNotificationLocale = "ru" | "ro";

export type PushNotificationCopy = {
  title: string;
  body: string;
};

const MESSAGE_COPY: Record<PushNotificationLocale, PushNotificationCopy> = {
  ru: {
    title: "Новое сообщение",
    body: "Вам написали по объявлению в Carzon.",
  },
  ro: {
    title: "Mesaj nou",
    body: "Ați primit un mesaj pentru anunțul din Carzon.",
  },
};

const FILTER_ALERT_COPY: Record<PushNotificationLocale, PushNotificationCopy> = {
  ru: {
    title: "Новое объявление",
    body:
      "Есть объявление по вашему сохранённому фильтру. Откройте, чтобы посмотреть.",
  },
  ro: {
    title: "Anunț nou",
    body:
      "Există un anunț pentru filtrul salvat. Deschideți pentru a-l vedea.",
  },
};

/** Normalizes stored push token locale; unknown/null → Russian. */
export function normalizePushLocale(
  raw: string | null | undefined,
): PushNotificationLocale {
  const tag = (raw ?? "").trim().toLowerCase();
  if (tag === "ro" || tag.startsWith("ro-")) {
    return "ro";
  }
  if (tag === "ru" || tag.startsWith("ru-")) {
    return "ru";
  }
  return "ru";
}

export function messageNotificationCopyForLocale(
  rawLocale: string | null | undefined,
): PushNotificationCopy {
  return MESSAGE_COPY[normalizePushLocale(rawLocale)];
}

export function filterAlertNotificationCopyForLocale(
  rawLocale: string | null | undefined,
): PushNotificationCopy {
  return FILTER_ALERT_COPY[normalizePushLocale(rawLocale)];
}
