---
name: manage-deliverables
description: Runs a client deliverable (D-<NNN>) through its life over markdown files in a docs repository. Drafts the package from a client request, prepares the offer, records scope changes, status transitions and payments, ships a phase, builds the HTML slide deck the client reviews, and closes it on payment. Reads the project's settings from .claude/manage-deliverables/. Use when creating or updating a deliverable, when a phase or a whole deliverable is finished, when the client accepts or pays, when the user asks for a client presentation of finished work, or when setting up deliverables in a repository.
---

<objective>
One place that knows where every client package stands: what was promised, what changed since, what shipped, what the client has seen, and what has been paid.

Two failures this skill exists to prevent. Drift: a task added, absorbed or split while the deliverable's README, the offer and the index each tell a different story. Silence: work finished and committed that the client never sees in a form they can review, so acceptance and the final payment wait on nothing.

The skill is generic. Paths, the client's language, the pricing document and project rules live in the project's own `.claude/manage-deliverables/` folder. Tasks are kept by the `manage-tasks` skill, which this skill requires.
</objective>

<quick_start>
Invoke the skill with what you want done: create a deliverable, prepare its offer, record a change or a payment, ship a phase, build a presentation, or `setup` (`--check` to validate the settings).
</quick_start>

<project_files>
Load these first, from `${CLAUDE_PROJECT_DIR}/.claude/`:

| File | Required | Holds |
|------|----------|-------|
| `manage-deliverables/config.md` | yes | Deliverables folder, client language, pricing document, correspondence, presentation audiences |
| `manage-deliverables/extensions.md` | no | Project rules, one `##` section per extension point |
| `manage-tasks/config.md` | yes | The docs repository, the tasks folder and the actions file, shared with `manage-tasks` |

- If `manage-deliverables/config.md` is missing, say so and run the Setup workflow first. If `manage-tasks/config.md` is missing, say that `manage-tasks` must be set up first.
- A lowercase `{name}` in this skill is a config value, from either file: `{deliverables_dir}`, `{client_language}`, `{docs_repo}`, `{actions_file}`. `{tasks_dir}` is `{docs_repo}/tasks`.
- **The rulebook** is `{deliverables_dir}/README.md`: the layout, IDs, status flow, money, language, screenshots and hosting of this project, and the index of its deliverables. **Read it first, every time.** This skill is the procedure; the rulebook is the project's conventions. Where they disagree, the rulebook wins for that project.
- Every setting and its default: `references/project-config.md`.

This skill's directory is `${CLAUDE_SKILL_DIR}`. Paths such as `workflows/presentation.md` and `templates/presentation.html` are relative to it.
</project_files>

<scope>
- `{deliverables_dir}/`: the rulebook and index `README.md`, and per deliverable its `README.md`, `offer.{client_language}.md`, `screenshots/`, `presentation/`, `source/`
- The `- Deliverable:` and `- Phase:` lines of task files in `{tasks_dir}`

Not covered here: implementing a task (`manage-tasks`), and correspondence beyond the offer and the presentation email (the project's correspondence skill, when it has one).
</scope>

<operations>
Ask only if the request does not already say which:

1. **Create**: a new deliverable from a client request or meeting (`<create>`)
2. **Offer**: prepare the offer for sending (`<offer>`)
3. **Update**: scope change, status transition, payment (`<update>`)
4. **Ship a phase**: a phase or the whole deliverable is done (`<ship>`)
5. **Presentation**: build the client review deck (`workflows/presentation.md`)
6. **Setup**: write or check the project's settings (`workflows/setup.md`)

Before any operation except Setup: load the project files, run `git pull` in `{docs_repo}` (on failure, show the error and ask whether to continue with the local copy), read the rulebook, and apply the `context` extension point.
</operations>

<non_negotiables>
**1. Amounts are the user's.** The user sets every total and every payment. Never propose a price. The internal days are the basis the user decides from, not a price. When the user gives a figure, do the arithmetic (taxes, rounding, the payment split) by `{pricing_doc}`; with no pricing document, ask for each figure.

**2. One source per fact.** Amounts are written once, in the deliverable's README; the offer copies them. Task scope lives in the task file; the README's task table links to it. Change the source, then everything that copies it, in the same pass.

**3. Internal stays internal.** Capacity, margins, absorbed costs and who works when go under *Internal notes* and never reach the offer or the presentation.

**4. Every change leaves a trace.** A task added, absorbed, split or dropped, a status move, a payment: one dated row in the *Status log*, saying what changed and whether the price moved. Update the index row in the rulebook when status, dates or totals change.

**5. Say the hard thing plainly.** A phase that slips, a dependency on a third party, work that grew: in the README, and in the client's text when it affects them.

**6. Language and voice.** READMEs and task files in the project's working language, English unless the rulebook says otherwise. Everything the client reads (offer, presentation, the email with the link) in `{client_language}`, business framing first. The offer and the email speak as the user, in the first person singular. The presentation is impersonal: it names who acts ("The app…", "The office…"), never "I show you" or "we start".

**7. Nothing goes out without the user.** You draft and build. Sending, uploading and deploying are the user's.

**8. Commit by name, after approval.** Stage only the files this run touched, never `git add .`, and only after the user approves the commit.
</non_negotiables>

<extension_points>
At each point, read the matching `## {point}` section of `extensions.md`, if the project has one, and apply it with the core step: `context` (end of the preparation above), `create`, `offer`, `update`, `ship`, `presentation`. A section may add steps, checks or wording rules, and may change a core rule for this project. It never removes the user's approval before sending or committing.
</extension_points>

<create>
1. Read the source in full: meeting notes into `source/`, client emails from `{correspondence_dir}` when it is set.
2. Take the next `D-<NNN>` from the rulebook's index. Create the folder `D-<NNN>-<client>-<slug>` and its `README.md` from `templates/deliverable-README.md`, or from the sections the project's existing deliverables use when they differ.
3. Split the scope into tasks through `manage-tasks` (Discuss workflow, with its related-task search). Each task carries `- Deliverable: D-<NNN>` and `- Phase: <n>`. Estimate days per task; sum them per phase.
4. Delivery dates are relative to acceptance ("2 weeks from acceptance"), unless the user gives fixed dates. Check them against the user's capacity before writing them; ask if it is unknown.
5. Leave the amounts as `—` and ask the user for the total. Add the index row with status `Draft`.
6. Apply the `create` extension point.
</create>

<offer>
1. The offer is client correspondence. With `{correspondence_skill}` set, write `offer.{client_language}.md` through that skill, as outbound text with its audit. Otherwise draft it in the deliverable folder and run `<point_audit>` on it.
2. Its structure follows the project's earlier offers when there are any; otherwise: what changes, the stages with their dates, how certain points were understood, cost and payment, what is not included, validity.
3. Copy the amounts from the README verbatim. Assumptions are stated, not asked.
4. Apply the `offer` extension point.
5. When the user confirms it was sent: status `Offered`, with the date and the validity, in the *Status log* and the index.
</offer>

<update>
- **Scope change.** Create or edit the task, add it to the README's task table with its phase and days, and recompute the phase and total days. Ask the user whether the price moves. If it does not, log the change as **absorbed**, with the reason. If it does, the change goes to the client as correspondence (`<offer>`, step 1).
- **Status transition** (`Draft → Offered → Accepted → In Progress → Delivered → Paid`). Log the date and what triggered it: "advance received", "final delivery live in production".
- **Payment.** Log the date and the amount. On the final payment, status `Paid`.
- **Open points.** Tick them with the date and who settled them; never leave one open here that is closed elsewhere.
- Apply the `update` extension point.
</update>

<ship>
1. Check the phase's tasks in the README's table against their task files: every one `Complete`, or explicitly held back with the reason. Never mark a phase shipped on a task that is still open.
2. Every task with something visible has its screenshot in `screenshots/`, linked from the README's *Screenshots* section and from the task file. Capture missing ones from the running app now.
3. Log the phase as shipped, with what went out and what was held back. If it was the last phase, status `Delivered`.
4. **Presentation prompt.** If no presentation covers this work, ask the user once whether they want one now. Yes: `workflows/presentation.md`. No: log `presentation declined`, and do not ask again for this delivery. The user may also ask for one at any other time.
5. **Leftover actions.** Ask once whether anything remains that only the user can do for this delivery: deploy, tell the client, send the link, collect the payment. Each one is an action in `{actions_file}`, in the format `manage-tasks` keeps there, with its arrow pointing at the deliverable and phase (`→ D-<NNN> phase <n>`).
6. Apply the `ship` extension point.
</ship>

<point_audit>
For a client text written without a correspondence skill. Read it as the client will, then:
- For every statement and every question: does the client need it to decide or to act? Cut what they do not.
- For every commitment the client could hold the user to (a date, a scope, a price, a promise of availability): is it meant, and can the user keep it? List each one for the user.
- Check every figure against the README, and every date against the delivery plan.

Hand over the text with what you cut and why, and the list of commitments.
</point_audit>

<success_criteria>
- The deliverable's README, its offer, its task files and the index agree on scope, phases, dates, amounts and status
- Every change since the offer has a dated *Status log* row saying whether the price moved
- A shipped phase has every task `Complete` or explicitly held back, and every visible task has a screenshot
- The user was asked about a presentation for each shipped delivery, and the answer is logged
- Nothing was sent, uploaded or committed without the user
</success_criteria>
