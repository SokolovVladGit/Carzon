import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  MESSAGING_BLOCKED_SKIP_REASON,
  shouldApplyMessagingBlockGate,
} from "./message_notification_block_gate.ts";

Deno.test("shouldApplyMessagingBlockGate skips support conversations", () => {
  assertEquals(shouldApplyMessagingBlockGate("support"), false);
});

Deno.test("shouldApplyMessagingBlockGate applies to listing conversations", () => {
  assertEquals(shouldApplyMessagingBlockGate("listing"), true);
});

Deno.test("shouldApplyMessagingBlockGate applies when kind is unknown or missing", () => {
  assertEquals(shouldApplyMessagingBlockGate(null), true);
  assertEquals(shouldApplyMessagingBlockGate(undefined), true);
  assertEquals(shouldApplyMessagingBlockGate(""), true);
});

Deno.test("MESSAGING_BLOCKED_SKIP_REASON is stable and non-revealing", () => {
  assertEquals(MESSAGING_BLOCKED_SKIP_REASON, "messaging_blocked");
  assertEquals(MESSAGING_BLOCKED_SKIP_REASON.includes("blocker"), false);
  assertEquals(MESSAGING_BLOCKED_SKIP_REASON.includes("blocked_user"), false);
});
