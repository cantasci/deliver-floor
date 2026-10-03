# Plan

> Produced by the PM (`ecc:planner`), written to this file by Michael.

## Goal

A customer can cancel their own order from the order detail page while it is `pending`, and receives a confirmation email.

## Scope

- `POST /api/orders/:id/cancel` with the status transition `pending → cancelled`
- "Cancel order" button + confirm dialog on the order detail page
- Cancellation confirmation email through the existing mailer queue

## Out of scope

- Refunds (payments are captured at shipping, so a pending order has nothing to refund)
- Admin-side cancellation
- Partial cancellation of line items

## Acceptance criteria

- AC-1: Cancelling a `pending` order returns 200 and the order's status becomes `cancelled`.
- AC-2: Cancelling a `shipped` or `cancelled` order returns 409 with an error code; status is unchanged.
- AC-3: Another user's order returns 404 (no information leak).
- AC-4: The order page shows "Cancel order" only for `pending` orders; confirming updates the page without reload.
- AC-5: A cancellation email is enqueued exactly once per successful cancellation.

## Risks and assumptions

- Race: two cancel clicks → must be idempotent at the DB level (conditional update).
- Assumes the auth middleware already scopes orders to the current user.

## Open questions

- (answered at Gate 1) Should shipped orders show a disabled button or nothing? → nothing.
