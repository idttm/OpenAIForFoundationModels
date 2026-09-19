#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Honor the caller's toolchain: keep a caller-supplied DEVELOPER_DIR,
# otherwise fall back to the active xcode-select developer directory.
if [[ -z "${DEVELOPER_DIR:-}" ]]; then
  DEVELOPER_DIR="$(xcode-select -p)"
  export DEVELOPER_DIR
fi

echo "Using developer directory: ${DEVELOPER_DIR}"
XCODE_INFO="$(xcodebuild -version)"
printf '%s\n' "$XCODE_INFO"
swift --version

# Require the SDK that provides server-side Foundation Models.
XCODE_VERSION="$(awk '/^Xcode / { print $2; exit }' <<< "$XCODE_INFO")"
XCODE_MAJOR="${XCODE_VERSION%%.*}"
if ! [[ "${XCODE_MAJOR:-}" =~ ^[0-9]+$ ]] || (( XCODE_MAJOR < 27 )); then
  cat >&2 <<EOF
error: release-check requires Xcode 27 or later (found: '${XCODE_VERSION:-unknown}').
Set a stable Xcode 27 toolchain, for example:
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
or:
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
EOF
  exit 1
fi

# Repo-local derived data keeps the checkout clean and avoids shared state.
DERIVED_DATA_DIR="${DERIVED_DATA_DIR:-$PWD/.derivedData/release-check}"
SWIFT_SCRATCH_PATH="${SWIFT_SCRATCH_PATH:-$PWD/.build/release-check}"
mkdir -p "${DERIVED_DATA_DIR}" "$SWIFT_SCRATCH_PATH"

./scripts/check-repository-hygiene.sh

xcrun swift format lint --recursive \
  Sources \
  Tests \
  Examples/OpenAIExample \
  Examples/DemoApp/OpenAIDemo \
  Examples/DemoApp/OpenAIDemoUITests \
  --configuration .swift-format \
  --strict

swift build --scratch-path "$SWIFT_SCRATCH_PATH" -c release
swift test --scratch-path "$SWIFT_SCRATCH_PATH"

# Do not regenerate the checked-in Xcode project here: xcodegen output may
# contain local user signing changes, so build the current project without rewriting it.
(
  cd Examples/DemoApp
  xcodebuild \
    -project OpenAIDemo.xcodeproj \
    -scheme OpenAIDemo \
    -destination 'generic/platform=iOS Simulator' \
    -configuration Debug \
    -derivedDataPath "${DERIVED_DATA_DIR}/DemoApp" \
    CODE_SIGNING_ALLOWED=NO \
    -quiet \
    build
)

echo "Release checks passed."
