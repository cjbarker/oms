# OMS — Old Man Strength

A personalized AI fitness trainer for iOS. OMS tailors daily compound-movement routines to your body, goals, limitations, available equipment, and day-to-day recovery (Apple Health sleep/HRV/heart-rate/workouts). It speaks through a coach persona you choose, can identify gym equipment from a photo, and links every exercise to a YouTube demo.

## Features

- Coach-led onboarding survey (basics, goals, training history, limitations, goals, equipment, persona, appearance, LLM backend).
- Daily routine generation, grounded in a curated exercise catalog.
- Compound-first: bodyweight when nothing available, scaled by Apple Health recovery.
- Equipment photo analysis via vision LLM — identifies what you have.
- Equipment profiles for Gym / Home / Travel; switch with one tap.
- Set-by-set logging (weight, reps, RPE) with auto rest timer (haptics + optional TTS) and a progressive-overload engine.
- Supersets, circuits, EMOM, AMRAP structures.
- In-workout "swap this exercise" when something hurts or equipment is taken.
- Coach personas: upbeat / drill sergeant / mixed.
- **Two LLM backends**:
  - **Remote**: any OpenAI-compatible or Anthropic Messages endpoint (default `https://api.anthropic.com/v1/messages`, default model `claude-sonnet-4-6`). URL + key are user-configured; key is stored in the iOS Keychain.
  - **On-device**: Google Gemma 3 E4B instruction-tuned, Q4_K_M quantized, GGUF format (≈3 GB). Downloads in the background, verified by SHA-256, runs via `llama.cpp` with Metal acceleration.
- System / Light / Dark appearance toggle.

## Requirements

- macOS 14+ with Xcode 15.4 or newer
- iOS 17+ (simulator or device)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project generation

## Build & run

```bash
brew install xcodegen
xcodegen generate
open OMS.xcodeproj
```

Select an iOS 17+ simulator and press ⌘R.

### First launch

The onboarding flow will walk you through:

1. Choosing a coach persona.
2. Basics, anthropometrics, activity level, training history, availability.
3. Primary & secondary goals, limitations, pain points, medical flags.
4. Starting equipment profile.
5. HealthKit permissions.
6. Appearance (System / Light / Dark).
7. **LLM backend selection**:
   - If **Remote**: paste your endpoint URL + API key (both editable later in Settings).
   - If **On-device**: optionally download the Gemma GGUF model over Wi-Fi.

You can skip the LLM setup and use the app in deterministic-fallback mode (it will pick a bodyweight push/pull/legs rotation from the catalog).

### On-device model (optional)

Gemma 3 E4B Q4_K_M weighs ≈3 GB. It downloads from Hugging Face by default:

```
https://huggingface.co/bartowski/google_gemma-4-E4B-it-GGUF/resolve/main/google_gemma-4-E4B-it-Q4_K_M.gguf
```

The `llama.cpp` Swift Package declared in `project.yml` is **commented out** by default so a fresh `xcodegen generate` produces a project that builds immediately. To enable the local backend:

1. Uncomment the `dependencies` block under the `OMS` target in `project.yml`.
2. Re-run `xcodegen generate`.
3. In Xcode, let SwiftPM resolve the `llama` package.
4. In `Services/LocalLLMClient.swift`, remove the `#if false` guard around the inference body.

Until the package is wired in, the app treats **On-device** mode as unavailable and prompts the user to switch to Remote.

## Command-line build & test

```bash
xcodebuild -scheme OMS \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' \
  build test
```

## Repository layout

```
OMS/
├── OMSApp.swift, ContentView.swift
├── Models/          # SwiftData @Model classes + value types
├── Services/        # LLM backends, HealthKit, Keychain, timers, progression
├── Prompts/         # Claude/Gemma prompt builders + JSON schemas
├── Views/
│   ├── Onboarding/  # Coach-led intake survey
│   ├── Today/       # Today's routine, set logger, rest timer
│   ├── Equipment/   # Inventory, profiles, photo capture
│   ├── Coach/, Profile/, Settings/
│   └── Components/  # YouTubePlayerView, cards
└── Resources/
    ├── ExerciseCatalog.json
    └── Assets.xcassets
OMSTests/             # XCTest bundle
```

## Privacy

- All profile, routine, and set-log data lives on-device (SwiftData).
- API keys are stored in the iOS Keychain.
- In Remote mode, routine inputs (profile, Health snapshot, equipment, recent workouts) are sent to the configured LLM endpoint.
- In On-device mode, nothing leaves the phone.
- A privacy dashboard in Settings shows exactly what fields are included in each LLM request.

## Not a medical device

OMS is a fitness tool. It is not medical advice. If you have injuries, post-surgery restrictions, or any condition that might interact with exercise, clear your plan with a qualified clinician first.

## License

See `LICENSE`.
