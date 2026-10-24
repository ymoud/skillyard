<required_reading>
1. `references/project-config.md`: every setting and its default
2. `references/extension-points.md`: where project rules go
3. `references/task-model.md`: the formats the checks compare against
</required_reading>

<modes>
| Invocation | Mode |
|------------|------|
| `setup` | `configure`: write the project files, or change them; migrate a legacy copy; install the skill |
| `setup --check` | `check`: validate the project files and the installed copy. Warnings only |
| `setup --update` | `update`: refresh the vendored copy from the source |

Setup never commits. It ends by proposing commits, as shared completion does.
</modes>

<process>
<step name="find_the_state">
Look in `${CLAUDE_PROJECT_DIR}`, the workspace root:
- `.claude/manage-tasks/config.md` exists: in `configure`, show the current values and ask what to change; apply the changes, then run `check`.
- `.claude/skills/manage-tasks/` exists **without** `vendor.json`: a legacy copy. `configure` migrates it (`migrate_legacy_copy`).
- `.claude/skills/manage-tasks/vendor.json` exists: a vendored copy. Its version is in the file.
- None of these: a new project.

In `check` and `update` mode, go straight to that step.
</step>

<step name="detect">
Gather what the workspace already tells you, so you ask only about gaps. Record where each value came from.

| Setting | Where to look |
|---------|---------------|
| `docs_repo` | A folder of the workspace root holding `tasks/ongoing.md` or `tasks/README.md`. Several: ask. None: a new project; ask where the docs live |
| Code repositories | The other git repositories in the workspace root. Leave out those the workspace `CLAUDE.md` calls read-only references. Confirm the list with the user |
| `base_branch` | Per repository: `development` or `main` (or `master`), whichever has the more recent commits on origin. Show both dates when both exist. A stale branch is not the base |
| `branch_policy` | `task-branch` if origin has `task-*` branches or the README describes them, otherwise ask |
| `base_branch_assignees` | The README or a legacy copy naming people who commit straight to the base branch |
| Build | `*.sln` at the root: `dotnet build <sln>`. `gradlew`: Gradle. `package.json` with a `build` script: `npm run build`. Otherwise ask |
| Test | `global.json` naming `Microsoft.Testing.Platform`: `dotnet test --project {project} --filter-class "*{class}"`, run from the repository root (the VSTest `--filter` is rejected there). Other .NET: `dotnet test {project} --filter "FullyQualifiedName~{filter}"`. Gradle: `gradlew test --tests "{filter}"`. npm: `npm test -- {filter}` |
| Test notes | The code repository's `CLAUDE.md` on what tests touch; otherwise ask what a test run can reach |
| `review_process` | `none` if a legacy config turns review off, or no task in `history.md` ever passed `Review Pending`; otherwise `full` |
| `ongoing_capacity` | The README's maximum for ongoing; otherwise 10 |
| `assignee_form` | `email` when the Assignee cells hold addresses, `role` when they hold roles |
| `coding_standards` | A coding standards document in the docs or code repository |
| `docs_commit_format` | The README's commit convention for task changes |
| `extra_columns` | The `ongoing.md` and `history.md` headers, minus the core columns |
| `snapshot_folders` | A legacy `move-task.ps1`'s `$snapshotFolders` value |
| Actions | A TODO or actions file in the docs repository, or a legacy copy that keeps one |

A legacy `project-config.md` or a legacy SKILL.md's paths and rules outrank the guesses above.
</step>

<step name="propose_config">
Show the proposed values in one message: detected values with their source, assumed ones marked as assumed, "overturn if you disagree". Ask only about what nothing could tell you. When the user agrees, write `.claude/manage-tasks/config.md` from `templates/project/config.md`.

Write `extensions.md` and `review-checklist.md` from their templates only when there is something to put in them: a legacy copy's rules, or rules the user names.
</step>

<step name="migrate_legacy_copy">
A legacy copy is a project's own copy of an older manage-tasks. Its rules must survive the move; none may be lost silently.

1. Read the whole legacy copy: SKILL.md, its references, its scripts, any `project-config.md`.
2. Compare it with this skill section by section: SKILL.md, the five workflows, the references.
3. Classify every difference:

   | Kind | Lands in |
   |------|----------|
   | A value: path, branch, command, capacity, toggle | `config.md` |
   | A project rule: its own deliverables, labels, sync with another skill | `extensions.md`, under the extension point where it fires, its meaning kept and its wording tightened |
   | A project review check or compliance gate | `review-checklist.md` |
   | A rule that would hold in any project | `extensions.md` for now, marked `<!-- core candidate -->`, and listed for the user |
   | Already in the core | Nothing |
   | Dropped on purpose | Nothing; list it so the user confirms |

4. Present the mapping as a table: legacy rule, where it lands. Wait for the user's agreement.
5. Write the project files.
6. Find the docs and `CLAUDE.md` files that quote the legacy copy's commands, such as the move script without `-DocsRoot`, and update them to the forms in SKILL.md.
7. Install (`install`). For a vendored copy, the vendor script replaces the legacy folder only when passed `-ReplaceUnvendored`, after the mapping is approved.
</step>

<step name="scaffold">
Create only what is missing. Never overwrite an existing file.
- A new project's task files: `{tasks_dir}/README.md`, `ongoing.md`, `backlog.md`, `history.md` from `templates/docs/`, and the empty `ongoing/`, `backlog/`, `history/` folders (each with a `.gitkeep`).
- With `actions: file`, the actions file from `templates/docs/actions.md`.
- The project command `.claude/commands/tasks.md` from `templates/project/tasks-command.md`. If one exists, show it, and fix it only if it invokes another skill.

Fill the templates' `{name}` placeholders with the config values.
</step>

<step name="install">
Ask how the project gets the skill:
1. **Vendored copy**: the skill is committed into the project, pinned to a release.
2. **Plugin**: Claude Code loads it from the marketplace.

**Vendored copy:**
- The source is this skill's own directory (`${CLAUDE_SKILL_DIR}` in SKILL.md) when this run loaded the skill from a plugin or from a clone of the source repository. If this run loaded a vendored copy, ask for the source: the `plugins/manage-tasks/skills/manage-tasks` folder of a clone of https://github.com/ymoud/skillyard.
- Run from the workspace root, with `-DryRun` first, then for real:

  ```bash
  powershell -NoProfile -ExecutionPolicy Bypass -File "<source>/scripts/vendor-skill.ps1" -Source "<source>" -ProjectRoot .
  ```
- In the command file, `allowed-tools` is `Skill(manage-tasks)`.

**Plugin:** merge into `.claude/settings.json`, keeping every existing key:

```json
{
  "extraKnownMarketplaces": {
    "skillyard": { "source": { "source": "github", "repo": "ymoud/skillyard" } }
  },
  "enabledPlugins": { "manage-tasks@skillyard": true }
}
```

In the command file, `allowed-tools` is `Skill(manage-tasks:manage-tasks)`. A project skill of the same name would compete with the plugin: remove a legacy copy only once its migration is approved.

Then run `check`.
</step>

<step name="check">
Validate, and report each item as OK or as a warning with its evidence. Never block. The user decides what to fix.

- `config.md` has every required setting, with a known value; unknown keys are listed.
- The paths exist: `{docs_repo}`, its `tasks/` files and folders, every code repository, `{coding_standards}`, `{actions_file}`, every snapshot folder.
- `{base_branch}` exists on origin in every code repository.
- The `ongoing.md`, `backlog.md` and `history.md` headers have the `extra_columns`. Columns outside the core and `extra_columns` are warnings. Core columns a header lacks are listed as information: the workflows skip them.
- The README's status names match `references/task-model.md`; unknown ones are listed.
- Every `##` heading in `extensions.md` is a known extension point.
- No task file sits in a folder that contradicts its row, and no ID has a live row in two tracking files.
- `.claude/commands/tasks.md` invokes this skill.
- A vendored copy matches its manifest:

  ```bash
  powershell -NoProfile -ExecutionPolicy Bypass -File ".claude/skills/manage-tasks/scripts/vendor-skill.ps1" -Check -ProjectRoot .
  ```

  Edited, missing or extra files mean someone changed the copy: offer to turn each change into a project change or a core change (`<maintenance>` in SKILL.md), then to restore the copy with `update`.
</step>

<step name="update">
1. Find the source, as in `install`. Read its version in `../../.claude-plugin/plugin.json` and the installed version in `.claude/skills/manage-tasks/vendor.json`.
2. Show the `CHANGELOG.md` entries between the two versions.
3. Run the vendor script with `-DryRun`, show the files it would add, change and remove, then run it for real.
4. Run `check`.
5. Propose a commit in the workspace repository, following its convention, naming the new version.
</step>

<step name="finish">
Run `git status` in every repository setup touched. Summarize the changes per file and propose a commit for each repository, in its convention. Commit only on the user's approval, staging by name.
</step>
</process>

<success_criteria>
- `.claude/manage-tasks/config.md` exists, and every value is detected, confirmed or marked as assumed
- A legacy copy's every rule was mapped, shown and approved before the copy was replaced
- The skill is installed, vendored or as a plugin, and `/tasks` invokes it
- `check` ran, and its warnings were reported with evidence
- Nothing was committed without approval
</success_criteria>
