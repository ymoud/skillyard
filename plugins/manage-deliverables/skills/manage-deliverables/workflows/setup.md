<required_reading>
1. `references/project-config.md`: every setting and its default
2. The `manage-tasks` skill's `references/extension-points.md`: the same rules apply to this skill's `extensions.md`
</required_reading>

<modes>
| Invocation | Mode |
|------------|------|
| `setup` | `configure`: write the project files or change them; migrate a legacy copy; install the skill |
| `setup --check` | `check`: validate the settings and the deliverables. Warnings only |
| `setup --update` | `update`: refresh the vendored copy from the source |

Setup never commits. It ends by proposing commits.

The vendor script ships with `manage-tasks`: `<clone>/plugins/manage-tasks/skills/manage-tasks/scripts/vendor-skill.ps1` in a clone of https://github.com/ymoud/skillyard, or `.claude/skills/manage-tasks/scripts/vendor-skill.ps1` in a project that vendors `manage-tasks`. Below, `<vendor script>` is that path.
</modes>

<process>
<step name="find_the_state">
Look in `${CLAUDE_PROJECT_DIR}`, the workspace root:
- `.claude/manage-tasks/config.md` missing: say that the task links and actions need `manage-tasks`, and offer to set it up first. Go on only if the user agrees to.
- `.claude/manage-deliverables/config.md` exists: in `configure`, show the current values and ask what to change; apply the changes, then run `check`.
- `.claude/skills/manage-deliverables/` exists **without** `vendor.json`: a legacy copy. `configure` migrates it (`migrate_legacy_copy`).
- None of these: a new project.

In `check` and `update` mode, go straight to that step.
</step>

<step name="detect">
Gather what the workspace already tells you, so you ask only about gaps. Record where each value came from. A legacy copy's paths and rules outrank these guesses.

| Setting | Where to look |
|---------|---------------|
| `deliverables_dir` | A `deliverables/` folder in `{docs_repo}`, or the folder holding `D-<NNN>-*` folders |
| `client_language` | The language code of existing `offer.<lang>.md` files; otherwise ask |
| `pricing_doc` | A pricing document beside the rulebook, or one the rulebook links |
| `correspondence_skill` | A project skill or enabled plugin whose description covers drafting and auditing emails |
| `correspondence_dir` | A correspondence folder in `{docs_repo}` with one subfolder per counterpart |
| `presentation_audiences` | The audience tags (`class="who"`) of existing decks, in the order they appear; otherwise ask |
</step>

<step name="propose_config">
Show the proposed values in one message: detected values with their source, assumed ones marked as assumed, "overturn if you disagree". Ask only about what nothing could tell you. When the user agrees, write `.claude/manage-deliverables/config.md` from `templates/project/config.md`. Write `extensions.md` from its template only when there is something to put in it.
</step>

<step name="migrate_legacy_copy">
A legacy copy's rules must survive the move; none may be lost silently.

1. Read the whole legacy copy: SKILL.md, its templates, its scripts.
2. Compare it with this skill, section by section.
3. Classify every difference: a value goes to `config.md`; a project rule goes to `extensions.md`, under the operation where it fires; a rule that would hold in any project goes to `extensions.md` for now, marked `<!-- core candidate -->`; one already in the core lands nowhere; one dropped on purpose is listed for the user to confirm.
4. Present the mapping as a table (legacy rule, where it lands) and wait for the user's agreement.
5. Write the project files. Update the docs that quote the legacy copy's paths, such as the rulebook's *Procedure* line.
6. Install (`install`). Remove the legacy copy only once the mapping is approved.
</step>

<step name="scaffold">
Create only what is missing; never overwrite a file. A project without a deliverables folder gets `{deliverables_dir}/README.md` from `templates/docs/README.md`, its placeholders filled from the config.
</step>

<step name="install">
Ask how the project gets the skill. Recommend the way the project already gets `manage-tasks`.
1. **Vendored copy**: the skill is committed into the project, pinned to a release.
2. **Plugin**: Claude Code loads it from the marketplace.

**Vendored copy:** the source is this skill's own directory (`${CLAUDE_SKILL_DIR}`) when this run loaded the skill from a plugin or from a clone; if this run loaded a vendored copy, ask for the clone's `plugins/manage-deliverables/skills/manage-deliverables` folder. Run from the workspace root, with `-DryRun` first, then for real:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "<vendor script>" -Source "<source>" -ProjectRoot .
```

Over a migrated legacy copy, add `-ReplaceUnvendored`, and only once the mapping is approved.

**Plugin:** merge into `.claude/settings.json`, keeping every existing key: the `skillyard` marketplace under `extraKnownMarketplaces` (`{ "source": { "source": "github", "repo": "ymoud/skillyard" } }`) and `"manage-deliverables@skillyard": true` under `enabledPlugins`. A project skill of the same name would compete with the plugin: remove a legacy copy only once its migration is approved.

Then run `check`.
</step>

<step name="check">
Report each item as OK, or as a warning with its evidence. Never block; the user decides what to fix.

- `config.md` has every required setting with a known value; unknown keys are listed.
- The paths exist: `{deliverables_dir}`, its `README.md`, `{pricing_doc}`, `{correspondence_dir}` up to its `<client>` part.
- `{correspondence_skill}`, when set, is an available skill.
- Every heading in `extensions.md` is a known extension point.
- Every index row's folder exists, and every `D-<NNN>-*` folder has an index row.
- Every task file with `- Deliverable: D-<NNN>` names a deliverable in the index, and is listed in that deliverable's task table.
- A vendored copy matches its manifest: `<vendor script>` with `-Check -ProjectRoot . -Name manage-deliverables`. Edited, missing or extra files mean someone changed the copy: offer to turn each change into a project rule in `extensions.md` or a change to the source, then to restore the copy with `update`.
</step>

<step name="update">
1. Find the source, as in `install`. Read its version in `../../.claude-plugin/plugin.json` and the installed version in `.claude/skills/manage-deliverables/vendor.json`.
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
- `.claude/manage-deliverables/config.md` exists, and every value is detected, confirmed or marked as assumed
- A legacy copy's every rule was mapped, shown and approved before the copy was removed
- `check` ran, and its warnings were reported with evidence
- Nothing was committed without approval
</success_criteria>
