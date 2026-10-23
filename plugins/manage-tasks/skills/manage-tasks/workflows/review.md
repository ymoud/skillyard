<required_reading>
1. `references/task-model.md`: statuses and transitions
2. For a review: `references/code-review-process.md`, and the project's `review-checklist.md` if it has one
3. If the config's `actions` setting is not `off`: `references/actions.md`
</required_reading>

<process>
<step name="analyze_tasks">
Check every ongoing task, and the backlog for tasks ready to start:

| Issue | Condition | Severity |
|-------|-----------|----------|
| Stale | *Updated* more than 7 days ago | Warning |
| Very stale | *Updated* more than 14 days ago | Critical |
| Missing assignee | Assignee empty or `-` | Warning |
| Blocked without reason | `Blocked` with an empty *Blocked By* | Critical |
| Paused without resume condition | `Paused` without a `- Resume When:` line, or, in ongoing, with an empty *Blocked By* | Critical |
| Long review | `Review Pending` or `Design Approval Pending` for more than 3 days, counted from `- Review Since:`, else from *Updated* | Warning |
| Capacity | More than `{ongoing_capacity}` rows in ongoing | Critical |
| Duplicate row | An ID has a row in more than one of `ongoing.md`, `backlog.md` and `history.md` (a struck superseded backlog row does not count) | Critical |
| Ready to start | A backlog task whose `- Starts When:` condition is met: the named task is `Complete`, or the event is recorded. An event nothing records is listed as "check with the user" | Info |

When actions are on, add the checks in `references/actions.md`. Then apply the `dashboard` extension point.
</step>

<step name="present_dashboard">
```markdown
## Task Review Summary

**Date:** {today} · **Ongoing:** {count}/{ongoing_capacity}

### Awaiting Review
| ID | Task | Assignee | Status | Days Waiting |
|----|------|----------|--------|--------------|

### By Status
| Status | Count | Tasks |
|--------|-------|-------|

### Issues
#### Critical
#### Warnings
#### Info

### All Ongoing
| ID | Task | Assignee | Status | Days Since Update |
|----|------|----------|--------|-------------------|

### Open Actions
| Added | Action | Unblocks | Age |
|-------|--------|----------|-----|
```

- Omit an empty Issues subsection. Omit Open Actions when actions are off or none are open; under each open action, list the tasks it blocks.
- Add the sections the `dashboard` extension point asks for.
- With `--summary`, stop here and go to shared completion.
- With `review_process: none`, stop here too, unless the user asked to review a specific task.
</step>

<step name="select_task_for_review">
If tasks are `Review Pending` or `Design Approval Pending`, ask which one to review, listing each as `#{ID} - {Title} ({assignee})`, plus "skip review". On skip, or when none awaits review (say so), go to shared completion.
</step>

<step name="conduct_review">
1. Read the task file: Problem, Solution, Acceptance Criteria, Status Info.
2. Decide the kind of task (`references/task-model.md`, transitions): a code task, or another task.
3. **Other task:** follow *other_task_review* in `references/code-review-process.md` and present its report.
4. **Code task:**
   1. Pick the code repository from the config's code repositories, by their Tasks rule.
   2. Bring it up to date and reach the change:
      - Task branch: `git fetch origin && git checkout task-{ID} && git pull`. If no branch matches (`git branch -a | grep -i "task-{ID}"`), say so and ask whether to search by another pattern.
      - Base branch (`branch_policy: base-branch`, or the assignee is in `base_branch_assignees`): `git checkout {base_branch} && git pull`.
      - If a pull fails, show the error and ask how to proceed. Do not retry.
   3. Follow `references/code-review-process.md`: read the commits, run the per-file checklist with the project checks, run the cross-file pass, fill its report template, list the Tests to Run. Do not run them.
5. Apply the `review` extension point.
</step>

<step name="review_outcome">
After the report, ask for the verdict:
1. **Approve**
2. **Reopen**: real rework needed; the task goes back to the developer
3. **Request changes**: small inline feedback; stays `Review Pending` for a re-review
4. **Defer**: no decision now

Reopen when the developer must redo or rethink something: the work is no longer ready for review, and the next thing to happen is more work. Request changes when the feedback is small (a typo, a name, a minor logic tweak) and the reviewer expects to re-review without a status change.

**Approve, other task:**
1. Set `Complete` in the task file. Add a review note with the date and the reviewer.
2. Apply the `complete` extension point.
3. Move the row from `ongoing.md` to the top of `history.md`, then the file: `-To history` (`<move_task_files>` in SKILL.md).
4. Apply `after-change`. Offer another review, or go to shared completion.

**Approve, code task:**
1. Set `Reviewed` in the task file and in `ongoing.md`. Add a review note with the date and the reviewer.
2. Tell the user the task is ready for merge. Ask: review another task, move this one to `In Test`, or done.
3. **Move to In Test:** set `In Test` in both places. List the tests the developer runs; do not run them. When the developer confirms they pass:
   1. Under `task-branch`, advise the squash merge into `{base_branch}` and deleting the branch.
   2. Apply the `complete` extension point: the deliverables due after the merge.
   3. Set `Complete`, tick the criteria met, move the row from `ongoing.md` to the top of `history.md` (carrying the extra columns `history.md` keeps), and move the file `-To history`.
   4. Apply `after-change` and go to shared completion.

   If the developer reports a failure, set `In Progress` again, apply `after-change`, and go to shared completion.

**Reopen:**
1. Ask for the rework feedback: the why and what to change.
2. Set `Reopened` in the task file and in `ongoing.md`; set *Updated* to today.
3. Add today to the `- Reopened:` line, or add the line: `- Reopened: 2026-04-15, 2026-04-29`.
4. Append `## Review Notes ({today})` at the end of the task file, with the reviewer and the feedback.
5. Switch the code repository back to `{base_branch}`.
6. Apply `after-change`. Tell the user the task is back with the developer, and offer another review.

**Request changes:**
1. Ask for the feedback.
2. Keep `Review Pending`. Add the feedback to the task file, in its Log or under Status Info.
3. Offer another review.

**Defer:** switch the code repository back to `{base_branch}` and return to the dashboard.

Review notes follow *report_audiences* in `references/code-review-process.md`: no zero-action observations in the task file.
</step>
</process>

<success_criteria>
- The dashboard was shown, with every check applied, including those of the extensions
- Each review followed the right path (code task or other task) and produced its report, with the tests listed and not run
- Every verdict updated the task file and the tracking row together; `Complete` moved the row and the file
- `complete` and `after-change` were applied wherever they fired
</success_criteria>
