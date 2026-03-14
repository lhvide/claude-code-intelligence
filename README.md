# Claude Code Intelligence

**Give Claude Code a memory.** A portable system of structured markdown files that makes Claude Code smarter with every session — carrying forward lessons, context, and behavioral corrections across conversations and projects.

Born from 75+ sprints of building a production SaaS entirely with Claude Code. These patterns turned a stateless AI into a compounding collaborator.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## The Problem

Every Claude Code session starts from zero. You re-explain your project, re-correct the same mistakes, re-establish your preferences. The AI makes the same wrong assumptions every time.

**Claude Code Intelligence fixes this.** Four structured files give Claude Code persistent memory that compounds with every session you invest.

| Without | With |
|---------|------|
| Re-explain project structure every session | Claude knows your codebase, commands, patterns |
| Same mistakes repeated across conversations | Behavioral corrections persist forever |
| No memory of what was done yesterday | Session continuity picks up where you left off |
| Generic responses, no personalization | Learns your preferences, communication style, and workflow |

---

## How It Works

Four files, layered from permanent to ephemeral:

```
your-project/
├── CLAUDE.md              ← Project constitution (commands, patterns, gotchas)
├── PROJECT_STATE.md       ← Living snapshot (current sprint, what's live)
└── .claude/memory/
    ├── MEMORY.md          ← Memory index (pointers to topic files)
    ├── MEMENTO.md         ← Session notes (rolling, newest first)
    ├── user_profile.md    ← Who you are, how you work
    └── feedback_*.md      ← Behavioral corrections
```

| File | Analogy | Updated | Scope |
|------|---------|---------|-------|
| `CLAUDE.md` | Employee handbook | After sprints | Whole team |
| `PROJECT_STATE.md` | Daily standup | Every session | Whole team |
| `MEMORY.md` | Personal notebook index | When memories change | Per developer |
| `MEMENTO.md` | Sticky notes on monitor | Every session | Per developer |

**The key insight:** Intelligence comes from context architecture, not code. Don't build complex prompt systems — write well-structured documents that the AI reads as-is.

---

## Quick Start

```bash
# Clone
git clone https://github.com/lhvide/claude-code-intelligence.git

# Bootstrap into your project (creates all files, auto-detects project name)
cd your-project
../claude-code-intelligence/scripts/bootstrap.sh

# Or manually
cp claude-code-intelligence/templates/CLAUDE.md ./CLAUDE.md
cp claude-code-intelligence/templates/PROJECT_STATE.md ./PROJECT_STATE.md
```

Fill in `CLAUDE.md` with your project's specifics. Start a Claude Code session. The memory system grows from there.

**Time to value: 5 minutes.**

---

## The Intelligence Stack

Layer these for compounding returns:

```
Layer 5 ─ Cross-Project Intelligence     ← Portable lessons across all repos
Layer 4 ─ Automated Distillation         ← Nightly extraction, dedup, decay
Layer 3 ─ Behavioral Memory              ← Feedback corrections, preferences
Layer 2 ─ Session Continuity             ← MEMENTO + PROJECT_STATE updates
Layer 1 ─ Project Context                ← CLAUDE.md (commands, patterns, gotchas)
Layer 0 ─ Raw Claude Code                ← Stateless. Resets every conversation.
```

Each layer multiplies the one below it. Start at Layer 1 (5 minutes). Add layers as you see value.

---

## Memory Tiers

The system mirrors how the human brain stores information — from working memory to permanent skills:

| Tier | Name | Persistence | Decay |
|------|------|-------------|-------|
| 0 | **Memento** | ~50 lines, rolling | Old entries displaced by new |
| 1 | **Working Memory** | Current conversation | Dies at session end |
| 2 | **Project Memory** | Indefinite | Manual pruning |
| 3 | **Distilled Experience** | Self-regulating | Exponential (0.95^days after 30d) |
| 4 | **Permanent Skills** | Forever | Never. Earned through 5+ observations |

Tier 3+ requires automation (see [Cron Patterns](docs/cron-patterns.md)). Tiers 0–2 work with zero setup.

---

## Recursive Self-Improvement

The real power: every session makes the next one better.

```
Session N → Feedback → Memory → Context → Session N+1 (smarter)
                ↓
         Distillation (async, nightly)
                ↓
         Experience → Dedup → Merge/Insert
                ↓
         Promotion (observation_count ≥ 5)
                ↓
         Permanent Skill (never decays)
```

**Day 1:** Raw model capability.
**Week 1:** Knows your project structure, commands, patterns.
**Month 1:** Remembers your corrections, avoids your pet peeves.
**Month 3:** 50+ distilled experiences from your sessions.
**Month 6:** 15+ permanent skills earned from repeated observation.
**Year 1:** More valuable than a new hire who just read the README.

---

## Works Great With

### [Ruflo](https://ruflo.dev)

Claude Code Intelligence provides the memory architecture. **Ruflo** supercharges it with MCP-powered agent orchestration, swarm coordination, and persistent memory backends. Together they turn Claude Code from a single-session tool into a persistent, multi-agent development system.

- **Memory persistence:** Ruflo's AgentDB provides vector-searchable storage for Tier 3+ experiences
- **Swarm coordination:** Orchestrate multiple Claude Code agents with shared memory
- **Session management:** Automatic session save/restore across conversations
- **Hook automation:** Pre/post task hooks that trigger memory updates automatically

If you're using Claude Code Intelligence at scale — multiple projects, multiple agents, or team environments — Ruflo is the infrastructure layer that makes it sing.

---

## Design Philosophy

Six principles that emerged from production use:

1. **Documents over code** — Write markdown, not prompt builders. The AI reads documents. Give it well-written documents.

2. **One source of truth** — Golden Record pattern. One canonical source per concern. Everything else is a pointer.

3. **Load less, not more** — Progressive disclosure beats context dumping. >40% context capacity filled with boilerplate = "dumb zone."

4. **Simpler over time** — If your AI harness is getting more complex while models improve, something is wrong. The model is the engine. The context is the car.

5. **Carry forward the lesson, not the client** — Strip project specifics when distilling experiences. "React Query v5 requires object syntax" is portable. "The Acme dashboard needs RQ v5" is not.

6. **Trust the decay** — Not everything is worth remembering. Exponential decay ensures irrelevant patterns fade while frequently-used ones strengthen.

---

## Anti-Patterns

| Don't | Why |
|-------|-----|
| Save everything | Noise drowns signal. Only save what's useful in a *future* session |
| Let CLAUDE.md go stale | If it says "47 tests" but you have 2,800, the AI makes wrong assumptions |
| Build prompt concatenation systems | `buildPrompt(user, features, context)` = fragile. Markdown files loaded as-is = robust |
| Put ephemeral state in memory | "Currently debugging auth" → MEMENTO.md, not permanent memory |
| Duplicate git history | "What changed in commit X" → `git log`, not memory |
| Skip the Session End Protocol | The 2-minute investment at session end pays dividends in every future session |

---

## Documentation

| Doc | What it covers |
|-----|---------------|
| [Design Philosophy](docs/design-philosophy.md) | The six principles in depth |
| [Memory Tiers](docs/memory-tiers.md) | Tier 0–4 architecture, decay mechanics, promotion criteria |
| [Cron Patterns](docs/cron-patterns.md) | Automation from session hooks to nightly consolidation |
| [Recursive Improvement](docs/recursive-improvement.md) | How the system gets smarter over time |
| [Database Experience System](docs/database-experience-system.md) | Schema, SQL, TypeScript for DB-backed experiences |

---

## Who Built This

Built by [Leif-Erik Hvide](https://x.com/lelouch_vi_brit), founder of [Sqyro](https://sqyro.com) — an AI-powered practice management platform for attorneys. Every line of Sqyro (91 migrations, 2,100+ tests, 75+ sprints) was built with Claude Code using this memory system.

The system started as survival — managing a complex monorepo across hundreds of Claude Code sessions without losing context. It became the single biggest force multiplier in the entire development process.

---

## License

MIT. Use it, adapt it, make your AI collaborators smarter.
