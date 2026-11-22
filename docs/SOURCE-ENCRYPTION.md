# Protecting proprietary source with age

This repository is public. Proprietary source must be encrypted before it enters Git. The repository must contain only ciphertext under `protected/`; never commit the plaintext source directory, age identity, credentials, or signing keys.

## 1. Generate and protect the encryption identity

On a trusted owner-controlled computer:

    age-keygen -o rss-source-identity.txt

Keep `rss-source-identity.txt` offline in a secure password manager or encrypted backup. Do not put it in this repository. The generated `age1...` public recipient may be shared; the `AGE-SECRET-KEY-1...` identity must remain private.

Add the complete identity file content as a GitHub Actions repository secret named:

    RSS_SOURCE_AGE_IDENTITY

Path: Repository Settings → Secrets and variables → Actions → New repository secret.

This is a manual owner action. This workflow does not create or modify GitHub secrets.

## 2. Encrypt before committing

Install age from https://age-encryption.org/ and obtain the public recipient from the age-keygen output. From a trusted machine, run:

    scripts/encrypt-source.sh /path/to/plaintext-source protected age1YOUR_PUBLIC_RECIPIENT

The script mirrors source file paths and writes each file as a `.age` ciphertext file. It refuses symlinks and refuses an output directory inside the plaintext source tree. Review the output, then commit only the encrypted files under `protected/`.

Do not commit the plaintext source, temporary copies, identity file, or decrypted build output. Remove temporary plaintext copies from shared/public workspaces after confirming the encrypted files can be decrypted on the trusted owner machine.

## 3. Manually test runner decryption

After the secret is configured and at least one encrypted file exists under `protected/`, open Actions → Decrypt protected source (manual) → Run workflow. Select `feat/rss-coin-game-integration`.

The workflow:
- Runs only when manually dispatched against this feature branch.
- Uses a GitHub-hosted ephemeral Ubuntu runner with read-only repository permission.
- Reads the identity from the protected Actions secret.
- Decrypts files only under the runner's temporary directory.
- Does not upload, cache, print, or commit decrypted source.
- Deletes the identity file and decrypted directory when the job exits.

The workflow intentionally does not build or deploy the application. This repository currently has no proprietary source package or defined build entry point. Add a reviewed build/test step only after the actual source layout and build commands are known. Never run untrusted pull-request code in a job that has access to the decryption secret.

## 4. Key rotation and access

If the identity is compromised, generate a new age identity, re-encrypt all source to the new public recipient, update the Actions secret, verify decryption, and then remove obsolete ciphertext. Restrict repository write access and Actions secret administration to trusted maintainers. A public key is not a secret; the private identity is.

## 5. Current status

- Encryption helper and manual decryption workflow are scaffolding only.
- No source files have been encrypted or added yet.
- No GitHub secret has been created or modified.
- No game build/test command is configured.
- No production resources or deployments are touched.
