# Maintenance

When Xcode or the OpenAI Responses API changes:

1. Verify the official Responses, streaming, function-calling, Structured
   Outputs, models, and conversation-state documentation, including refusal
   and incomplete-response semantics.
2. Update wire DTOs and semantic event decoding in `OpenAIAPI`, preserving
   terminal completion requirements and cumulative response metadata.
3. Update transcript, error, and event mapping in
   `OpenAIForFoundationModels`.
4. Add or adjust deterministic offline fixtures in Swift Testing for new
   response outcomes and public error mappings.
5. Run `./scripts/release-check.sh` with the selected stable Xcode 27+
   toolchain and review the checked-in demo project.
6. Update README, API reference, changelog, public tests/examples, and useful
   contributor documentation together.

Before a release, follow [Publishing](Publishing.md) and review all public
references, release assets, and CI logs. Keep private agent material, prompts,
harness files, audit or log material, personal paths, and secrets out of the
public set.

Do not infer OpenAI capabilities from marketing names unless the Models endpoint
or a maintained family rule supports the inference. Prefer a conservative
profile and an explicit app override.
