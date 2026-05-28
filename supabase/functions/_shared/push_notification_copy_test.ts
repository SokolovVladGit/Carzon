import {
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  filterAlertNotificationCopyForLocale,
  messageNotificationCopyForLocale,
  normalizePushLocale,
} from "./push_notification_copy.ts";

Deno.test("normalizePushLocale supports ro and ru prefixes", () => {
  assertEquals(normalizePushLocale("ro"), "ro");
  assertEquals(normalizePushLocale("RO"), "ro");
  assertEquals(normalizePushLocale("ro-MD"), "ro");
  assertEquals(normalizePushLocale("ru"), "ru");
  assertEquals(normalizePushLocale("ru-RU"), "ru");
});

Deno.test("normalizePushLocale falls back to ru", () => {
  assertEquals(normalizePushLocale(null), "ru");
  assertEquals(normalizePushLocale(undefined), "ru");
  assertEquals(normalizePushLocale(""), "ru");
  assertEquals(normalizePushLocale("en"), "ru");
  assertEquals(normalizePushLocale("fr-FR"), "ru");
});

Deno.test("message copy by locale", () => {
  assertEquals(
    messageNotificationCopyForLocale("ru").title,
    "Новое сообщение",
  );
  assertEquals(
    messageNotificationCopyForLocale("ru").body,
    "Вам написали по объявлению в Carzon.",
  );
  assertEquals(messageNotificationCopyForLocale("ro").title, "Mesaj nou");
  assertEquals(
    messageNotificationCopyForLocale("ro").body,
    "Ați primit un mesaj pentru anunțul din Carzon.",
  );
  assertEquals(
    messageNotificationCopyForLocale(null).title,
    "Новое сообщение",
  );
});

Deno.test("filter alert copy by locale", () => {
  assertEquals(
    filterAlertNotificationCopyForLocale("ru").title,
    "Новое объявление",
  );
  assertEquals(
    filterAlertNotificationCopyForLocale("ro").title,
    "Anunț nou",
  );
  assertEquals(
    filterAlertNotificationCopyForLocale("xx").body,
    "Есть объявление по вашему сохранённому фильтру. Откройте, чтобы посмотреть.",
  );
});
