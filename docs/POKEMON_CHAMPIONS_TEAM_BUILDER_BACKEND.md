# Pokémon Champions Team Builder Backend Spec

## Purpose

This document defines the backend data model and scoring algorithm for the Pokémon Champions team builder app.

The backend is responsible for four things:

1. maintaining a versioned format and legality snapshot for the current Pokémon Champions regulation
2. generating legal candidate teams around zero to six user-locked Pokémon
3. scoring and ranking those teams deterministically
4. returning structured outputs that an explanation layer can turn into player-facing advice

This spec is intentionally backend-first. The team construction engine must remain deterministic and auditable. Language models may explain results, but they must not be the source of truth for legality, move lists, or final team selection.

## Product assumptions from official Pokémon Champions materials

The backend must be built around current Pokémon Champions rules rather than historical assumptions.

Official gameplay materials currently establish these durable requirements:

- Pokémon Champions supports both **Singles** and **Doubles** for Ranked, Casual/Friendly, and Private battles.
- Ranked Battles run in **seasons**, and a new **regulation** may be introduced every few seasons.
- Under the **first Ranked Battle regulation**, **Mega Evolution** is allowed.
- Pokémon may be brought in through **Pokémon HOME**, but only if they already appear in Pokémon Champions.
- A visiting Pokémon may need move retraining if it knows a move that cannot be used in Pokémon Champions.
- Training in Pokémon Champions can modify stats, Abilities, and moves.
- Pokémon can also be recruited directly inside Pokémon Champions rather than only imported.

Because regulations rotate and legal pools can change, all legality and meta logic in this backend must be keyed to a published **snapshot version**, not hardcoded globally.

## Non-goals

This spec does not define:

- client UI state
- real-time battle simulation
- a full damage calculator
- public-web scraping logic
- LLM prompting details beyond the contract boundary

## Design rules

1. **Legality is snapshot-bound.** Every build response must identify the format snapshot version used.
2. **No live web calls on the user request path.** Snapshot ingestion happens out of band.
3. **User intent matters.** The solver should preserve locked Pokémon and style preference unless a legality gate or severe score penalty requires a change.
4. **Explanations trail the solver.** The backend must emit enough reasoning metadata that an explanation layer can describe why the team was chosen.
5. **Singles and Doubles are different problems.** They share infrastructure, but not identical weights.
6. **Current data beats templates.** Curated set templates are useful priors, but the legal snapshot is authoritative.

## Backend architecture at a glance

The backend is split into five bounded subsystems:

1. **Snapshot ingestion**
   - pulls official format and roster data
   - normalizes legality into internal tables
   - stores source and confidence metadata
2. **Knowledge layer**
   - set templates
   - role tags
   - synergy annotations
   - curated matchup priors
3. **Build engine**
   - validates user inputs
   - generates candidate completions
   - scores candidates
   - chooses final team and backups
4. **Recommendation layer**
   - replacement suggestions
   - strategy objects
   - matchup and warning summaries
5. **Explanation layer**
   - consumes structured build output
   - produces readable coaching copy
   - never edits legality or set composition

## Core entities

The canonical storage can be relational. Postgres is the simplest fit.

### 1. `format_snapshot`

One row per published backend snapshot.

```sql
CREATE TABLE format_snapshot (
  id UUID PRIMARY KEY,
  snapshot_version TEXT NOT NULL UNIQUE,
  game_slug TEXT NOT NULL,                   -- e.g. 'pokemon-champions'
  format_mode TEXT NOT NULL,                 -- 'singles' | 'doubles'
  regulation_id TEXT NOT NULL,               -- e.g. 'reg_ma'
  regulation_name TEXT NOT NULL,
  source_checked_at TIMESTAMPTZ NOT NULL,
  published_at TIMESTAMPTZ NULL,
  is_current BOOLEAN NOT NULL DEFAULT FALSE,
  source_confidence TEXT NOT NULL,           -- 'official', 'official_plus_curated', 'community_weighted'
  rules_json JSONB NOT NULL,                 -- bans, caps, special mechanics, move constraints
  meta_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

#### Notes
- `rules_json` stores machine-consumed constraints.
- `meta_json` stores format descriptors such as common archetypes, common speed tiers, and top threats.
- `format_mode` is explicit so Singles and Doubles snapshots can evolve independently even within the same regulation label.

### 2. `species`

Stable Pokémon identity table.

```sql
CREATE TABLE species (
  id UUID PRIMARY KEY,
  species_id TEXT NOT NULL UNIQUE,           -- e.g. 'dragonite'
  dex_number INTEGER NULL,
  display_name TEXT NOT NULL,
  primary_type TEXT NOT NULL,
  secondary_type TEXT NULL,
  base_stats_json JSONB NOT NULL,            -- hp/atk/def/spa/spd/spe
  default_ability_ids TEXT[] NOT NULL DEFAULT '{}',
  introduced_generation INTEGER NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 3. `pokemon_form`

Separates regional forms, alternate formes, and Mega states.

```sql
CREATE TABLE pokemon_form (
  id UUID PRIMARY KEY,
  form_id TEXT NOT NULL UNIQUE,              -- e.g. 'zoroark-hisui', 'dragonite-mega'
  species_id TEXT NOT NULL REFERENCES species(species_id),
  form_kind TEXT NOT NULL,                   -- 'base' | 'regional' | 'battle' | 'mega'
  display_name TEXT NOT NULL,
  primary_type TEXT NOT NULL,
  secondary_type TEXT NULL,
  ability_ids TEXT[] NOT NULL DEFAULT '{}',
  base_stats_json JSONB NOT NULL,
  requires_item_id TEXT NULL,
  is_mega BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 4. `snapshot_legal_form`

Maps a form into a given snapshot and records the legality reason.

```sql
CREATE TABLE snapshot_legal_form (
  id UUID PRIMARY KEY,
  snapshot_version TEXT NOT NULL REFERENCES format_snapshot(snapshot_version),
  form_id TEXT NOT NULL REFERENCES pokemon_form(form_id),
  legal_status TEXT NOT NULL,                -- 'legal' | 'restricted' | 'banned' | 'unconfirmed'
  legal_reason TEXT NOT NULL,
  source_note TEXT NULL,
  UNIQUE(snapshot_version, form_id)
);
```

### 5. `move`

```sql
CREATE TABLE move (
  id UUID PRIMARY KEY,
  move_id TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  type TEXT NOT NULL,
  category TEXT NOT NULL,                    -- 'physical' | 'special' | 'status'
  power INTEGER NULL,
  accuracy INTEGER NULL,
  priority INTEGER NOT NULL DEFAULT 0,
  target_mode TEXT NULL,                     -- single/adjacent/all-foes/etc
  tags TEXT[] NOT NULL DEFAULT '{}',         -- 'pivot','spread','setup','recovery','redirection',...
  metadata_json JSONB NOT NULL DEFAULT '{}'::jsonb
);
```

### 6. `snapshot_legal_move`

```sql
CREATE TABLE snapshot_legal_move (
  id UUID PRIMARY KEY,
  snapshot_version TEXT NOT NULL REFERENCES format_snapshot(snapshot_version),
  move_id TEXT NOT NULL REFERENCES move(move_id),
  legal_status TEXT NOT NULL,
  legal_reason TEXT NOT NULL,
  UNIQUE(snapshot_version, move_id)
);
```

### 7. `item` and `snapshot_legal_item`

```sql
CREATE TABLE item (
  id UUID PRIMARY KEY,
  item_id TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  tags TEXT[] NOT NULL DEFAULT '{}',
  metadata_json JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE snapshot_legal_item (
  id UUID PRIMARY KEY,
  snapshot_version TEXT NOT NULL REFERENCES format_snapshot(snapshot_version),
  item_id TEXT NOT NULL REFERENCES item(item_id),
  legal_status TEXT NOT NULL,
  legal_reason TEXT NOT NULL,
  UNIQUE(snapshot_version, item_id)
);
```

### 8. `learnset_snapshot`

Per-snapshot move availability for each legal form.

```sql
CREATE TABLE learnset_snapshot (
  id UUID PRIMARY KEY,
  snapshot_version TEXT NOT NULL REFERENCES format_snapshot(snapshot_version),
  form_id TEXT NOT NULL REFERENCES pokemon_form(form_id),
  move_id TEXT NOT NULL REFERENCES move(move_id),
  availability_source TEXT NOT NULL,         -- 'native','training','event','unavailable'
  UNIQUE(snapshot_version, form_id, move_id)
);
```

### 9. `ability` and `snapshot_legal_ability`

```sql
CREATE TABLE ability (
  id UUID PRIMARY KEY,
  ability_id TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  tags TEXT[] NOT NULL DEFAULT '{}',
  metadata_json JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE snapshot_legal_ability (
  id UUID PRIMARY KEY,
  snapshot_version TEXT NOT NULL REFERENCES format_snapshot(snapshot_version),
  ability_id TEXT NOT NULL REFERENCES ability(ability_id),
  legal_status TEXT NOT NULL,
  legal_reason TEXT NOT NULL,
  UNIQUE(snapshot_version, ability_id)
);
```

### 10. `role_tag`

Role vocabulary used by the solver.

```sql
CREATE TABLE role_tag (
  id UUID PRIMARY KEY,
  role_id TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  format_scope TEXT NOT NULL,                -- 'shared','singles','doubles'
  description TEXT NOT NULL
);
```

#### Recommended starter roles

Shared:
- pivot
- special_breaker
- physical_breaker
- cleaner
- setup_wincon
- revenge_tool
- defensive_glue
- status_spreader
- bulky_progress
- anti_setup
- speed_control

Singles:
- hazard_setter
- hazard_removal
- wallbreaker
- emergency_priority
- stallbreaker

Doubles:
- redirector
- trick_room_setter
- trick_room_abuser
- fake_out_support
- spread_damage
- board_control
- wide_guard_user
- snarl_user
- tailwind_user
- protect_anchor

### 11. `set_template`

Curated set priors, not final truth.

```sql
CREATE TABLE set_template (
  id UUID PRIMARY KEY,
  template_key TEXT NOT NULL UNIQUE,
  snapshot_version TEXT NULL REFERENCES format_snapshot(snapshot_version),
  format_mode TEXT NOT NULL,
  form_id TEXT NOT NULL REFERENCES pokemon_form(form_id),
  ability_id TEXT NULL REFERENCES ability(ability_id),
  item_id TEXT NULL REFERENCES item(item_id),
  nature TEXT NULL,
  tera_type TEXT NULL,
  move_ids TEXT[] NOT NULL,
  ev_spread_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  role_ids TEXT[] NOT NULL DEFAULT '{}',
  archetype_tags TEXT[] NOT NULL DEFAULT '{}',
  confidence_score NUMERIC(5,2) NOT NULL DEFAULT 0.50,
  source_kind TEXT NOT NULL,                 -- 'official','curated','generated','usage-backed'
  source_note TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

#### Notes
- Snapshot-specific templates should override generic evergreen templates.
- The scorer can mutate EVs or one move slot inside bounded rules, but should not silently violate learnsets or item legality.

### 12. `meta_signal_snapshot`

Stores matchup and usage priors keyed to a snapshot.

```sql
CREATE TABLE meta_signal_snapshot (
  id UUID PRIMARY KEY,
  snapshot_version TEXT NOT NULL REFERENCES format_snapshot(snapshot_version),
  signal_type TEXT NOT NULL,                 -- 'top_threat','top_core','speed_tier','archetype','usage'
  key TEXT NOT NULL,
  value_json JSONB NOT NULL,
  confidence_score NUMERIC(5,2) NOT NULL DEFAULT 0.50,
  source_kind TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Example `value_json` shapes:
- top threat: `{ "forms": ["dragonite-mega"], "reasons": ["priority cleanup", "bulk"], "weight": 0.92 }`
- speed tier: `{ "speed": 135, "common_forms": ["meowscarada"], "weight": 0.64 }`
- archetype: `{ "name": "balanced pivot offense", "weight": 0.71 }`

### 13. `build_request`

Stores exact inputs sent by the client.

```sql
CREATE TABLE build_request (
  id UUID PRIMARY KEY,
  request_key TEXT NOT NULL UNIQUE,
  user_id TEXT NULL,
  snapshot_version TEXT NOT NULL REFERENCES format_snapshot(snapshot_version),
  format_mode TEXT NOT NULL,
  style_preference TEXT NULL,
  risk_tolerance TEXT NULL,
  goal TEXT NULL,
  locked_slots_json JSONB NOT NULL,          -- user chosen Pokémon/forms
  excluded_forms_json JSONB NOT NULL DEFAULT '[]'::jsonb,
  options_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 14. `build_result`

```sql
CREATE TABLE build_result (
  id UUID PRIMARY KEY,
  request_key TEXT NOT NULL REFERENCES build_request(request_key),
  snapshot_version TEXT NOT NULL REFERENCES format_snapshot(snapshot_version),
  team_name TEXT NOT NULL,
  archetype TEXT NOT NULL,
  score_total NUMERIC(10,3) NOT NULL,
  score_breakdown_json JSONB NOT NULL,
  warnings_json JSONB NOT NULL DEFAULT '[]'::jsonb,
  explanation_payload_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 15. `build_slot`

```sql
CREATE TABLE build_slot (
  id UUID PRIMARY KEY,
  build_result_id UUID NOT NULL REFERENCES build_result(id) ON DELETE CASCADE,
  slot_index INTEGER NOT NULL,
  form_id TEXT NOT NULL REFERENCES pokemon_form(form_id),
  ability_id TEXT NOT NULL REFERENCES ability(ability_id),
  item_id TEXT NOT NULL REFERENCES item(item_id),
  nature TEXT NOT NULL,
  tera_type TEXT NULL,
  ev_spread_json JSONB NOT NULL,
  move_ids TEXT[] NOT NULL,
  role_ids TEXT[] NOT NULL,
  locked_by_user BOOLEAN NOT NULL DEFAULT FALSE,
  slot_score NUMERIC(10,3) NOT NULL,
  why_selected_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE(build_result_id, slot_index)
);
```

### 16. `replacement_option`

```sql
CREATE TABLE replacement_option (
  id UUID PRIMARY KEY,
  build_result_id UUID NOT NULL REFERENCES build_result(id) ON DELETE CASCADE,
  slot_index INTEGER NOT NULL,
  replacement_rank INTEGER NOT NULL,
  suggested_form_id TEXT NOT NULL REFERENCES pokemon_form(form_id),
  delta_score NUMERIC(10,3) NOT NULL,
  replacement_reason TEXT NOT NULL,
  reason_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE(build_result_id, slot_index, replacement_rank)
);
```

### 17. `strategy_plan`

```sql
CREATE TABLE strategy_plan (
  id UUID PRIMARY KEY,
  build_result_id UUID NOT NULL REFERENCES build_result(id) ON DELETE CASCADE,
  plan_rank INTEGER NOT NULL DEFAULT 1,
  archetype TEXT NOT NULL,
  best_leads_json JSONB NOT NULL DEFAULT '[]'::jsonb,
  opening_plan_json JSONB NOT NULL DEFAULT '[]'::jsonb,
  midgame_plan_json JSONB NOT NULL DEFAULT '[]'::jsonb,
  win_conditions_json JSONB NOT NULL DEFAULT '[]'::jsonb,
  danger_matchups_json JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(build_result_id, plan_rank)
);
```

## In-memory build graph

The relational model is the source of truth, but the builder should materialize a normalized graph in memory.

```ts
type CandidateTeam = {
  snapshotVersion: string
  formatMode: 'singles' | 'doubles'
  slots: CandidateSlot[]
  archetype: string
  lockedCount: number
  featureVector: TeamFeatureVector
  scoreBreakdown?: ScoreBreakdown
}

type CandidateSlot = {
  formId: string
  megaFormId?: string | null
  itemId: string
  abilityId: string
  moveIds: [string, string, string, string]
  evs: { hp: number; atk: number; def: number; spa: number; spd: number; spe: number }
  nature: string
  teraType?: string | null
  roles: string[]
  lockedByUser: boolean
  templateKey?: string | null
}

type TeamFeatureVector = {
  typeWeaknessCounts: Record<string, number>
  typeResistanceCounts: Record<string, number>
  speedBands: Record<string, number>
  roleCoverage: Record<string, number>
  pivotCount: number
  protectCount?: number
  spreadMoveCount?: number
  statusPressure: number
  priorityCount: number
  setupCount: number
  trickRoomModeScore?: number
  weatherModeScore?: number
  hazardScore?: number
  recoveryCount: number
  metaMatchupScores: Record<string, number>
}
```

## Snapshot ingestion spec

### Source hierarchy

The ingestion job should rank sources in this order:

1. official Pokémon Champions site
2. official Pokémon / Play! Pokémon pages if they publish regulation or event details
3. curated tournament datasets
4. trusted community data with lowered confidence

### Required normalized outputs

Each ingestion run must produce:

- snapshot header
- legal forms
- legal items
- legal moves
- legal abilities
- learnsets or trainable move allowances
- legal special mechanics
- top-level meta notes
- confidence notes for ambiguous or partial data

### Snapshot versioning

Use a version string like:

```text
2026-04-09-singles-reg-ma-v1
2026-04-09-doubles-reg-ma-v1
```

Rules:
- increment `vN` when backend parsing or curation changes without a regulation change
- change the middle regulation token when official regulation changes
- use a fresh date whenever the snapshot is rebuilt

### Build-path constraint

The public API must never hit live sources during a build request.

Correct flow:
1. scheduled ingestion job runs
2. snapshot is validated and published
3. builder API uses only published snapshot tables

Incorrect flow:
1. user taps build
2. backend scrapes current site
3. response depends on scrape latency or transient page changes

## Team build pipeline

### Step 0: validate request

Reject or downgrade inputs that are:
- illegal in current snapshot
- unconfirmed in current snapshot
- duplicate beyond format rules
- missing mandatory format fields

Validation result should separate:
- `hard_errors`: request cannot proceed as submitted
- `soft_warnings`: proceed but flag replacements or degraded score

### Step 1: normalize locked core

For each locked slot:
- resolve species -> form
- resolve form legality
- attach allowed ability/item/move pools
- infer role candidates from template library and raw move pool
- tag it as `lockedByUser = true`

If the user supplies all 6 Pokémon:
- the engine should still optimize sets and replacements
- but it should not silently delete a user pick
- instead it should score the locked 6, then produce ranked replacement suggestions

### Step 2: infer desired archetype

Archetype inference uses:
- explicit `style_preference`
- locked core role composition
- meta priors for format
- set template compatibility

Possible outputs:
- balanced
- bulky offense
- pivot offense
- trick room
- weather
- snow balance
- hyper offense
- anti-meta control
- goodstuff balance

### Step 3: candidate pool generation

Candidate generation is constrained search, not brute force over the full roster.

#### Candidate sources
- snapshot-legal forms
- snapshot-compatible set templates
- direct synergy expansions around locked core
- archetype anchor shortlists
- anti-meta shortlist for the current snapshot

#### Generation rules
- prefer forms with non-zero synergy to locked core
- avoid generating teams that exceed weakness clump thresholds too early
- keep candidate beam width configurable

Suggested defaults:
- initial expansion beam: 40
- mid-search beam: 25
- final scored candidates: 10
- final returned teams: 1 primary + up to 2 alternates

### Step 4: build candidate sets

For each candidate slot, generate a bounded set of valid set options.

Order of preference:
1. curated snapshot template
2. generic evergreen template adapted to snapshot legality
3. role-targeted synthesis from legal moves and items

The builder may synthesize a set only if it can satisfy:
- legal move list
- legal ability
- legal item
- coherent role definition
- no direct anti-synergy with chosen archetype

### Step 5: compute feature vector

The team feature vector is the shared input to the scorer.

#### Required features

Shared:
- role coverage
- offensive spread
- defensive overlap
- weakness clumping
- resistance distribution
- speed band coverage
- pivot density
- setup density
- priority access
- recovery count
- status pressure
- legal Mega availability and fit
- locked-slot preservation cost
- meta threat responses

Singles additional:
- hazard access
- hazard removal access
- stallbreaking pressure
- emergency revenge capacity
- long-game progress index

Doubles additional:
- protect count
- redirection access
- fake out access
- spread damage access
- speed control mode access
- trick room mode score
- board control index
- lead coherence score

## Scoring algorithm spec

The scorer is weighted, additive, and explainable. It uses hard legality gates before soft optimization.

### Hard gates

If any hard gate fails, the team is invalid and cannot win selection.

Hard gates:
- illegal form
- illegal move
- illegal item
- illegal ability
- unsupported special mechanic
- duplicate rule violation
- fewer than 6 slots
- impossible set (e.g. template references unavailable move)

### Score structure

The total score is:

```text
team_total =
  hard_gate_score
+ composition_score
+ synergy_score
+ meta_score
+ intent_score
- risk_penalties
```

Where:
- `hard_gate_score` is either `0` for valid or `-infinity` for invalid
- all other components are scaled to a 0-100 style domain before weighting

### Recommended normalized components

#### A. composition score
Measures whether the team has the roles and board tools it needs.

```text
composition_score =
  1.4 * role_coverage
+ 0.8 * speed_control
+ 0.7 * pivoting_or_positioning
+ 0.6 * progress_making
+ 0.5 * recovery_or_stability
```

#### B. synergy score
Measures offensive and defensive fit across the six.

```text
synergy_score =
  1.1 * offensive_synergy
+ 1.1 * defensive_synergy
+ 0.7 * role_compression_bonus
+ 0.5 * archetype_cohesion
```

#### C. meta score
Measures current snapshot matchup quality.

```text
meta_score =
  1.5 * top_threat_matchup
+ 1.0 * archetype_field_matchup
+ 0.6 * speed_tier_alignment
```

#### D. intent score
Preserves what the user wanted.

```text
intent_score =
  1.2 * locked_core_preservation
+ 0.8 * style_match
+ 0.6 * goal_match
+ 0.4 * risk_tolerance_match
```

#### E. risk penalties
Subtracts structural problems.

```text
risk_penalties =
  1.8 * illegality_penalty
+ 1.3 * weakness_clump_penalty
+ 1.1 * redundancy_penalty
+ 0.9 * dead_slot_penalty
+ 0.8 * fragile_wincon_penalty
```

### Singles weight profile

Use this profile for Singles unless a regulation-specific override exists.

```json
{
  "role_coverage": 14,
  "speed_control": 9,
  "pivoting_or_positioning": 8,
  "progress_making": 11,
  "recovery_or_stability": 6,
  "offensive_synergy": 12,
  "defensive_synergy": 12,
  "role_compression_bonus": 7,
  "archetype_cohesion": 6,
  "top_threat_matchup": 15,
  "archetype_field_matchup": 10,
  "speed_tier_alignment": 6,
  "locked_core_preservation": 12,
  "style_match": 8,
  "goal_match": 6,
  "risk_tolerance_match": 4,
  "weakness_clump_penalty": 14,
  "redundancy_penalty": 10,
  "dead_slot_penalty": 18,
  "fragile_wincon_penalty": 8
}
```

### Doubles weight profile

Doubles prioritizes lead coherence, protect, board control, and mode integrity.

```json
{
  "role_coverage": 12,
  "speed_control": 12,
  "pivoting_or_positioning": 10,
  "progress_making": 8,
  "recovery_or_stability": 4,
  "offensive_synergy": 12,
  "defensive_synergy": 10,
  "role_compression_bonus": 8,
  "archetype_cohesion": 8,
  "top_threat_matchup": 15,
  "archetype_field_matchup": 10,
  "speed_tier_alignment": 7,
  "locked_core_preservation": 12,
  "style_match": 8,
  "goal_match": 6,
  "risk_tolerance_match": 4,
  "weakness_clump_penalty": 12,
  "redundancy_penalty": 10,
  "dead_slot_penalty": 18,
  "fragile_wincon_penalty": 10
}
```

## Component definitions

### 1. role coverage

Role coverage is not “count every role once.” It is weighted coverage against the target archetype.

Example Singles target profile for balanced pivot offense:

```json
{
  "pivot": 1.0,
  "hazard_setter": 1.0,
  "physical_breaker": 1.0,
  "special_breaker": 1.0,
  "defensive_glue": 1.0,
  "cleaner": 1.0,
  "revenge_tool": 0.8,
  "hazard_removal": 0.6
}
```

Coverage score formula:

```text
role_coverage =
  SUM over roles [
    min(actual_role_count / desired_role_count, 1.0) * role_importance
  ] / SUM(role_importance)
```

### 2. offensive synergy

Measures whether the team can force progress across common defensive structures.

Suggested signals:
- number of distinct offensive types that matter in current meta
- mixed physical/special pressure
- pivot into breaker chains
- setup threat quality
- immunity-punishing coverage
- access to chip engines like hazards, Salt Cure style attrition, spread damage, etc.

A simple starting model:

```text
offensive_synergy =
  0.25 * stab_pressure_diversity
+ 0.20 * mixed_damage_balance
+ 0.20 * safe_entry_paths
+ 0.20 * progress_engines
+ 0.15 * cleanup_support
```

### 3. defensive synergy

Measures how well the six cover each other’s weaknesses.

Suggested procedure:
1. compute weakness/resistance matrix by attacking type
2. mark 2x, 4x, immunity, resistance
3. apply coverage bonuses if a weakness is backed by:
   - a hard resist or immunity
   - speed control
   - priority revenge
   - pivot escape

A practical normalized model:

```text
defensive_synergy =
  1.0
- normalized_uncovered_weakness_mass
- normalized_four_x_cluster_penalty
+ immunity_bonus
+ defensive_glue_bonus
```

### 4. speed control

Singles:
- raw top-speed slots
- speed boosting cleaners
- priority users
- choice-speed users
- paralysis/web/other control when legal

Doubles:
- Tailwind
- Trick Room
- Icy Wind / Electroweb style board speed control
- priority plus redirection support
- mode coherence between setters and abusers

### 5. pivoting or positioning

Singles:
- U-turn / Volt Switch / Flip Turn
- slow pivots
- double-switch facilitation via matchup pressure

Doubles:
- Protect density
- pivoting / reset tools
- fake out + pivot sequences
- redirection into setup or room turns

### 6. progress making

A team that cannot make progress should not score well even if it looks balanced on paper.

Signals:
- hazards
- status pressure
- chip engines
- item disruption
- boosting options that demand answers
- spread damage
- Encore/Yawn/taunt-like tempo theft where legal

### 7. top threat matchup

This is the most regulation-sensitive component.

For each `top_threat` in `meta_signal_snapshot`:
- compute an answer score from 0 to 1
- weight by threat meta weight
- average across the top N threats

Threat answer score can combine:
- direct type advantage
- speed advantage
- ability/item disruption
- reliable KO pressure proxy
- board control tools
- switch-in or pivot comfort

### 8. speed tier alignment

Measure whether the team meaningfully occupies or answers relevant speed bands in the current snapshot.

Example bands:
- `very_fast`
- `fast`
- `mid`
- `slow`
- `room_optimized`

### 9. locked core preservation

The app promise is “build around my picks,” not “ignore my picks.”

Use:

```text
locked_core_preservation =
  locked_slots_retained / locked_slots_requested
```

Then apply a secondary fit modifier:
- if locked Pokémon are technically retained but saddled with incoherent sets, lower the score

### 10. weakness clump penalty

Penalty rises sharply when multiple slots stack the same exploitable weakness.

Suggested formula:

```text
weakness_clump_penalty =
  SUM over attack types [
    max(0, weak_count(type) - safe_threshold(type)) ^ 1.5 * type_meta_weight(type)
  ]
```

Suggested safe thresholds:
- 2 for common attacking types
- 1 for especially dangerous meta types in the current snapshot

### 11. redundancy penalty

Penalize teams that duplicate function without improving matchup coverage.

Examples:
- three Pokémon all trying to be the same speed booster
- two redirectors with no payoff
- multiple slow breakers with no room mode
- excessive same-type offense that worsens coverage

### 12. dead slot penalty

A dead slot is not merely “suboptimal.” It is a slot that rarely gets safe entry or meaningful clicks in current matchups.

Signals:
- no usable safe entry path
- role already duplicated by better slot
- poor synergy with chosen mode
- frequent forced tera/mega/item conflict
- unacceptably narrow matchup value

## Slot scoring

Each slot also gets an internal score used for replacement suggestions.

```text
slot_score =
  0.30 * individual_power
+ 0.25 * team_synergy
+ 0.20 * role_fit
+ 0.15 * meta_value
+ 0.10 * ease_of_pilot
- penalties
```

The lowest-scoring non-essential slots are the first replacement candidates.

## Candidate search strategy

A practical search flow:

1. **Seed phase**
   - start from locked core
   - inject archetype anchors if the locked core lacks structure
2. **Beam expansion**
   - add one slot at a time
   - prune low-scoring partial teams
3. **Set resolution**
   - pick one set per slot from valid templates
   - re-score
4. **Local improvement**
   - single-slot swaps
   - item swaps
   - move slot swaps
5. **Final ranking**
   - keep best team
   - store top alternates for rebuilds and safer/spicier toggles

### Partial team scoring

Partial teams need a forward-looking score.

Use:

```text
partial_score =
  realized_score
+ projected_fill_potential
- current_structural_risk
```

This prevents early pruning of promising but incomplete archetypes.

## Replacement suggestion algorithm

Replacement suggestions should be generated after final team selection.

For each slot:
1. remove the slot
2. regenerate 20-50 compatible substitutes
3. score the rebuilt team
4. keep top 3 replacements
5. label replacement type

Replacement labels:
- direct upgrade
- same role, better meta fit
- legality fix
- same flavor, safer option
- anti-meta option
- simpler pilot option

### Replacement reason JSON

```json
{
  "why_replace": [
    "Stacks Ground weakness",
    "No reliable safe entry",
    "Role duplicated by another slot"
  ],
  "why_better": [
    "Improves Electric matchup",
    "Adds real hazard removal",
    "Keeps pivot offense identity"
  ],
  "score_delta": {
    "total": 6.8,
    "defensive_synergy": 2.1,
    "meta_score": 2.9,
    "redundancy_penalty": -1.4
  }
}
```

## Strategy plan generation

The backend should emit structured strategy data without relying on freeform model generation.

### Strategy plan inputs
- final team roles
- lead pairs or lead singles
- archetype
- primary progress engines
- win conditions
- known danger matchups

### Required outputs
- summary
- best leads or openers
- opening plan
- midgame plan
- win conditions
- danger matchups
- emergency lines

### Heuristic examples

#### Singles balanced pivot offense
- opener: best pivot or hazard lead into unknown matchup
- midgame: chip with progress engine, scout, preserve cleaner
- endgame: activate speed or priority cleaner once bulky checks are softened

#### Doubles room balance
- opener: choose between room line and non-room line
- midgame: exploit board control and spread pressure
- endgame: preserve one protected wincon plus cleanup support

## API contract

### Build request

```json
{
  "snapshot_version": "2026-04-09-singles-reg-ma-v1",
  "format_mode": "singles",
  "style_preference": "balanced_pivot_offense",
  "risk_tolerance": "stable",
  "goal": "ladder",
  "locked_slots": [
    { "form_id": "palafin", "must_keep": true },
    { "form_id": "dragonite", "must_keep": true }
  ]
}
```

### Build response

```json
{
  "snapshot_version": "2026-04-09-singles-reg-ma-v1",
  "team": {
    "name": "Balanced Pivot Offense",
    "archetype": "balanced_pivot_offense",
    "score_total": 87.4,
    "score_breakdown": {
      "composition": 22.8,
      "synergy": 24.1,
      "meta": 19.5,
      "intent": 17.0,
      "penalties": -6.0
    }
  },
  "slots": [],
  "replacements": [],
  "strategy_plans": [],
  "warnings": []
}
```

## Observability and auditability

Every build should log:

- request key
- snapshot version
- locked inputs
- selected archetype
- top 10 candidate score summaries
- final score breakdown
- replacement deltas
- generation duration

This enables:
- regression testing
- meta recalibration
- postmortems when users say “the builder keeps suggesting bad teams”

## Evaluation and calibration

The scorer should be calibrated against held-out reference sets.

### Offline evaluation set
Maintain a dataset of:
- successful tournament-style teams
- competent ladder teams
- intentionally bad control teams
- intentionally illegal examples
- common user-style locked cores

### Evaluation metrics
- legality precision
- illegal suggestion rate
- mean score of curated good teams vs bad teams
- locked-core retention rate
- replacement usefulness click-through or selection rate
- build latency percentile
- explanation mismatch rate

### Calibration loop
1. run snapshot update
2. score curated evaluation corpus
3. compare ranking drift
4. review large deltas
5. adjust weights or templates
6. publish new snapshot version only after passing thresholds

## Safeguards

### 1. Unconfirmed content handling
If a form, Mega, move, or item is not confirmed in the current snapshot:
- treat it as `unconfirmed`
- never silently mark it legal
- offer a nearby legal replacement if available

### 2. User-locked illegal Pokémon
If a user locks an illegal or unsupported Pokémon:
- preserve it in the request echo
- mark the slot invalid
- build the closest legal team shell around replacement options
- surface a direct explanation

### 3. Model boundary
The explanation layer may only consume:
- chosen sets
- score breakdowns
- replacement reasons
- strategy objects

The explanation layer may not:
- invent new sets
- override legality
- rename snapshot rules
- claim tournament viability beyond backend confidence

## Recommended implementation order

1. snapshot schema and ingestion
2. legality service
3. set template store
4. feature vector computation
5. beam search candidate generator
6. scorer with Singles and Doubles profiles
7. replacement engine
8. strategy object generator
9. explanation contract

## Suggested first shipping scope

### V1
- Singles only
- one current snapshot
- 0-6 locked Pokémon
- one best team
- up to 3 slot replacements
- one strategy plan

### V1.5
- Doubles
- multiple archetypes
- snapshot-conditioned meta signals
- safer vs spicier rebuild toggle

### V2
- alternate team variants
- counter-meta mode
- calibrated matchup priors from live result ingestion
- per-slot explanation embeddings for search and analytics

## Open questions

These should remain explicit until the backend has authoritative answers per snapshot:

1. Are Tera types available in the active regulation, and if so, are they unrestricted?
2. How broad is the legal Mega pool in the active snapshot?
3. How complete is the legal roster versus full National Dex expectations?
4. Which moves are available only through in-game training versus incoming HOME state?
5. Which doubles mechanics need bespoke scoring adjustments once live data stabilizes?

## References for snapshot ingestion

Use official sources first when building or updating snapshots:

- Pokémon Champions homepage
- Pokémon Champions gameplay page
- Pokémon Champions Pokémon / roster page
- official Play! Pokémon competition announcements if regulation or event usage is clarified there

The ingestion system should store:
- source URL
- fetch time
- parser version
- confidence score
- human review status

That keeps the builder reproducible when official rules evolve.

### Current official URLs

- https://champions.pokemon.com/en-us/
- https://champions.pokemon.com/en-us/gameplay
- https://champions.pokemon.com/en-ca/pokemon/
