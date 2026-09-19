#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Honor an explicit toolchain or the active Xcode selection.
export DEVELOPER_DIR="${DEVELOPER_DIR:-$(xcode-select -p)}"

echo "Using: ${DEVELOPER_DIR:-$(xcode-select -p)}"
xcodebuild -version
swift --version

./scripts/check-repository-hygiene.sh
swift build
swift test
xcrun swift format lint --recursive \
  Sources \
  Tests \
  Examples/OpenAIExample \
  Examples/DemoApp/OpenAIDemo \
  Examples/DemoApp/OpenAIDemoUITests \
  --configuration .swift-format \
  --strict

echo
echo "Package and offline tests passed."
echo "Full release validation: ./scripts/release-check.sh"
echo "Demo: open Examples/DemoApp/OpenAIDemo.xcodeproj"
echo "Live CLI: OPENAI_API_KEY=… swift run OpenAIExample --model gpt-5-mini"
