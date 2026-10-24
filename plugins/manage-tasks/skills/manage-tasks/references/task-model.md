<overview>
The shapes every workflow reads and writes. The project's `{tasks_dir}/README.md` may refine them: its task template, categories and length rule win. Each tracking file's own header decides that file's columns (`<tracking_files>`). The README's status names must match the ones below; `setup --check` warns when they do not.
</overview>

<statuses>
| Status | Meaning |
|--------|---------|
| `Pending` | Assigned or queued, not started |
| `Design Approval Pending` | The approach needs approval before work starts |
| `In Progress` | Being worked on (code tasks: on its task branch, or on `{base_branch}` under `base-branch`) |
| `Blocked` | Cannot proceed and no choice of ours gets around it (`<decide_then_ask>` in SKILL.md). *Blocked By* names the reason |
| `Paused` | Suspended by our own decision, not an impediment. The file carries `- Paused On:` and `- Resume When:`. In ongoing, the resume condition goes in *Blocked By*; a paused task parked in the backlog keeps it in `- Resume When:`. Any branch is kept |
| `Review Pending` | Work done, awaiting review. The file carries `- Review Since: {date}` |
| `Reopened` | Sent back after review for rework. Picked up like `Pending`. Each time, add the date to `- Reopened:` |
| `Reviewed` | Code tasks: approved, ready for merge |
| `In Test` | Code tasks: the developer runs the tests after approval |
| `Complete` | Done. Row to `history.md`, file to `history/`, in the same change |
| `Rejected` | Will not be done; the reason is recorded. File to `history/` |
</statuses>

<transitions>
```
Code task, review on:   Pending → In Progress → Review Pending → Reviewed → In Test → Complete
Other task, review on:  Pending → In Progress → Review Pending → Complete
Review off:             Pending → In Progress → Complete
Before work starts:     Pending → Design Approval Pending → In Progress
After review:           Review Pending → Reopened → In Progress → Review Pending
Any phase:              → Blocked or Paused → back to where it was
Instead of doing it:    → Rejected (with the reason)
```

A **code task** is one whose work is commits in a code repository. Every other task (documents, designs, coordination, investigation write-ups) is an **other task**: it skips `Reviewed` and `In Test`.

Invalid: `Pending` straight to `Complete`, or `Complete` back to any open status. A finished task that turns out wrong gets a new task, cited on its `- Related:` line.
</transitions>

<status_info>
Every task file ends with a `## Status Info` section of `- Key: value` lines.

| Line | When | Value |
|------|------|-------|
| `Category` | always | One of the README's categories; by default `Feature`, `Bug`, `Technical`, `Investigation`, `Documentation` |
| `Priority` | always | `Critical`, `High`, `Medium`, `Low` |
| `Effort` | always | `High` (up to 3 days), `Medium` (1 to 2 days), `Low` (up to 1 day). Work over 3 days is split |
| `Status` | always | A status above |
| `Assignee` | always | In the config's `assignee_form`, or `-` |
| `Related` | always | Task IDs from the related-task search, each with a clause on how it relates, or `none found; searched: {terms}` |
| `Blocked By` | when `Blocked` | What it waits on |
| `Paused On`, `Resume When` | when `Paused` | Date; condition |
| `Starts When` | optional, backlog | The condition that makes it ready to start: a task completing, an event, a reply |
| `Review Since` | when `Review Pending` | The date review was requested |
| `Reopened` | after each reopen | Dates, comma-separated |

Extension points may add lines, such as a release label or a milestone.
</status_info>

<tracking_files>
Core columns. The file's own header wins: write the columns it has, in its order, and never drop or add one. A core column the file lacks, such as *Started On*, is skipped wherever a workflow says to fill it. Extra columns (`extra_columns` in the config) sit where the file already has them.

**`ongoing.md`**: `| ID | Task | Category | Status | Assignee | Started On | Blocked By | Updated |`
- The Task cell links the task file: `[Title](ongoing/task-{ID}-{slug}.md)`.
- *Updated* is the date of the last change to the task.

**`backlog.md`**: `| ID | Task | Category | Priority | Effort | Added |`
- Rows ordered by priority, Critical first.
- A total line at the bottom, kept current on every change: `**Total: X tasks** (Y active, Z superseded)`.
- A superseded task keeps its row, struck through: `~~[Title](history/task-{ID}-{slug}.md)~~ *(Superseded by #{ID})*`.

**`history.md`**: `| ID | Task | Category | Implemented By | Started On | Completed |`
- New rows go at the top.
- *Completed* is the date the task reached `Complete`.
</tracking_files>

<ids_and_files>
- IDs are numbers, zero-padded to three digits (`007`, `132`). A letter suffix marks a split task (`140a`). The next ID is the highest one found across the three tracking files and the three folders, plus one.
- Rows with a letter prefix (`C14`, `U07`) belong to another task set. Leave them alone.
- File names: `task-{ID}-{slug}.md`, with a lowercase, hyphenated slug. Companion files (`task-{ID}-findings.md`) sit next to the task file and move with it.
- Length: 10 to 150 lines, unless the README sets another range.
</ids_and_files>

<task_template>
Use the template in `{tasks_dir}/README.md` when it has one. Otherwise use `templates/task-file.md`. Its required sections are Summary, Problem, Solution, Acceptance Criteria and Status Info. When the template has a `## Log` section, keep it current: one dated line per event (started, asked whom for what, blocked, reviewed, completed).
</task_template>
