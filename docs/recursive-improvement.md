# Recursive Improvement: How AI Agents Get Smarter Over Time

The central insight: **intelligence that compounds with use is a moat.** A tool that resets every session can be copied. A tool that gets smarter the more you use it creates switching costs and genuine value.

This document describes how to build systems where every interaction makes the next one better.

---

## The Compound Intelligence Loop

```
Session N → Feedback → Memory → Context → Session N+1 (smarter)
                ↓
         Distillation (async)
                ↓
         Experience → Dedup → Merge/Insert
                ↓
         Promotion (observation_count >= 5)
                ↓
         Permanent Skill (never decays)
```

Each session generates three types of signal:
1. **Explicit feedback** — "Don't do X, do Y instead"
2. **Implicit patterns** — what the user accepts vs. modifies
3. **Contextual decisions** — choices made during the session

The recursive improvement system captures all three and feeds them back into future sessions.

---

## Feedback as Training Data

When a user corrects Claude Code, that correction is worth 100x its weight in gold. It contains:
- **The wrong approach** (what the AI did)
- **The right approach** (what the user wanted)
- **The context** (when this rule applies)
- **The reasoning** (why it matters)

**Capture pattern:**
```markdown
---
name: No database mocks in integration tests
description: Integration tests must hit real DB — mocked tests masked a broken migration
type: feedback
---

## The Correction
Don't mock the database in integration tests.

## Why
Last quarter, mocked tests passed but the production migration failed. The mock/prod
divergence masked a broken migration that deleted user data.

## The Rule
Integration tests must hit a real database. Only unit tests may use mocks.
Mock boundary: external APIs (Stripe, email providers) = mock. Internal DB = real.
```

**Why this format works:**
- The `description` field in frontmatter is used for relevance matching — it should be specific enough to trigger in the right context
- The "Why" section prevents the AI from over-generalizing (it won't avoid ALL mocks, just DB mocks in integration tests)
- The "Rule" section gives a clear, actionable directive

---

## The Distillation Pipeline

### Step 1: Harvest
Collect interactions from the last 24 hours (or last session). This is your raw material.

### Step 2: Extract
Use a lightweight model (fast, cheap) to extract reusable lessons:

```
Prompt: "Given these developer-AI interactions, extract PRACTICE LESSONS —
reusable patterns that would help in OTHER projects or contexts.

RULES:
1. Strip project-specific details (names, paths, URLs, credentials)
2. Generalize: 'For the Acme auth system...' → 'For JWT auth systems...'
3. Only extract genuinely reusable insights — not one-off facts
4. Each lesson should be self-contained and actionable

For each lesson, provide:
- title: short descriptor
- content: the generalized lesson (2-4 sentences)
- category: architecture | testing | deployment | debugging | performance | security
```

### Step 3: PII/Specifics Gate
Run a second pass to ensure no project-specific or sensitive data leaked through:
- Check for file paths, URLs, API keys, names, dates
- Reject anything that fails the check
- This is the "belt AND suspenders" approach — the extraction prompt says to strip, the gate catches what slips through

### Step 4: Dedup & Merge
Generate an embedding for the new lesson and compare against existing experiences:
- **Similarity > 0.85:** Merge — update content with latest version, increment `observation_count`, bump confidence, reset decay timer
- **Similarity < 0.85:** Insert as new experience

### Step 5: Promote to Permanent
Check if any experience has `observation_count >= 5`:
- If a matching permanent skill already exists (>70% title word overlap): update it
- If no match: create new permanent skill with `confidence = 0.9`
- Mark the experience as promoted (prevents double-promotion)

### Step 6: Decay
Apply exponential decay to experiences not accessed in 30+ days:
```
new_relevance = current_relevance * (0.95 ^ days_past_30)
if new_relevance < 0.1: soft_archive (deactivate, don't delete)
```

**Critical:** Permanent skills (Tier 4) NEVER decay. They earned their permanence.

---

## Self-Healing Memory

### When to Prune
- Experiences contradicted by newer feedback should be deactivated
- Experiences about deprecated tools/frameworks should be archived
- Duplicate experiences that survived dedup should be merged manually

### When to Revisit
- When the AI makes a mistake that should have been prevented by an existing memory
- When a memory is consistently irrelevant (loaded but never useful)
- When the project pivots and old context becomes misleading

### The "Memory Audit" Cron Pattern
Weekly (or monthly):
1. List all memory files
2. For each, check last_accessed_at
3. Flag any not accessed in 30+ days
4. Present to user for review: keep, update, or archive

---

## Cross-Project Intelligence

The most powerful application: lessons from Project A improve performance on Project B.

### What transfers well:
- Language/framework patterns ("React 19 concurrent features require...")
- Deployment patterns ("Vercel monorepo builds need explicit output directories")
- Testing patterns ("Always test the unhappy path before the happy path")
- Architecture patterns ("Event-driven > polling for real-time features")
- Debugging patterns ("When Supabase RLS blocks a query, check auth context first")

### What does NOT transfer:
- Project-specific architecture ("Our auth uses withAuth() HOF")
- Business logic ("Lawyers must not see other lawyers' clients")
- Infrastructure specifics ("Deploy to us-east-1")
- Team conventions ("We use conventional commits")

### The Portable Experience Format
```markdown
---
name: JWT Token Expiry Pattern
description: Short access tokens (15min) with long refresh tokens (7d) balances security and UX
type: experience
category: security
observation_count: 7
confidence: 0.95
---

For JWT-based auth systems, use short-lived access tokens (15 minutes) paired with
long-lived refresh tokens (7 days). This balances security (compromised access tokens
expire quickly) with UX (users don't re-authenticate constantly). Implement silent
refresh in an HTTP interceptor so the user never sees a login screen during normal use.

Source pattern: Observed across 3 production auth implementations. The 15min/7d split
consistently outperforms both shorter (5min — too many refreshes) and longer (1hr —
too much risk) access token durations.
```

---

## Measuring Intelligence Growth

### Metrics that matter:
1. **Corrections per session** — should decrease over time as feedback memories accumulate
2. **Time to first useful output** — should decrease as context improves
3. **Memory utilization** — what percentage of loaded memories are actually useful?
4. **Promotion rate** — how many experiences earn permanent status?
5. **Decay rate** — are most experiences being archived (too much noise) or retained (good signal)?

### Healthy ratios:
- **Permanent skills:** 10-30 per project (more = either very mature project or too-low promotion threshold)
- **Active experiences:** 20-100 (more = consider tightening dedup threshold)
- **Decay archives:** 50-70% of all-time experiences (healthy — most things aren't worth remembering forever)
- **Feedback memories:** 5-20 per project (if more, the AI may have fundamental capability gaps)

---

## The Economic Argument

Every AI tool on the market resets every conversation. ChatGPT, GitHub Copilot, cursor — they all start cold. This creates a ceiling: the tool is only as good as its base model + whatever context you manually provide each time.

A system with compound memory breaks through this ceiling:
- **Day 1:** Raw model capability (same as everyone else)
- **Week 1:** Knows your project structure, commands, patterns
- **Month 1:** Remembers your corrections, avoids your pet peeves
- **Month 3:** Has distilled 50+ reusable experiences from your sessions
- **Month 6:** Has 15+ permanent skills earned from repeated observation
- **Year 1:** More valuable than a new hire who just read the README

**The switching cost is the intelligence itself.** All those memories, experiences, and skills are locked into YOUR system. A competitor offering a better base model still starts from zero.
