# Security and Release Gates

## Public repository controls

- Keep proprietary application source encrypted before commit.
- Never commit plaintext proprietary source, API tokens, service credentials, private/signing keys, production configuration, user data, or payment credentials.
- Keep decryption keys and runtime credentials outside Git, in protected CI/CD or Cloudflare secret storage.
- Do not add generated APKs, installers, proprietary source maps, or build artifacts to public Git.
- CI may validate documentation, public schemas, and encrypted-file structure without decrypting source in untrusted pull-request contexts.

## Runtime trust boundary

- RSS Core is the only RSC ledger authority.
- The RSS Core service credential is server-to-server only. Never expose it to web JavaScript, Telegram Mini Apps, Android/iOS, desktop apps, public configuration, or logs.
- Verify Telegram Mini App initData on the backend with signature and freshness checks. A username, user ID field, query parameter, or client-provided player ID is not proof of identity.
- Validate RSS account sessions server-side and bind game identities to a stable RSS Core player ID.
- Apply authorization, input validation, rate limits, replay protection, and idempotency to every mutation.
- Match result verification must be independent of client-reported winner/score values.

## Runtime configuration names (not existing secrets)

- RSS_CORE_API_BASE_URL
- RSS_CORE_API_TOKEN
- RSS_CORE_REQUEST_TIMEOUT_MS
- TELEGRAM_BOT_TOKEN (only where Telegram validation requires it)

Do not create or populate these values until the owner explicitly approves the exact target environment and secret binding. Never put values in committed .env files.

## Payment boundary

- Card, local bank/online payment, mobile wallet, Google Play Billing, and Apple App Store billing remain disabled/unconfigured until separately approved and provider setup is verified.
- LKR and USD package catalogue values are configuration, not payment-provider credentials.
- Never credit a purchase from a browser redirect or client callback. Credit only after authenticated provider-side verification and idempotent server processing.
- Do not create payment accounts or provider credentials as part of game integration.

## Match economy safeguards

- Transfers are disabled by default.
- Match fees are resolved from RSS Core configuration, not client requests.
- Reserve fees before competitive play.
- No platform commission: the full reserved pool is allocated to eligible participants according to that game's approved payout rules.
- Refund every affected reserved entry for qualifying interrupted matches.
- No offline/client-only result may issue transferable RSC.
- Never enable cash-out, redemption, external trading, or blockchain movement.

## Release gates

Before enabling a game for competitive RSC:

1. RSS Core feature branch passes fresh typecheck and migration/ledger regression tests.
2. RSS Core API changes are reviewed and separately approved for production migration/deployment.
3. Game backend source is implemented in the protected/encrypted source workflow and independently validated.
4. The service credential is explicitly approved, created in the selected secret manager, and bound only to the server runtime.
5. Identity verification, account linking, authorization, and player provisioning are tested.
6. Reserve, retry, duplicate, insufficient-balance, interruption/refund, settlement, tie, and multi-winner cases pass integration tests.
7. Each game's entry fee, winner allocation, tie, disconnect, abandonment, and dispute rules are explicitly approved and disclosed.
8. Monitoring, reconciliation, rate limits, abuse controls, and audit trails are verified.
9. A preview/staging test completes without touching production balances.
10. Production migration, secret binding, and deployment each receive explicit approval before execution.

## Current blockers

- The age encryption/decryption scaffolding and non-secret round-trip CI check are present, but no proprietary source files have been encrypted and no application build pipeline is defined yet.
- The existing Liquid Flow game Worker has no RSS Core service-token binding.
- The latest RSS Core settlement implementation still requires a fresh typecheck and test run.
- Game-specific payout allocation and interruption rules have not been finalized.
- No game-side RSS COIN integration has been deployed.

A documentation commit or branch creation does not satisfy these gates and must not be represented as a live integration.
