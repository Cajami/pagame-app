# Pagame Agent Handoff

Last updated: 2026-05-19

## 1) Current Goal

Build Pagame as an Android-first Flutter app to track payments with this hierarchy:

Category > Service > Year > Month > Payment

Development mode agreed with user: screen-by-screen, validate each screen before moving to next one.

## 2) User Constraints

- Workspace root is `D:/Desarrollos/pagame`.
- Flutter binaries are in `D:/flutter` and must be used from there.
- Project files must stay in this workspace only.
- User cannot install Android Studio or additional system software on this laptop.
- For now, run and validate on Windows and Chrome only.

## 3) Product Decisions Already Closed

- MVP includes one-time and recurring monthly payments.
- Attachments in v1: images and PDF.
- No predefined categories; user creates categories.
- One-time payments belong to dedicated category "Pago unico".
- Payment states: Pendiente, Pagado, Vencido.
- If amount is empty, user chooses state manually on create.
- Recurrence selector in service form: Quincena (day 15) or Fin de mes.
- If service type is Unico, monthly due selector is hidden and service stores Sin vencimiento.
- Reminders: 3 days before, 1 day before, same day.
- Due-to-overdue transition: end of due day (23:59).
- Reminder hour: one global user-configured hour.
- Security: Android system auth (biometric or device credential), lock on app open and after 5 min inactivity.
- Future sync priority: Google Drive first; conflict strategy asks user.

See planning docs for full context:

- [docs/PLAN_MVP_PAGAME.md](docs/PLAN_MVP_PAGAME.md)
- [PLAN_MVP.md](../PLAN_MVP.md)

## 4) Current Implemented State

Main app entry and first visual shell are in [lib/main.dart](../lib/main.dart).

Implemented now:

- App theme updated to modern dark style.
- Background color set to `#041C36`.
- Header component on top (brand + subtitle + date pill).
- Bottom tabs added (Categorias, Vencimientos, Ajustes).
- Categories module:
	- Empty state with CTA when there are no categories.
	- Floating button Nueva categoria is hidden when list is empty and shown after at least one category exists.
	- Create category bottom sheet (name required, icon optional, color optional).
	- Category list with service count.
- Services module (inside selected category):
	- Empty state and create service flow.
	- Service creation form: name, type (Mensual/Unico), recurrence selector for mensual only.
	- Service list with subtitle using selected recurrence.
- Year/Month module (inside selected service):
	- Service opens Year list screen.
	- Year creation uses tactile wheel picker (ListWheelScrollView), range 2025-2028, current year preselected.
	- Duplicate year validation: blocks repeated year.
	- Year row label shows only number (no Ano prefix).
	- Year opens Month list screen.
	- Month creation uses tactile wheel picker with month names only (no number in picker row).
	- Duplicate month validation: message "El mes XXX ya existe.".
	- Month list uses fixed icon on left (no month number badge to avoid confusion).
	- Month list subtitle currently: "Sin pagos registrados".
- Feedback/snackbar:
	- High-contrast snackbar style for dark background and better readability.
	- Typical success/info actions are visible for several seconds.

Current status by tab:

- Categorias: create/list categories done (in-memory).
- Vencimientos: placeholder screen only.
- Ajustes: placeholder screen only.

## 5) Design Direction (Active)

- User approved a modern interface.
- Dark palette direction is active.
- Avoid heavy boxed cards in empty states; keep cleaner composition.
- Keep header and bottom tabs as baseline navigation pattern.
- Keep month labels human-readable (names instead of numbers where possible).

## 6) Quality Gates and Validation

Validated successfully after latest UI changes:

- `flutter analyze` passes.
- `flutter test` passes.

Widget test file:

- [test/widget_test.dart](../test/widget_test.dart)

## 7) Known Environment Notes

- `flutter emulators` currently shows no Android AVD configured.
- Android doctor reports incomplete toolchain for emulator usage in this machine.
- Active practical targets now: `windows`, `chrome`, `edge`.
- On Chrome hot restart, occasional CanvasKit lifecycle/context-lost messages can appear; they are transient and usually resolved by browser hard reload.

## 8) Recommended Next Work Item

Next screen to build (do not jump ahead):

Screen: Payment records inside selected Month

Suggested scope:

- Open month detail from Month list row tap.
- Empty state with CTA to create first payment record.
- Payment form v1 fields:
	- status (Pendiente/Pagado/Vencido)
	- amount (optional per prior decision)
	- payment date
	- notes (optional)
- Month subtitle should evolve from "Sin pagos registrados" to dynamic counters:
	- 0 -> Sin pagos registrados
	- 1 -> 1 pago registrado
	- N -> N pagos registrados
- Keep all data in memory for now; local persistence can be introduced after this screen.

After Screen 2 implementation, run:

- `flutter analyze`
- `flutter test`
- Manual run in Chrome or Windows.

## 9) File Map (Important)

- App shell and current UI: [lib/main.dart](../lib/main.dart)
- Basic widget test: [test/widget_test.dart](../test/widget_test.dart)
- Primary MVP plan: [docs/PLAN_MVP_PAGAME.md](docs/PLAN_MVP_PAGAME.md)
- Secondary MVP summary: [PLAN_MVP.md](../PLAN_MVP.md)
- Repo quick start doc: [README.md](../README.md)

## 10) Agent Operating Notes

- Keep edits minimal and focused per screen.
- Validate after every screen change.
- Do not implement large architecture batches in one go.
- Keep UX consistency with the current dark modern visual language.
- Preserve user-approved text details for months/years messages.