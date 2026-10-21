# Writing

How to write ADRs, PR descriptions, docs and commit messages so they are quick to read.

**The reader knows nothing about this work.** They want two things: **what** changed or was decided, and **why**. Everything else is detail they can find in the diff.

## Rules

- **Bullets, examples and short statements beat paragraphs.** One fact per bullet. If a paragraph lists things, make it a list.
- **Take a position.** State the decision. Do not offer a menu of options without a recommendation. Name a rejected option only if the reader would otherwise ask "why not that?", and give the reason in one line.
- **Be concise and clear.** Name the thing. No metaphors, no scene-setting, no filler words such as "robust", "seamless", "leverage", "comprehensive" or "ensure". Ask of each sentence, phrase and word: can I remove it without losing meaning? If so, remove it. A sentence that adds only detail the reader does not need to get the what and the why goes too.
- **Check every absolute claim.** "Every", "all", "never", "always", "nothing" and "cannot" are claims about all cases. Before writing one, find the test that proves it or look for a case that breaks it. If you cannot, say what you checked ("for all 448 current batches") or drop the absolute.
- **Say each fact once.** If a reference doc holds the keys, rules or values, link to it. Do not copy them.
- **An example is worth more than a description.** Show the input and output, or the config, in a few lines.
- **No dashes as punctuation.** Use a full stop, a colon or a comma.

## Context in an ADR

Context says why a decision was needed. It is the problem and the forces, not a tour of the code.

- State the problem in the first sentence.
- List only the facts that make the decision necessary. Each is a bullet.
- Leave out how the system works today unless the decision depends on it.

## PR descriptions

A reviewer reads the diff. The description tells them what to look for.

- **Open with one sentence: the old thing and the new thing.** "Update X to read `new` instead of `old`." Do not give PR history ("replaces #123") or say what the PR stops doing.
- **One fact per bullet, with no reason attached.** The ADR and the diff hold the why. Split a bullet that joins two facts.
- **Do not narrate how the PR was built.** "Two commits", "one reader, no parallel load" and "both pass on their own" describe the author's work, not the change.
- **Keep "Design choices to review" for choices a reviewer could disagree with**, such as what is kept or removed.
- **Use a list for three or more parallel items.** Names, batches and rollout steps are bullets. Number steps that happen in order, and mark each done or `TODO`, so the PR tracks the rollout.
- **Fill a template section with the minimum.** "Plugin change?" gets "Yes. It needs a rollout restart.", with no reassurance.
- **Put a risk the reviewer cannot fix in a sentence, or tell the user in chat.** Do not write a paragraph.
- **Check names against the code.** A flag, key or file is spelled as it is in the source.

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
- [ ] Does a PR description open with old to new in one sentence, and give each fact a bullet with no reason?
- [ ] Is every name, flag and path spelled as in the code?

---

**Last Updated**: 2026-10-22
