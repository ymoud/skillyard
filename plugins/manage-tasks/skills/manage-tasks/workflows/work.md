<required_reading>
1. `references/task-model.md`: statuses, transitions, Status Info
2. Code tasks: the project's `review-checklist.md` (its compliance gates apply to every method you write) and `{coding_standards}` when set
3. When asked to review code in standby mode: `references/code-review-process.md`
</required_reading>

<process>
<step name="select_task">
With an ID, use it. Otherwise list:
- each `In Progress` task as "Resume #{ID} - {Title} ({assignee})",
- then each `Pending` or `Reopened` task as "Start #{ID} - {Title} ({assignee}, {status})",
- then "pick from the backlog" and "cancel".

Each option carries the full `#{ID}`, so a typed reply can be matched. A typed ID is looked up in `ongoing.md`, then `backlog.md`; if it is in neither, say so and ask again.

- **Resume:** skip to `setup_branch`, then `plan_the_work`.
- **Start:** continue with `confirm_and_start`.
- **Pick from the backlog:** show the top backlog tasks by priority and ask which. Check capacity, move the row to `ongoing.md` (status `Pending`, *Started On* and *Updated* today), and move the file `-To ongoing` (`<move_task_files>` in SKILL.md).
- **Cancel:** go to shared completion.
</step>

<step name="confirm_and_start">
1. Read the task file and show it:

   ```markdown
   ## Task #{ID}: {Title}
   **Category:** {category} · **Priority:** {priority} · **Assignee:** {assignee}

   ### Problem
   ### Solution
   ### Acceptance Criteria
   ```
2. Ask whether the approach is right, or whether to discuss changes first. Update the task file with any change. If the approach needs approval before work starts (the task or the README says so, or the user does), set `Design Approval Pending` in both places, apply `after-change`, and stop.
3. If the task has no assignee, or someone else's, confirm or set it, in the config's `assignee_form`. Look up the full form of a person in `history.md` when needed.
</step>

<step name="setup_branch">
Code tasks only. Pick the code repository by the Tasks rule of the config's code repositories.

- **Task branch** (`task-branch`, and the assignee is not in `base_branch_assignees`): if `task-{ID}` exists (`git branch -a | grep -i "task-{ID}"`), `git checkout task-{ID} && git pull`. Otherwise `git checkout {base_branch} && git pull && git checkout -b task-{ID}`.
- **Base branch:** `git checkout {base_branch} && git pull`. Commit messages carry `{commit_task_marker}`, so the review can find them.

If a pull fails, show the error and ask how to proceed. Do not retry.

Then set `In Progress` in the task file and in `ongoing.md`: *Started On* if it is empty, *Updated* today, a Log line if the template has a Log. Apply `after-change`.
</step>

<step name="plan_the_work">
From the Problem and the Solution, find what the task changes: code files with symbolic tools when they are available (`get_symbols_overview`, `find_symbol`, `search_for_pattern`), otherwise Grep and Glob; documents with Grep and Read. Propose an order by dependency (models before services, services before controllers). Apply the `work` extension point: files to leave alone, extra checks.

Ask how to proceed:
1. **Guided:** I propose each change and you approve it
2. **Autonomous:** I make every change, then you review the result
3. **You implement, I stay available**
4. **Back to the menu**
</step>

<step name="guided">
For each item, in order:
1. Read the code (symbols first, then the bodies you need) and the patterns around it.
2. Propose the change and why. Make it once the user approves.
3. Check every new or changed method against the compliance gates in `review-checklist.md`. Refactor before moving on if one fails.
4. Build, with the code repository's Build command.
5. Name the tests that cover the change, as a narrow command from its Test pattern, with its Test notes. Do not run them unless the user asks.

Then go to `finish_work`.
</step>

<step name="autonomous">
**Phase 1, change:** make every change in dependency order, checking each method against the compliance gates as you go.

**Phase 2, build:** build until it is clean. Name the tests; do not run them unless the user asks.

**Phase 3, report:**

```markdown
## Implementation Summary

### Files Changed
| File | What Changed |
|------|--------------|

### Compliance Gates
| Gate | Status |
|------|--------|

### Build
{Succeeded / failed, with details}

### Tests to Run (Developer)
The agent does not run tests. Run these to confirm:
| Test project / filter | Command |
|-----------------------|---------|

### Key Decisions
- {choices worth knowing, including any **Decided** ones}
```

Wait for the user's review. Apply requested changes, then build and check the gates again. Then go to `finish_work`.
</step>

<step name="standby">
The developer implements; you stay available. Show a short brief, then wait:

```markdown
You're on `{branch}`. Task #{ID}: {Title}
**Approach:** {recap of the Solution}
**Key areas:** {what plan_the_work found}

Ask me whenever you like: review what you've written, explain existing code, weigh two approaches, find a pattern in the codebase, build and read the errors, draft a method, check the work against the acceptance criteria. I don't run tests on my own: I'll name the ones that cover your change, and run one if you ask.
```

- Answer whatever the developer asks. Do not prompt them or check in uninvited.
- When asked to review code, read `references/code-review-process.md` first and apply its checklist with the project checks: targeted feedback grounded in the project's rules, not generic advice.
- When the developer says they are done, go to `finish_work`.
</step>

<step name="decide_then_ask">
Whenever the work needs someone else's answer, follow `<decide_then_ask>` in SKILL.md: recommend, settle it with the user, label it **Decided** in the task file, make sure the question reaches its owner, and carry on. Keep the Log current: what was done, what was asked of whom, decisions.
</step>

<step name="finish_work">
1. Tick the acceptance criteria that are met.
2. Set the next status in the task file and in `ongoing.md`, with *Updated* today:
   - `review_process: full`: `Review Pending`, with `- Review Since: {today}`. If the reviewer says no review is needed, take the Complete path below instead.
   - `review_process: none`: `Complete`. Apply the `complete` extension point, move the row to the top of `history.md`, and move the file `-To history`.
3. Add a Log line. Apply `after-change`. Go to shared completion.
</step>
</process>

<success_criteria>
- The task was started or resumed on the right branch, with its status set in both places
- Every new or changed method meets the compliance gates, and the build is clean
- The tests covering the change were named, and run only if the user asked
- Questions for others were decided, recorded and passed to their owners, and none stopped the work on its own
- The task ended `Review Pending` or `Complete`, with `complete` and `after-change` applied
</success_criteria>
