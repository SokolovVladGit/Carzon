/**
 * Shared helpers for message notification delivery block suppression (M0.3 Phase B).
 *
 * Support conversations remain deliverable; listing (and unknown-kind) conversations
 * apply the bidirectional user_blocks gate at delivery time.
 */

/** `notification_delivery_events.last_error` when push is skipped due to user block. */
export const MESSAGING_BLOCKED_SKIP_REASON = "messaging_blocked";

/**
 * Whether to call `carzon_users_are_blocked` before sending a message push.
 * Support threads are exempt to match SQL enqueue/send gates.
 */
export function shouldApplyMessagingBlockGate(
  conversationKind: string | null | undefined,
): boolean {
  return conversationKind !== "support";
}
