# skillyard

Skills for running project work with [Claude Code](https://code.claude.com). The repository is also a Claude Code plugin marketplace.

| Plugin | What it does |
|--------|--------------|
| [manage-tasks](plugins/manage-tasks/skills/manage-tasks/SKILL.md) | Task lifecycle over markdown task files in a docs repository: review, work, discuss, groom and setup |
| [manage-deliverables](plugins/manage-deliverables/skills/manage-deliverables/SKILL.md) | Client deliverables over markdown files: the package, its offer, scope changes and payments, shipped phases, and the HTML deck the client reviews. Needs manage-tasks |

## How to install

A project gets each skill in one of two ways: as a plugin that Claude Code loads from this marketplace, or as a vendored copy committed into the project and pinned to a release. Either way, finish with the skill's `setup`, which writes the project's settings. Set up manage-tasks first: manage-deliverables reads its settings.

### Plugin

In Claude Code:

```
/plugin marketplace add ymoud/skillyard
/plugin install manage-tasks@skillyard
```

Installing `manage-deliverables@skillyard` installs manage-tasks with it. To enable a plugin for one project only, run `claude plugin install <plugin>@skillyard --scope project` in that project instead. Then run the plugin's setup in the project (`/manage-tasks:manage-tasks setup`, `/manage-deliverables:manage-deliverables setup`) and choose the plugin.

### Vendored copy

The skill is committed into the project under `.claude/skills/<skill>/`, with a `vendor.json` manifest that records the version and a hash of every file.

1. Clone this repository: `git clone https://github.com/ymoud/skillyard`.
2. In the project's workspace, start Claude Code with the clone loaded: `claude --plugin-dir <clone>/plugins` loads every plugin in it.
3. Run the skill's setup (`/manage-tasks:manage-tasks setup`, then `/manage-deliverables:manage-deliverables setup` if you use it) and choose the vendored copy.
4. Review the changes and commit them.

Later, `setup --update` brings in a newer release, and `setup --check` reports files that differ from the manifest.

## Project settings

The skills are generic. Each project keeps its own settings and rules in `.claude/<skill>/`, which `setup` writes. It detects what it can, asks about the rest, and migrates a project's older copy of the skill without losing its rules. Run it again to change a setting.

| File | Holds |
|------|-------|
| `manage-tasks/config.md` | Docs repo, code repositories, branch policy, review cycle, capacity, build and test commands |
| `manage-tasks/extensions.md` | Project rules at named extension points, such as deliverables due when a task completes |
| `manage-tasks/review-checklist.md` | Compliance gates and project review checks |
| `manage-deliverables/config.md` | Deliverables folder, the client's language, pricing document, correspondence, presentation audiences |
| `manage-deliverables/extensions.md` | Project rules at named extension points, such as the wording of client texts |

manage-deliverables also follows the project's own rulebook, `README.md` in its deliverables folder: the layout, status flow, money and hosting rules, and the index of deliverables.

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

`/tasks` is a project command that manage-tasks' `setup` adds. Without it, invoke the skill by name: `/manage-tasks:manage-tasks` for the plugin, `/manage-tasks` for a vendored copy.

manage-deliverables has no command. Ask for what you want done (create a deliverable, prepare its offer, record a payment, ship a phase, build a presentation), or invoke it by name: `/manage-deliverables:manage-deliverables` for the plugin, `/manage-deliverables` for a vendored copy, with `setup`, `setup --check` or `setup --update`.

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
plugins/manage-deliverables/
├── .claude-plugin/plugin.json         plugin manifest; depends on manage-tasks
└── skills/manage-deliverables/
    ├── SKILL.md                       operations, non-negotiables, create, offer, update, ship
    ├── CHANGELOG.md
    ├── workflows/                     presentation, setup
    ├── references/                    settings, presentation labels
    ├── templates/                     project files, rulebook, deliverable README, presentation deck
    └── scripts/                       serve-folder.js
```

## Maintaining

- Change a skill only here. A vendored copy is never edited in place.
- A rule true for one project belongs in that project's `.claude/<skill>/`, not here.
- Try a change in a project before releasing it: load the clone with `--plugin-dir`. A copy vendored from uncommitted work is marked as such by the check.
- Release: bump `version` in the plugin's `.claude-plugin/plugin.json`, add a `CHANGELOG.md` entry, commit, and tag `<plugin>-v<version>`. Then run the skill's `setup --update` in each project that has a vendored copy.

## License

[MIT](LICENSE)
