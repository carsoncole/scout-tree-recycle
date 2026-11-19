# Views

## The Rails Way

- Follow standard Ruby on Rails approach. RESTful routes.

##

## Theming

- Support light and dark modes for all views using Tailwind's `dark:` variants driven by native `prefers-color-scheme` (no manual theme toggle).
- Do not add dark-mode rules to custom CSS. Colors are expressed as Tailwind utilities in markup, using the semantic tokens defined in `app/assets/tailwind/application.css`.
- Reuse the recipes below for common UI roles. Repetition is fine; consistency is the goal.

### Color tokens

Semantic Tailwind tokens live in `app/assets/tailwind/application.css` via `@theme`. Each role has a light token and a `*-dark` counterpart:

| Role | Light | Dark |
|------|-------|------|
| Page background | `page` | `page-dark` |
| Surface/card | `surface` | `surface-dark` |
| Primary text | `ink` | `ink-dark` |
| Secondary text | `ink-soft` | `ink-soft-dark` |
| Muted/meta text | `muted` | `muted-dark` |
| Divider/border | `line` | `line-dark` |
| Strong border/input | `line-strong` | `line-strong-dark` |
| Subtle/stone fill | `stone` | `stone-dark` |
| Cool fill | `cool` | `cool-dark` |
| Primary accent | `sage` | `sage-dark` |
| Deep accent (links) | `sage-deep` | `sage-deep-dark` |
| Accent soft fill | `sage-soft` | `sage-soft-dark` |
| Deep fir (footer, pickup panel) | `fir` | `fir-dark` |
| Danger text | `danger` | `danger-dark` |
| Danger border | `danger-border` | `danger-border-dark` |
| Danger background | `danger-bg` / `danger-bg-strong` | `danger-bg-dark` / `danger-bg-strong-dark` |
| Warning | `warning` | `warning-dark` |
| Warning background | `warning-bg` / `warning-row` | `warning-bg-dark` / `warning-row-dark` |
| Warning badge | `warning-badge` / `warning-badge-text` | `warning-badge-dark` / `warning-badge-text-dark` |
| Positive | `positive` | `positive-dark` |
| Positive background | `positive-bg` | `positive-bg-dark` |
| Info | `info` | `info-dark` |
| Info background | `info-bg` | `info-bg-dark` |
| Table row hover | `table-hover` | `table-hover-dark` |
| Danger row | `danger-row` | `danger-row-dark` |
| Input focus (dark) | — | `input-focus-dark` |

### Component recipes

Use these exact class strings (light + `dark:`) together:

| Element | Classes |
|---------|---------|
| Page / body | `bg-page text-ink dark:bg-page-dark dark:text-ink-dark` |
| Header | `border-b border-line bg-page dark:border-line-dark dark:bg-page-dark` |
| Surface / panel / card | `border border-line bg-surface dark:border-line-dark dark:bg-surface-dark` |
| Primary text | `text-ink dark:text-ink-dark` |
| Secondary text | `text-ink-soft dark:text-ink-soft-dark` |
| Muted/meta text | `text-muted dark:text-muted-dark` |
| Divider | `border-line dark:border-line-dark` |
| Strong border | `border-line-strong dark:border-line-strong-dark` |
| Subtle fill / hover | `bg-stone dark:bg-stone-dark` / `hover:bg-stone dark:hover:bg-stone-dark` |
| Link | `text-sage-deep hover:text-ink dark:text-sage-deep-dark dark:hover:text-ink-dark` |
| Danger link | `text-danger hover:text-[#743730] dark:text-danger-dark dark:hover:text-danger-border-dark` |
| Muted link | `text-ink-soft dark:text-ink-soft-dark` |
| Input / select / textarea | `border border-line-strong bg-surface text-ink placeholder-muted focus:border-sage focus:bg-[#fffdf8] dark:border-line-strong-dark dark:bg-stone-dark dark:text-ink-dark dark:placeholder-muted-dark dark:focus:border-sage-dark dark:focus:bg-input-focus-dark` |
| Label | `text-ink dark:text-ink-dark` |
| Hint / help text | `text-ink-soft dark:text-ink-soft-dark` |
| Error text | `text-danger dark:text-danger-dark` |
| Primary button | `bg-sage text-surface hover:bg-sage-deep dark:bg-sage-dark dark:text-page-dark dark:hover:bg-sage-deep-dark` |
| Secondary button | `border border-line-strong bg-surface text-ink hover:bg-stone dark:border-line-strong-dark dark:bg-surface-dark dark:text-ink-dark dark:hover:bg-stone-dark` |
| Quiet button | `text-ink-soft hover:text-ink dark:text-ink-soft-dark dark:hover:text-ink-dark` |
| Danger button | `bg-danger text-surface hover:bg-[#743730] dark:bg-danger-dark dark:text-page-dark dark:hover:bg-danger-border-dark` |
| Notice (info/success) | `border border-line border-l-[3px] border-l-sage bg-sage-soft text-ink dark:border-line-dark dark:border-l-sage-dark dark:bg-sage-soft-dark dark:text-ink-dark` |
| Notice (alert/error) | `border border-line border-l-[3px] border-l-ink-soft bg-stone text-ink dark:border-line-dark dark:border-l-ink-soft-dark dark:bg-stone-dark dark:text-ink-dark` |
| Notice (warning) | `border border-line border-l-[3px] border-l-warning bg-warning-bg text-ink dark:border-line-dark dark:border-l-warning-dark dark:bg-warning-bg-dark dark:text-ink-dark` |
| Notice (danger) | `border border-line border-l-[3px] border-l-danger-border bg-danger-bg text-ink dark:border-line-dark dark:border-l-danger-border-dark dark:bg-danger-bg-dark dark:text-ink-dark` |
| Table header cell | `border-b border-line bg-stone text-ink-soft dark:border-line-dark dark:bg-stone-dark dark:text-ink-soft-dark` |
| Table body cell | `border-b border-line text-ink dark:border-line-dark dark:text-ink-dark` |
| Table row hover | `hover:bg-table-hover dark:hover:bg-table-hover-dark` |
| Warning row | `bg-warning-row dark:bg-warning-row-dark` |
| Danger row | `bg-danger-row dark:bg-danger-row-dark` |
| Badge (neutral) | `bg-stone text-ink-soft dark:bg-stone-dark dark:text-ink-soft-dark` |
| Badge (info) | `bg-info-bg text-info dark:bg-info-bg-dark dark:text-info-dark` |
| Badge (positive) | `bg-positive-bg text-positive dark:bg-positive-bg-dark dark:text-positive-dark` |
| Badge (warning) | `bg-warning-badge text-warning-badge-text dark:bg-warning-badge-dark dark:text-warning-badge-text-dark` |
| Badge (danger) | `bg-danger-bg-strong text-danger dark:bg-danger-bg-strong-dark dark:text-danger-dark` |
| Nav link (default) | `text-ink-soft hover:text-ink dark:text-ink-soft-dark dark:hover:text-ink-dark` |
| Nav link (active) | `bg-sage-soft text-sage-deep dark:bg-sage-soft-dark dark:text-sage-deep-dark` |
| Filter (active) | `bg-sage text-surface dark:bg-sage-dark dark:text-page-dark` |
| Pagination link (current) | `border-sage bg-sage text-surface dark:border-sage-dark dark:bg-sage-dark dark:text-page-dark` |
| Fir panel/footer | `bg-fir dark:bg-fir-dark` |
| Fir panel label | `text-sage-soft` |
| Fir panel soft text | `text-sage-soft/90` |
| Fir panel strong text/link | `text-surface` |
| Fir panel link (underline) | `text-surface underline decoration-sage-soft/40 underline-offset-4 hover:decoration-sage-soft` |
| Focus visible | `focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ink dark:focus-visible:outline-ink-dark` |

### Rules of thumb

- Every element that sets a light color should set its `dark:` counterpart from the table above.
- Exception: on `fir` backgrounds only the panel itself switches (`bg-fir dark:bg-fir-dark`). Its text tokens (`text-sage-soft`, `text-sage-soft/90`, `text-surface`) read on both, so they stay the same in both modes.
- Prefer semantic tokens (`bg-surface`, `text-ink`) over arbitrary hex values.
- Pseudo-elements cannot take utilities directly; use Tailwind variants such as `after:bg-surface dark:after:bg-surface-dark`.
- For repeated markup (table cells, form fields), it is fine to repeat the recipe strings or expose small helpers that return them. Do not reintroduce color rules in `app/assets/stylesheets/application.css`.

## Forms

- Use the shared `admin-select` class for `<select>` elements. Tailwind's preflight removes native form-control styling, and native selects can render with no inner padding. `admin-select` sets `appearance: none`, explicit padding, and a custom chevron so dropdown text is always inset. Avoid bare or custom-styled selects without it.

## Destructive actions

- For destructive "delete all" actions, require the user to type a confirmation word (e.g. `DELETE`) in a form field and validate it server-side before performing the deletion. Do not rely solely on `turbo_confirm` for important data.

## Routes and URLs

- Prefer Rails-standard, RESTful resource paths using underscores.
- Keep controllers, actions, and route helper names underscored, e.g. `Admin::ReservationsController` and `admin_reservations_path`.
- If a hyphenated public path is required, keep the helper name underscored and set `path:` in `config/routes.rb`.
- Follow the conventions already used in `config/routes.rb`; do not introduce a new URL style without a deliberate migration.