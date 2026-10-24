<required_reading>
1. The rulebook, `{deliverables_dir}/README.md`: where decks are published
2. `references/presentation-labels.md`: the deck's fixed labels in `{client_language}`
</required_reading>

<overview>
An HTML slide deck that shows the client what a delivery changed, for their review: one screen per slide, «‹ / ›» buttons with a counter, arrow keys, and scrolling or swiping that moves one slide at a time. Every screenshot opens full size on click. The user publishes the folder where the rulebook says and sends the link with a short email.
</overview>

<process>
<step name="decide_what_it_covers">
Ask the user which work the deck covers if it is not obvious: a phase, several, or the whole deliverable. Collect the tasks: `Complete` only, plus anything held back that the client must know about.
</step>

<step name="collect_the_material">
Per task: the task file (what it does, for whom), its screenshots, and the README's *Status log* for anything the client must decide. Read the code or run the app when the task file does not make the user-visible effect clear: the deck describes what the client will see, not what the code does.

A task with a visible surface and no screenshot gets one captured from the running app before you go on, or it is left out. Never describe something you have not seen working.
</step>

<step name="write_the_deck">
Copy `templates/presentation.html` to `{deliverables_dir}/D-<NNN>-<client>-<slug>/presentation/YYYY-MM-DD/index.html`. Its header comment lists the three slide layouts. Replace every `{{label:…}}` with the `{client_language}` column of `references/presentation-labels.md`, and every other `{{…}}` with the deck's content. Copy the screenshots it uses into the folder, at full resolution, and reference every asset by relative path, so the folder works wherever it is copied. The navigation and the full-size viewer need no edits.

Slides, in this order:
- **Title:** the delivery in one sentence; each stage of the offer with a status tag (`{{label:done}}`, or what is pending); a note on where the screenshots come from and when the steps to try it apply (for example, once installed on the client's system).
- **One slide per change**, grouped by audience in the order of `{presentation_audiences}`, each tagged with its audience (a change for two audiences carries both, joined with ` · `; with no audiences set, drop the tag). Each has a plain-words title, what changed and why it helps, its screenshots, and `{{label:how_to_try}}` with the menu path. A slide fits one desktop screen: about 80 words and at most three screenshots. A change with more material gets several slides.
- **`{{label:needed_from_you}}`:** decisions, approvals, information. Omit the slide when there is nothing.
- **`{{label:whats_next}}`:** held-back items and why, the next step, and which step of the offer this delivery completes. Amounts only as the offer states them.

Write impersonally (non-negotiable 6 in SKILL.md). Examples quote the real on-screen text. Where a name would appear, use `{{label:name_placeholder}}`, never an invented name.

Never on a slide: internal notes, absorbed costs, commits, code, file names, task numbers, anything not seen working.

Apply the `presentation` extension point.
</step>

<step name="check_it">
Browser tools refuse `file://` pages, so serve the folder in the background and open `http://127.0.0.1:8765/` in a new tab:

```bash
node "${CLAUDE_SKILL_DIR}/scripts/serve-folder.js" <folder>
```

- **Desktop:** every image loaded (`naturalWidth > 0`), no slide taller than the window, no horizontal overflow; «›», the arrow keys and the counter move together. Test the navigation with a real key or click a few seconds after the page loads: a scroll fired right after loading can be dropped, which is a test artefact, not a bug.
- **Phone:** resizing the window may not take effect. Load the page in a 390×844 `<iframe>` injected into the open tab, and check that no element inside the deck is wider than it; text stacks above the screenshots there. Remove the iframe afterwards.
- **Audit the text:** a deck is client correspondence too. Use `{correspondence_skill}`'s audit when it is set, otherwise `<point_audit>` in SKILL.md.

Leave the tab open for the user to page through, and stop the server when they are done.
</step>

<step name="record_and_hand_over">
Log a *Status log* row: the date, the folder, the tasks it covers. Tell the user which folder to publish, and where, per the rulebook. When the user gives you the URL, add it to that row. The personal wording (here is what was done, thanks, the link) belongs in the email that carries the link: written through `{correspondence_skill}`, or drafted for the user and audited with `<point_audit>`.
</step>
</process>

<success_criteria>
- The deck covers verified, client-relevant changes only, one screen per slide, in `{client_language}`, impersonal
- It works as a copied folder on desktop and on a phone, with every image loaded
- Its text passed an audit
- It is logged with its folder and, once known, its URL
</success_criteria>
