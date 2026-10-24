<!-- Rulebook and index for the manage-deliverables skill. Setup fills the {placeholders} from the project's config and drops every line marked "optional" whose setting is not set. Edit freely afterwards: this file wins over the skill's defaults. -->
# Deliverables

Client-facing work packages: a bundle of tasks sold as one unit with a cost, a phased delivery plan and a payment schedule. Each deliverable owns a folder here; the individual tasks stay in `{tasks_dir}/` and point back to their deliverable.

## Layout

```
{deliverables_dir}/
├── README.md                          # this rulebook and index
└── D-<NNN>-<client>-<slug>/
    ├── README.md                      # the deliverable: scope, tasks, phases and dates, cost, payments, exclusions, status log
    ├── offer.{client_language}.md     # the offer, verbatim as sent
    ├── screenshots/                   # what each implemented task looks like, named task-<id>-<slug>.jpg
    ├── presentation/YYYY-MM-DD/       # client review deck: index.html and its images, published as-is
    └── source/                        # raw inputs: meeting notes, client requests, attachments
```

## Conventions

- **ID:** `D-<NNN>`, sequential, never reused. Folder name `D-<NNN>-<client>-<slug>` (lowercase, hyphenated).
- **Status flow:** `Draft` → `Offered` → `Accepted` → `In Progress` → `Delivered` → `Paid`. Record every transition, with its date, in the deliverable's *Status log*.
- **Tasks:** every task belonging to a deliverable carries `- Deliverable: D-<NNN>` and `- Phase: <n>` in its *Status Info*. The deliverable README lists its tasks in a table and is the place to read overall progress.
- **Money:** the deliverable README holds the cost breakdown and the payment schedule (advance and final, or per phase). Amounts are written once, in the README; the offer copies them verbatim.
- **Pricing** (optional): the arithmetic from the user's figure (taxes, rounding, the payment split) is in [`{pricing_doc}`]({pricing_doc}).
- **Language:** READMEs and task files in English (internal); the offer and the presentation in the client's language (`{client_language}`).
- **Internal-only notes** (capacity, margins, who works when) go under an explicit *Internal notes* heading in the README and never into the offer or the presentation.
- **Screenshots:** when a task lands something visible, capture it from the running app into `screenshots/` as `task-<id>-<slug>.jpg`, and link it from the deliverable README's *Screenshots* section (grouped by task) and from the task file. Tasks with no visible surface are absent.
- **Client presentation:** an HTML deck in `presentation/YYYY-MM-DD/` that shows the client what a delivery changed, for their review. The user publishes the folder and sends the link. When a phase ships without one, the user is asked once, and a "no" is logged as `presentation declined`.
- **Hosting:** where decks are published, and how. Fill in before the first deck.
- **Procedure:** creating, offering, updating, shipping and presenting a deliverable follow the `manage-deliverables` skill.
- **Correspondence** (optional): correspondence about a deliverable lives in `{correspondence_dir}` and is linked from the README, not copied.

## Index

| ID | Client | Title | Status | Offered | Accepted | Final delivery | Total | Advance / Final |
|---|---|---|---|---|---|---|---|---|
