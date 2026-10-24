<overview>
`config.md` holds the values that differ between projects. It lives at `.claude/manage-deliverables/config.md` in the project, is committed with it, and is written by `setup` from `templates/project/config.md`. A value of `-` means "not set". Paths are relative to the workspace root, use forward slashes, and are never absolute.

The docs repository, the tasks folder and the actions file come from the project's `.claude/manage-tasks/config.md`, so each is set in one place.
</overview>

<settings>
| Key | Values | Default | Effect |
|-----|--------|---------|--------|
| `deliverables_dir` | path | required | Folder holding the rulebook and index `README.md` and one folder per deliverable |
| `client_language` | language code (`el`, `en`, …) | `en` | Language of everything the client reads: the offer, the presentation, the email with the link. Names the offer file (`offer.{client_language}.md`) and picks the presentation labels |
| `pricing_doc` | path | `-` | How a figure the user gives becomes the offer price: taxes, rounding, the payment split. Without it, ask the user for each figure |
| `correspondence_skill` | skill name | `-` | The skill that writes and audits offers and emails. Without it, this skill drafts them and runs its own point audit |
| `correspondence_dir` | path containing `<client>` | `-` | Where each client's correspondence is filed; read when creating a deliverable |
| `presentation_audiences` | comma-separated tags | `-` | Audience tags for the change slides, in the client's language and in slide order. Without them, slides carry no tag |
</settings>

<from_manage_tasks>
| Value | Used for |
|-------|----------|
| `docs_repo` | `git pull` before every operation; `{tasks_dir}` is `{docs_repo}/tasks` |
| `actions_file`, `actions_label` | The leftover actions written when a phase ships |
</from_manage_tasks>

<precedence>
- The rulebook (`{deliverables_dir}/README.md`) wins over this skill's defaults for its project.
- `extensions.md` wins over the core steps it extends.
- Nothing in the project files removes the user's approval before anything is sent, published or committed.
- A key the skill does not know is reported by `setup --check` and otherwise ignored.
</precedence>
