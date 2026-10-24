# skillyard

Skills for running project work with [Claude Code](https://code.claude.com). The repository is also a Claude Code plugin marketplace.

| Plugin | What it does |
|--------|--------------|
| [manage-tasks](plugins/manage-tasks/skills/manage-tasks/SKILL.md) | Task lifecycle over markdown task files in a docs repository: review, work, discuss, groom and setup |

## How to install

A project gets manage-tasks in one of two ways: as a plugin that Claude Code loads from this marketplace, or as a vendored copy committed into the project and pinned to a release. Either way, finish with `setup`, which writes the project's settings.

### Plugin

In Claude Code:

```
/plugin marketplace add ymoud/skillyard
/plugin install manage-tasks@skillyard
```

To enable it for one project only, run `claude plugin install manage-tasks@skillyard --scope project` in that project instead. Then run `/manage-tasks:manage-tasks setup` in the project and choose the plugin.

### Vendored copy

The skill is committed into the project under `.claude/skills/manage-tasks/`, with a `vendor.json` manifest that records the version and a hash of every file.

1. Clone this repository: `git clone https://github.com/ymoud/skillyard`.
2. In the project's workspace, start Claude Code with the clone loaded: `claude --plugin-dir <clone>/plugins/manage-tasks`.
3. Run `/manage-tasks:manage-tasks setup` and choose the vendored copy.
4. Review the changes and commit them.

Later, `/tasks setup --update` brings in a newer release, and `/tasks setup --check` reports files that differ from the manifest.

## Project settings

The skill is generic. Each project keeps its own settings and rules in `.claude/manage-tasks/`:

| File | Holds |
|------|-------|
| `config.md` | Docs repo, code repositories, branch policy, review cycle, capacity, build and test commands |
| `extensions.md` | Project rules at named extension points, such as deliverables due when a task completes |
| `review-checklist.md` | Compliance gates and project review checks |

`setup` writes them. It detects what it can, asks about the rest, and migrates a project's older copy of the skill without losing its rules. Run it again to change a setting.

## Commands

| Command | Does |
|---------|------|
| `/tasks` | Main menu |
| `/tasks review` | Dashboard, then the reviews waiting for approval (`--summary`: dashboard only) |
| `/tasks work {ID}` | Start or resume a task |
| `/tasks discuss` | Turn a discussion, finding or brief into tasks |
| `/tasks groom` | Manage the backlog |
| `/tasks setup` | Set the project up or change its settings (`--check`, `--update`) |
| `/tasks {ID}` | Route by the task's status |

`/tasks` is a project command that `setup` adds. Without it, invoke the skill by name: `/manage-tasks:manage-tasks` for the plugin, `/manage-tasks` for a vendored copy.

## Repository layout

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

## Maintaining

- Change the skill only here. A vendored copy is never edited in place.
- A rule true for one project belongs in that project's `.claude/manage-tasks/`, not here.
- Try a change in a project before releasing it: load the clone with `--plugin-dir`. A copy vendored from uncommitted work is marked as such by the check.
- Release: bump `version` in `plugins/manage-tasks/.claude-plugin/plugin.json`, add a `CHANGELOG.md` entry, commit, and tag `manage-tasks-v<version>`. Then run `/tasks setup --update` in each project that has a vendored copy.

## License

[MIT](LICENSE)
