# Feature Registry Template

Use this registry to track every feature that should land in `bmo-stack`.

| Feature | Source repo | Source path | Source license | Target module | Delivery mode | Profile(s) | Status | Notes |
|---|---|---|---|---|---|---|---|---|
| Mission Control | `PrismBot` | `apps/mission-control` | AGPL-3.0 | `apps/mission-control` | service boundary or relicensed import | `public-web`, `desktop-local` | planned | keep operator plane separate until license decision |
| Public Chat | `PrismBot` | `apps/public-chat` | AGPL-3.0 | `apps/public-chat` | service boundary or relicensed import | `public-web` | planned | pairs with PrismBot core |
| PrismBot core / Omni API | `PrismBot` | `apps/prismbot-core` | AGPL-3.0 | `services/prismbot-core` | service boundary first | `desktop-local`, `mac-host-cloud`, `public-web` | planned | highest-value integration target |
| Desktop client | `PrismBot` | `apps/prismbot-desktop` | AGPL-3.0 | `apps/desktop` | later import | `desktop-local` | planned | client after core contracts stabilize |
| Mobile client | `PrismBot` | `apps/prismbot-mobile` | AGPL-3.0 | `apps/mobile` | later import | `public-web` | planned | lower priority than mission control |
| Website | `prismtek-site` or `Prismtek.dev` | site content | unlicensed currently | `apps/website` | internal import after license added | `public-web` | blocked | add explicit license first |
| Wake word runtime | `omni-bmo` | wakeword / runtime scripts | MIT | `services/wakeword` | modular import | `pi-local`, `pi-hailo` | planned | keep hardware-specific code profiled |
| Speech-to-text | `omni-bmo` | STT flow | MIT | `services/speech-stt` | modular import | `pi-local`, `pi-hailo`, `desktop-local` | planned | define provider contract |
| Text-to-speech | `omni-bmo` | TTS flow | MIT | `services/speech-tts` | modular import | `pi-local`, `pi-hailo`, `desktop-local` | planned | define voice asset layout |
| Vision hooks | `omni-bmo` and `be-more-hailo` | camera / vision code | MIT | `services/vision` | modular import | `pi-local`, `pi-hailo` | planned | separate local vs Hailo backends |
| Hailo profile | `be-more-hailo` | core, web UI, setup | MIT | `profiles/pi-hailo` | fork + documented adaptation | `pi-hailo` | planned | preserve attribution and upstream link |
| Timers / media / game loops | `be-more-hailo` | runtime features | MIT | `services/timers-media` | modular import | `pi-hailo`, `pi-local` | planned | implement behind shared contracts |
| Council runtime | `bmo-stack` | `context/council` | no top-level repo license yet | `packages/council-runtime` | native | all | in progress | add explicit platform license first |

## Delivery mode definitions

- `native` — implemented directly in `bmo-stack`
- `modular import` — code imported with provenance preserved
- `service boundary` — integrated as separate deployable component
- `fork + documented adaptation` — maintained from an upstream fork

## Status definitions

- `planned`
- `in progress`
- `blocked`
- `done`
- `deprecated`
