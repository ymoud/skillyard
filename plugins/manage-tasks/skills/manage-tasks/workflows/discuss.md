<required_reading>
1. `references/task-model.md`: Status Info, tracking files, IDs, the task template
2. If the config's `actions` setting is not `off`: `references/actions.md`
</required_reading>

<process>
<step name="understand_case">
1. Let the user describe the case in their own words. If anything is unclear, ask before going further.
2. When actions are on, apply the task-or-action test: could the agent finish this alone, inside a repository? If it needs a person, it is an action: record it (`references/actions.md`) and stop here. If it splits, go on with the agent's part only.
3. Ask the category, from the README's list. The default list is Feature (new functionality), Bug (a defect), Technical (refactoring, infrastructure, design), Investigation (research, timeboxed) and Documentation.
</step>

<step name="gather_details">
1. Clarify the problem and the outcome wanted.
2. Check the claims against the code (symbolic tools when available, otherwise Grep and Read) and the docs. Identify the files affected.
3. A bug: locate the failing code. A feature: find where it fits in the architecture.
4. Summarize your understanding and confirm it with the user.
</step>

<step name="search_related_tasks">
**Mandatory gate.** No task is proposed and no task file is written until this step has run. That holds when the user hands over a fully written task and says "just create it", and when another skill or an investigation sent you here. IDs are unique by construction; content is not. A duplicate is cheap to write and expensive to discover.

**1. Derive at least three search terms**, from different angles:
- the symbol, method or class it touches;
- the file, component or system;
- the domain noun or the symptom (`NullReferenceException`, `empty response`, `timeout`).

A single term is not a search. For a defect, one term MUST be the failing symbol or file: that catches earlier work on the same code.

**2. Search every task folder and tracking file**, plus the actions file when actions are on, plus any location the `create` extension point names:

```bash
cd {tasks_dir}
grep -rlni "{term}" ongoing/ backlog/ history/ ongoing.md backlog.md history.md
```

Repeat per term. For every hit, read the task's title, its Status Info and, if it has one, its Out of Scope section before judging it.

**3. Classify each hit and act:**

| Finding | Action |
|---------|--------|
| **Duplicate**: an open task already covers it | Do NOT create. Show the existing task and ask whether to update it instead |
| **Already done**: a `Complete` task covers it | Do NOT create. Show the task and its completion date. If the behavior is back, call it a regression, explicitly |
| **Superseded scope**: an open task is a superset of it | Do NOT create. Propose folding the case into it |
| **Adjacent**: same file, method or subsystem, a different defect | Create, and cite it on `- Related:` with a clause saying how it differs |
| **Explains the gap**: a past task touched this exact code and scoped this out on purpose | Create, and cite it on `- Related:`, quoting the scope-out. The most valuable reference a reviewer can get: it shows the gap survived a deliberate pass |
| **Nothing found** | Create. Name the terms you searched |

**4. Report before proposing.** Tell the user, in a line or two, what you searched and what you found. Never report "no existing task" without naming the terms: an unnamed search cannot be challenged, and the user is the one who remembers the task you missed.
</step>

<step name="propose_tasks">
Propose one or more tasks:

```markdown
## Proposed Tasks

### Task 1: {Title}
- **Category:** {category} · **Priority:** {priority} · **Effort:** {effort}
- **Summary:** {one or two sentences}
- **Related:** {task IDs from the search, or "none found; searched: {terms}"}
```

- A task over 3 days (`High` effort and beyond) is split.
- Each task has clear acceptance criteria and is deliverable on its own where possible.
- Apply the `create` extension point: its extra fields belong in the proposal.

Ask the user to approve, change or reject each one.
</step>

<step name="determine_task_id">
Take the highest ID across the tables of `ongoing.md`, `backlog.md` and `history.md` and the file names in `ongoing/`, `backlog/` and `history/`. Ignore letter-prefixed IDs. Number the new tasks from that maximum plus one, zero-padded to three digits.
</step>

<step name="create_task_files">
**Precondition:** `search_related_tasks` ran for this case, and no `Duplicate`, `Already done` or `Superseded scope` finding is unresolved. If you got here without it, go back and run it now.

For each approved task:
1. **Placement first**, since it decides the folder. Ask:
   1. **Backlog**: queued; ask for a `- Starts When:` condition if one applies
   2. **Ongoing**: as `Pending`
   3. **Ongoing, start now**: as `Pending`, then straight to the Work workflow

   For either ongoing option, check capacity first; at `{ongoing_capacity}`, say so and ask for another placement.
2. Ask the assignee, in `{assignee_form}`, or propose `{default_assignee}` when set.
3. Apply the `create` extension point: its questions, its Status Info lines, its acceptance criteria, the files it keeps out of *Files to Modify*.
4. Write `{tasks_dir}/{backlog|ongoing}/task-{ID}-{slug}.md` from the task template (`references/task-model.md`): slug lowercase and hyphenated; `- Related:` filled from the search; `- Created:` or a first Log line with today's date when the template has them.
5. Check it before going on:
   - Every `Adjacent` and `Explains the gap` finding is on `- Related:`, with how it relates
   - The ID is unused in every tracking file and folder
   - The name matches `task-{ID}-{slug}.md`, in the folder of the placement chosen
   - Summary, Problem, Solution, Acceptance Criteria and Status Info are all present
   - The file is 10 to 150 lines
</step>

<step name="place_tasks">
For each task file written:
- **Backlog:** add the row to `backlog.md` in priority order, and update the total line.
- **Ongoing:** add the row to `ongoing.md` with status `Pending`, *Started On* and *Updated* today, the extra columns filled per the `create` extension point (`-` otherwise).

Apply `after-change` once for the new tasks. For "start now", go to the Work workflow with that task. Otherwise go to shared completion.
</step>
</process>

<success_criteria>
- The related-task search ran with at least three terms, and its terms and findings were reported before any proposal
- No task file duplicates, repeats or falls inside an existing task's scope
- Each file has a unique ID, sits in the folder of its placement, and passed the checks in `create_task_files`
- Every new task has its tracking row, and the backlog total is current
- The `create` and `after-change` extension points were applied
</success_criteria>
