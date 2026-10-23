# manage-tasks: project configuration

Read by the `manage-tasks` skill before every workflow. `/tasks setup` writes it; change it by hand or run setup again. Every key is defined in the skill's `references/project-config.md`. `-` means not set. Paths are relative to the workspace root.

## Settings

| Key | Value |
|-----|-------|
| `project_name` | {project_name} |
| `docs_repo` | {docs_repo} |
| `base_branch` | {base_branch} |
| `branch_policy` | {branch_policy} |
| `base_branch_assignees` | {base_branch_assignees} |
| `commit_task_marker` | {commit_task_marker} |
| `review_process` | {review_process} |
| `ongoing_capacity` | {ongoing_capacity} |
| `assignee_form` | {assignee_form} |
| `default_assignee` | {default_assignee} |
| `coding_standards` | {coding_standards} |
| `docs_commit_format` | {docs_commit_format} |
| `snapshot_folders` | {snapshot_folders} |
| `extra_columns` | {extra_columns} |

## Code repositories

| Name | Path | Tasks | Build | Test |
|------|------|-------|-------|------|
| {name} | {path} | all | {build command} | {test command pattern} |

**Test notes:** {what a test run can reach, and any syntax rule}

## Actions

| Key | Value |
|-----|-------|
| `actions` | {off, file or skill} |
| `actions_file` | {actions_file} |
| `actions_label` | {actions_label} |
| `actions_blocked_by` | {actions_blocked_by} |
| `actions_skill` | {actions_skill} |
