# Design Philosophy: Building the Car, Not More Engine

These principles emerged from 75 sprints of production development with Claude Code. They apply to any project that uses AI as a development collaborator.

---

## 1. Intelligence Comes from Context Architecture, NOT Code

The single most important lesson: **don't build complex prompt-engineering systems.** Build well-structured documents that the AI reads as-is.

**Wrong approach:**
```javascript
function buildSystemPrompt(user, project, features) {
  let prompt = BASE_PROMPT;
  if (user.isAdmin) prompt += ADMIN_SECTION;
  if (features.includes('billing')) prompt += BILLING_CONTEXT;
  prompt += `\n\nUser name: ${user.name}`;
  prompt += `\n\nProject: ${project.description}`;
  // ... 200 more lines of string concatenation
  return prompt;
}
```

**Right approach:**
```
CLAUDE.md → loaded as-is (project patterns, commands, gotchas)
PROJECT_STATE.md → loaded as-is (current state)
MEMORY.md → index, loaded as-is
Relevant memory files → loaded as-is based on index
```

The AI reads documents. Give it well-written documents. Don't assembly-line prompts from code fragments.

---

## 2. The Golden Record Pattern

One source of truth for each concern. When it changes, update it in one place. Every consumer does a dumb read.

**Example:** Your project's architecture is described in CLAUDE.md. When it changes, update CLAUDE.md. Claude Code reads it at session start. Done.

**Anti-pattern:** Describing architecture in CLAUDE.md, in a `docs/architecture.md`, in code comments, AND in memory files. Now you have four things to update, and they'll inevitably diverge.

**The rule:** For any piece of context, there should be exactly ONE canonical source. Everything else should be a pointer to that source.

---

## 3. Progressive Disclosure

Only load what this specific session needs. The AI gets dumber as context grows — after ~40% of context capacity is filled with boilerplate, the AI enters what we call the "dumb zone" where it starts missing things it would normally catch.

**Practical implications:**
- CLAUDE.md should be concise (commands, patterns, gotchas — not full documentation)
- Memory files are loaded selectively, not all at once
- MEMENTO.md is capped at ~50 lines
- Experiences are searched by similarity, not loaded in bulk
- Context budget should be split: 60% for the actual task, 40% for background

**The test:** If you're loading more context than the current task needs, you're hurting performance.

---

## 4. Simplify, Never Complicate

If your AI harness is getting more complex over time while models improve, something is wrong. Models get better at understanding natural language, reasoning, and following instructions. Your infrastructure should get simpler in response, not more complex.

**Symptoms of over-engineering:**
- Prompt templates with 10+ variables
- Complex routing logic to decide which prompt to use
- Multiple layers of "context builders" that assemble prompts from fragments
- Retry/fallback logic for "prompt didn't work" scenarios
- Custom parsers for model output (when you could just ask for JSON)

**The ideal trajectory:**
```
Month 1: Complex prompt system with 2,000 lines of orchestration code
Month 6: Simplified to structured documents + 200 lines of loading logic
Month 12: Just well-written markdown files, loaded as-is
```

---

## 5. The Model is the Engine. The Context is the Car.

You can't improve the engine (that's the model provider's job). You CAN build a better car. The car is:
- **The documents** it reads (CLAUDE.md, PROJECT_STATE.md, memory files)
- **The structure** of those documents (frontmatter, sections, formatting)
- **The freshness** of those documents (updated every session, not every quarter)
- **The relevance** of what's loaded (progressive disclosure, not dump everything)

Build the car. Let Anthropic/OpenAI/Google build better engines.

---

## 6. Trust the Decay

Not everything is worth remembering. A memory system without decay is a hoarder's attic — eventually, the noise drowns out the signal.

**Design for forgetting:**
- Memento entries naturally fall off after ~15 sessions
- Experiences decay exponentially after 30 days of non-use
- Only patterns observed 5+ times earn permanent status
- Soft-archive (deactivate, don't delete) so nothing is truly lost

**The mental model:** Your memory system should act like a garden. New ideas are planted, promising ones are watered (accessed, reinforced), and neglected ones are pruned. The garden stays healthy because of the pruning, not despite it.

---

## 7. Carry Forward the Lesson, Not the Client

When extracting reusable experiences from project-specific interactions, strip the specifics and keep the pattern.

**Before (project-specific):**
> "For the Acme Corp dashboard migration to React Query v5, we had to update all useQuery calls from positional args to object syntax. The analytics page was the hardest because it had 12 nested queries."

**After (portable):**
> "React Query v5 migration: all useQuery calls must change from positional args to object syntax. Components with deeply nested queries (5+) should be migrated bottom-up to prevent intermediate breakage."

The second version is useful in ANY React Query v5 migration. The first is only useful for Acme Corp.

---

## 8. Feedback is Your Most Valuable Signal

Every time you correct the AI, you're generating training data for your specific workflow. Most people let these corrections evaporate. Capture them.

**High-value corrections to save:**
- "Don't do X" — save as feedback memory with rationale
- "Always do Y before Z" — save as process feedback
- "Use X format, not Y" — save as preference feedback
- "That's wrong because..." — save the "because" part

**Low-value corrections to skip:**
- One-off factual corrections ("the port is 3001, not 3000")
- Typo fixes
- Corrections about things that are obvious from code

**The litmus test:** Would this correction be useful in a FUTURE session? If yes, save it.

---

## Summary: The Six Rules

1. **Documents over code** — write markdown, not prompt builders
2. **One source of truth** — golden record for each concern
3. **Load less, not more** — progressive disclosure beats context dumping
4. **Simpler over time** — if it's getting complex, you're doing it wrong
5. **Build the car** — context quality is your competitive advantage
6. **Earn permanence** — let decay handle curation, trust the process
