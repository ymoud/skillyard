<overview>
`config.md` holds every value that differs between projects. It lives at `.claude/manage-tasks/config.md` in the project, is committed with it, and is written by `/tasks setup` from `templates/project/config.md`. Values are in markdown tables, so people and agents read them the same way. A value of `-` means "not set".

All paths are relative to the workspace root, use forward slashes, and are never absolute.
</overview>

<settings>
| Key | Values | Default | Effect |
|-----|--------|---------|--------|
| `project_name` | text | the workspace folder name | Name used in dashboards and reports |
| `docs_repo` | path | required | The docs git repository. Tasks live in `{docs_repo}/tasks/`; task commits are made here |
| `base_branch` | branch | required | Task branches are cut from it and merged back into it; reviews compare against it |
| `branch_policy` | `task-branch`, `base-branch` | `task-branch` | `task-branch`: each code task gets a `task-{ID}` branch from `{base_branch}`, squash-merged back. `base-branch`: work is committed to `{base_branch}` directly, and reviews read the task's commits there |
| `base_branch_assignees` | comma-separated assignees | `-` | Assignees who commit straight to `{base_branch}` even under `task-branch`, such as `tech lead` |
| `commit_task_marker` | text with `{ID}` | `Related Task: {ID}` | Text in a commit message that ties it to a task. Finds a task's commits on `{base_branch}` |
| `review_process` | `full`, `none` | `full` | `full`: work ends in `Review Pending` and goes through review. `none`: work goes from `In Progress` to `Complete`; Review shows the dashboard only, unless the user asks to review a task |
| `ongoing_capacity` | number | `10` | Maximum rows in `ongoing.md` |
| `assignee_form` | `email`, `role` | `email` | How people are written in task files and tracking rows. `role`: a role or a team, never a name |
| `default_assignee` | assignee | `-` | Proposed when a task is created or started without one |
| `coding_standards` | path | `-` | The project's coding standards, read for implementation and review |
| `docs_commit_format` | text with `{description}` | `- [tasks] {description}` | Subject of commits in `{docs_repo}` |
| `snapshot_folders` | comma-separated docs folders | `-` | Folders whose plain-text task paths the move script leaves alone, such as dated reports that record what a commit touched |
| `extra_columns` | comma-separated column names | `-` | Columns in the tracking tables beyond the core ones (`references/task-model.md`). Their meaning and values come from `extensions.md`; without a rule, write `-` |
</settings>

<code_repositories>
One row per code repository:

| Column | Meaning |
|--------|---------|
| Name | Short name used in messages |
| Path | Repository root, relative to the workspace root |
| Tasks | Which tasks use it: `all`, or a rule on a tracking column, such as `Project = web` |
| Build | Command that builds it. The agent runs it freely |
| Test | Command pattern for a narrow test run, with placeholders such as `{project}` and `{filter}`. The agent names it for the developer, and runs it only when asked |

Below the table, a **Test notes** line says what a test run can touch (external systems, shared databases) and any syntax rule: for example, a test platform that rejects one filter style. It goes into every "Tests to Run" list the agent writes.

A project whose tasks are all documents has no rows. Its tasks never take the code paths of the workflows.
</code_repositories>

<actions_settings>
| Key | Values | Default | Effect |
|-----|--------|---------|--------|
| `actions` | `off`, `file`, `skill` | `off` | `file`: this skill keeps actions in `{actions_file}`. `skill`: another skill owns them (`{actions_skill}`); this skill reads `{actions_file}` for the dashboard and hands new actions over |
| `actions_file` | path | `-` | The single file holding the project's actions |
| `actions_label` | word | `action` | What the project calls an action, such as `TODO` |
| `actions_blocked_by` | text with `<label>` | `Action: <label>` | How a task's *Blocked By* names the action it waits on |
| `actions_skill` | skill name | `-` | The skill that owns actions when `actions` is `skill` |
</actions_settings>

<precedence>
- `config.md` wins over this skill's defaults. `extensions.md` and `review-checklist.md` win over the core steps they extend.
- Nothing in the project files removes the user's approval before a commit or push.
- A key the skill does not know is reported by `setup --check` and otherwise ignored.
</precedence>
