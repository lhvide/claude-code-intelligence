# Claude Code Intelligence Kit

**The roadmap to agent intelligence.** A portable system of markdown files that makes Claude Code smarter with every session — carrying forward lessons, context, and behavioral corrections across conversations and projects.

Born from 75 sprints of building a production SaaS with Claude Code. These patterns turned a stateless AI into a compounding collaborator.

---

## The Thesis

A 30-year engineer is more valuable than a 10-year engineer not because they type faster — but because they carry forward lessons from thousands of projects. Claude Code resets every conversation. This kit gives it memory.

**Without this kit:** Every Claude Code session starts cold. You re-explain your project structure, re-correct the same mistakes, re-establish your preferences. The AI makes the same wrong assumptions every time.

**With this kit:** Claude Code knows your project, remembers what went wrong last time, understands your preferences, and gets meaningfully better with every session you invest.

---

## Architecture: Four-File Memory System

```
┌─────────────────────────────────────────────────────────┐
│                    CLAUDE.md                             │
│         "Compile-time" context — always loaded           │
│    Commands, patterns, gotchas, rules, architecture      │
│         Checked into repo. Shared with team.             │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│               PROJECT_STATE.md                           │
│         Living snapshot — updated every session           │
│    Current sprint, what's live, what's in progress        │
│    The bridge between code and context.                   │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│           .claude/memory/MEMORY.md                       │
│         Memory index — pointers to topic files            │
│    User preferences, feedback, project context            │
│    Grows over time. Selectively loaded.                   │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│          .claude/memory/MEMENTO.md                        │
│         Session continuity — rolling notes                │
│    What was done, decisions made, next steps              │
│    Newest first. Oldest drops off at ~50 lines.           │
└─────────────────────────────────────────────────────────┘
```

### Why Four Files?

| File | Analogy | Persistence | Scope |
|------|---------|-------------|-------|
| `CLAUDE.md` | Employee handbook | Permanent, versioned | Whole team |
| `PROJECT_STATE.md` | Daily standup notes | Updated each session | Whole team |
| `MEMORY.md` + topic files | Personal notebook | Grows over time | Per developer |
| `MEMENTO.md` | Sticky notes on monitor | Rolling window | Per developer |

---

## Quick Start

```bash
# Clone the kit
git clone https://github.com/YOUR_ORG/claude-code-intelligence.git

# Bootstrap into your project
cd your-project
../claude-code-intelligence/scripts/bootstrap.sh

# Or manually copy templates
cp -r claude-code-intelligence/templates/.claude .claude/
cp claude-code-intelligence/templates/CLAUDE.md ./CLAUDE.md
cp claude-code-intelligence/templates/PROJECT_STATE.md ./PROJECT_STATE.md
```

Then fill in `CLAUDE.md` with your project's specifics and start a Claude Code session. The memory system will grow organically from there.

---

## File Reference

### `CLAUDE.md` — The Source of Truth

**What:** Project-level instructions that Claude Code loads at the start of every conversation. This is your project's "constitution" — the rules, patterns, and context that should always be available.

**When to update:** After every sprint or significant change. When you discover a new gotcha. When a pattern is established.

**What belongs here:**
- Build/test/deploy commands
- Code patterns and conventions (auth, error handling, DB access)
- Architecture decisions and their rationale
- Known gotchas and footguns
- Environment variable reference
- Database/migration patterns
- Reference to `PROJECT_STATE.md` for current state

**What does NOT belong here:**
- Ephemeral state (current sprint progress, in-flight work)
- Personal preferences (use memory files instead)
- Full documentation (link to docs, don't duplicate)

**Key rule:** CLAUDE.md should always reference PROJECT_STATE.md at the top. This creates a two-layer system: CLAUDE.md has the permanent patterns, PROJECT_STATE.md has the current state.

See `templates/CLAUDE.md` for the full template.

### `PROJECT_STATE.md` — The Living Snapshot

**What:** A standalone document that captures where the project stands RIGHT NOW. Updated at the end of every work session. Readable by both Claude Code and humans.

**When to update:** End of every session. After deploys. After major milestones.

**What belongs here:**
- Current sprint/phase and status
- What's live in production
- What's in progress
- Key metrics (test count, migration count, etc.)
- Recent completions
- Immediate priorities

**Key rule:** This file is referenced by CLAUDE.md but is standalone — it should make sense to anyone reading it without context. Think of it as the answer to "where are we?"

See `templates/PROJECT_STATE.md` for the full template.

### `.claude/memory/MEMORY.md` — The Memory Index

**What:** An index file that points to topic-specific memory files. Each memory file has frontmatter (name, description, type) and content. Claude Code reads MEMORY.md to find relevant memories, then reads specific files as needed.

**When to update:** When creating or removing memory files. Keep it concise — lines after 200 are truncated.

**Memory types:**
- **user** — Who is the developer? Role, expertise, preferences
- **feedback** — Behavioral corrections ("don't do X, do Y instead")
- **project** — Ongoing work context, team info, deadlines
- **reference** — Pointers to external systems (Jira, Slack, dashboards)

**Key rule:** MEMORY.md is an index, not a memory. Never write memory content directly into it. Each memory gets its own file with proper frontmatter.

See `templates/.claude/memory/MEMORY.md` for the full template.

### `.claude/memory/MEMENTO.md` — Session Continuity

**What:** Rolling notes from each session — what was done, decisions made, next steps. Named after the film where the protagonist writes notes to his future self.

**When to update:** End of every session (ideally automated — see Cron Patterns).

**Format:**
```markdown
### [2026-03-14 4:30pm] Brief description of session
What was done. Key decisions. Gotchas encountered.
Next steps for the next session.

### [2026-03-14 2:15pm] Previous session
...
```

**Key rules:**
- Newest entries at top, oldest drop off at ~50 lines
- Include decisions and their rationale — "why" is more valuable than "what"
- Include blockers and next steps — this is what your future self needs most
- Never include sensitive data (API keys, passwords, PII)

See `templates/.claude/memory/MEMENTO.md` for the full template.

---

## Cron Patterns: Recursive Self-Improvement

The real power of this system is that it improves itself over time. Here are the automation patterns, ordered from simple to advanced.

### Level 1: Manual Discipline (Day 1)

At the end of every session, you or Claude Code:
1. Updates `PROJECT_STATE.md` with current state
2. Appends to `MEMENTO.md` with session summary
3. Creates/updates memory files for any new learnings
4. Updates `CLAUDE.md` if new patterns or gotchas were discovered

This is the minimum viable memory system. It works with zero automation.

### Level 2: Session Hooks (Week 1)

Configure Claude Code hooks to automate memento writing:

```json
// .claude/settings.json
{
  "hooks": {
    "session_end": [
      "echo 'Remember to update PROJECT_STATE.md and MEMENTO.md'"
    ]
  }
}
```

Or add a rule to CLAUDE.md:
```markdown
## Session End Protocol
At the end of every session:
1. Update PROJECT_STATE.md with current state
2. Prepend session summary to MEMENTO.md
3. If any behavioral corrections were given, create/update feedback memory files
4. If CLAUDE.md has stale information, update it
```

### Level 3: Skill Extraction (Month 1)

Set up a weekly/nightly cron that:
1. Reviews recent conversation patterns
2. Extracts behavioral preferences ("user always wants X format")
3. Creates skill memory files automatically
4. Merges overlapping skills (>70% topic similarity)

This is the "sleep cycle" — consolidation happens offline, and the next session benefits from distilled patterns.

**Implementation pattern:**
```
Cron triggers → Fetch recent conversations →
LLM extracts patterns → Dedup against existing skills →
Update/create memory files → Prune stale entries
```

### Level 4: Experience Distillation (Month 2+)

The most advanced pattern. After enough sessions:
1. Extract cross-project lessons (generalized, PII-free)
2. Generate embeddings for semantic dedup
3. Merge similar experiences (>0.85 similarity = merge, increment count)
4. Promote high-confidence experiences (observed 5+ times → permanent)
5. Decay stale experiences (exponential decay after 30 days of non-access)
6. Soft-archive irrelevant ones (relevance < 0.1 → deactivate)

**The compound effect:** Each session feeds the distillation pipeline. Over months, the system builds a library of battle-tested patterns that make every future session more productive.

### Level 5: Memory Lifecycle Management

```
                    ┌──────────────────┐
                    │   Conversation   │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │    Memento       │ ← Session notes (ephemeral, ~50 lines)
                    └────────┬─────────┘
                             │ nightly consolidation
                    ┌────────▼─────────┐
                    │   Experience     │ ← Generalized lessons (growing)
                    │   (with decay)   │
                    └────────┬─────────┘
                             │ 5+ observations
                    ┌────────▼─────────┐
                    │  Permanent Skill │ ← Battle-tested patterns (never decay)
                    └──────────────────┘

    Decay: experiences not accessed in 30+ days → relevance *= 0.95^days
    Archive: relevance < 0.1 → soft delete
    Promote: observation_count >= 5 → permanent skill (never decays)
```

---

## The Intelligence Stack

Layer these on top of each other for compounding returns:

```
Layer 5: Cross-Project Intelligence
         Portable lessons across all your repos
         ↑
Layer 4: Automated Distillation
         Nightly extraction, dedup, decay, promotion
         ↑
Layer 3: Behavioral Memory
         Feedback corrections, preferences, patterns
         ↑
Layer 2: Session Continuity
         Memento + PROJECT_STATE updates
         ↑
Layer 1: Project Context
         CLAUDE.md with commands, patterns, gotchas
         ↑
Layer 0: Raw Claude Code
         Stateless, resets every conversation
```

**Each layer multiplies the one below it.** A well-maintained CLAUDE.md (Layer 1) is 10x more effective than raw Claude Code. Add session continuity (Layer 2) and you stop repeating yourself. Add behavioral memory (Layer 3) and the AI stops making the same mistakes. Add distillation (Layer 4) and the system discovers patterns you didn't even know existed.

---

## Design Philosophy

### 1. Intelligence comes from context architecture, NOT code

Don't build complex prompt-injection systems. Build well-structured documents that the AI reads as-is. Mirror Claude Code's own patterns: CLAUDE.md, MEMORY.md, skills files.

### 2. Simplify, never complicate

If your context system is getting more complex while models improve, something is wrong. The model is the engine. The context is the car. Build the car, not more engine.

### 3. Progressive disclosure

Only load what this specific session needs. Rule of thumb: >40% context capacity filled with boilerplate = "dumb zone" where the AI gets confused.

### 4. The Golden Record pattern

One source of truth for each concern. When it changes, update it in one place. Every consumer does a dumb read — zero formatting logic at request time.

### 5. Carry forward the lesson, not the client

When distilling experiences across projects, strip project-specific details. "React Query v5 migration requires updating all useQuery calls to use object syntax" is portable. "The Acme Corp dashboard needs React Query v5" is not.

### 6. Trust the decay

Not everything is worth remembering forever. Exponential decay ensures that irrelevant patterns naturally fade while frequently-used ones strengthen. Only patterns observed 5+ times earn permanent status.

---

## Anti-Patterns

- **Memory hoarding:** Saving everything creates noise. Be selective — only save what would be useful in a FUTURE session
- **Stale CLAUDE.md:** The most common failure mode. If CLAUDE.md says "47 tests" but you have 2,800, the AI will make wrong assumptions
- **Prompt injection:** Never concatenate strings to build prompts at runtime. Context should be pre-written documents loaded as-is
- **Giant monolithic CLAUDE.md:** Split project-specific knowledge across CLAUDE.md (permanent patterns) and PROJECT_STATE.md (current state). CLAUDE.md should grow slowly; PROJECT_STATE.md changes every session
- **Duplicating git history:** Don't save "what changed in commit X" as memory. That's what `git log` is for
- **Ephemeral state in memory:** Don't save "currently debugging the auth bug" — that's for MEMENTO.md or tasks, not permanent memory

---

## Directory Structure

```
your-project/
├── CLAUDE.md                          # Project context (checked in)
├── PROJECT_STATE.md                   # Living snapshot (checked in)
└── .claude/
    ├── settings.json                  # Claude Code settings
    └── projects/
        └── <project-hash>/
            └── memory/
                ├── MEMORY.md          # Memory index
                ├── MEMENTO.md         # Session continuity
                ├── user_profile.md    # Who is the developer
                ├── feedback_*.md      # Behavioral corrections
                ├── project_*.md       # Ongoing work context
                └── reference_*.md     # External system pointers
```

**Note:** The `.claude/` directory is typically in `~/.claude/projects/<project-path>/memory/`, not in the repo root. The `CLAUDE.md` and `PROJECT_STATE.md` files ARE in the repo root and should be checked into version control.

---

## Getting Started

1. **Run the bootstrap script** (see `scripts/bootstrap.sh`)
2. **Fill in CLAUDE.md** with your project's commands, patterns, and gotchas
3. **Write an initial PROJECT_STATE.md** describing where the project stands
4. **Start a Claude Code session** — the system will grow from here
5. **At session end**, update PROJECT_STATE.md and MEMENTO.md (manually at first, then automate)
6. **After a week**, review your memory files and prune anything stale
7. **After a month**, consider implementing Level 3+ automation

The system is designed to be bootstrapped incrementally. Start with CLAUDE.md + PROJECT_STATE.md (5 minutes of setup) and layer on memory, memento, and automation as you see value.

---

## License

MIT. Use it, adapt it, make your AI collaborators smarter.
