# Task Management

This folder holds the project's tasks. People and agents read it every day; the `manage-tasks` skill (`/tasks`) keeps it consistent.

## Structure

```
tasks/
├── README.md     this file
├── ongoing.md    active tasks (at most {ongoing_capacity})
├── backlog.md    queued tasks, by priority
├── history.md    closed tasks, newest first
├── ongoing/      task files of active tasks
├── backlog/      task files of queued tasks, and of paused tasks parked here
└── history/      task files of closed tasks: Complete, Rejected, superseded, removed
```

## Tracking files

**`ongoing.md`**

| ID | Task | Category | Status | Assignee | Started On | Blocked By | Updated |
|----|------|----------|--------|----------|------------|------------|---------|

**`backlog.md`**: ordered by priority, with the total kept current at the bottom: `**Total: X tasks** (Y active, Z superseded)`.

| ID | Task | Category | Priority | Effort | Added |
|----|------|----------|----------|--------|-------|

**`history.md`**: newest first.

| ID | Task | Category | Implemented By | Started On | Completed |
|----|------|----------|----------------|------------|-----------|

## Categories, priorities, effort

- **Categories:** `Feature` (new functionality), `Bug` (defects), `Technical` (refactoring, infrastructure, design), `Investigation` (research, timeboxed), `Documentation`.
- **Priorities:** `Critical` (as soon as possible), `High`, `Medium`, `Low`.
- **Effort:** `Low` (up to a day), `Medium` (1 to 2 days), `High` (up to 3 days). Larger work is split.

## Statuses

| Status | Meaning |
|--------|---------|
| `Pending` | Assigned or queued, not started |
| `Design Approval Pending` | The approach needs approval before work starts |
| `In Progress` | Being worked on |
| `Blocked` | Cannot proceed; *Blocked By* says why |
| `Paused` | Suspended by our own decision; the file carries `- Paused On:` and `- Resume When:` |
| `Review Pending` | Done, awaiting review; the file carries `- Review Since:` |
| `Reopened` | Sent back after review; the file carries `- Reopened:` dates |
| `Reviewed` | Code tasks: approved, ready for merge |
| `In Test` | Code tasks: tests being run after approval |
| `Complete` | Done: row to `history.md`, file to `history/` |
| `Rejected` | Will not be done; the reason is recorded |

```
Code tasks:   Pending → In Progress → Review Pending → Reviewed → In Test → Complete
Other tasks:  Pending → In Progress → Review Pending → Complete
Any time:     → Blocked / Paused → back to where it was
After review: Review Pending → Reopened → In Progress
```

## Task files

One file per task, `task-{ID}-{slug}.md`, in the folder that matches its state. IDs are three digits, unique across ongoing, backlog and history. Length: 10 to 150 lines.

**Never move a task file by hand:** a plain move breaks every link to it. From the workspace root:

```
powershell -NoProfile -ExecutionPolicy Bypass -File .claude/skills/manage-tasks/scripts/move-task.ps1 -DocsRoot {docs_repo} -Id 007 -To history
```

The script moves the file with its companions and rewrites every link to them. `-DryRun` previews.

**Template:**

```markdown
# Task {ID}: {Title}

## Summary
One or two sentences.

## Problem
What need or defect this addresses.

## Solution
The approach.

## Files to Modify
| File | Change |
|------|--------|

## Acceptance Criteria
- [ ] Criterion

## Status Info
- Category: {Category}
- Priority: {Priority}
- Effort: {Effort}
- Status: {Status}
- Assignee: {assignee}
- Related: {related task IDs and how they relate, or "none found; searched: {terms}"}

## Log
- {YYYY-MM-DD}: created
```

## Commits

`{docs_commit_format}`, committed only after review by a person.
