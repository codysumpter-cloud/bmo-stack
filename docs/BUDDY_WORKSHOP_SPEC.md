# Buddy Workshop Spec

## Product concept

Buddy Workshop is the in-app library, sharing layer, and later marketplace where users can publish, share, install, and eventually sell Buddy Templates.

The marketplace object is **not** a raw live Buddy.
It is a sanitized portable Buddy Template that can be installed into another user's account and then personalized there.

## Core safety rule

Never publish live Buddy state.

Publishing must always convert a Buddy into a sanitized template draft.
This is the most important policy in the whole system.

## What a Buddy Template contains

### Required
- Buddy name
- short description
- category
- intended use case
- primary role or class
- personality profile
- voice style profile
- visual archetype
- color palette
- body style
- starter stats
- starter moves or starter skills
- growth path metadata
- recommended user type
- tags
- version number
- creator name or handle
- cover art, ASCII preview, or pixel preview

### Optional
- starter routines
- task recipes
- workflow suggestions
- challenge profile
- recommended council pairings
- public benchmark results
- sample outputs
- premium skin bundle
- premium skill bundle

### Structured metadata
Every template should also carry:
- template_id
- creator_id
- created_at
- updated_at
- template_version
- compatibility_version
- content_rating
- visibility
- price
- license_type

## What must be stripped before publishing

### Always strip
- private conversation history
- raw chat logs
- user-specific memory
- linked accounts
- documents uploaded by the creator
- email, text, and calendar contents
- private creator notes
- secret prompts containing private information
- API keys, tokens, and credentials
- hidden task history tied to the creator
- private markdown memory state
- personal identifiers unless explicitly public

### Strip by default unless creator marks it public
- training transcripts
- examples generated from real user work
- benchmark inputs
- saved workflows containing private context
- custom notes
- internal tags or annotations

### Safe to keep
- personality structure
- role or class
- skill loadout
- visual identity
- generic public starter memories
- public routines
- public sample tasks
- benchmark summaries
- performance badges
- challenge achievements
- public descriptions

## Marketplace item types

Start with a narrow item set.

### Buddy Templates
Main marketplace object for:
- starter companions
- role-based Buddies
- workflow-specific Buddies
- themed personality Buddies

### Skill Packs
Attach new capabilities or starter loadouts to compatible Buddies.

### Knowledge Packs
Curated public knowledge bundles for specific domains.
Examples:
- indie game dev pack
- ADHD planning pack
- startup ops pack
- content creator pack

### Cosmetic Packs
Skins, pixel variations, idle animation packs, and visual accents.

### Council Packs
Small themed teams of Buddies designed to work together.

## Publishing flow

### Step 1 — Create
Creator starts from:
- a Buddy they trained
- a premade template
- a new template draft

### Step 2 — Package
System converts the Buddy into a publishable template draft.

### Step 3 — Sanitize
Automatic sanitation pass removes:
- private memory
- account links
- personal documents
- unsafe hidden content
- private logs

### Step 4 — Fill listing info
Creator chooses:
- title
- short description
- category
- tags
- intended audience
- preview images
- pricing
- version notes

### Step 5 — Validation
System checks:
- metadata completeness
- broken references
- banned content
- restricted terms
- unsafe prompt patterns
- unsupported skill dependencies

### Step 6 — Review
Either:
- auto-approved if low risk
- queued for moderation if medium or high risk

### Step 7 — Publish
Template becomes one of:
- private
- unlisted
- public free
- public paid

## Creator publishing rules

### Allowed
- original Buddy templates
- productivity-focused Buddies
- creative Buddies
- workflow helpers
- business or personal planning templates
- public-domain-safe knowledge bundles
- original visual variations

### Not allowed
- stolen or copied creator content
- copyrighted character clones
- templates containing personal data
- impersonation Buddies
- misleading claims such as guaranteed income
- illegal activity workflows
- harmful instructions
- scam, fraud, or social-engineering templates
- templates designed to evade platform safety

### Restricted or manual review
- health-related Buddies
- legal or financial-heavy Buddies
- child-facing Buddies
- emotionally manipulative or dependency-driven Buddies
- public therapy Buddies
- extreme persuasion workflows

## Review and moderation flow

### Layer 1 — automated checks
- profanity and abuse scan
- private data scan
- secrets scan
- policy keyword scan
- copyrighted-character flagging
- restricted domain detection
- unsupported dependency detection

### Layer 2 — marketplace safety rules
- listing clarity
- honest labeling
- no deceptive screenshots
- no fake benchmark claims
- no hidden premium dependency traps

### Layer 3 — human review
Use for:
- flagged listings
- premium creators at launch
- disputes
- high-volume creators
- restricted categories

### User controls
Users must be able to:
- report a Buddy
- block a creator
- hide content categories
- uninstall and review purchases
- see what a Buddy Template contains before installing

## Install flow for buyers

Listing pages should show:
- Buddy name
- creator
- role or class
- personality summary
- ideal use case
- included items
- starter stats
- move or skill highlights
- screenshots or previews
- compatibility
- review score
- whether it includes premium dependencies

### On install
The app should:
- create a new local copy
- mark it as derived from the installed template
- let the user rename it
- let the user personalize it
- start clean with the buyer's own private memory

That guarantees:
- the buyer owns their version
- the creator's source Buddy stays separate
- private state does not bleed across users

## Rating and reputation

### Creator metrics
- total installs
- paid installs
- retention score
- average rating
- completion rate
- challenge score
- refund rate
- moderation strikes

### Buddy metrics
- usefulness rating
- setup ease
- visual quality
- task reliability
- benchmark category scores
- works-as-described score

### Early badges
- Verified Creator
- Great Starter Buddy
- Strong Daily Life Buddy
- Top Workflow Buddy
- Well Rated
- High Retention
- Great for Teams

## Pricing model

Keep early pricing simple.

### Free templates
Use for:
- community growth
- discovery
- starter ecosystem
- creator onboarding

### Paid templates
Recommended ranges:
- $0.99 to $2.99 for simple starter Buddies
- $3.99 to $7.99 for high-quality specialized Buddies
- $9.99 to $19.99 for premium packs, council bundles, or business workflow Buddies

## Revenue share

Best launch order:

### Phase 1
Only platform-sold content:
- official Buddies
- official packs
- premium cosmetic packs

### Phase 2
Creators can publish free templates.

### Phase 3
Creators can sell paid templates.

### Revenue split options
- 70 / 30 for fast ecosystem goodwill
- 60 / 40 if hosting and moderation cost are high
- later tiered splits for verified creators

## Licensing model

Each template should carry a clear license.

Suggested license types:
- Personal Use
- Personal + Team Use
- Commercial Internal Use
- No Resale / No Repackaging
- Remix Allowed
- Remix Not Allowed

Best default:
Personal Use, No Resale, Remix Allowed, attribution off by default unless creator opts in.

## Buddy Template schema

Use a structured object, not a giant prompt blob.

```ts
type BuddyTemplate = {
  templateId: string;
  creatorId: string;
  version: string;
  compatibilityVersion: string;

  listing: {
    title: string;
    description: string;
    category: string;
    tags: string[];
    priceCents: number;
    visibility: "private" | "unlisted" | "public_free" | "public_paid";
    contentRating: "general" | "teen" | "restricted";
  };

  buddy: {
    defaultName: string;
    class: string;
    role: string;
    personalityPrimary: string;
    personalitySecondary?: string;
    voicePrimary: string;
    voiceSecondary?: string;
    archetype: string;
    bodyStyle: string;
    palette: string;
    evolutionStage: number;
  };

  gameplay: {
    stats: Record<string, number>;
    moves: string[];
    passive?: string;
    growthPath?: string[];
  };

  utility: {
    starterSkills: string[];
    taskBiases: string[];
    recommendedUseCases: string[];
    suggestedRoutines?: string[];
  };

  assets: {
    asciiVariantId?: string;
    pixelVariantId?: string;
    coverImage?: string;
    gallery?: string[];
  };

  provenance: {
    derivedFromTemplateId?: string;
    sanitizedAt: string;
    benchmarkSummary?: Record<string, number>;
  };
};
```

## Phased rollout

### Phase 1 — Buddy Library
- official starter council
- official premium packs
- no creator publishing yet

### Phase 2 — Community sharing
- free creator templates
- private, unlisted, and public free visibility
- ratings
- moderation
- no payouts yet

### Phase 3 — Paid creator marketplace
- paid templates
- creator profiles
- payouts
- verified creators
- review system
- reports and disputes

### Phase 4 — Advanced marketplace
- council bundles
- business packs
- team templates
- seasonal drops
- creator subscriptions

## Strong launch recommendation

Launch with:
- official Council Starter Pack
- custom Buddy creation
- Buddy Workshop as a library and sharing system
- free community template publishing
- paid official packs only

Add later:
- paid creator templates
- revenue share
- creator verification
- business workflow Buddy packs

Avoid at launch:
- raw live-Buddy resale
- unsanitized exports
- internal marketplace currency
- wallets or balances
- wager-based battling
- copyrighted character marketplace items
