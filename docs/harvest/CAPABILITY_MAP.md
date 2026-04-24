# Harvest Phase 2: Capability Map

This document maps the 25 identified donor repositories to target capabilities and canonical landing zones within the BMO ecosystem.

## 🗺️ Mapping Matrix

| Donor Repo | Core Capability | Canonical Target | Class | Priority |
| :--- | :--- | :--- | :--- | :--- |
| **claw-code** | Hardened MCP Lifecycle / Permission Engine | `bmo-stack/runtime/mcp-daemon` | Production | High |
| **nemoclaw** | Domain-Specific Agent Logic | `bmo-stack/skills/` | Experimental | Medium |
| **hermes-ecosystem** | Cross-Agent Orchestration | `bmo-stack/runtime/coordinator` | Production | High |
| **hermes-hudui** | HUD-style Operator Interface | `prismtek-apps/companion-ui` | Experimental | Medium |
| **hermes-webui** | Web-based Management Surface | `prismtek-apps/admin-web` | Production | Medium |
| **gbrain** | Knowledge Runtime / RRF Search / Anti-Hallucination | `bmo-stack/runtime/knowledge-runtime` | Production | Critical |
| **agentic-stack** | Generic Agent Framework Patterns | `bmo-stack/runtime/core` | Production | Medium |
| **hermes-workspace** | Advanced Context Window Management | `bmo-stack/runtime/context` | Production | High |
| **hermes-control-interface** | Unified API Bridge / Command Surface | `bmo-stack/runtime/api` | Production | Medium |
| **awesome-hermes-agent** | Meta-pattern Discovery / Plugin Index | `bmo-stack/docs/` | Docs | Low |
| **hermes-desktop** | macOS Native Automation / Bridge | `bmo-stack/runtime/bridge` | Production | High |
| **bevy** | ECS-based State Engine / Reactive Logic | `bmo-stack/runtime/state` | Experimental | Medium |
| **mcporter** | MCP Host / Transport Fallbacks | `bmo-stack/runtime/mcp-daemon` | Production | Critical |
| **hermes-paperclip-adapter** | Protocol Translation / API Adapter | `bmo-stack/runtime/api/adapters` | Production | Low |
| **hermes-agent-self-evolution** | Recursive Logic / Kernel Mutation | `bmo-stack/runtime/evolution` | Experimental | High |
| **superpowers-zh** | Localization / CJK Optimization | `bmo-stack/runtime/i18n` | Production | Low |
| **ml-intern** | ML Utility Scripts / Dataset Prep | `bmo-stack/scripts/ml` | Experimental | Low |
| **hermes-lcm** | Inference Optimization / Latency Reduction | `bmo-stack/runtime/inference` | Experimental | Medium |
| **hermes-agent-orange-book** | Reference Patterns / Implementation Guides | `bmo-stack/docs/patterns` | Docs | Medium |
| **hermes-agent** | Core Agent Logic / Baseline Implementation | `bmo-stack/runtime/core` | Production | Medium |
| **context-mode** | Prompt-based Context Switching | `bmo-stack/runtime/context` | Production | Medium |
| **learn-hermes-agent** | Agent Onboarding / Tutorial Logic | `bmo-stack/docs/onboarding` | Docs | Low |
| **agentmemory** | Memory Compression / Long-term Storage | `bmo-stack/runtime/memory` | Production | High |
| **LiteRT-LM** | Edge-Optimized Runtime / Quantization | `bmo-stack/runtime/edge` | Experimental | Medium |
| **Hermes-Wiki** | Knowledge Compilation / Wiki Generation | `bmo-stack/runtime/knowledge-runtime` | Production | High |

## 🛠️ Implementation Strategy
1. **Phase 2.1 (Infrastructure)**: Finalize MCP Hardening and Knowledge Runtime (Current).
2. **Phase 2.2 (Surface)**: Integrate HUDUI and WebUI concepts into `prismtek-apps`.
3. **Phase 2.3 (Advanced Core)**: Implement Self-Evolution and State Engine (`bevy`).
4. **Phase 2.4 (Optimization)**: Memory compression (`agentmemory`) and Inference tuning (`lcm`).

## 🛡️ Guardrails
- **Reuse First**: If a pattern exists in `bmo-stack`, optimize it. Do not replace it.
- **Wrap Second**: If a donor tool is useful but incompatible, wrap it in a BMO-compatible adapter.
- **Rewrite Last**: Only rewrite from scratch if the donor implementation is fundamentally broken or insecure.
