# ArsosTech ERP Whitelabel Plan (Corrected)

## 1) Executive Summary

This corrected plan is designed for **fast launch + maintainability** across multiple clients.

Key decisions:

1. Use a **companion app** (`arsostech_whitelabel`) for most branding logic, instead of heavy edits in ERPNext core.
2. Keep ERPNext fork changes **minimal and explicit** (only unavoidable default branding surfaces).
3. Drive per-client branding from a **Single DocType** and apply it per-site.
4. Prefer **multi-site on one bench by default** for speed; use dedicated bench/server for enterprise isolation cases.
5. Add **automated brand-leak checks** before every release.

This approach gives quick onboarding without creating an upgrade nightmare.

---

## 2) Goals and Constraints

### Goals

- Remove visible Frappe/ERPNext branding from client-facing UI/emails/pages.
- Show client brand (name/logo/colors) and developer credit as **ArsosTech Pvt. Ltd.** where desired.
- Onboard a new client in minutes with repeatable steps.
- Keep future upgrades from upstream practical.

### Constraints

- This repository is the `erpnext` app only (Frappe framework is a separate app in bench environments).
- ERPNext here targets Frappe 16 (`>=16.0.0,<17.0.0` in `pyproject.toml`).
- GPL/trademark obligations still apply at source/license level.

---

## 3) Why the Earlier Plan Needed Correction

Critical corrections:

1. `extend_bootinfo` is already a list in `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/hooks.py`; replacing it risks breaking existing behavior.
2. Dynamic website context should use `update_website_context`, not replacing `website_context` dict with function path.
3. Branding leakage surfaces were incomplete (install help links, workspace labels, help link docs URLs, patches that reset `app_name`).
4. Writing generated CSS into app source paths is brittle; use site-scoped approach.

---

## 4) Target Architecture

## 4.1 Apps

- `frappe` (upstream framework in bench)
- `erpnext` (your fork)
- `arsostech_whitelabel` (new app; your branding engine)

## 4.2 Ownership split

- `erpnext` fork:
  - Keep minimal defaults safe for white-label baseline.
  - Remove hardcoded upstream-facing links/text where unavoidable.
- `arsostech_whitelabel`:
  - Per-site branding config DocType
  - Runtime branding hooks
  - CSS generation and cache clear
  - Onboarding API/CLI helpers
  - Validation and automated checks

This reduces merge conflicts and keeps business logic under your control.

---

## 5) Phased Plan

## Phase 0 (Day 0): Baseline, Branching, and Safety

1. Create working branch: `codex/whitelabel-foundation`.
2. Add a `docs/whitelabel/` folder for runbook + acceptance checklist.
3. Capture baseline scans:
   - Search for visible branding strings in templates, JS, setup files.
   - Save a baseline report for regression comparison.

Deliverable:

- Branding inventory report committed to repo (markdown).

---

## Phase 1 (Day 1): Minimal Core Fork Fixes (High-Impact, Low-Risk)

Apply minimal edits in ERPNext fork:

1. `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/hooks.py`
   - Update `app_title`, `app_publisher`, `app_email`, `source_link`, `default_mail_footer`.
   - Keep `website_context` as dict fallback.
   - Do **not** replace existing `extend_bootinfo` list behavior.
2. `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/setup/install.py`
   - Change install defaults:
     - `default_mail_footer`
     - `add_app_name()` generic value (not ERPNext).
   - Replace default help dropdown links from ERPNext/Frappe endpoints to ArsosTech docs/support endpoints.
3. `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/templates/includes/footer/footer_powered.html`
   - Replace static “Powered by ERPNext” with configurable ArsosTech/client output.
4. `/Users/wahab/Desktop/Projects/arsostech/erp-system/pyproject.toml`
   - Update metadata authors/description/URLs to ArsosTech-managed endpoints.
5. `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/public/js/help_links.js`
   - Replace docs base URL and links to your docs portal.
6. `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/setup/workspace/erpnext_settings/erpnext_settings.json`
   - Rename label/title/name from “ERPNext Settings” to neutral branding label.
7. App name reset prevention:
   - Update `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/patches/v13_0/set_app_name.py`.
   - Remove/replace ERPNext hardcoded app name execute line in `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/patches.txt`.

Deliverable:

- One mergeable PR with all baseline branding leak plugs in ERPNext fork.

---

## Phase 2 (Day 1-2): Build `arsostech_whitelabel` App (Primary Engine)

Create new app with:

1. **Single DocType** `White Label Settings`:
   - `client_name`
   - `client_logo`
   - `client_favicon`
   - `email_logo`
   - `primary_color`
   - `secondary_color`
   - `custom_css`
   - `developer_credit` (default `ArsosTech Pvt. Ltd.`)
   - `show_developer_credit` (check)
   - optional `support_url`, `privacy_url`, `terms_url`
2. Validation:
   - Enforce hex color format
   - Image size/type checks
   - Fallbacks for missing logo/favicon
3. Hooks:
   - `update_website_context` to inject favicon/splash/website brand
   - `extend_bootinfo` by **appending** hook function (not overriding ERPNext existing ones)
4. Apply settings on update:
   - Sync `System Settings` values where valid in your version
   - Generate site-scoped CSS assets (or safe site-level custom CSS strategy)
   - Clear relevant caches/build artifacts safely
5. Optional endpoint/command:
   - `apply_brand_profile(site, profile_json)` for scripted onboarding

Deliverable:

- New app installable on any site with single-save branding update.

---

## Phase 3 (Day 2): Client Onboarding Automation

Implement repeatable workflow:

1. `Create site` -> `install apps` -> `seed brand settings`.
2. Add script/runbook command sequence for operations team.
3. Input package per client:
   - Brand name, logo, favicon, email logo, primary/secondary colors, support links.
4. One command/playbook applies all settings and runs post-setup checks.

Deliverable:

- `docs/whitelabel/onboarding-runbook.md`
- Script(s) for automated per-client branding apply.

---

## Phase 4 (Day 2-3): Release Gates and QA

Add CI/local gate checks:

1. String leak scan (allowlist approach):
   - Fail if visible client-facing surfaces contain banned branding tokens.
2. Smoke tests:
   - Login page logo/name
   - Desk navbar app name/logo
   - Footer text
   - Outgoing email footer/logo
3. Visual checklist for one demo site.

Deliverable:

- Build/release checklist + test scripts.

---

## 6) Detailed Branding Surface Checklist (Must Cover)

## 6.1 Core metadata and default UI

- `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/hooks.py`
- `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/setup/install.py`
- `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/setup/utils.py` (`welcome_email` fallback)

## 6.2 Footer and email branding

- `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/templates/includes/footer/footer_powered.html`
- `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/hooks.py` (`default_mail_footer`, `email_brand_image`)

## 6.3 Help/docs/support links

- `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/setup/install.py` (default help dropdown links)
- `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/public/js/help_links.js`
- Any documentation URLs in DocType JSON where visible in UI.

## 6.4 Workspace and labels

- `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/setup/workspace/erpnext_settings/erpnext_settings.json`
- Any visible “ERPNext …” labels/titles in workspace metadata.

## 6.5 Patch and migration persistence

- `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/patches/v13_0/set_app_name.py`
- `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/patches.txt`

## 6.6 Static assets

- `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/public/images/erpnext-logo.svg`
- `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/public/images/erpnext-favicon.svg`
- `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/public/images/erpnext-logo.png`
- `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/public/images/erpnext-logo.jpg`
- `/Users/wahab/Desktop/Projects/arsostech/erp-system/erpnext/public/images/erpnext-logo-blue.png`

Use neutral defaults in the app, then override per-site via White Label Settings.

---

## 7) Deployment Topology Recommendation

Use a **hybrid policy**:

1. Default: one bench, many sites (faster onboarding, lower cost).
2. Dedicated bench/server for:
   - strict compliance clients
   - high-scale clients
   - custom release cadence clients

Decision matrix:

- If client requires strict isolation/compliance -> dedicated bench.
- Otherwise -> multi-site shared bench with strong operational controls.

---

## 8) Compliance and Legal Guardrails

1. Keep GPL copyright/license headers in source files.
2. Keep license files intact.
3. Avoid using ERPNext trademark/logo in your product branding unless policy allows.
4. Maintain an internal process to provide source changes to customers as required by license terms.
5. Avoid claims like “built from scratch”; use “developed/customized by ArsosTech Pvt. Ltd.”

---

## 9) Acceptance Criteria (Ship Gate)

A release is approved only if all pass:

1. No ERPNext/Frappe visible branding on:
   - login
   - desk navbar
   - footer
   - outgoing emails
   - help links/workspace labels
2. White Label Settings update applies without manual code edits.
3. New client onboarding from zero to branded site in target SLA (example: <= 30 minutes).
4. Upgrade dry-run from upstream branch does not break white-label behavior.
5. Automated leak scan passes.

---

## 10) 72-Hour Execution Plan

## Day 1

1. Implement Phase 1 core fixes.
2. Merge and deploy to staging bench.
3. Validate baseline checklist.

## Day 2

1. Build and install `arsostech_whitelabel`.
2. Implement White Label Settings + hooks + runtime apply.
3. Test with two sample client brand profiles.

## Day 3

1. Add onboarding script/runbook.
2. Add leak scan + smoke tests.
3. Final staging sign-off and production rollout.

---

## 11) Risks and Mitigations

1. Risk: branding reappears after upstream merge.
   - Mitigation: automated leak scans + small, isolated diffs + companion app overrides.
2. Risk: hook misuse breaks boot/session.
   - Mitigation: append/compose hooks, never replace existing ERPNext list hooks blindly.
3. Risk: per-site CSS conflicts with upstream assets.
   - Mitigation: use scoped CSS variables and fallback tokens; test common desk pages.
4. Risk: ops complexity across many clients.
   - Mitigation: scripted onboarding and profile-driven config.

---

## 12) Integration Automation Architecture (Email/PDF -> DN/PI)

This use-case is feasible, but should be implemented as a **hybrid**:

1. One-time custom development of a reusable automation engine.
2. Per-client/per-supplier parser and mapping adapters.

Do not treat this as pure no-code automation at first. Incoming email/PDF quality varies heavily and needs controlled parsing and validation.

### 12.1 Recommended Product Model

1. Build in `arsostech_whitelabel` as a reusable module:
   - Email ingestion
   - Attachment extraction (PDF/text/image OCR fallback)
   - Data normalization and validation
   - ERP document orchestration (Delivery Note, Purchase Invoice)
   - PDF generation + notifications (SMS/email)
   - Audit trail, retries, dead-letter queue
2. Keep client users **read-only** for automation internals:
   - They can view runs, statuses, and logs.
   - They cannot edit core automation definitions or mappings.
3. ArsosTech Ops/Admin controls:
   - Parser profiles
   - Mapping rules
   - Confidence thresholds
   - Auto-post policy

### 12.2 Core Components (DocTypes/Modules)

1. `Automation Definition` (managed by ArsosTech only)
   - Trigger type (`incoming_email`, schedule, webhook)
   - Enabled flag
   - Target workflow type (`email_to_dn_pi`)
2. `Parser Profile`
   - Supplier/sender specific parsing strategy
   - Field extraction patterns/template version
   - Confidence thresholds
3. `Automation Run`
   - Message ID/hash
   - Parsed payload
   - Validation status
   - Created doc links
   - Notification status
   - Error logs/retry count
4. `Approval Queue` (optional but recommended for phase 1/2)
   - Human review step before submission/posting

### 12.3 Workflow (Recommended)

1. Receive email in monitored inbox.
2. Deduplicate using `Message-ID` + attachment hash.
3. Parse body/attachment (PDF extractor and OCR fallback when needed).
4. Match sender/supplier to `Parser Profile`.
5. Map extracted fields to ERP schema and validate required data.
6. If confidence < threshold or validation fails:
   - send to approval queue.
7. If confidence >= threshold and policy allows:
   - create Draft Delivery Note/Purchase Invoice (or submit per policy).
8. Generate outbound PDFs and send notifications to configured recipients/drivers.
9. Persist full audit log in `Automation Run`.

### 12.4 Governance and Access Control

1. Roles:
   - `ArsosTech Automation Admin`: full create/edit/deploy access.
   - `ArsosTech Automation Operator`: can reprocess, approve, monitor.
   - `Client Automation Viewer`: read-only visibility.
2. Permissions:
   - Client roles: read on run status/results only.
   - No write/delete on automation definitions/profiles.
3. All manual override actions must be logged with user/time/reason.

### 12.5 Rollout Strategy (Risk-Controlled)

1. Phase A: Assist mode
   - Parse and prepare draft documents only.
   - Human approval required before submit/send.
2. Phase B: Semi-auto
   - Auto-process high-confidence suppliers/templates.
   - Low-confidence goes to approval queue.
3. Phase C: Full auto (limited scope)
   - Only for proven templates with stable accuracy SLA.

### 12.6 Why This is Better Than Pure One-Off Scripts

1. Reusable platform for multiple clients/industries.
2. Lower long-term maintenance and faster onboarding.
3. Better auditability and operational control.
4. Safe path from manual review to controlled automation.

### 12.7 Acceptance Criteria for This Automation

1. Idempotency: same email cannot create duplicate DN/PI.
2. Traceability: each created document links to `Automation Run`.
3. Accuracy target defined per parser profile before full-auto enablement.
4. Failure handling: retries + dead-letter queue + operator alerts.
5. Client users can monitor but cannot alter automation logic.

---

## 13) Immediate Next Actions

1. Approve this corrected plan as the baseline.
2. Implement Phase 1 in a single PR.
3. Spin up `arsostech_whitelabel` app skeleton and start Phase 2.
4. Add the automation foundation backlog item from Section 12 and execute Phase A (assist mode) first.
