# OmniAPI Localization Strategy

## Overview
This document outlines the strategy for implementing OmniAPI as a fully local, trainable LLM based on the current Nemotron 3 Super model, aligned with Huntress Wizard's local-first principles.

## Goals
1. Replace external API dependencies with a fully local, controllable LLM
2. Maintain the ability to train and specialize the model for specific use cases
3. Preserve all existing local components (wake word, STT, TTS, UI, memory)
4. Enable offline operation for core reasoning capabilities
5. Provide clear version control and rollback capabilities for model updates

## Implementation Plan

### Phase 1: Foundation (Current State Assessment)
- [x] Verify current Nemotron 3 Super model is available and working
- [x] Document current model usage in BeMore-stack and PrismBot
- [x] Identify all points where the LLM is called (ollama.chat instances)
- [x] Assess hardware requirements for local model training/inference

### Phase 2: Local Model Setup
- [ ] Create local model repository in bmo-context/models/
- [ ] Download and verify Nemotron 3 Super base model locally
- [ ] Set up local inference server (could be ollama-compatible or custom)
- [ ] Verify basic chat functionality works with local model
- [ ] Document model performance characteristics (speed, memory usage, quality)

### Phase 3: Training Infrastructure
- [ ] Set up local training environment (using same base model architecture)
- [ ] Create training data pipeline from existing interactions and feedback
- [ ] Implement safety filtering for training data
- [ ] Set up model versioning system (git-lfs or DVC)
- [ ] Create training scripts that can be run locally

### Phase 4: Integration
- [ ] Create omniAPI adapter that can switch between:
    - Base Nemotron 3 Super model
    - Locally trained omniAPI variant
    - Fallback to external API (if ever needed for comparison)
- [ ] Update Huntress Wizard's local LLM strategy oversight
- [ ] Implement model switching mechanism controlled by Huntress Wizard
- [ ] Add model performance monitoring and logging
- [ ] Create rollback procedures for model updates

### Phase 5: Validation & Handoff
- [ ] Verify all existing functionality works with local model
- [ ] Test training cycle with sample data
- [ ] Document performance comparisons (base vs trained model)
- [ ] Hand off to Huntress Wizard for ongoing local LLM strategy oversight
- [ ] Create maintenance procedures for model updates

## Key Components

### Model Storage
- `/home/prismtek/bmo-context/models/nemotron-3-super-base/` - Base model
- `/home/prismtek/bmo-context/models/omniapi-v*/` - Versioned trained models
- `/home/prismtek/bmo-context/models/current/` - Symlink to active model

### Training Data
- `/home/prismtek/bmo-context/data/training/` - Curated training examples
- `/home/prismtek/bmo-context/data/validation/` - Validation set
- `/home/prismtek/bmo-context/data/feedback/` - Real-time feedback for continuous improvement

### Configuration
- Model selection controlled via environment variables or config files
- Huntress Wizard can override model selection for local-first compliance
- Clear audit trail of which model version is being used for decisions

## Success Metrics
- [ ] 100% of reasoning happens locally (no external API calls for LLM)
- [ ] Model training completes successfully on local hardware
- [ ] Trained model shows measurable improvement on target tasks
- [ ] Rollback to previous model version works reliably
- [ ] Huntress Wizard confirms local-first compliance
- [ ] Princess Bubblegum approves architectural integrity
- [ ] Finn confirms implementation readiness
- [ ] NEPTR verifies functionality before deployment

## Related Documents
- HUNTRESS_WIZARD.md - Updated council role documentation
- PRINCESS_BUBBLEGUM.md - Architecture oversight
- FINN.md - Implementation guidance
- NEPTR.md - Verification procedures
- SIMON.md - Context recovery for model strategy
- PEPPERMINT_BUTLER.md - Security considerations for model distribution

## Next Steps
1. Create the model directory structure
2. Download and verify the base Nemotron 3 Super model
3. Set up initial local inference capability
4. Create the omniAPI adapter interface
5. Begin training data collection from existing interactions