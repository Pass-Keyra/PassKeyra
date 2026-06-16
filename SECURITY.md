# Security Policy

PassKeyra is a password manager — security is its core function. We take vulnerability reports seriously.

## Reporting a vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Instead, email **contact@passkeyra.com** with:

- A clear description of the issue
- Steps to reproduce (proof of concept if possible)
- The version / commit hash affected
- Your assessment of the impact

You can expect:

- An acknowledgement within **72 hours**
- A first assessment within **7 days**
- A coordinated disclosure timeline agreed with you before any public communication

## Scope

In scope:

- The Flutter application code (this repository)
- Cryptographic design (key derivation, vault encryption, backup encryption)
- Cloud sync / cloud backup protocol (the application side — server-side Firebase configuration is out of scope)
- Authentication flows

Out of scope:

- Vulnerabilities in third-party services (Firebase, Google Drive, Google Play) — please report them directly to the provider
- Social engineering of PassKeyra users or the maintainer
- Physical attacks requiring access to an unlocked device
- Issues requiring a compromised OS or root/jailbreak access (these typically defeat any password manager)

## Supported versions

Only the **latest release** on Google Play is actively supported. Earlier versions may receive patches at the maintainer's discretion.

## Recognition

We're happy to credit reporters in release notes if you'd like. Let us know in your initial email how you'd like to be acknowledged (or whether you prefer to remain anonymous).
