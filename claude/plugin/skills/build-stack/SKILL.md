---
name: build-stack
description: Use this skill whenever asked to build an approved stack of PRs or implement a planned milestone. Builds one PR at a time, agent-reviewed, overlapping human review. Not for planning or for reviewing a single existing PR.
---

# build-stack

Build the approved stack one PR at a time. The user has approved the plan, so do not stop to ask between PRs. Stop only for an escalation (below).

## Who does what

- **You, the main session**, orchestrate. You write briefs, run the review, discuss findings with the user and rule on disputes. You are the neutral party between the builder and the reviewer.
- **The `builder` agent** writes the commits and runs every mechanical check. It returns a summary.
- **The `adversarial-reviewer` agent** reviews the draft. It saves its report and returns a digest.

## The loop

The stack starts as draft PRs. For each PR, bottom to top:

1. **Brief.** Start a fresh `builder` for the PR with a build brief (see `agents/builder.md`): the branch and its base, the PR number, the project language, the plan's commit list, the ADRs it completes, the issues it closes and their acceptance, and anything a lower PR decided that this one depends on.
2. **Build.** The builder writes the commits, runs the checks and returns its summary. Push the branch (`gh stack push`). If the commit list changed, update the PR description.
3. **Review.** Run `pr-prep`. It runs the reviewer, settles the findings in the session's mode (below), sends fix briefs to this PR's builder, pushes the fixups and re-reviews until the reviewer returns `CLEAR`.
4. **Ready.** Mark the PR ready (`gh pr ready`). Ready means the agent has cleared it and the user may review. A ready PR is never returned to draft.
5. **Next.** Start the next PR straight away, with a fresh builder. While the user reviews PR N, you build PR N+1. Do not wait on the user.

Run one agent that uses the checkout at a time, a builder or the reviewer, and wait for it to return before starting another: builders switch branches and restack, and the reviewer reads `HEAD`.

Repeat until every PR is ready, reviewed and approved.

Fixes and rebases: the builder makes changes to an earlier commit as `git commit --fixup=<sha>` and restacks with `gh stack rebase`, so upper branches carry lower changes. Push the fixups as they are (do not autosquash yet).

### Modes

- **Discuss** (the default). The user is present. Report each digest line to the user before the fix brief, with your recommendation, and agree what to do.
- **Delegated.** The user has said to carry on without them. Use your own judgement on each finding. Dispute a finding you think is wrong once with the reviewer, with evidence; if it still holds, decide it yourself and log a `dissent` line marked `decided by main session`, so the retro checks your ruling. Do not open issues: a deferral needs the user's agreement, so list each one you propose. Every other escalation below still stops the build. At the end of the stack, report every finding you declined, disputed or propose to defer.

## Footprint

Your context lasts the whole stack, so everything you read stays for every later PR. Hold only briefs, summaries and digests.

- Never read code, full logs or the diff of a PR's work. The builder reads those. To rule on one finding, read only that finding in the report. A command you run only to confirm a diff is empty, as after the user merges, is fine.
- For a search across many files, use the `Explore` agent and keep its conclusion.
- Do not use `fork` subagents. A fork starts with your whole context, which is what this section keeps small.

## Human review

Comments arrive in the dialogue, not as PR replies. Never reply to, resolve or react to PR comments or reviews. Discuss each with the user, then send the agreed fixes as a fix brief to that PR's builder (or a fresh one, if it has ended), with the user's comments as the findings, and push the fixups. If a comment needs a major rework of the PR, run `pr-prep` again. Otherwise there is no further agent review.

When the user edits a PR description before marking it ready, compare the edit with your draft. A pattern in what they cut or rewrote is feedback for `writing.md`: raise it at the retro.

## Finishing

Once every PR is approved and the user says to merge, squash from the bottom up. For each branch in turn, send its builder (or a fresh one) a squash brief and wait for its summary. The builder checks commit hygiene, autosquashes (which folds fixups into the commits they fix and leaves the atomic commits as they are), confirms no content changed, and restacks the branches above.

Then `gh stack push` and `gh stack merge --rebase`. Run the `retro` skill after the last merge.

## After the user merges

A rebase-merge on GitHub gives the merged commits new SHAs. A PR still open above them keeps the old ones, shows conflicts, and may have been added after the stack was planned. Restack each remaining branch onto the trunk:

```bash
git fetch origin
git rebase --onto origin/<trunk> <old parent tip> <branch>
git diff <old tip> <new tip> -- <package>   # empty: only the base changed
git ls-remote origin refs/heads/<branch>    # the lease SHA, read here and never typed
git push --force-with-lease=<branch>:<that sha> origin <branch>
```

Run `just check` on the new tip, and remove "Stacked on #N" from the PR description.

- **Lockfile.** Have a builder regenerate it on the new base (`uv lock`) and check it only adds packages and changes no version. A text merge of a lockfile can be clean and still undo someone's bump.
- **Approvals.** Before the first force-push in a repo you have not pushed to, read its reviews and branch protection. Some repos dismiss approvals on a push (`dismiss_stale_reviews`), and some do not.

## When to stop and ask

Bring the user in, with the options and a recommendation, when:

- **A decision is irreversible or outward-facing**: pushing, opening or merging PRs, deleting, publishing. Ask first, unless the plan already authorised it. An approved stack authorises pushing its branches and marking its PRs ready (see `plan-stack`), not merging.
- **The builder or you disagree with the reviewer**: dispute it once, with evidence (have the builder run something where it can). If the reviewer still holds, the user decides. Once it is ruled, log a `dissent` line saying who was right. In delegated mode this one does not stop the build: see Modes.
- **The plan or an ADR no longer holds**: stop that PR and bring the options. Do not quietly change the design.
- **Conventions conflict** with each other, or with the tooling.
- **Spiral**: the builder reports the same failure after three attempts, or a third review round on one PR is not `CLEAR`.
- **User-visible behaviour is ambiguous** and the plan does not say.

Do not stop for anything the checklist already settles. When blocked on one PR, stop it, note it, and carry on with work that does not depend on it. Speed to the retro matters more than a perfect stack: defer non-blocking problems as GitHub issues and raise them there. In delegated mode, propose them instead (see Modes).
