# RSS Games Hub

RSS Games Hub is the shared entry point for Razeen Secure Solution games across web and Telegram Mini Apps.

## RSS COIN

RSS COIN (RSC) is the single internal currency shared by all RSS Games. RSS Core is the authoritative wallet and double-entry ledger service. Game clients must never calculate, credit, debit, reserve, refund, or settle RSC themselves.

- [RSS COIN Game Integration](docs/RSS-COIN-GAME-INTEGRATION.md)
- [Security and Release Gates](docs/SECURITY-AND-RELEASE-GATES.md)

## Source protection

This repository is public. Proprietary application source, buildable binaries, credentials, tokens, private keys, and unencrypted environment files must not be committed. Public commits may contain documentation, non-sensitive schemas, and CI checks that do not disclose proprietary implementation. Any proprietary source published here must be encrypted before it enters Git; decryption keys must remain in protected CI secrets.

## Current release status

The integration branch is a development branch only. No production migration, secret, payment provider, or deployment is authorized by this documentation.
