# Security

## Client-held keys

An API key embedded in an iOS or macOS binary can be extracted. Direct
`.apiKey` mode exists for development and internal tools, not as an end-user
authentication design.

For a shipping app, use `.proxied` and a relay that:

- authenticates the app user;
- owns the OpenAI credential server-side;
- applies per-user authorization, quota, and rate limits;
- validates model, tools, and request size;
- avoids logging prompts or credentials by default.

## Endpoint policy

Direct keys may only be sent to an HTTPS URL whose exact host is
`api.openai.com`. User info in URLs is rejected.

Relay URLs may use HTTPS on any host. Plain HTTP is allowed only for localhost,
127.0.0.1, or ::1 during local development.

## Header policy

Caller-provided relay or extra headers cannot set:

- authorization or proxy authorization;
- host, cookies, content length, or transfer encoding;
- content type or user agent;
- OpenAI organization or project scope.

CR and LF characters are stripped from accepted names and values. Transport
defaults are applied again after caller headers.

## Storage and identifiers

Responses use `store: false` by default. Turning on `storeResponses` is an
explicit product decision and does not replace the app’s privacy disclosure.

Use an opaque or hashed value for `safetyIdentifier`; never send a direct email,
phone number, or payment identifier.

The demo stores chat history locally with SwiftData and credentials in
Keychain. Clearing a Keychain value and deleting local conversation history are
separate actions.

## Logging

`AuthMode` descriptions redact secret contents. `OpenAIError.sanitize` removes
API-key and bearer-token patterns from surfaced upstream text. Applications
should still avoid dumping raw requests or response headers.
