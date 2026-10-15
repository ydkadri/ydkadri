# Writing

How to write ADRs, PR descriptions, docs and commit messages so they are quick to read.

**The reader knows nothing about this work.** They want two things: **what** changed or was decided, and **why**. Everything else is detail they can find in the diff.

## Rules

- **Bullets, examples and short statements beat paragraphs.** One fact per bullet. If a paragraph lists things, make it a list.
- **Take a position.** State the decision. Do not offer a menu of options without a recommendation. Name a rejected option only if the reader would otherwise ask "why not that?", and give the reason in one line.
- **Be concise and clear.** Name the thing. No metaphors, no scene-setting, no filler words such as "robust", "seamless", "leverage", "comprehensive" or "ensure". Ask of each sentence, phrase and word: can I remove it without losing meaning? If so, remove it. A sentence that adds only detail the reader does not need to get the what and the why goes too.
- **Say each fact once.** If a reference doc holds the keys, rules or values, link to it. Do not copy them.
- **An example is worth more than a description.** Show the input and output, or the config, in a few lines.
- **No dashes as punctuation.** Use a full stop, a colon or a comma.

## Context in an ADR

Context says why a decision was needed. It is the problem and the forces, not a tour of the code.

- State the problem in the first sentence.
- List only the facts that make the decision necessary. Each is a bullet.
- Leave out how the system works today unless the decision depends on it.

## Examples

```
❌ The system currently makes use of a robust mechanism whereby batches are
   translated, in a number of different ways depending on the engine, which
   we feel could potentially be improved in a variety of respects.

✅ nosparkio re-derives the catalog, bucket and schema name from a legacy
   file that does not hold them. The new file states them.
```

```
❌ We considered several approaches. Option A would be to rebuild the legacy
   output, while option B would be a new directory, and option C would be to
   do nothing. Each has trade-offs.

✅ Write a new `standard/ingestion` file for nosparkio only.
   - Rejected: rebuild the legacy output first. It proves a model against
     output nothing reads.
```

## Checklist

- [ ] Could the reader act on this knowing nothing else?
- [ ] Is every paragraph that lists things a list?
- [ ] Is there a decision, not a menu?
- [ ] Is anything here already said in a linked doc?
- [ ] Can any sentence, phrase or word go without losing meaning? Any filler word or dash?

---

**Last Updated**: 2026-10-16
