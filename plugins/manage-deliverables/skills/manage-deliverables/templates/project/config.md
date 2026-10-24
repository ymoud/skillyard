# manage-deliverables: project configuration

Read by the `manage-deliverables` skill before every operation. `setup` writes it; change it by hand or run setup again. Every key is defined in the skill's `references/project-config.md`. `-` means not set. Paths are relative to the workspace root. The docs repository and the actions file come from `.claude/manage-tasks/config.md`.

## Settings

| Key | Value |
|-----|-------|
| `deliverables_dir` | {deliverables_dir} |
| `client_language` | {client_language} |
| `pricing_doc` | {pricing_doc} |
| `correspondence_skill` | {correspondence_skill} |
| `correspondence_dir` | {correspondence_dir} |
| `presentation_audiences` | {presentation_audiences} |
