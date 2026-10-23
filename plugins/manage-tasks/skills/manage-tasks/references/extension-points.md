<overview>
A project adds its own rules in `.claude/manage-tasks/extensions.md`. Each rule sits under a `##` heading named after an extension point. When a workflow reaches that point, it reads the section and applies it together with the core step. A section may add steps, questions, checks or exclusions, and may change a core rule for this project. It never removes the user's approval before a commit or push.

Write each section as instructions to the agent: imperative, specific, with paths and names. Keep a section short. When it needs more than a screen, put the detail in a project document and point to it.
</overview>

<points>
| Point | Fires during | The core step it extends |
|-------|--------------|--------------------------|
| `context` | context loading, step 6 | Which files are read before any workflow |
| `dashboard` | Review: `analyze_tasks`, `present_dashboard` | The checks table and the dashboard sections |
| `create` | Discuss: `search_related_tasks`, `propose_tasks`, `create_task_files`, `place_tasks` | Where to search, what to ask, what the task file and its row carry |
| `work` | Work: `plan_the_work` to `finish_work` | Which files a task changes, extra checks while implementing |
| `review` | Review: `conduct_review` | What the review checks, skips or adds to the report |
| `complete` | Every transition to `Complete`, in any workflow | What must be delivered or recorded when a task closes |
| `after-change` | After any status change, new task, rejection or move | Documents or skills that must follow task changes |
| `groom` | Groom: `grooming_menu` | Extra grooming actions |
| `finish` | Shared completion, before the commit | Commit messages, other repositories to commit |
</points>

<examples>
**A deliverable due after the tests pass, not on the task branch** (`create`, `work`, `review`, `complete`):

```markdown
## create
When a task adds or changes a public endpoint, do not list the API collection or the consumer guide under *Files to Modify*. Add this Status Info line instead: `- API collection: update at In Test → Complete`.

## work
Never edit `api-collections/` on a task branch.

## review
A missing API collection update is never a finding. For an older task that still carries it as a criterion, mark it "post-test deliverable, not reviewed".

## complete
If the task carries `- API collection:`, update `api-collections/service.json` for the changed endpoint and propose a separate commit in that repository.
```

**A release label** (`create`, `dashboard`, `groom`, `complete`, with `extra_columns: Release`):

```markdown
## create
Ask whether the task belongs to a planned release (list the open ones in `docs/releases/`). Record `- Release: {name or -}` in Status Info and in the row's Release column.

## dashboard
Warn when a task's release is cut and the task is still in ongoing.

## complete
Carry the Release value into the history row.
```

**Another skill that follows task changes** (`context`, `after-change`, `finish`):

```markdown
## context
Read `docs/planning/plan.md`.

## after-change
Apply the plan's sync rules in `.claude/skills/project-plan/SKILL.md` and set the plan's *Last updated* to today.

## finish
When the plan changed too, the commit subject is `- [planning] {description}`.
```
</examples>

<rules>
- A heading that names no known point is reported by `setup --check` and ignored.
- When two rules apply at one point, the core step runs first and the extension adjusts it, unless the extension says it replaces the step.
- An extension that stays true for every project is a candidate for the core (`<maintenance>` in SKILL.md). Offer to promote it.
</rules>
