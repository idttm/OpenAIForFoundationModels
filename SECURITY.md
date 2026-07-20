# Security policy

## Supported versions

Security fixes are applied to the latest tagged release and the default branch.
Pre-release tags and older `0.x` tags may require upgrading to receive a fix.

## Reporting

Report vulnerabilities privately through the repository host’s security
advisory feature: open the repository’s **Security** tab, choose
**Advisories**, and create a private report. Do not open a public issue
containing credentials, exploit details, or user data.

Include affected versions, reproduction steps, impact, and any proposed
mitigation. Do not include a real OpenAI credential. The maintainers will
acknowledge a complete report as availability permits and coordinate disclosure
after a fix is ready.

Never commit an OpenAI API key. Direct `.apiKey` authentication is intended for
local development; distributed clients should use `.proxied` with a relay that
owns the OpenAI credential. See [Docs/SECURITY.md](Docs/SECURITY.md).
