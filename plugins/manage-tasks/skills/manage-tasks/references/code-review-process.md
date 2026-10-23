<overview>
How to review a task's work: the sources to read, how to read the change, the checklists, the cross-file pass, and the report templates. The project's `review-checklist.md` adds its own checks; the `review` extension point may add exclusions.
</overview>

<sources>
Read these before reviewing. The checklist below applies them; it does not replace them.
- `{coding_standards}`, when the config sets it
- `.claude/manage-tasks/review-checklist.md`, when the project has one: its compliance gates and project checks are part of this review
- The code repository's `CLAUDE.md`, when it has one: architecture rules and conventions
</sources>

<reading_the_change>
Read the change commit by commit with `git show <hash>`. A range `git diff` can be unreliable and hides which commit did what.

- **Task branch:** `git log --oneline task-{ID} ^{base_branch}` lists its commits.
- **Base branch** (`branch_policy: base-branch`, or an assignee in `base_branch_assignees`): `git log --oneline --grep "<marker>" {base_branch}`, where `<marker>` is `{commit_task_marker}` with the ID filled in. If nothing matches, ask the user for the commit range.

For each commit: `git show <hash> --stat --format="%h | %s | %an | %ad"`, then `git show <hash>` for the content.
</reading_the_change>

<report_audiences>
**The review report you present** goes to the reviewer and is triage. A no-action observation may appear there as a one-line aside, labeled as such, so the reviewer can decide whether it matters.

**The task file's review notes** are the developer's permanent record. Do NOT write zero-action observations there: anything you would label "harmless", "no action required", "cosmetic", "note only" or "worth knowing". Write one only if the reviewer explicitly asks.

The test for the task file: name the person who would do something differently after reading the entry. Either the developer changes code, or the entry records a decision nobody should re-litigate. If neither, leave it out. Padding the record spends the developer's attention on nothing and reads as nitpicking work they did on purpose.

Zero-action material, a reviewer aside at most:
- Cosmetic churn: region renames, whitespace, trailing newlines, using order, comment rewording, small tidy-ups next to the real change.
- Restating what the change does without saying anything is wrong with it.

Unrelated changes become findings only when they carry risk: behavior changed outside the task's scope, or a change hidden where the reviewer would miss it. Then the finding is the risk, not the untidiness.
</report_audiences>

<commit_messages>
When task branches are squash-merged, do NOT raise commit message format or wording at all: not in the report, not to the reviewer, not in the task file. Branch messages never reach `{base_branch}`; only the squash subject does. Read commits for *what changed* and judge the code, never the commit prose.

Under `base-branch`, commits land as written, so the repository's commit convention applies and may be checked.
</commit_messages>

<tests>
By default the agent runs NO tests, in review as in implementation. A test run can reach external systems and shared data, and may hang or change them. Deciding a change is "verified" from a run the agent started on its own is exactly the failure this rule prevents.

**Exception:** when the user explicitly asks for a run, run exactly what they asked, narrowest filter first, and report the output.

Otherwise:
- Find the test projects and filters that cover the change, mapped to the acceptance criteria where possible.
- List them in the report's **Tests to Run (Reviewer)** section as ready-to-paste commands built from the code repository's Test pattern, with its Test notes.
- The reviewer runs them and reads the results. Never report a pass or fail you produced unprompted, and never move a task on one.
- If no automated test covers a criterion, say so and describe the manual check.

Builds are fine to run, with the code repository's Build command.
</tests>

<per_file_checklist>
For each changed file, read the changed methods with symbolic tools when they are available (`find_symbol`, `get_symbols_overview`), otherwise with Read and Grep. Find their callers (`find_referencing_symbols`, or Grep) to see the side effects. Then check:

1. **Maintainability**
   - Every compliance gate in `review-checklist.md` (method length, branch points, parameters, or whatever the project sets); without gates, methods short and focused, with few branches and parameters
   - No duplication within the file (across files: the cross-file pass)
   - Error handling at the right level; null and empty cases covered
   - Logging follows the project's conventions
   - Clear names; no dead code, commented-out code or stray TODO comments
   - No hardcoded value that belongs in configuration
2. **Security**
   - Input validated at the API boundary
   - Parameterized queries only; no SQL built by concatenation
   - No sensitive data in logs: passwords, tokens, personal data
   - Authorization checked; fails securely, deny by default
3. **Project checks:** every check under *Project checks* in `review-checklist.md`
4. **Side effects**
   - Callers of the changed code
   - Changed signatures, return types or behavior
   - Backward compatibility, such as a contract another repository consumes
</per_file_checklist>

<cross_file_pass>
The per-file checklist catches problems inside one file. This pass catches the same operation written twice across files. Do NOT run it by scanning for similar-looking code: that finds only verbatim copy-paste and misses the duplication that matters, the SAME OPERATION written with DIFFERENT code. Run it once, after reading every file.

**Step 1: say what each changed region does.** For every changed method or block, write one line naming its *responsibility* as a verb phrase, ignoring how it is coded.
- Good: "registers the in-scope preferences with the external system, idempotently"
- Bad: "has an `isRetry` ternary and two `await` calls"

**Step 2: group by responsibility, not by text.** Two regions with the same phrase are duplication even when the code looks different: different names, `bool` against `bool?`, inline against extracted, success flag against outcome enum. Same operation, different code is the worst kind, because each copy drifts on its own. When you spot a shared fragment, expand outward: if the whole surrounding methods do the same job, the finding is the methods. Abstract to the LARGEST shared responsibility, not the smallest shared snippet.

**Step 3: look for an existing home.** Before concluding the operation is new, search for sibling methods on the relevant base classes and helpers (`find_symbol`, `search_for_pattern`, or Grep), such as an existing `Register*` / `Unregister*` pair. Code that solves an already-solved problem a second way is a finding on its own.

**Step 4: rate it and feed the verdict.**

| What is duplicated | Severity | Required action |
|--------------------|----------|-----------------|
| An operation: multi-step, calls a service or the database, carries business meaning | **Significant** | Name the home; recommend `Reopen` or a follow-up task. Never rate it "acceptable as-is" |
| A non-trivial block copied verbatim | **Significant** | Recommend extraction |
| A language idiom: a few lines, no business logic (null guard, ternary, projection) | Minor | Aside only |

Severity follows WHAT is duplicated, not how many lines match. Every Significant finding appears in the Duplication Assessment AND in the Reviewer Recommendation.

**Worked example.** A change adds the same eligibility gate to three services. Step 1 yields "registers the in-scope preferences with the external system" for both `CreationService` and `RecoveryService.Register`, and "unregisters the in-scope preferences" for both `StatusService` and `RecoveryService.Unregister`. Step 2 groups them: one operation duplicated twice, another twice. Both are Significant, though the code differs (success flag with a compensating action, against `bool?` with an outcome mapping). Step 3 finds the home: a shared base class already hosts the same `Register*` / `Unregister*` pair for another entity, so the new pair belongs there. A text scan would have flagged only a shared `inScope ? book.Recovery : null` idiom and rated it minor. That is the miss this pass exists to prevent.
</cross_file_pass>

<code_report_template>
```markdown
## Code Review Report: Task #{ID}

**Task:** {Title}
**Branch:** `task-{ID}` (base `{base_branch}`), or `{base_branch}` with the commits listed below
**Assignee:** {assignee}
**Status:** {status}

### Task Summary
**Problem:** {from the task file}
**Solution:** {from the task file}

### Commit History
| Commit | Message | Author | Date |
|--------|---------|--------|------|

**Total commits:** X

### Files Changed
| File | Change | Lines | Related Methods |
|------|--------|-------|-----------------|
| `src/path/to/File.cs` | Modified | +25 / -10 | `MethodA()`, `MethodB()` |

Related Methods names the methods or symbols added or changed in each file: the units a reviewer should open, not just the file. For a new file, its key public methods. For config, project files or SQL, a short noun phrase ("package versions", "migration script").

**Summary:** X files changed, +Y insertions, -Z deletions

### Key Locations to Review
1. **{File}** (lines X–Y): {what changed}

### Code Quality
| Aspect | Status | Notes |
|--------|--------|-------|
| Compliance gates | OK / Issue / N/A | |
| Error handling | OK / Issue | |
| Logging | OK / Issue | |
| Naming and style | OK / Issue | |

### Project Checks
| Check | Status | Notes |
|-------|--------|-------|
{one row per check in review-checklist.md; omit the section when the project has none}

### Security
| Check | Status | Notes |
|-------|--------|-------|
| Input validation | OK / N/A | |
| SQL injection | OK / N/A | |
| Sensitive data in logs | OK / N/A | |
| Authorization | OK / N/A | |

### Side Effects
| Method | File | Impact |
|--------|------|--------|

**Breaking changes:** {None / list}
**Backward compatibility:** {OK / concerns}

### Duplication Assessment
| Duplicated Responsibility | Locations | Severity | Home / Action |
|---------------------------|-----------|----------|---------------|

**Consistency with existing patterns:** {OK / diverges from <pattern>: details}

### Acceptance Criteria Check
| # | Criterion | Status |
|---|-----------|--------|

### Tests to Run (Reviewer)
The agent does not run tests. These cover the change; run them and confirm the results:

| Test project / filter | Command | Covers |
|-----------------------|---------|--------|

{If no automated test covers the change, say so and describe the manual check.}

### Reviewer Recommendation
{One paragraph: the assessment and a recommended verdict (Approve / Request changes / Reopen / Approve + follow-up task) with the reason. Every Significant finding appears here, saying what should change and where.}
```
</code_report_template>

<other_task_review>
A task whose deliverable is not code (documents, designs, a request sent to another team, an investigation write-up):
1. Read what it produced: the documents, the designs, the sent request.
2. Check each acceptance criterion against it.
3. Check the docs rules from the README and the docs repository's `CLAUDE.md`: language, terms, labels, links.

```markdown
## Review Report: Task #{ID}

**Task:** {Title} · **Assignee:** {assignee} · **Status:** {status}

### Task Summary
**Problem:** {from the task file}
**Solution:** {from the task file}

### What It Produced
| Artifact | Path |
|----------|------|

### Acceptance Criteria Check
| # | Criterion | Met? | Evidence |
|---|-----------|------|----------|

### Findings
{Numbered findings the author acts on, or "None".}

### Reviewer Recommendation
{Assessment and a recommended verdict, with the reason.}
```
</other_task_review>
