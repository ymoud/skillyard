# skillyard

Skills for running project work with [Claude Code](https://code.claude.com). The repository is also a Claude Code plugin marketplace.

| Plugin | What it does |
|--------|--------------|
| [manage-tasks](plugins/manage-tasks/skills/manage-tasks/SKILL.md) | Task lifecycle over markdown task files in a docs repository: review, work, discuss, groom and setup |

## Layout

```
.claude-plugin/marketplace.json        the marketplace: lists the plugins
plugins/manage-tasks/
├── .claude-plugin/plugin.json         plugin manifest; its version is the release version
└── skills/manage-tasks/
    ├── SKILL.md                       router, constraints, shared steps
    ├── CHANGELOG.md
    ├── workflows/                     review, work, discuss, groom, setup
    ├── references/                    settings, task model, extension points, actions, review method
    ├── templates/                     project files, task files, docs scaffold
    └── scripts/                       move-task.ps1, vendor-skill.ps1
```

## manage-tasks in a project

The skill is generic. A project keeps its own settings and rules in `.claude/manage-tasks/`:

| File | Holds |
|------|-------|
| `config.md` | Docs repo, code repositories, branch policy, review cycle, capacity, build and test commands |
| `extensions.md` | Project rules at named extension points, such as deliverables due when a task completes |
| `review-checklist.md` | Compliance gates and project review checks |

`/tasks setup` writes them. It detects what it can, asks about the rest, and migrates a project's older copy of the skill without losing its rules.

### Vendored copy

The skill is committed into the project under `.claude/skills/manage-tasks/`, pinned to a release, with a `vendor.json` manifest that records the version and a hash of every file.

1. Clone this repository: `git clone https://github.com/ymoud/skillyard`.
2. In the project's workspace, start Claude Code with the clone loaded: `claude --plugin-dir <clone>/plugins/manage-tasks`.
3. Run `/manage-tasks:manage-tasks setup` and choose the vendored copy.
4. Review the changes and commit them. `/tasks` then runs the vendored copy.

`/tasks setup --check` reports files that differ from the manifest. `/tasks setup --update` brings in a newer release.

### Plugin

```
/plugin marketplace add ymoud/skillyard
/plugin install manage-tasks@skillyard
```

Then run `/manage-tasks:manage-tasks setup` in the project and choose the plugin.

## Maintaining

- Change the skill only here. A vendored copy is never edited in place.
- A rule true for one project belongs in that project's `.claude/manage-tasks/`, not here.
- Try a change in a project before releasing it: load the clone with `--plugin-dir`. A copy vendored from uncommitted work is marked as such by the check.
- Release: bump `version` in `plugins/manage-tasks/.claude-plugin/plugin.json`, add a `CHANGELOG.md` entry, commit, and tag `manage-tasks-v<version>`. Then run `/tasks setup --update` in each project.

## License

[MIT](LICENSE)
