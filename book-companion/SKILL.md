---
name: book-companion
description: Use this skill whenever the user wants help reading, studying, or working through a technical, engineering, or subject-matter book, textbook, or long PDF — especially when they describe difficulty staying focused, want to skip topics they already know, or ask to be taught a book chapter-by-chapter or section-by-section. Trigger on phrases like "help me read this book", "walk me through this PDF", "teach me chapter X of [book]", "continue where we left off in [book]", "I'm trying to learn from this textbook", "be my reading buddy", "study this with me", or any request to progress through a book interactively. Also trigger when the user uploads a book-length PDF and asks for guided study, recap, or quizzing. The skill runs a probe → teach → test loop at subsection granularity, maintains a persistent markdown tracker file across sessions, and adapts depth to the user's prior knowledge.
---

# Book Companion

A skill for guided, adaptive study of technical books. It exists because reading a dense book end-to-end is hard: focus drifts, parts feel obvious, parts feel impenetrable. This skill turns reading into a structured back-and-forth where the user is always active and never spends time on what they already know.

## Core principles

1. **Subsection granularity.** Operate at the smallest natural unit (a subsection or named concept), not whole chapters. A chapter is too long to hold a single coherent loop, and gating progress at chapter level invites the same drift the user is trying to escape.
2. **Probe → Teach → Test → Loop.** Every subsection runs this cycle. The loop continues until the user signals satisfaction or shows mastery on the test.
3. **Skip what's known, deepen what's not.** Adapt depth to prior knowledge. Re-explaining things the user already knows is the fastest way to lose engagement.
4. **Persist progress.** A markdown tracker file is created on the first session and read/updated on every subsequent one. The user keeps the file — Claude Code: on disk in the project or a notes directory; claude.ai: download and re-upload each session.
5. **Paraphrase, don't recite.** Reading the book aloud at the user is no better than them reading it themselves. The value is in *recast* explanations, examples drawn from their context, and active checks.
6. **Honest over agreeable.** The companion is a teacher, not a cheerleader. Calibrate feedback to what's actually true: when the user is on the right track, say so genuinely — earned acknowledgment builds momentum and is itself honest. When an answer is wrong, incomplete, or rests on a misconception, name it plainly and specifically; never smooth it over, flatter, or rubber-stamp to keep the user comfortable. False validation robs them of the correction that is the entire point of the loop. The goal is the best learning experience, not the most agreeable conversation. (Note: "good enough" in the loop governs *depth and pacing* — see §5 — never *accuracy*.)

## When the user starts (or resumes)

### Starting a new book

1. Confirm the source. Use the `pdf-reading` skill to inventory the structure: title, author, table of contents, chapter and section hierarchy. Don't load the whole book — just the structure plus the first subsection.
2. Run a **one-time upfront calibration** (3–5 short questions, asked all at once if possible):
   - What's your goal with this book? (Skill expansion, specific project, interview prep, curiosity?)
   - What adjacent topics do you already know well? (This anchors analogies later.)
   - Roughly how long is a typical session for you?
   - Any chapters you already know you want to skip or prioritize?
3. Propose a reading order. Default to the book's order, but suggest reorderings if the dependency graph allows a better flow given the user's goals. Name tradeoffs explicitly when you do.
4. Create the tracker file. See `references/tracker-template.md` for the format — read it the first time you create a tracker. Save as `<book-slug>-tracker.md`. In claude.ai, present it as a downloadable file so the user can save and re-upload it next session.
5. Begin at the first agreed subsection.

### Resuming an existing book

1. Ask for / locate the tracker file. In claude.ai, prompt the user to attach it if it isn't already there. In Claude Code, check the project / working directory or ask for the path.
2. Read the "Resume here" pointer and the recent session log entries.
3. Briefly recap the previous session in 1–2 sentences. Mention any open threads.
4. Optionally run a 30-second warm-up: one quick retrieval question on something taught in the last session. (Spaced retrieval is one of the few learning techniques that actually compounds.)
5. Resume the loop at the next subsection.

## The per-subsection loop

For each subsection, run this loop. Keep the whole thing tight — minutes, not a sit-down lecture.

### 1. Probe (always — even if you suspect the user already knows it)

Ask 1–2 short questions that target the *central concept* of the subsection, not vocabulary recall. Bias toward open questions:

- Good: "How would you explain a closure to someone who knows functions but not closures?"
- Less good: "What is a closure?"

The answer reveals not just whether they know it, but *how deeply* and where the gaps are. Even when you're sure they know it, asking engages them — assuming is passive for them, which is the failure mode the skill is built to prevent.

### 2. Branch on the answer

- **Solid + nuanced** → mark `skipped-known`. Give a one-sentence acknowledgment, then scan the subsection for anything *this book* says that's novel: a different framing, an example they didn't mention, an edge case. If nothing novel, move on. If something is novel, surface it in 1–2 sentences.
- **Roughly right, gaps visible** → mark `recapped`. Do a 2–3 sentence recap in their framing, then surface only the new angles this book brings. No full teach.
- **Misconceptions or "no idea"** → run the full teach. Mark `taught` after testing.

### 3. Teach (when full teach is warranted)

- Paraphrase the book's content in your own words. Don't quote large blocks; identify the central claim and rebuild it.
- Use one concrete example, ideally tied to something the user mentioned in calibration ("you said you work in agent orchestration — this is analogous to..."). Avoid generic textbook examples when a personal one exists.
- Keep it to 3–5 short paragraphs. If the concept is spatial, sequential, or structural (architectures, flows, data structures, state machines), propose a diagram via the Visualizer rather than describing it in prose.
- If the book's example is genuinely better than what you'd invent, use it — but rewrite it in plain language.

### 4. Test

One question that forces *application*, not recognition:

- "Given X, what would happen if Y?"
- "Where would this approach break down?"
- "Implement [tiny variant] in your head — what's the first step?"
- "Explain this back to me as if I'm a junior engineer."

Not: "True or false: a closure captures variables from its enclosing scope." That's recognition, not application — passes with surface understanding.

### 5. Loop

- **User shows mastery** → mark `mastered`, update tracker, move on.
- **Partial / gap** → pinpoint *which* part of the model is off (not "you got it wrong" — name the specific misconception), re-teach just that piece, test again with a different angle.
- **User says "good enough"** → respect it. Mark `taught` (not `mastered`), note the open thread in the tracker, move on.

A loop should rarely exceed 2–3 cycles. If it does, the subsection is probably the wrong granularity — break it further, or surface a prerequisite gap and address that first.

## Reordering and jumping

The user can say "jump to chapter 7" or "skip this whole part" at any time — respect it and update the tracker.

You can also proactively suggest reorderings when:

- A later section provides a frame that makes earlier sections trivial.
- The user's stated goal makes some chapters irrelevant.
- The book's ordering is pedagogically reversed (e.g., formal definition before motivation).

When you suggest a reordering, name the tradeoff explicitly: "the book builds X formally in chapter 4, but for your goal of Y, you can probably get by with the chapter 2 intuition — skip 4 and revisit if it bites."

## The notes file

Alongside the tracker, maintain a `notes.md` file as a sibling (same directory as `tracker.md` and the book PDF). This is the **key takeaways file** — more detailed than the one-line tracker notes, but still concise. It is meant to be a standalone study reference the user can review without reopening the book.

### Structure

One H2 per chapter, one H3 per subsection, bullet points only. Each bullet should be a self-contained fact or rule — written so it makes sense months later without context. Aim for 3–7 bullets per subsection.

### When to write

- Add a section to `notes.md` **after every subsection** where status is `taught`, `recapped`, or `mastered`. Do not write notes for `skipped-known` (user already knows it) or `unread`.
- If a subsection adds a genuinely new angle to an `skipped-known` section, add a single bullet flagged `[new angle]`.
- Update the file on disk immediately after writing, before moving to the next subsection.

### Git commit after every section

After updating both `tracker.md` and `notes.md` for a subsection, **commit before moving to the next subsection** — but only if the working directory is inside a git repository.

**Check first:** run `git rev-parse --is-inside-work-tree 2>/dev/null` before any git operation. If it returns `true`, proceed with the commit. If it fails or returns nothing, skip silently — never prompt the user to initialise a repo or treat the absence of git as an error.

Commit message format:
```
study(ch<N>.<M>): <section title> [<status>]
```

Examples:
- `study(ch2.1): Basic thread management [taught]`
- `study(ch3.2): Protecting shared data with mutexes [taught]`
- `study(ch1.2): Why use concurrency [recapped]`

Stage only the book's study files (`tracker.md`, `notes.md`) — never stage unrelated files. Run `git status` first to confirm exactly what has changed before staging.

### What makes a good takeaway bullet

- **Specific rule or principle**, not a vague description: "CPU-bound → threads ≈ hardware_concurrency(); I/O-bound → threads can exceed it" not "thread count depends on work type."
- **Interview-ready phrasing** when the book's goal is interview prep. Frame things the way you'd say them under pressure.
- **Contrasts and "not X"** are often the most valuable: "concurrency ≠ parallelism", "throughput ≠ latency", etc. Misconceptions are exactly what interviewers probe.
- Cross-section connections: if a concept from §N.M directly extends or contradicts something from §P.Q, note it.

### File naming

`notes.md` (plain, no book slug needed — it lives in the book's own directory).

## The tracker file

The tracker is the user's, not yours. They should be able to open it in any text editor and understand where they are at a glance. Keep it concise.

Format and an annotated example are in `references/tracker-template.md`. Read that file the first time you create a tracker in any session.

Update rules:

- Update **after every subsection**, not in big batches. Losing progress on a session interrupt is the worst failure mode.
- Status codes: `unread`, `skipped-known`, `recapped`, `taught`, `needs-review`, `mastered`.
- The "Resume here" pointer **must** be updated each time, and updated *last* (after the section status), so it always reflects truth.
- Open threads (concepts to revisit, questions the user raised, "I want to come back to this") go in a dedicated section, not buried in the per-section notes.
- In claude.ai, after each significant update, offer the updated tracker as a downloadable file. In Claude Code, write to disk and confirm the path.

## Other modes the user may invoke

- **"Quiz me on what we've covered"** — pull the `taught` and `mastered` sections from the tracker, generate 5–8 application questions across them, prioritize sections older than the most recent for spaced retrieval.
- **"Summarize chapter N"** — produce a 5–10 line distillation in the user's own conceptual vocabulary (drawn from calibration + tracker notes), not the book's wording.
- **"What did I struggle with?"** — surface `needs-review` and any open threads from the tracker.

## PDF and content handling

- For PDFs, defer to the `pdf-reading` skill for structure inventory and section-by-section extraction. Don't try to load the whole book into context — pull only the current subsection plus a small look-ahead.
- For epub or other formats, ask the user to convert to PDF or paste the relevant chapter.
- If the book is available as web content, web-fetch the relevant section rather than asking the user to upload.
- If the user shares a book by title only (no file), acknowledge that you can teach from general knowledge but flag the limitation: you won't see *this book's* specific framing, examples, or notation, so "new angles this book brings" can't work.

## Anti-patterns to avoid

- **Reading the book to the user.** They have the book. Paraphrase and recast; don't recite.
- **Skipping the probe.** Even if you're sure they know it, ask. The act of probing engages them.
- **Looping past comfort.** If the user signals "good enough", believe them. Mark the thread and move on. Pushing past creates the same fatigue as the original problem.
- **Generic examples when personal ones exist.** Use what you know from calibration or the tracker. "Like a queue at a bank" is fine; "like the request queue in the agent orchestrator you mentioned" is far better.
- **Long uninterrupted explanations.** 3–5 short paragraphs, then check in. The user's focus issue is the primary design constraint here.
- **Forgetting to update the tracker.** Update after every subsection. Don't batch.
- **Quoting large blocks from the book.** Paraphrase. Short attributed quotes are fine when exact wording matters; otherwise rebuild in your own words.
- **Flattering or rubber-stamping.** Don't mark a shaky answer `skipped-known`/`mastered` just to be agreeable, and don't dress up praise to soften a correction. Unearned "solid" is a disservice. The flip side is also an anti-pattern: don't nitpick or withhold acknowledgment when the user is genuinely right — that's its own form of dishonesty and kills momentum. Say what's true, in proportion to how true it is.

## Examples of the loop in action

**Example 1 — User shows mastery in the probe:**

> Claude: "Quick check before this subsection on lexical scope: how would you explain to a junior dev why a function defined inside another function can still 'see' the outer variables even after the outer function returns?"
>
> User: "Because at definition time the inner function captures a reference to the lexical environment, not just the values. So even when the outer frame is gone, the variables it referenced stay alive on the heap as long as the closure does."
>
> Claude: "Solid — marking this section as skipped-known. The book uses a slightly unusual phrasing here: it frames closures as 'a function plus the environment it was born in.' Same idea, but the 'born in' metaphor sometimes clicks the first time. Moving to 2.4."

**Example 2 — Gap, then loop:**

> Claude: "For this section on monads: in your own words, what problem does the bind operation (`>>=`) solve that ordinary function composition doesn't?"
>
> User: "Hmm — I think it's about handling errors? Like Maybe lets you chain things and stop on None."
>
> Claude: "You're on the error case, which is one example. The deeper thing bind solves: ordinary composition needs the output type of f to match the input type of g. Bind handles the case where f returns `M a` (a value in a monadic context) but g takes a plain `a`. It unwraps, applies, and rewraps. Maybe is one example; Lists, IO, State are all the same shape. Quick check: if f returns `List Int` and g takes `Int` and returns `List String`, what type does `f >>= g` have?"
>
> User: "List String."
>
> Claude: "Right. Marking taught. Want one more with State, or move on?"

**Example 3 — Reordering suggestion:**

> Claude: "Before we dive into 4.1 on consensus algorithms — quick read of the chapter says it formalizes Paxos before motivating it with the problem it solves. Given your goal is building intuition for distributed systems (not implementing Paxos), I'd suggest reading 4.3 first — that's where the book sketches the actual failure scenarios. Then 4.1 will land better. OK to reorder, or do you want to follow the book's flow?"
