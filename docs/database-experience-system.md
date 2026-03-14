# Database-Backed Experience System

For projects with database infrastructure (Supabase, PostgreSQL, etc.), the memory system can be elevated from flat files to a full vector-searchable experience database with automated consolidation, decay, and promotion.

This is the "Level 4+" implementation described in the cron patterns doc.

---

## Schema

### `experiences` table

```sql
CREATE TABLE experiences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Core content
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN (
    'architecture', 'testing', 'deployment', 'debugging',
    'performance', 'security', 'tooling', 'patterns'
  )),

  -- Vector search
  embedding vector(1536),  -- pgvector; adjust dimensions for your model

  -- Lifecycle
  observation_count INT NOT NULL DEFAULT 1,
  confidence FLOAT NOT NULL DEFAULT 0.5,
  relevance_score FLOAT NOT NULL DEFAULT 1.0,
  is_active BOOLEAN NOT NULL DEFAULT true,

  -- Promotion
  promoted_to_skill_id UUID REFERENCES skills(id),

  -- Audit
  source_sessions TEXT[] DEFAULT '{}',  -- Which sessions contributed
  last_accessed_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Vector index for similarity search
CREATE INDEX idx_experiences_embedding
  ON experiences USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 50);

-- Composite index for active experience lookup
CREATE INDEX idx_experiences_active
  ON experiences (is_active, relevance_score DESC);
```

### `skills` table (permanent patterns)

```sql
CREATE TABLE skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT NOT NULL,

  -- Permanence
  is_permanent BOOLEAN NOT NULL DEFAULT false,
  observation_count INT NOT NULL DEFAULT 1,
  confidence FLOAT NOT NULL DEFAULT 0.5,
  is_active BOOLEAN NOT NULL DEFAULT true,

  -- Lineage
  source_experience_ids UUID[] DEFAULT '{}',

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

### Similarity search RPC

```sql
CREATE OR REPLACE FUNCTION match_experiences(
  p_query_embedding vector(1536),
  p_match_threshold FLOAT DEFAULT 0.7,
  p_match_count INT DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  content TEXT,
  category TEXT,
  observation_count INT,
  confidence FLOAT,
  relevance_score FLOAT,
  similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.id,
    e.title,
    e.content,
    e.category,
    e.observation_count,
    e.confidence,
    e.relevance_score,
    1 - (e.embedding <=> p_query_embedding) AS similarity
  FROM experiences e
  WHERE e.is_active = true
    AND e.embedding IS NOT NULL
    AND 1 - (e.embedding <=> p_query_embedding) > p_match_threshold
  ORDER BY (1 - (e.embedding <=> p_query_embedding)) * e.relevance_score DESC
  LIMIT p_match_count;

  -- Side effect: update last_accessed_at for spaced repetition
  UPDATE experiences
  SET last_accessed_at = now()
  WHERE experiences.id IN (
    SELECT e2.id
    FROM experiences e2
    WHERE e2.is_active = true
      AND e2.embedding IS NOT NULL
      AND 1 - (e2.embedding <=> p_query_embedding) > p_match_threshold
    ORDER BY (1 - (e2.embedding <=> p_query_embedding)) * e2.relevance_score DESC
    LIMIT p_match_count
  );
END;
$$;
```

---

## Consolidation Pipeline (TypeScript)

### Experience Distiller

```typescript
interface DistilledExperience {
  title: string;
  content: string;
  category: string;
}

interface ExperienceRecord {
  id: string;
  title: string;
  content: string;
  category: string;
  observationCount: number;
  confidence: number;
  relevanceScore: number;
  similarity?: number;
}

const DISTILLATION_PROMPT = `You are analyzing developer-AI interactions to extract
PRACTICE EXPERIENCE — reusable development wisdom.

Extract lessons that would help with OTHER projects. Think patterns, not specifics.

CRITICAL RULES:
1. STRIP ALL SPECIFICS — No project names, file paths, URLs, API keys, team names
2. GENERALIZE — "For the Acme auth system..." → "For JWT auth systems..."
3. Only extract genuinely reusable insights
4. Each experience should be self-contained and actionable

For each lesson, provide:
- title: short descriptor (e.g., "React Query v5 Migration Pattern")
- content: the generalized lesson (2-4 sentences)
- category: architecture | testing | deployment | debugging | performance | security | tooling | patterns

Respond in JSON: { "experiences": [{ "title": "...", "content": "...", "category": "..." }] }
If no meaningful experiences can be extracted, return: { "experiences": [] }`;
```

### Merge Logic

```typescript
async function mergeExperience(
  db: DatabaseClient,
  experience: DistilledExperience,
  sessionIds: string[],
): Promise<'merged' | 'inserted'> {
  // Generate embedding
  const embedding = await generateEmbedding(
    `${experience.title}: ${experience.content}`
  );

  // Search for similar existing experiences
  const matches = await db.rpc('match_experiences', {
    p_query_embedding: embedding,
    p_match_threshold: 0.85,
    p_match_count: 1,
  });

  if (matches.length > 0) {
    const match = matches[0];
    // Merge: update content, increment observation count
    await db.update('experiences', match.id, {
      content: experience.content,
      observation_count: match.observation_count + 1,
      confidence: Math.min(1.0, match.confidence + 0.1),
      relevance_score: 1.0,  // Reset decay on re-observation
      last_accessed_at: new Date().toISOString(),
      source_sessions: [...match.source_sessions, ...sessionIds],
    });
    return 'merged';
  }

  // Insert new
  await db.insert('experiences', {
    title: experience.title,
    content: experience.content,
    category: experience.category,
    embedding: JSON.stringify(embedding),
    source_sessions: sessionIds,
  });
  return 'inserted';
}
```

### Skill Promotion

```typescript
async function promoteToSkill(
  db: DatabaseClient,
  experience: ExperienceRecord,
): Promise<string | null> {
  if (experience.observationCount < 5) return null;

  // Check for existing matching skill
  const existingSkills = await db.query('skills', {
    is_active: true,
  });

  const matchingSkill = existingSkills.find(s =>
    skillsOverlap(s.title, experience.title, s.category, experience.category)
  );

  if (matchingSkill) {
    // Update existing skill
    await db.update('skills', matchingSkill.id, {
      is_permanent: true,
      confidence: Math.max(matchingSkill.confidence, 0.9),
      observation_count: experience.observationCount,
      source_experience_ids: [experience.id],
    });
    return matchingSkill.id;
  }

  // Create new permanent skill
  const newSkill = await db.insert('skills', {
    title: experience.title,
    content: experience.content,
    category: experience.category,
    confidence: 0.9,
    is_permanent: true,
    observation_count: experience.observationCount,
    source_experience_ids: [experience.id],
  });

  // Mark experience as promoted
  await db.update('experiences', experience.id, {
    promoted_to_skill_id: newSkill.id,
  });

  return newSkill.id;
}

function skillsOverlap(
  titleA: string, titleB: string,
  categoryA: string, categoryB: string,
): boolean {
  if (categoryA !== categoryB) return false;
  const wordsA = titleA.toLowerCase().split(/\s+/);
  const wordsB = titleB.toLowerCase().split(/\s+/);
  const intersection = wordsA.filter(w => wordsB.includes(w));
  const union = new Set([...wordsA, ...wordsB]);
  return (intersection.length / union.size) > 0.7;
}
```

### Exponential Decay

```typescript
async function decayExperiences(db: DatabaseClient): Promise<{
  decayed: number;
  archived: number;
}> {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  // Fetch stale experiences (not accessed in 30+ days, not promoted)
  const staleExperiences = await db.query('experiences', {
    is_active: true,
    promoted_to_skill_id: null,
    last_accessed_at: { lt: thirtyDaysAgo.toISOString() },
  });

  let decayed = 0;
  let archived = 0;

  for (const exp of staleExperiences) {
    const lastAccessed = new Date(exp.last_accessed_at);
    const daysStale = Math.floor(
      (Date.now() - lastAccessed.getTime()) / (24 * 60 * 60 * 1000)
    ) - 30;

    const decayFactor = Math.pow(0.95, daysStale);
    const newScore = (exp.relevance_score ?? 1.0) * decayFactor;

    if (newScore < 0.1) {
      // Soft archive
      await db.update('experiences', exp.id, {
        is_active: false,
        relevance_score: newScore,
      });
      archived++;
    } else {
      // Decay
      await db.update('experiences', exp.id, {
        relevance_score: newScore,
      });
      decayed++;
    }
  }

  return { decayed, archived };
}
```

---

## Context Injection

When assembling the AI's system prompt, inject experiences after project context:

```typescript
function formatExperiences(experiences: ExperienceRecord[]): string {
  if (experiences.length === 0) return '';

  const lines = experiences.map(e => {
    const meta = [e.category, `observed ${e.observationCount}x`]
      .filter(Boolean)
      .join(', ');
    return `### ${e.title} [${meta}]\n${e.content}`;
  });

  return `\n## Practice Experience\n(Lessons learned from your development history)\n\n${lines.join('\n\n')}`;
}
```

### RAG Budget Allocation

```
Total context budget: 100%
├── System prompt + rules: ~10%
├── Project context (CLAUDE.md): ~15%
├── Current task content: ~35%
├── Document/code chunks: ~20%
├── Project memories: ~10%
└── Distilled experiences: ~10%
```

Adjust ratios based on what you have. If no experiences exist yet, reallocate to document chunks.

---

## Security: PII Gate

If your experiences might contain sensitive data, implement a double-gate:

1. **Extraction prompt** instructs the LLM to strip all specifics
2. **Regex gate** catches anything that slipped through

```typescript
function containsSensitiveData(text: string): boolean {
  const patterns = [
    /\b\d{3}-\d{2}-\d{4}\b/,           // SSN
    /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z]{2,}\b/i,  // Email
    /\b\d{3}[.-]?\d{3}[.-]?\d{4}\b/,   // Phone
    /\b(?:sk|pk)[-_](?:live|test)_\w+/i, // API keys
    /\b(?:ghp|gho|github_pat)_\w+/i,    // GitHub tokens
    /\/(?:Users|home)\/\w+\//,           // File paths with usernames
    /https?:\/\/(?!example\.com)\S+/,    // Real URLs (allow example.com)
  ];

  return patterns.some(p => p.test(text));
}
```

**Rule:** If an experience fails the PII gate, reject it entirely. Don't try to redact — the risk of partial redaction is worse than losing the experience.
