# Memory Tiers: From Ephemeral to Permanent

The human brain doesn't store everything the same way. Working memory holds the current thought. Episodic memory records experiences. Semantic memory distills patterns. Procedural memory automates skills. Each tier has different persistence, access patterns, and decay characteristics.

This system mirrors that architecture for AI-assisted development.

---

## Tier 0 — Memento (Session Continuity)

**Analogy:** The sticky notes on your monitor.

**What it stores:** Rolling summary of recent sessions — what was done, decisions made, next steps.

**Persistence:** ~50 lines, newest first. Oldest entries drop off the bottom.

**Decay:** Implicit — old entries are displaced by new ones.

**Access pattern:** Always loaded at session start. Written at session end.

**Implementation:** `MEMENTO.md` file in the memory directory.

**Why it matters:** Without this, every session starts with "what were we doing?" With it, the AI picks up exactly where you left off — like a colleague who was in yesterday's meeting.

### Writing Good Memento Entries

```markdown
### [2026-03-14 4:30pm] Migrated auth to JWT tokens
Replaced session-cookie auth with JWT. Updated middleware, all 12 protected routes,
and the refresh flow. Decided to keep 15min access token / 7d refresh token split
after researching security tradeoffs (see auth-design.md).
Next: Update client SDK to handle token refresh. The interceptor pattern from
axios-auth-refresh looks right.
```

**Include:**
- What was accomplished (the "what")
- Key decisions and their rationale (the "why")
- Blockers encountered and how they were resolved
- Explicit next steps for the next session

**Exclude:**
- Code snippets (they're in git)
- Full error messages (they're in logs)
- Sensitive data (API keys, PII, credentials)

---

## Tier 1 — Working Memory (Conversation Context)

**Analogy:** What you're actively thinking about right now.

**What it stores:** The current conversation with Claude Code.

**Persistence:** Dies when the conversation ends.

**Decay:** Immediate — gone after session close.

**Access pattern:** Automatic (the conversation itself).

**Implementation:** Built into Claude Code. No files needed.

**Why it matters:** This is the baseline. Every other tier exists to enrich this one.

---

## Tier 2 — Episodic Memory (Project-Scoped Facts)

**Analogy:** Your personal notebook about this project.

**What it stores:** Specific facts, preferences, and corrections tied to this project.

**Persistence:** Indefinite, but subject to manual pruning.

**Decay:** Manual — you delete what's no longer relevant.

**Access pattern:** Loaded when relevant to the current task (via MEMORY.md index).

**Implementation:** Memory files in `.claude/memory/` — `feedback_*.md`, `project_*.md`, `user_*.md`, `reference_*.md`.

**Why it matters:** This is where behavioral corrections live. "Don't mock the database" is a Tier 2 memory. Without it, the AI repeats the same mistakes across sessions.

### Memory Types

| Type | What it captures | Example |
|------|-----------------|---------|
| `user` | Developer profile, preferences | "Senior Go dev, new to React frontend" |
| `feedback` | Behavioral corrections | "Always run tests before committing" |
| `project` | Ongoing work context | "Merge freeze starts March 5th" |
| `reference` | External system pointers | "Pipeline bugs tracked in Linear/INGEST" |

---

## Tier 3 — Semantic Memory (Distilled Experience)

**Analogy:** The wisdom of a 30-year veteran.

**What it stores:** Generalized lessons extracted from specific interactions. Project-specific details stripped, reusable patterns preserved.

**Persistence:** Subject to decay and promotion.

**Decay:** Exponential — unused experiences lose relevance over time.

**Access pattern:** Searched by semantic similarity when context is being assembled.

**Implementation:** Experience database with embeddings (for projects with database infrastructure). For simpler projects, curated `experience_*.md` files.

### The Distillation Pipeline

```
Conversations → Extract lessons → Strip specifics → Generate embedding →
Check for duplicates (>0.85 similarity = merge) → Insert or merge →
Apply decay to stale experiences → Promote high-frequency to permanent
```

### Decay Mechanics

The decay model prevents unbounded growth while preserving valuable patterns:

```
After 30 days of non-access:
  relevance_score *= 0.95 per additional day

Day 30: 1.0    (no decay yet)
Day 45: 0.46   (15 days of decay: 0.95^15)
Day 60: 0.21   (30 days of decay: 0.95^30)
Day 90: 0.046  (60 days of decay: 0.95^60)

When relevance_score < 0.1: soft-archive (deactivate, don't delete)
```

**Why exponential?** Linear decay is too aggressive early and too slow late. Exponential decay gives experiences a fair chance to prove their value while ensuring unused ones don't clutter the system.

### Deduplication via Embedding Similarity

When a new experience is extracted:
1. Generate an embedding vector (e.g., via OpenAI, local model, etc.)
2. Search existing experiences by cosine similarity
3. If similarity > 0.85: **merge** — update content, increment `observation_count`, reset decay
4. If similarity < 0.85: **insert** as new experience

This prevents the common failure mode of accumulating 50 variations of the same lesson.

### Experience vs. Memory

| Concern | Memory (Tier 2) | Experience (Tier 3) |
|---------|-----------------|---------------------|
| Scope | Project-specific | Cross-project portable |
| Specificity | "Our auth uses JWT with 15min expiry" | "Short-lived access tokens (15min) with long-lived refresh tokens (7d) is the industry standard" |
| Decay | Manual pruning | Automatic exponential decay |
| Growth | Bounded by manual curation | Self-regulating via decay + dedup |

---

## Tier 4 — Procedural Memory (Permanent Skills)

**Analogy:** Riding a bike — once learned, never forgotten.

**What it stores:** Patterns observed 5+ times that have proven their value through repetition.

**Persistence:** Permanent. Never decays.

**Decay:** None — earned through repeated observation.

**Access pattern:** Always loaded (like skills).

**Implementation:** Promoted from Tier 3 when `observation_count >= 5`.

### Promotion Criteria

An experience earns permanent status when:
1. It has been observed in 5+ separate sessions/conversations
2. Each observation reinforces the same pattern (similarity > 0.85)
3. It has not been contradicted by newer feedback

**Examples of permanent patterns:**
- "Always run the full test suite before pushing, not just the changed tests"
- "React Query v5 uses object syntax for useQuery — never pass positional args"
- "Supabase RLS policies must use get_my_lawyer_id(), not raw auth.uid() queries"

### The "Riding a Bike" Guarantee

Once a pattern reaches Tier 4, it is:
- Never subject to decay
- Always loaded into context
- Only removable by explicit human intervention

This mirrors how human procedural memory works: you don't forget how to ride a bike, even if you haven't ridden one in years.

---

## Tier Summary

```
┌────────────────────────────────────────────────────────┐
│ Tier 4: Permanent Skills                               │
│ Patterns observed 5+ times. Never decay.               │
│ "Riding a bike" — always loaded, always trusted.       │
├────────────────────────────────────────────────────────┤
│ Tier 3: Distilled Experience                           │
│ Generalized lessons. Exponential decay (0.95^days).    │
│ Embedding dedup. Soft-archive at < 0.1 relevance.      │
├────────────────────────────────────────────────────────┤
│ Tier 2: Project Memory                                 │
│ Specific facts, corrections, preferences.              │
│ Manual curation. Indefinite persistence.               │
├────────────────────────────────────────────────────────┤
│ Tier 1: Working Memory                                 │
│ Current conversation context.                          │
│ Dies when session ends.                                │
├────────────────────────────────────────────────────────┤
│ Tier 0: Memento                                        │
│ Session notes. Rolling ~50 lines.                      │
│ Newest first. Oldest drops off.                        │
└────────────────────────────────────────────────────────┘
```

Each tier feeds the one above it. Conversations (Tier 1) generate memento entries (Tier 0). Memento entries that contain reusable lessons get distilled into experiences (Tier 3). Experiences observed 5+ times become permanent skills (Tier 4). The whole system compounds — like the human brain's consolidation process during sleep.
