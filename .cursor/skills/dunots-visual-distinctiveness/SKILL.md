---
name: dunots-visual-distinctiveness
description: Review and design Dunots mobile interfaces to preserve a study-product identity and prevent accidental resemblance to WhatsApp, chat apps, social feeds, or generic CRUD dashboards. Use when creating, revising, previewing, or validating mobile screens, navigation, headers, cards, dialogs, colors, or interaction patterns.
---

# Dunots visual distinctiveness

Use this skill together with `ui-visual-quality-gate` whenever a mobile UI is
created or changed. Its purpose is to catch visual drift before implementation
is presented to the user.

## Product identity

Dunots is a focused study workspace, not a conversation surface. The visual
hierarchy must answer, in this order:

1. What should I study now?
2. How much have I completed?
3. What is the next useful action?
4. Where are the secondary tools?

Prefer roadmap structure, progress, status, review state, and content density
over brand repetition, decorative badges, or chat-like activity.

## Anti-WhatsApp review

Before accepting a screen, inspect it for these cues. A single cue can be valid;
several cues together indicate visual drift and require redesign.

- fixed global brand name plus a second page title;
- green circle repeated as the default icon, avatar, badge, selection, and action;
- bottom navigation that feels like a messenger tab bar rather than study areas;
- rows shaped like conversations, especially avatar + title + preview + trailing state;
- speech bubbles, message tails, unread dots, online-style indicators, or chat-like timestamps;
- many circular icon buttons grouped in the same header or card;
- floating action buttons used as a generic shortcut instead of a clear study action;
- rounded pills for every status, filter, and action;
- stacked controls with no visible primary action;
- an empty content area framed like a messaging inbox or recent conversation list.

Do not solve resemblance by adding random colors. Remove the structural cue
first, then choose a semantic color only when it communicates state.

## Dunots patterns to prefer

- Page identity: one contextual title and one contextual icon in the global
  header; do not repeat the same title and icon inside the first content block.
- Primary action: one labeled action per section, preferably tied to studying,
  continuing, answering, or reviewing.
- Roadmaps: compact rows with title, progress/count, status text, and an
  optional priority point. Use hierarchy and indentation, not chat-row styling.
- Study progress: use a visible linear or circular metric with a meaningful
  number. The progress indicator must answer a real question.
- Secondary actions: overflow menu, details page, or bottom sheet. Avoid a row
  of equal-weight buttons.
- Empty states: explain what can be created and make the whole state actionable;
  do not imitate an empty inbox.
- Navigation: labels must name study destinations (`Hoje`, `Estudar`,
  `Questões`, `Trilhas`). Icons support the label and must not carry the whole
  meaning.

## Color semantics

Use `DunotsColors` tokens and the theme. Do not introduce literal colors in a
screen without a documented semantic reason.

- `#0B1316`: app background and quiet space.
- `#122021`: cards, dialogs, drawers, and fixed surfaces.
- `#49D17D`: primary action, current selection, and active study state.
- `#A8D5BA`: completion and consolidated progress. Make it visible enough to
  distinguish it from the primary action.
- `#E8C56A`: review, pending attention, priority, due work, and reward.
- `#B9A1F5`: rare special category or explicitly marked item; never use it as a
  generic second primary color.
- red: errors, destructive actions, and real risk only.

If a screen uses only emerald in its normal state, verify whether the other
colors are actually reachable through status, priority, review, or completion.
If they are not reachable, add the missing state or a restrained legend rather
than decorating neutral content.

## Required workflow

1. Read `docs/design.md`, `docs/ux-simplification.md`, and the relevant screen
   implementation before changing the UI.
2. Identify the screen's primary study intention and remove duplicate page
   identity from either the shell or the content.
3. Mark every visible element as primary action, progress, status, content, or
   secondary action. Rebalance if more than one element competes as primary.
4. Run the anti-WhatsApp review above and record any detected cues.
5. Implement with shared tokens and existing components before creating a new
   pattern.
6. Render a realistic state, including at least one completed, review,
   pending, or special state when the screen supports it.
7. Validate at 320, 360, 390, and 414 px, plus one wide viewport and landscape.
8. Check accessibility: labels for icon actions, status text in addition to
   color, visible focus/selected/disabled states, and tap targets of at least
   44 px where possible.
9. Run `flutter analyze` and the focused widget tests. Run the full suite when
   shared shell, theme, or navigation changes.
10. Only present the result after fixing clipping, overflow, duplicate titles,
    accidental chat cues, or ambiguous hierarchy.

## Final report

Report these items briefly:

- primary study intention;
- WhatsApp/chat cues found and removed;
- color states rendered;
- viewports checked;
- overflow and accessibility result;
- tests and build status.

