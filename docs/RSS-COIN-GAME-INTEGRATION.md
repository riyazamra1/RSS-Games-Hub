# RSS COIN Game Integration Contract

**Status:** implementation contract for the RSS Games Hub integration branch  
**Authority:** RSS Core owns player wallets, RSC balances, ledger entries, transaction history, and settlement.  
**Currency:** RSS COIN (RSC), shared by every RSS game.

## 1. Non-negotiable invariants

1. A single player identity maps to one RSS Core player and one shared RSC wallet across all games.
2. Browser, Android/iOS, desktop, and Telegram Mini App clients are untrusted. They never receive the RSS Core service credential.
3. Only an authenticated game backend may call RSS Core internal endpoints.
4. Game backends validate player identity and match results before requesting ledger operations.
5. Every mutation carries a stable Idempotency-Key. Retries reuse the same key and identical body.
6. Match entry fees are reserved before play. A qualifying interrupted match refunds every affected reserved entry.
7. Settlement distributes the entire reserved pool. Platform commission is 0%. RSS Core rejects payout totals that do not equal the reserved pool.
8. No game may directly update wallet balances or write ledger rows.
9. Offline/practice/AI-only play cannot create transferable RSC rewards.
10. Cash withdrawal/redemption, external trading, and blockchain transfers are out of scope.

## 2. RSS Core API contract

All internal routes require existing RSS Core backend service authorization. The service token exists only in server-side secret storage.

| Operation | Method and route | Required behavior |
|---|---|---|
| Read packages | GET /api/v1/rsc/packages?currency=LKR or USD | Public-safe catalogue; not proof of payment |
| Provision player | POST /api/v1/rsc/internal/players/provision | Only after backend identity verification |
| Read wallet | GET /api/v1/rsc/internal/wallet?player_id={id} | Authoritative available/reserved balance |
| Read history | GET /api/v1/rsc/internal/transactions?player_id={id} | Ledger-backed transaction history |
| Transfer | POST /api/v1/rsc/internal/transfers | Disabled by default; Core limits apply |
| Reserve entry | POST /api/v1/rsc/internal/matches/reserve | Reserve configured fee before match starts |
| Refund entry | POST /api/v1/rsc/internal/matches/refund | Refund qualifying interruption with reason |
| Settle match | POST /api/v1/rsc/internal/matches/settle | Verified result reference and complete allocation |

Every mutation requires Idempotency-Key. Treat timeout/connection loss as an unknown outcome and retry with the same key and identical body. Never issue a second reservation, refund, or settlement with a new key just because the first response was lost.

### Match reserve request

    {
      "match_id": "server-generated-unique-match-id",
      "player_id": "rss-core-player-id",
      "game_key": "rss-ludo",
      "match_type": "ranked"
    }

RSS Core resolves the configured fee. A client-supplied fee is never authoritative.

### Match refund request

    {
      "match_id": "server-generated-unique-match-id",
      "reason": "qualifying_interruption"
    }

Refund only when the match meets the game's documented interruption/refund rules.

### Match settlement request

    {
      "match_id": "server-generated-unique-match-id",
      "result_reference": "immutable-server-verified-result-id",
      "payouts": [
        { "player_id": "winner-player-id", "amount_rsc": 200 }
      ]
    }

The allocation above is illustrative only. Each game must define its disclosed winner/tie allocation before competitive RSC matches are enabled. The game backend computes allocation from a verified result. RSS Core validates recipients participated and payout sum equals the full reserved pool. Do not invent a universal winner split.

## 3. Required game-backend flow

1. Authenticate: validate RSS account session or Telegram Mini App initData on the server. Never trust a player ID supplied by the client.
2. Resolve identity: map verified identity to a stable RSS Core player ID. Provision idempotently if absent.
3. Display wallet: fetch authoritative wallet through the game backend. A local cached balance is never authoritative.
4. Join competitive match: validate eligibility, create the server-side match record, and reserve the configured entry fee for every entrant before play begins.
5. Play: authoritative game server records events and enforces rules. Reconnection resumes the same match and does not create a new reservation.
6. Verify result: derive outcome from server-authoritative events, apply anti-cheat checks, and persist an immutable result reference.
7. Settle: calculate the game's approved payout allocation and call Core settlement once, with deterministic match idempotency.
8. Interruptions: when documented qualifying conditions are met, refund every reserved entry.
9. Reconcile: retain match ID, result reference, Core transaction IDs, correlation IDs, and final entry states.

## 4. Identifiers and idempotency

- player_id: RSS Core player identifier resolved server-side.
- game_key: stable registered game identifier, not a display name.
- match_id: globally unique, server-generated, immutable identifier.
- result_reference: immutable reference to a persisted, verified game result.
- Reservation key: rsc:match:reserve:{match_id}:{player_id}
- Refund key: rsc:match:refund:{match_id}
- Settlement key: rsc:match:settle:{match_id}

If the deployed RSS Core contract requires a different key format, the adapter follows the exact Core contract. Never reuse an idempotency key across different payloads.

## 5. Hub-facing API boundary

The game backend may expose client-safe endpoints such as:

- GET /api/wallet — authenticated wallet summary.
- GET /api/wallet/transactions — paginated transaction history.
- GET /api/rsc/packages?currency={LKR|USD} — package catalogue only.
- POST /api/matches — create/join after server eligibility checks.
- GET /api/matches/{matchId} — match status and reconnect information.

These are proposed Hub endpoint contracts, not a claim they are already deployed. They must authenticate the user, authorize match access, validate schemas, rate-limit sensitive operations, and call RSS Core only from server-side code.

## 6. Failure handling

- Core unavailable before reservation: do not start a paid match.
- Reservation outcome uncertain: retry the same request/key; do not admit the player until confirmed.
- One entrant cannot reserve: do not start; refund any already-confirmed reservations.
- Result uncertain: keep match pending verification; never pay based on client claims.
- Settlement outcome uncertain: retry same key and identical allocation.
- Qualifying interruption: refund all reserved entries and mark interrupted.
- Duplicate events/callbacks: deduplicate by immutable event ID and idempotency key.

## 7. Audit and observability

Log request_id, game_key, match_id, player_id, operation, idempotency-key hash, Core transaction ID, result reference, and outcome. Never log bearer tokens, Telegram auth payloads, passwords, payment data, or secrets. Alert on repeated reservation failures, duplicate result attempts, settlement mismatches, refunds, and unexpected ledger/API errors.

## 8. Launch gates

Competitive RSC remains disabled until all gates in SECURITY-AND-RELEASE-GATES.md are satisfied and the relevant game's payout and interruption rules are approved.
