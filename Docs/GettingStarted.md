# Getting started

## 1. Configure Xcode

The package uses Swift 6.2 and Apple’s OS 27 Foundation Models server-side
language-model APIs.

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -version
swift --version
```

## 2. Add the local package

```swift
.package(path: "../OpenAIForFoundationModels")
```

Import both frameworks:

```swift
import FoundationModels
import OpenAIForFoundationModels
```

## 3. Create a session

For local development, read a key from environment or Keychain:

```swift
let model = OpenAILanguageModel(
  name: "gpt-5-mini",
  auth: .apiKey(apiKey)
)
let session = LanguageModelSession(
  model: model,
  instructions: "Be accurate and concise."
)

let response = try await session.respond(to: "Hello")
print(response.content)
```

For a distributed app, replace direct authentication with a relay:

```swift
let model = OpenAILanguageModel(
  name: "gpt-5-mini",
  auth: .proxied(headers: ["X-App-Token": userSessionToken]),
  baseURL: URL(string: "https://api.example.com/openai/v1")!
)
```

The relay must append `responses` and `models` under the configured base URL and
add the OpenAI credential server-side.

## 4. Stream

```swift
for try await partial in session.streamResponse(to: "Write a haiku.") {
  render(partial.content)
}
```

Cancellation propagates through the async sequence to the URLSession byte
stream.

## 5. Configure optional behavior

```swift
let model = OpenAILanguageModel(
  name: "gpt-5-mini",
  auth: .apiKey(apiKey),
  reasoning: .effort(.high),
  builtInTools: [.webSearch],
  accountScope: .init(
    organizationID: organizationID,
    projectID: projectID
  ),
  strictCapabilities: true,
  storeResponses: false,
  safetyIdentifier: hashedUserID,
  promptCacheKey: "assistant-v1"
)
```

Do not put email addresses or other direct identifiers in
`safetyIdentifier`; use a stable hash or opaque internal identifier.

## 6. Run the demo

```sh
cd Examples/DemoApp
xcodegen generate
open OpenAIDemo.xcodeproj
```

The demo accepts a development key through Keychain or a relay URL/token.
