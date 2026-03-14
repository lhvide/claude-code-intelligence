# [Project Name] — Claude Code Context

## Project State
- **Live status doc:** `PROJECT_STATE.md` — current sprint/phase, what's live, what's in progress
- Update `PROJECT_STATE.md` at the end of each work session

## Commands
- Build: `[your build command]`
- Dev: `[your dev command]`
- Lint: `[your lint command]`
- Tests: `[your test command]`
- Single test: `[single test command]`
- Deploy: `[deploy command or process]`

## Architecture
- [Framework and major dependencies]
- [Directory structure overview]
- [Key architectural decisions]

## Code Patterns
- [Auth pattern: how routes are protected]
- [Error handling: how errors are caught and reported]
- [Database access: ORM, raw SQL, query patterns]
- [API patterns: request/response conventions]
- [State management: how state flows through the app]

## Gotchas
- [Things that break in non-obvious ways]
- [Common mistakes and how to avoid them]
- [Platform-specific quirks]
- [Migration or deployment footguns]

## Environment Variables
- [List env vars and what they're for]
- [Which are required vs optional]
- [Which are build-time vs runtime]

## Database
- [Migration system and conventions]
- [Number of migrations, tables, key schemas]
- [Security model: RLS, auth, access control]

## Session End Protocol
At the end of every work session:
1. Update `PROJECT_STATE.md` with what was accomplished and current state
2. Prepend session summary to `.claude/memory/MEMENTO.md` (or equivalent)
3. If behavioral corrections were given during this session, create/update feedback memory files
4. If new patterns or gotchas were discovered, update this file
5. If any TODO items were completed or discovered, update `TODO.md`
