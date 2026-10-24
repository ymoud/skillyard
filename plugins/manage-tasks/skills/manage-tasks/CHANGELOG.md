# Changelog

Newest first. Every release bumps `version` in `../../.claude-plugin/plugin.json` and adds an entry here. `setup --update` shows the entries between a project's copy and the new version.

## 1.0.1 (2026-10-24)

- A tracking file's own header decides its columns. A core column the file lacks, such as *Started On*, is skipped instead of filled, and `setup --check` lists it as information rather than a warning.
- The README's task length rule wins over the default of 10 to 150 lines.

## 1.0.0 (2026-10-23)

First release.

- One generic core. Each project's settings and rules move to `.claude/manage-tasks/`: `config.md`, `extensions.md` and `review-checklist.md`.
- Nine extension points (`context`, `dashboard`, `create`, `work`, `review`, `complete`, `after-change`, `groom`, `finish`) for project rules.
- Settings for the branch policy (task branches or the base branch, with assignees who commit straight to it), the review cycle (full or none), several code repositories, and the assignee form (email or role).
- The actions module: work only a person can do, kept in one file or handed to another skill.
- Decide-then-ask: an unanswered question no longer stops a task.
- Other tasks (documents, designs, coordination) skip `Reviewed` and `In Test`. New fields `Review Since` and `Starts When`, with a "ready to start" check.
- The Setup workflow: detect the settings, migrate a legacy copy without losing a rule, scaffold the task files, install the skill as a vendored copy or a plugin, check, update.
- `vendor-skill.ps1` copies a release into a project with a hash manifest and checks a copy against it. `move-task.ps1` takes `-DocsRoot` and `-SnapshotFolders` as parameters.
- Questions are asked in plain prose, not through a dialog tool.
- `/tasks {ID}` on an `In Progress` task resumes it in the Work workflow.
- The dashboard flags an ID with live rows in two tracking files.
