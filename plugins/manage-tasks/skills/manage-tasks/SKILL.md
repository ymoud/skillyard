---
name: manage-tasks
description: Runs the task lifecycle of a project whose tasks are markdown files in a docs repository (review, work, discuss, groom) and sets a repository up for it. Reads the project's settings and rules from .claude/manage-tasks/. Use when working with project tasks, reviewing a task's work, creating tasks from a discussion or finding, grooming the backlog, or setting up task management in a repository.
---

<objective>
Runs one project's task lifecycle. Tasks are markdown files in a docs repository, tracked in `ongoing.md`, `backlog.md` and `history.md`, and implemented in one or more code repositories. Five workflows: Review, Work, Discuss, Groom and Setup.

This skill is generic. Everything that differs between projects lives in the project's own `.claude/manage-tasks/` folder: paths, branches, the review cycle, build and test commands, and project rules.
</objective>

<quick_start>
- `/tasks`: main menu
- `/tasks review`: dashboard, then review the tasks awaiting approval (`--summary`: dashboard only)
- `/tasks work {ID}` or `/tasks implement {ID}`: start or resume a task
- `/tasks discuss`: turn a discussion, finding or brief into tasks
- `/tasks groom`: manage the backlog
- `/tasks setup`: set the project up or change its settings (`--check`: validate them; `--update`: refresh the vendored copy)
- `/tasks {ID}`: route by the task's status

`/tasks` is a project command that invokes this skill. Without it, invoke the skill by name.
</quick_start>

<project_files>
Load these first, from `${CLAUDE_PROJECT_DIR}/.claude/manage-tasks/`:

| File | Required | Holds |
|------|----------|-------|
| `config.md` | yes | Settings: docs repo, code repositories, branch policy, review cycle, capacity, commands, modules |
| `extensions.md` | no | Project rules, one `##` section per extension point |
| `review-checklist.md` | no | Compliance gates and the project's own review checks |

- If `config.md` is missing, say so and run the Setup workflow before anything else.
- A lowercase `{name}` anywhere in this skill is a config value: `{docs_repo}`, `{base_branch}`, `{ongoing_capacity}`. `{tasks_dir}` is `{docs_repo}/tasks`. `{ID}` is a task ID.
- Where the project files and this skill disagree, the project files win for that project. They add or change rules. They never remove the user's approval before a commit or push.
- Every setting and its default: `references/project-config.md`.

This skill's directory is `${CLAUDE_SKILL_DIR}`. Paths such as `workflows/review.md` and `scripts/move-task.ps1` are relative to it.
</project_files>

<constraints>
- **Approval before every commit and push.** Never commit, push or merge without the user's explicit approval. Stage files by name; never `git add .` or `git add -A`.
- **Read changes commit by commit**, with `git show <hash>`. Never judge a change from a range `git diff`: it can be unreliable and it hides which commit did what.
- **Tests: point them out, don't run them.** Unless the user explicitly asks, run no tests in any workflow. Name the test projects and filters that cover the change, and let the developer or reviewer run them. Never report a pass or fail you produced unprompted, and never move a task on the strength of one. When asked, run exactly what was asked, narrowest filter first, and report the output. Builds are always fine.
- **Search before you create.** Never write a task file without the related-task search (`workflows/discuss.md`, step `search_related_tasks`), however the task arrived: the user's full brief, an investigation, a review outcome, another skill. A free ID only proves the number is unused, not that the work is new. Report the search terms and findings before writing the file.
- **One status, two places.** A status change follows a valid transition (`references/task-model.md`) and updates the task file and its tracking row together.
- **The folder follows the state.** `backlog/` holds tasks not started, or paused and parked; `ongoing/` holds active tasks; `history/` holds closed ones. Files change folder only through the move script (`<move_task_files>`), never with `git mv`, `Move-Item` or copy-and-delete, which break every link to them.
- **Capacity.** At most `{ongoing_capacity}` rows in `ongoing.md`. Check before adding one.
- **Unique IDs** across the three tracking files and the three task folders. A row whose ID carries a letter prefix (`C14`, `U07`) belongs to another task set: it counts toward capacity, and you never renumber or move it.
- **Task files** are named `task-{ID}-{slug}.md` and run 10 to 150 lines, unless the README sets another range.
- **People** are written in the config's `assignee_form`: a work email or a role. Never guess an assignee; ask.
- **Ask in plain prose.** Write each question as text, with the options listed, so the user can answer with context. Ask one question at a time when the answers depend on each other.
- **Decide, then ask** (`<decide_then_ask>`). An unanswered question never stops the work on its own.
- **Canonical statuses** (`references/task-model.md`). Write `Review Pending`, never `In Review`; correct `In Review` wherever you meet it.
</constraints>

<argument_parsing>
| Invocation | Behavior |
|------------|----------|
| `/tasks` | Main menu |
| `/tasks review` | Review workflow: dashboard, then review |
| `/tasks review {ID}` | Review workflow, step `conduct_review`, for that task |
| `/tasks review --summary` | Review workflow, dashboard only |
| `/tasks work` or `/tasks implement` | Work workflow: pick a task |
| `/tasks work {ID}` or `/tasks implement {ID}` | Work workflow for that task |
| `/tasks discuss` | Discuss workflow |
| `/tasks groom` | Groom workflow |
| `/tasks setup`, `setup --check`, `setup --update` | Setup workflow, in that mode |
| `/tasks {ID}` | By status: `Pending`, `Reopened`, `In Progress` → Work; `Review Pending`, `Design Approval Pending` → Review `conduct_review`; anything else → show the task and ask what to do |

`{ID}` is a task ID such as `132`, `007` or `140a`.
</argument_parsing>

<main_menu>
With no argument, ask what the user wants to do:
1. Review: dashboard and reviews
2. Work: pick a task and work on it
3. Discuss: create tasks from a discussion
4. Groom: manage the backlog
5. Setup: project settings
</main_menu>

<routing>
| Choice | Workflow |
|--------|----------|
| Review | `workflows/review.md` |
| Work, implement | `workflows/work.md` |
| Discuss | `workflows/discuss.md` |
| Groom | `workflows/groom.md` |
| Setup | `workflows/setup.md` |

Run `<context_loading>` first, except for Setup, which loads what it needs itself. Then read the workflow file and follow it exactly.
</routing>

<context_loading>
Shared by Review, Work, Discuss and Groom. Run it before any workflow logic.

1. Load the project files (`<project_files>`).
2. Run `git pull` in `{docs_repo}`, so every task file and tracking file reflects what others committed. If the pull fails, show the error and ask whether to continue with the local copy; never retry on your own. Code repositories are pulled later, when a workflow first touches a branch.
3. Read `{tasks_dir}/README.md` for the project's statuses, categories, formats and task template.
4. Read `{tasks_dir}/ongoing.md`. Read `backlog.md` when the workflow needs it.
5. If the config's `actions` setting is not `off`, read `{actions_file}` (`references/actions.md`).
6. Apply the `context` extension point.
</context_loading>

<extension_points>
At each point below, read the matching `## {point}` section of `extensions.md`, if the project has one, and apply it together with the core step.

| Point | Fires | Typical use |
|-------|-------|-------------|
| `context` | End of context loading | Extra files to read |
| `dashboard` | Review: analyzing and presenting tasks | Extra checks and dashboard sections |
| `create` | Discuss: searching, proposing and writing a task | Extra search locations, questions, Status Info lines, acceptance criteria, files kept out of a task |
| `work` | Work: planning and implementing | Files to leave alone, extra checks |
| `review` | Review: conducting a review | Exclusions, extra report rows |
| `complete` | Any transition to `Complete` | Deliverables due at completion, values carried into `history.md`, follow-up skills |
| `after-change` | After any task change | Keeping another document or skill in step |
| `groom` | Groom: the menu | Extra grooming actions |
| `finish` | Shared completion | Commit message rules, other repositories to commit |

Details and examples: `references/extension-points.md`.
</extension_points>

<move_task_files>
A task file changes folder only through this script, run from the workspace root:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}/scripts/move-task.ps1" -DocsRoot {docs_repo} -Id {ID} -To {ongoing|backlog|history}
```

Add `-SnapshotFolders {snapshot_folders}` when the config sets it.

| Transition | Target |
|------------|--------|
| Backlog → ongoing (start or assign) | `-To ongoing` |
| Ongoing → backlog (demote, or park a paused task) | `-To backlog` |
| `Complete`, `Rejected`, superseded, removed from the backlog | `-To history` |

- The script moves the task file with its companions (`task-{ID}-findings.md` and the like) and rewrites every link to them across the docs repository, including the link in the tracking row. Moving the row itself stays your job.
- Relay its summary to the user. Renames of tracked files come staged; link rewrites do not: stage those files by name at commit time.
- `-DryRun` previews. `-Path tasks/<folder>/<file>.md` moves a file whose name does not follow `task-{ID}-{slug}.md`.
- If it stops with an error, show it and fix the cause. Never fall back to a manual move.
</move_task_files>

<actions>
Some work only a person can do: send a request, test on a device, decide, deploy, chase a reply. When the config's `actions` setting is not `off`, such work is an **action**, kept outside the task files. The test is one question: could the agent finish this alone, inside a repository? Yes: it is a task, or a step of one. No: it is an action. Mixed work splits into both.

The project may call actions something else (`{actions_label}`, such as `TODO`). Formats, links to tasks, lifecycle and dashboard checks: `references/actions.md`. When `actions` is `off`, a task that waits on a person is `Blocked`, and *Blocked By* names who and what.
</actions>

<decide_then_ask>
When work needs an answer from someone else, do not stop. Recommend a choice and settle it with the user. Record it in the task file as **Decided**, open to change. Make sure the question reaches whoever owns the answer: as an action when the module is on, otherwise as a line in the task's Log or Status Info naming who to ask and what their answer would confirm or change. Then carry on.

Set `Blocked` only when no choice gets around the wait:
- the next step is hard to undo: a table created in a shared environment, a published contract, a change to another team's system or to production data;
- or it needs something only another party can give: access, an environment, an approval.
</decide_then_ask>

<shared_completion>
Shared by every workflow when it finishes.

1. If a code repository was switched to a task branch, offer to switch it back to `{base_branch}`.
2. If a task reached `Complete` and actions are on, ask once whether anything remains that only a person can do. If so, record the action (`references/actions.md`), pointing at the task it follows from.
3. Apply the `finish` extension point.
4. Run `git status` in `{docs_repo}` and in every other repository this session changed. If anything changed, summarize it per file. Propose a commit message in the form `{docs_commit_format}` (other repositories follow their own convention) and ask before committing. On approval, stage by name, including the files whose links the move script rewrote, and commit.
5. Offer the main menu or done.
</shared_completion>

<error_handling>
- **Config missing:** run the Setup workflow.
- **Task file not found:** no `task-{ID}-*.md` in `ongoing/`, `backlog/` or `history/`. Say so and list the available tasks.
- **Branch not found:** say so and ask whether to search by another pattern.
- **Capacity reached:** do not add to ongoing. Suggest completing or demoting a task first.
- **Git failure:** show the error, leave the state unchanged, do not retry.
- **Merge conflict on checkout:** tell the user and suggest resolving it by hand. Never force a checkout.
- **Malformed tracking file:** read it raw, show the problem and offer to fix the formatting before going on.
</error_handling>

<maintenance>
This skill has one source, the `skillyard` repository (https://github.com/ymoud/skillyard). A project holds it either as a plugin or as a vendored copy: `.claude/skills/manage-tasks/` with a `vendor.json` next to `SKILL.md`.

- **Never edit a vendored copy.** `setup --check` reports edited files.
- When the user asks to change how the skill behaves, first decide which kind of change it is, and say so:
  - **Project change:** true for this project only, such as a path, a rule about its own deliverables or one of its review checks. Edit `.claude/manage-tasks/`.
  - **Core change:** true for any project. Make it in the source repository (ask the user where their clone is), bump the plugin version, add a `CHANGELOG.md` entry, then run `setup --update` in each project. Someone who does not maintain the skill proposes the change to its maintainer instead.
  - When unsure, make it a project change and offer to promote it to the core later.
</maintenance>

<reference_index>
All in `references/`:
- `project-config.md`: every setting in `config.md`, its values and its default
- `task-model.md`: statuses, transitions, Status Info fields, tracking-file formats, IDs, the task template
- `extension-points.md`: what each extension point allows, with examples
- `actions.md`: the actions module
- `code-review-process.md`: the review method, checklists and report templates
</reference_index>

<workflows_index>
All in `workflows/`:

| Workflow | Purpose |
|----------|---------|
| `review.md` | Dashboard, then reviews and their outcomes |
| `work.md` | Pick, start, implement and finish a task |
| `discuss.md` | Turn a case into searched, approved, placed tasks |
| `groom.md` | Assign, reprioritize, supersede and remove backlog tasks |
| `setup.md` | Write the project files, migrate a legacy copy, install, check, update |
</workflows_index>

<success_criteria>
A run is complete when:
- The user finished the chosen workflow, or chose the main menu or done
- Every task file created was preceded by a reported related-task search and carries a `- Related:` line
- Each task file and its tracking row agree, and each file sits in the folder that matches its state, moved with the script
- Every extension point the run passed through was applied
- Nothing was committed or pushed without the user's approval
- Any task branch checked out was offered a switch back to `{base_branch}`
</success_criteria>
