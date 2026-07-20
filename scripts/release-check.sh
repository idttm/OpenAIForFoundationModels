#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -d /Applications/Xcode-beta.app ]]; then
  export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
elif [[ -d /Applications/Xcode.app ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

echo "Using developer directory: ${DEVELOPER_DIR:-$(xcode-select -p)}"
xcodebuild -version
swift --version

./scripts/check-repository-hygiene.sh

xcrun swift format lint --recursive \
  Sources \
  Tests \
  Examples/OpenAIExample \
  Examples/DemoApp/OpenAIDemo \
  Examples/DemoApp/OpenAIDemoUITests \
  --configuration .swift-format \
  --strict

swift build
swift test

(
  cd Examples/DemoApp
  xcodegen generate
  xcodebuild \
    -project OpenAIDemo.xcodeproj \
    -scheme OpenAIDemo \
    -destination 'generic/platform=iOS Simulator' \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO \
    -quiet \
    build
)

echo "Release checks passed."
