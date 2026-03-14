# Cron Patterns: Automated Memory Management

Automation turns a manual discipline into a self-improving system. These patterns are ordered from simplest to most sophisticated — implement them incrementally.

---

## Pattern 1: Session End Hook

**Trigger:** End of every Claude Code session.
**Complexity:** Low (just a rule in CLAUDE.md).
**Value:** High (session continuity from day 1).

### Implementation

Add to your `CLAUDE.md`:
```markdown
## Session End Protocol
At the end of every work session:
1. Prepend a summary to MEMENTO.md with format:
   ### [YYYY-MM-DD HH:MMam/pm] Brief description
   What was done. Decisions made. Next steps.
2. Update PROJECT_STATE.md if sprint status changed
3. Create feedback_*.md files for any corrections given this session
4. Update CLAUDE.md if new patterns or gotchas were discovered
```

Claude Code will follow this protocol when you say "we're done" or "end session."

### Optional: Automated via Hooks

If your project supports it, create a hook that triggers at session end:
```json
// .claude/settings.json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "session_end",
        "command": "echo 'SESSION END: Update MEMENTO.md, PROJECT_STATE.md, and any feedback memories'"
      }
    ]
  }
}
```

---

## Pattern 2: Memento Trimming

**Trigger:** When MEMENTO.md exceeds ~50 lines.
**Complexity:** Low.
**Value:** Prevents context overflow.

### Implementation

When prepending a new memento entry:
1. Split the file on `###` headers
2. Count entries
3. If more than ~15 entries (or ~50 lines): drop the oldest entries from the bottom
4. Never cut an entry in half — always trim at entry boundaries

### Why 50 Lines?

MEMENTO.md is loaded into every session's context. At ~50 lines (~2,000 tokens), it provides recent history without consuming too much of the context window. More than that and you're in "diminishing returns" territory where older entries are rarely relevant.

---

## Pattern 3: Weekly Skill Extraction

**Trigger:** Weekly cron (or manual trigger).
**Complexity:** Medium (requires LLM call).
**Value:** High (behavioral pattern discovery).

### Pipeline

```
1. Fetch recent conversations/sessions from the past week
2. Call a fast LLM (e.g., Claude Haiku) with extraction prompt:
   "Review these developer-AI interactions. Extract behavioral preferences:
    - Formatting preferences (code style, response length)
    - Tool preferences (frameworks, libraries, patterns)
    - Communication preferences (verbose vs. terse, code-first vs. explanation-first)
    - Process preferences (TDD, commit patterns, review habits)
    Return as structured JSON."
3. Compare extracted patterns against existing skill files
4. If >70% title word overlap: merge (update content, increment observation_count)
5. If new: create skill file
6. If observation_count >= 5: mark as permanent
```

### Merge Logic

```
function skillsOverlap(existingTitle, newTitle, existingCategory, newCategory) {
  if (existingCategory !== newCategory) return false;
  const existingWords = existingTitle.toLowerCase().split(/\s+/);
  const newWords = newTitle.toLowerCase().split(/\s+/);
  const intersection = existingWords.filter(w => newWords.includes(w));
  const union = new Set([...existingWords, ...newWords]);
  return (intersection.length / union.size) > 0.7;
}
```

### Frustration Detection

A valuable addition to skill extraction: detect when the user expresses frustration with Claude Code's behavior. Patterns like "no, not that", "I already told you", "stop doing X" are strong signals for feedback memories.

---

## Pattern 4: Nightly Experience Consolidation

**Trigger:** Nightly cron (e.g., 2 AM).
**Complexity:** High (requires LLM + embeddings + database).
**Value:** Very high (cross-session learning).

### The "Sleep Cycle" Pipeline

This mirrors the brain's memory consolidation during sleep:

```
┌─────────────────────────────────────────────────┐
│ Step 1: HARVEST                                  │
│ Fetch all sessions from last 24 hours            │
│ Group by project/context                         │
└──────────────────────┬──────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────┐
│ Step 2: EXTRACT                                   │
│ LLM prompt: "Extract reusable lessons..."         │
│ Output: [{title, content, category}]              │
└──────────────────────┬───────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────┐
│ Step 3: PII/SPECIFICS GATE                        │
│ Regex scan for project-specific data              │
│ Reject anything with: paths, URLs, names, keys    │
└──────────────────────┬───────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────┐
│ Step 4: DEDUP & MERGE                             │
│ Generate embedding → cosine similarity search     │
│ > 0.85 similarity: merge (increment count)        │
│ < 0.85 similarity: insert new                     │
└──────────────────────┬───────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────┐
│ Step 5: PROMOTE                                   │
│ observation_count >= 5 → permanent skill          │
│ Check for existing matching skill (>70% overlap)  │
│ Create or update accordingly                      │
└──────────────────────┬───────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────┐
│ Step 6: DECAY                                     │
│ Experiences not accessed in 30+ days:             │
│   relevance *= 0.95^(days - 30)                   │
│ If relevance < 0.1: soft-archive                  │
│ Permanent skills: NEVER decay                     │
└──────────────────────────────────────────────────┘
```

### Cron Lock

If running in a distributed environment, acquire a lock before processing:
```sql
SELECT pg_try_advisory_lock(hash_code) AS acquired;
-- Process only if acquired = true
-- Release: SELECT pg_advisory_unlock(hash_code);
```

This prevents duplicate processing if the cron runs on multiple instances.

### Cost Control

- Use the cheapest LLM for extraction (Haiku-class: fast, cheap, good enough for structured extraction)
- Process max N entities per cron run to cap costs
- Track token usage for each run
- Set a monthly budget cap and alert

---

## Pattern 5: Spaced Repetition

**Trigger:** On every memory access.
**Complexity:** Low (just a timestamp update).
**Value:** High (decay signal).

### Implementation

Every time an experience is loaded into context:
1. Update `last_accessed_at = now()`
2. Reset `relevance_score = 1.0`

This creates a natural spaced repetition effect:
- Frequently accessed experiences stay relevant (relevance stays high)
- Rarely accessed experiences decay (relevance drops over time)
- The system naturally converges on what's actually useful

### The RAG Budget Split

When assembling context, allocate token budget:
- **60%** — Primary content (documents, code, search results)
- **20%** — Project memories (Tier 2)
- **20%** — Distilled experiences (Tier 3+4)

If no experiences exist yet, the budget reallocates to primary content (80/20 fallback).

---

## Pattern 6: Monthly Memory Audit

**Trigger:** Monthly (first of month).
**Complexity:** Low.
**Value:** Medium (prevents memory rot).

### Checklist

1. Review MEMORY.md index — are all pointers valid?
2. Check for stale memories — any not accessed in 60+ days?
3. Check for contradictory memories — do any feedback files conflict?
4. Review permanent skills — are they still accurate?
5. Check memory directory size — is it growing reasonably?
6. Archive or delete memories for deprecated features/tools

### Automated Report

Generate a monthly report:
```
Memory Health Report — March 2026
================================
Total memory files: 23
  user: 1
  feedback: 8
  project: 5
  reference: 4
  experience: 5

Active experiences: 12
Archived experiences: 3
Permanent skills: 4

Oldest unaccessed memory: feedback_no_mocks.md (45 days)
Most accessed: feedback_test_before_push.md (32 accesses)

Recommendation: Review feedback_no_mocks.md — consider archiving if no longer relevant.
```

---

## Implementation Priority

| Pattern | Effort | Impact | When to Implement |
|---------|--------|--------|-------------------|
| Session End Hook | 5 min | High | Day 1 |
| Memento Trimming | 10 min | Medium | Day 1 |
| Weekly Skill Extraction | 2-4 hrs | High | Week 2 |
| Nightly Consolidation | 4-8 hrs | Very High | Month 1 |
| Spaced Repetition | 30 min | High | When you have experiences |
| Monthly Audit | 1 hr | Medium | Month 2 |

Start with Pattern 1 and 2 — they provide 80% of the value with 5% of the effort. Layer on the rest as your project matures and the value of compound memory becomes clear.
