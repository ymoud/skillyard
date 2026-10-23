<required_reading>
1. `references/task-model.md`: tracking files, the backlog total line, superseded rows
</required_reading>

<process>
<step name="load_backlog">
Read `backlog.md` and `ongoing.md`, then show:

```markdown
## Backlog Summary

**Total:** X tasks (Y active, Z superseded) · **Ongoing:** {count}/{ongoing_capacity}

### By Priority
| Priority | Count |
|----------|-------|

### By Category
| Category | Count |
|----------|-------|

### Ready to Start
{backlog tasks whose `- Starts When:` condition is met, or "none"}
```
</step>

<step name="grooming_menu">
Ask what to do:
1. **Assign or start**: move a backlog task to ongoing
2. **Reprioritize**
3. **Ready to start**: start a task whose condition is met
4. **Stale items**: tasks added more than 30 days ago
5. **Supersede**: mark a task superseded by another
6. **Remove**: take a task off the backlog
7. Any action the `groom` extension point adds
8. **Done**

After each action, apply `after-change` and come back to this menu, until the user picks done. Then go to shared completion.
</step>

<step name="assign_task">
1. Show the backlog tasks by priority; ask which one.
2. Check capacity: below `{ongoing_capacity}`, or stop and say so.
3. Ask the assignee, in `{assignee_form}`; look up a person's full form in `history.md` when needed.
4. Remove the row from `backlog.md` and update the total. Add it to `ongoing.md` with status `Pending`, *Started On* and *Updated* today, and the task file's values for any extra columns (`-` when it has none).
5. Move the file `-To ongoing` (`<move_task_files>` in SKILL.md).
6. Set the assignee and status in the task file.
</step>

<step name="reprioritize">
1. Ask which task, and the new priority: `Critical`, `High`, `Medium` or `Low`.
2. Update the row and reorder the table: Critical first, then High, Medium, Low.
3. Update the Priority line in the task file.
</step>

<step name="ready_to_start">
List the backlog tasks whose `- Starts When:` condition is met, with the evidence for each. Offer to start the ones the user picks, through `assign_task`.
</step>

<step name="review_stale_items">
1. List the backlog tasks added more than 30 days ago. If there are none, say so and return to the menu.
2. For each, show its details and ask: keep, reprioritize, supersede or remove. Apply the choice.
</step>

<step name="mark_superseded">
1. Ask which task is superseded, and which task supersedes it (or a description).
2. Strike its row in `backlog.md`: `~~[Title](link)~~ *(Superseded by #{ID})*`. Update the superseded count in the total.
3. Add a note to the superseded task file pointing to the new task.
4. Move the file `-To history`. The struck row stays in `backlog.md`, and its link now points into `history/`.
</step>

<step name="remove_task">
1. Ask which task, and confirm the removal.
2. Remove the row from `backlog.md` and update the total.
3. Keep the file for reference: never delete it. Move it `-To history`.
</step>
</process>

<success_criteria>
- Every change updated the row, the task file and the backlog total together
- Every file that changed state was moved with the script
- Capacity was checked before any task entered ongoing
- `after-change` was applied after each action
</success_criteria>
