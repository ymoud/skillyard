<overview>
An **action** is work only a person can do, outside the repositories, that tracked work waits on or that finished work leaves behind: send a request, test on a device, open an account, decide, deploy, pay, chase a reply. A **task** is work an agent can finish alone inside a repository. The test is one question: could the agent do this alone, inside a repository? Yes: a task, or a step of one. No: an action. Mixed work splits: the agent's part is a task, the person's part an action.

The project names the concept `{actions_label}` (for example `TODO`); this file says "action".
</overview>

<modes>
- **`file`**: this skill keeps the actions in `{actions_file}`, in the format below.
- **`skill`**: another skill (`{actions_skill}`) owns them. This skill reads `{actions_file}` for the dashboard, read-only, and hands every new action to that skill, in that skill's format.
</modes>

<file_format>
One file. Actions live only in `{actions_file}`, under `## Open` and `## Done`. There are no per-task lists: every line names what it unblocks, so "what is pending on task 042" is a filter of the one file.

```
- [ ] YYYY-MM-DD · **label** · context · → what it unblocks
- [x] YYYY-MM-DD · **label** · done YYYY-MM-DD: outcome · → what it unblocks
```

- *date*: when the action was added.
- *label*: short, bold, stable. Other files refer to it, so never reword it once referenced.
- *context*: one clause: why, where the material is, and, when the person's action hands work back to the agent, what the agent then does.
- *→*: the task IDs or the deliverable it unblocks. Never empty.
</file_format>

<links_to_tasks>
- A task waiting on an action is `Blocked`, and its *Blocked By* (in `ongoing.md` and in the task file) reads `{actions_blocked_by}` with the action's label. The action's arrow names the task.
- An action never *becomes* a task. If doing it uncovers implementation work, create the task through the Discuss workflow, with its related-task search, and close the action with the new task ID in its arrow.
- An action whose text is really implementation was misfiled. Convert it the same way the next time you read the file, and tell the user.
</links_to_tasks>

<lifecycle>
Open → Done or Dropped.
- Only the user says an action is done. Then tick it, append `done YYYY-MM-DD: <one-line outcome>`, and move the line under `## Done`.
- A dropped action is struck through with the reason and moved under `## Done`. Nothing is deleted.
- Never tick an action on your own initiative.
</lifecycle>

<when_to_write>
- In the same pass, whenever finishing a task, a review or a delivery leaves behind something only a person can do. Shared completion asks explicitly when a task reached `Complete`.
- When the Discuss workflow's task-or-action test says "action".
- When decide-then-ask leaves a question for someone else (`<decide_then_ask>` in SKILL.md).
- The user adds, ticks and drops actions in plain language; there is no subcommand.
</when_to_write>

<dashboard_checks>
| Issue | Condition | Severity |
|-------|-----------|----------|
| Stale action | An open action added more than 14 days ago | Warning |
| Dangling reference | A *Blocked By* names an action label that no open action carries | Critical |

The dashboard lists open actions with their age, and under each one the tasks blocked by it, so the cost of a stale action is visible.
</dashboard_checks>
