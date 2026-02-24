# ArsosTech ERP — Whitelabeling & Multi-Client Deployment Plan (Final)

> Consolidated from four independent plan drafts. Takes the best architecture, surface coverage, correctness, and operational practices from each.

---

## 1. Context & Goals

This is a forked ERPNext/Frappe repo (GPL v3) that **ArsosTech Pvt. Ltd.** will whitelabel, customize, and deploy for multiple clients as a managed ERP product.

**Goals:**
- Remove **all** Frappe Technologies / ERPNext branding from every user-facing surface — UI, emails, help menus, error messages, portal pages, tooltips, and field descriptions
- Replace with each client's own branding (name, logo, colors) via a config-driven Single DocType
- Present the product as an **ArsosTech offering** (clients see "ArsosTech ERP" or their own branded name)
- Make onboarding a new client fast and repeatable (target: < 30 minutes from fresh site to fully branded)
- Maintain ability to pull upstream ERPNext updates without re-introducing branding

**Constraints:**
- This repository is the `erpnext` app only (Frappe framework is a separate app in bench environments)
- ERPNext targets Frappe 16 (`>=16.0.0,<17.0.0` per `pyproject.toml`)
- GPL/trademark obligations apply at source/license level

---

## 2. GPL v3 Compliance

- **Allowed:** Removing Frappe/ERPNext branding from the UI — the license does not require showing Frappe's brand to end users
- **Allowed:** Presenting the product under ArsosTech's brand — standard whitelabeling practice
- **Required:** Keep all `# Copyright (c) Frappe Technologies` headers in source code files intact
- **Required:** Provide clients with access to the source code of this fork upon request (GPL obligation)
- **Not required:** Advertising that this is built on ERPNext/Frappe in the UI or marketing material

**Attribution approach:** Use "Powered by ArsosTech ERP" or simply show ArsosTech/client branding. Avoid claiming "built from scratch" — presenting as an ArsosTech product is standard reseller/whitelabeling practice.

---

## 3. Architecture Strategy

### 3.1 The Companion App Approach

Instead of modifying the ERPNext core extensively (which guarantees painful merge conflicts on upgrades), we use a **companion Frappe app** (`arsostech_whitelabel`) for all branding logic.

```
bench/
├── apps/
│   ├── frappe/                          # Framework (upstream or light fork)
│   ├── erpnext/                         # Whitelabeled ERPNext fork (minimal changes)
│   └── arsostech_whitelabel/            # Branding engine (our app)
│       ├── arsostech_whitelabel/
│       │   ├── hooks.py                 # extend_bootinfo, update_website_context, CSS includes
│       │   ├── whitelabel.py            # Hook function implementations
│       │   ├── doctype/
│       │   │   └── white_label_settings/
│       │   │       ├── white_label_settings.json
│       │   │       └── white_label_settings.py
│       │   ├── public/
│       │   │   ├── css/whitelabel.css   # Generated theme CSS
│       │   │   └── js/whitelabel.js     # Runtime JS overrides (hide help, rebrand)
│       │   └── templates/
│       │       └── includes/footer/
│       │           └── footer_powered.html
│       └── pyproject.toml
```

### 3.2 Ownership Split

| Concern | ERPNext Fork (minimal changes) | `arsostech_whitelabel` App |
|---------|-------------------------------|---------------------------|
| Static metadata (`pyproject.toml`, `app_publisher`) | Yes | — |
| Default mail footer, help links | Yes | — |
| Static image assets (logo SVGs/PNGs) | Yes (replace file content) | — |
| Workspace/patch branding strings | Yes | — |
| White Label Settings DocType | — | Yes |
| Runtime hooks (bootinfo, website context) | — | Yes |
| CSS generation & theme injection | — | Yes |
| Onboarding CLI/API helpers | — | Yes |
| Branding leak CI checks | — | Yes |

This keeps ERPNext fork diffs small and predictable, while all business logic lives in our fully-owned app.

### 3.3 Deployment Topology

**One Frappe bench per client** (separate server or VM per client).

| Benefit | Detail |
|---------|--------|
| Full data isolation | Each client's data is completely separate — no risk of cross-contamination |
| Independent upgrades | Upgrade one client without affecting others |
| Simple mental model | One deployment = one client = one bench |
| Custom configuration | Per-client `site_config.json`, Python dependencies, and integrations without side effects |
| Easier debugging | Issues are isolated to a single bench/client |

**New client workflow:**
1. Provision server → install Frappe bench → install Frappe + ERPNext fork + `arsostech_whitelabel`
2. Create site → run setup wizard
3. Open **White Label Settings** → fill in client name, logo, colors → Save → done

---

## 4. Phased Implementation Plan

### Phase 0 — Baseline & Safety (Day 0)

1. Create working branch: `whitelabel-foundation`
2. Run branding inventory scan — capture all visible "ERPNext", "Frappe Technologies", `erpnext.com`, `frappe.io` strings in user-facing files
3. Commit baseline scan report to `docs/whitelabel/branding-inventory.md`
4. Create `arsostech_whitelabel` app scaffold: `bench new-app arsostech_whitelabel`

**Deliverable:** Branch ready, baseline documented, app skeleton created.

---

### Phase 1 — Ship-Blocking Fork Fixes (Day 1)

Minimal, targeted edits in the ERPNext fork. These are **P0 — clients WILL see these**.

#### 1.1 `erpnext/hooks.py`

| Line(s) | Current | Change To |
|---------|---------|-----------|
| 2 | `app_title = "ERPNext"` | `app_title = "ERP"` |
| 3 | `app_publisher = "Frappe Technologies Pvt. Ltd."` | `app_publisher = "ArsosTech Pvt. Ltd."` |
| 7 | `app_email = "hello@frappe.io"` | `app_email = "contact@arsostech.com"` |
| 9 | `source_link = "https://github.com/frappe/erpnext"` | Remove or point to Bitbucket repo |
| 10 | `app_logo_url = "/assets/erpnext/images/erpnext-logo.svg"` | Keep (we replace the file content) |
| 487 | `email_brand_image` referencing erpnext-logo.jpg | Verify file exists; update to `.png` if needed |
| 489–496 | `default_mail_footer` with "Sent via ERPNext" | Replace (see below) |

New mail footer:
```python
default_mail_footer = """<div style="padding:7px;text-align:right;color:#888">
    <small>Sent via <a style="color:#888" href="https://arsostech.com">ArsosTech ERP</a></small></div>"""
```

> **Important:** Do NOT replace the existing `extend_bootinfo` list — it's already a list in hooks.py. The companion app will **append** its own hook function via its own `hooks.py`. Do NOT replace `website_context` dict with a function path — the companion app uses `update_website_context` hook instead.

#### 1.2 `erpnext/setup/install.py`

| Line(s) | Issue | Fix |
|---------|-------|-----|
| 16–17 | `default_mail_footer` with `frappe.io/erpnext` | Replace with ArsosTech footer |
| 190 | Help: Documentation → `docs.erpnext.com` | Change to ArsosTech docs URL or remove |
| 196 | Help: User Forum → `discuss.frappe.io` | Remove or replace |
| 200 | Help: `"Frappe School"` label | Remove entirely |
| 202 | Help: `frappe.io/school` route | Remove entirely |
| 208 | Help: Report Issue → `github.com/frappe/erpnext/issues` | Change to ArsosTech support URL |
| 238 | `app_name` set to `"ERPNext"` | Change to `"ERP"` |

#### 1.3 `erpnext/templates/includes/footer/footer_powered.html`

```html
{{ _("Powered by {0}").format('<a href="https://arsostech.com" target="_blank" class="text-muted">ArsosTech ERP</a>') }}
```

#### 1.4 `erpnext/public/js/help_links.js`

Line 3: `const docsUrl = "https://erpnext.com/docs/";` → Change to your docs URL or `/help/docs/`

This single variable controls every "?" help icon in the entire desk — high-visibility leak.

#### 1.5 Workspace Deprecation Banners

- `erpnext/crm/workspace/crm/crm.json` — Remove "Frappe CRM" reference
- `erpnext/support/workspace/support/support.json` — Remove "Frappe Helpdesk" reference

Replace with: `"This module may be replaced in a future version. Contact ArsosTech for details."`

#### 1.6 Static Image Assets — `erpnext/public/images/`

Replace **file content** (keep filenames the same so all existing references resolve):

| File | Usage |
|------|-------|
| `erpnext-logo.svg` | Main logo (login splash, navbar, apps screen) |
| `erpnext-favicon.svg` | Browser tab favicon |
| `erpnext-logo.png` | Raster logo |
| `erpnext-logo-blue.png` | Blue variant |
| `erpnext-video-placeholder.jpg` | Video thumbnail |
| `v16/erpnext.svg` | v16 branded SVG |

Also replace desktop icon SVGs:
- `erpnext/public/desktop_icons/erpnext_settings.svg`
- `erpnext/public/icons/desktop_icons/solid/erpnext_settings.svg`
- `erpnext/public/icons/desktop_icons/subtle/erpnext_settings.svg`

> **Note:** `erpnext-logo.jpg` is referenced in `hooks.py:487` but may not exist on disk. Verify and create or update the reference.

#### 1.7 `erpnext/startup/__init__.py`

Line 19: `product_name = "ERPNext"` → `product_name = "ERP"`

#### 1.8 `pyproject.toml`

| Field | Change To |
|-------|-----------|
| `authors` | `ArsosTech Pvt. Ltd.` with contact email |
| `Homepage` | ArsosTech URL or remove |
| `Repository` | Private repo URL or remove |
| `Bug Reports` | ArsosTech support URL or remove |

#### 1.9 Patch App Name Reset Prevention

- `erpnext/patches/v13_0/set_app_name.py` — Change `"ERPNext"` to `"ERP"`
- `erpnext/patches.txt` line 194 — Change inline `'ERPNext'` to `'ERP'`

**Deliverable:** One PR with all P0 branding leak plugs in the ERPNext fork.

---

### Phase 2 — Build `arsostech_whitelabel` App (Day 1–2)

#### 2.1 White Label Settings DocType (Single)

Path: `arsostech_whitelabel/arsostech_whitelabel/doctype/white_label_settings/`

| Fieldname | Type | Label | Default | Notes |
|-----------|------|-------|---------|-------|
| **Section: Branding** | | | | |
| `client_name` | Data | App / Client Name | `"ArsosTech ERP"` | Navbar, login page, emails, browser title |
| `client_logo` | Attach Image | App Logo | — | Login splash + navbar logo |
| `client_favicon` | Attach Image | Favicon | — | Browser tab icon |
| `login_background_image` | Attach Image | Login Background | — | Custom background for `/login` |
| `email_logo` | Attach Image | Email Header Logo | — | Outgoing emails |
| **Section: Colors** | | | | |
| `primary_color` | Color | Primary Color | — | Buttons, sidebar, links |
| `secondary_color` | Color | Secondary Color | — | Accents |
| `sidebar_color` | Color | Sidebar Color | — | Sidebar background |
| `navbar_color` | Color | Navbar Color | — | Top navbar background |
| `custom_css` | Code (CSS) | Additional Custom CSS | — | Freeform overrides |
| **Section: Developer Credit** | | | | |
| `developer_name` | Data | Developer / Provider Name | `"ArsosTech Pvt. Ltd."` | Footer, about |
| `developer_url` | Data | Developer Website | `"https://arsostech.com"` | Link in footer |
| `show_powered_by` | Check | Show "Powered by" in footer | `1` | Toggle visibility |
| **Section: Support & Links** | | | | |
| `help_url` | Data | Help / Docs URL | — | Override help_links.js base URL |
| `support_email` | Data | Support Email | — | Shown in help menu |
| `support_url` | Data | Support URL | — | Link for "Report Issue" |
| `privacy_url` | Data | Privacy Policy URL | — | Footer link |
| `terms_url` | Data | Terms of Service URL | — | Footer link |

**Validation rules:**
- Enforce valid hex color format on all color fields
- Image file type validation (SVG/PNG/JPG only)
- Image size check (warn if > 500KB)
- Graceful fallbacks when fields are empty

#### 2.2 Controller (`white_label_settings.py`)

```python
import frappe
from frappe.model.document import Document

class WhiteLabelSettings(Document):
    def validate(self):
        self.validate_colors()

    def on_update(self):
        self.update_system_settings()
        self.update_website_settings()
        self.generate_theme_css()
        frappe.clear_cache()

    def validate_colors(self):
        import re
        hex_pattern = re.compile(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$')
        for field in ("primary_color", "secondary_color", "sidebar_color", "navbar_color"):
            value = self.get(field)
            if value and not hex_pattern.match(value):
                frappe.throw(f"Invalid hex color for {self.meta.get_label(field)}: {value}")

    def update_system_settings(self):
        if self.client_name:
            frappe.db.set_single_value("System Settings", "app_name", self.client_name)
        if self.client_logo:
            frappe.db.set_single_value("System Settings", "app_logo", self.client_logo)
        if self.email_logo:
            frappe.db.set_single_value("System Settings", "email_logo", self.email_logo)

    def update_website_settings(self):
        if self.client_favicon:
            frappe.db.set_single_value("Website Settings", "favicon", self.client_favicon)
        if self.client_logo:
            frappe.db.set_single_value("Website Settings", "splash_image", self.client_logo)

    def generate_theme_css(self):
        css_parts = []
        if self.primary_color:
            css_parts.append(f""":root {{
    --primary: {self.primary_color};
    --primary-color: {self.primary_color};
    --btn-primary-bg: {self.primary_color};
}}""")
        if self.sidebar_color:
            css_parts.append(f".desk-sidebar, .standard-sidebar {{ background-color: {self.sidebar_color}; }}")
        if self.navbar_color:
            css_parts.append(f".navbar {{ background-color: {self.navbar_color} !important; }}")
        if self.custom_css:
            css_parts.append(self.custom_css)

        css_content = "\n".join(css_parts)
        css_path = frappe.get_app_path("arsostech_whitelabel", "public", "css", "whitelabel.css")
        with open(css_path, "w") as f:
            f.write(css_content)
```

#### 2.3 Hook Functions (`whitelabel.py`)

```python
import frappe

def get_website_context(context):
    """Called by update_website_context hook — sets favicon, splash, background for portal pages."""
    try:
        settings = frappe.get_cached_doc("White Label Settings")
    except frappe.DoesNotExistError:
        return

    if settings.client_favicon:
        context["favicon"] = settings.client_favicon
    if settings.client_logo:
        context["splash_image"] = settings.client_logo
    if settings.login_background_image:
        context["background_image"] = settings.login_background_image

def extend_bootinfo(bootinfo):
    """Called by extend_bootinfo hook — injects branding into desk session."""
    try:
        settings = frappe.get_cached_doc("White Label Settings")
    except frappe.DoesNotExistError:
        return

    bootinfo.whitelabel = {
        "client_name": settings.client_name,
        "client_logo": settings.client_logo,
        "primary_color": settings.primary_color,
        "developer_name": settings.developer_name,
        "help_url": settings.help_url,
        "support_email": settings.support_email,
    }
    if settings.client_name:
        bootinfo.app_name = settings.client_name  # Forces the navbar string
```

#### 2.4 Companion App `hooks.py`

```python
app_name = "arsostech_whitelabel"
app_title = "ArsosTech Whitelabel"
app_publisher = "ArsosTech Pvt. Ltd."
app_description = "Whitelabeling and branding engine for ArsosTech ERP deployments"

# IMPORTANT: Use update_website_context (appends), NOT website_context (replaces)
update_website_context = "arsostech_whitelabel.whitelabel.get_website_context"

# IMPORTANT: This appends to the existing extend_bootinfo list — does not replace ERPNext's hooks
extend_bootinfo = "arsostech_whitelabel.whitelabel.extend_bootinfo"

# CSS and JS includes
app_include_css = "/assets/arsostech_whitelabel/css/whitelabel.css"
app_include_js = "/assets/arsostech_whitelabel/js/whitelabel.js"
web_include_css = "/assets/arsostech_whitelabel/css/whitelabel.css"
```

> **Critical corrections applied here (from Codex plan):**
> - `extend_bootinfo` is already a list in ERPNext's hooks.py — the companion app's hook appends, never replaces
> - Use `update_website_context` (which safely merges), NOT `website_context` (which would override ERPNext's static dict)
> - CSS is written to the companion app's public directory (site-safe), not into the ERPNext source tree

#### 2.5 Runtime JS Overrides (`whitelabel.js`)

```javascript
// Hide Frappe help menu items and rebrand desk elements
$(document).ready(function () {
    // Hide the default Help dropdown if it contains Frappe/ERPNext links
    if (frappe.boot.whitelabel) {
        var wl = frappe.boot.whitelabel;
        // Override document title
        if (wl.client_name) {
            document.title = document.title.replace(/ERPNext/g, wl.client_name);
        }
    }
});
```

**Deliverable:** Installable companion app with single-save branding update.

---

### Phase 3 — P1 Polish (Day 2–3, before first client delivery)

#### 3.1 Desktop Icon & Workspace JSON Fixtures

| File | Change |
|------|--------|
| `erpnext/desktop_icon/erpnext.json` | `"label": "ERPNext"` → `"ERP"`, update `logo_url`, `name` |
| `erpnext/desktop_icon/erpnext_settings.json` | `"label"/"link_to"/"name"` → `"ERP Settings"` |
| All module desktop icons (9 files) | `"parent_icon": "ERPNext"` → `"ERP"` |
| `erpnext/setup/workspace/erpnext_settings/erpnext_settings.json` | `"ERPNext Settings"` → `"ERP Settings"` |
| `erpnext/workspace_sidebar/erpnext_settings.json` | `"ERPNext Settings"` → `"ERP Settings"` |

#### 3.2 User-Facing JS Field Descriptions

| File | Issue |
|------|-------|
| `buying/doctype/buying_settings/buying_settings.js` | "ERPNext will prevent you..." → "The system will prevent you..." |
| `stock/doctype/item/item.js` | "ERPNext will make a stock ledger entry..." → "The system will..." + remove docs.frappe.io link |
| `accounts/doctype/bank_account/bank_account.js` | "integrating ERPNext with your bank" → "integrating the system with your bank" |
| `manufacturing/doctype/production_plan/production_plan.js` | Remove erpnext.com/docs link |
| `public/js/conf.js` | `"ERPNext Integrations": "Integrations"` breadcrumb label |

#### 3.3 Email Subjects & Error Messages

| File | Fix |
|------|-----|
| `stock/reorder_item.py` | `"[Important] [ERPNext] Auto Reorder Errors"` → `"[Important] Auto Reorder Errors"` |
| `stock/stock_ledger.py` | Remove `docs.erpnext.com` link in msgprint |
| `setup/utils.py` | Change `test@erpnext.com` email, change fallback name from `"ERPNext"` to `"ERP"` |

#### 3.4 CRM Integration Labels

`erpnext/crm/frappe_crm_api.py` — `"Frappe CRM Deal"` → `"CRM Deal"`

#### 3.5 Frappe Framework Branding Overrides

Start with **Option B (runtime overrides)** for speed:

1. **System Settings** (set by White Label Settings `on_update`): `app_name`, `app_logo`
2. **Website Settings** (set by White Label Settings `on_update`): `splash_image`, `favicon`, `footer_powered`
3. **Navbar Settings**: Override help dropdown items during install
4. **Login page**: Frappe reads `app_name` and `app_logo` from System Settings — if set correctly, login shows our branding

If specific Frappe surfaces can't be overridden via settings, selectively fork those templates later (**Option A** as fallback).

**Deliverable:** All P1 items resolved. Run branding CI check. Full verification checklist pass.

---

### Phase 4 — Hardening (Day 3–4, before scaling to multiple clients)

#### 4.1 P2 — DocType JSON documentation URLs

All `documentation_url` fields pointing to `docs.erpnext.com` or `docs.frappe.io/erpnext`:

| File |
|------|
| `accounts/doctype/accounts_settings/accounts_settings.json` |
| `accounts/doctype/payment_reconciliation/payment_reconciliation.json` |
| `accounts/doctype/process_payment_reconciliation/process_payment_reconciliation.json` |
| `setup/doctype/company/company.json` (2 fields) |
| `stock/doctype/stock_settings/stock_settings.json` |
| `manufacturing/doctype/production_plan/production_plan.json` |

**Fix:** Point to own docs, or remove `documentation_url` values (the "?" icon simply won't appear).

#### 4.2 P2 — DocType Field Labels & Module Names

- `setup/doctype/employee_group_table/employee_group_table.json` — `"ERPNext User ID"` → `"System User ID"`
- `erpnext_integrations/doctype/plaid_settings/plaid_settings.json` — module name in breadcrumbs
- `modules.txt` — `ERPNext Integrations` → consider renaming (requires directory rename + DocType updates; can defer)
- `setup/setup_wizard/data/sample_blog_post.html` — Replace ERPNext sample content
- `www/payment_setup_certification.html` — Update page title

#### 4.3 P3 — Historical Patches (low risk)

Bulk find-replace of "ERPNext" → "the system" in deprecation warning patch strings:

| Patch File |
|------------|
| `patches/v13_0/set_app_name.py` |
| `patches/v13_0/healthcare_deprecation_warning.py` |
| `patches/v13_0/hospitality_deprecation_warning.py` |
| `patches/v13_0/agriculture_deprecation_warning.py` |
| `patches/v13_0/non_profit_deprecation_warning.py` |
| `patches/v13_0/shopify_deprecation_warning.py` |
| `patches/v13_0/show_hr_payroll_deprecation_warning.py` |
| `patches/v13_0/show_india_localisation_deprecation_warning.py` |
| `patches/v13_0/update_docs_link.py` |
| `patches/v14_0/show_loan_management_deprecation_warning.py` |
| `patches/v15_0/remove_exotel_integration.py` |

#### 4.4 Branding CI Check Script

Create `scripts/check-branding.sh`:

```bash
#!/bin/bash
# Fail if any user-facing file contains forbidden branding strings.
# Run in CI after every merge from upstream.

FORBIDDEN_PATTERNS=(
    "Frappe Technologies"
    "frappe.io/erpnext"
    "docs.erpnext.com"
    "erpnext.com/docs"
    "discuss.frappe.io"
    "frappe.io/school"
    "Frappe School"
    "Frappe CRM"
    "Frappe Helpdesk"
)

FOUND=0
for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    results=$(grep -rn "$pattern" erpnext/ \
        --include='*.html' --include='*.js' --include='*.css' \
        --exclude-dir='node_modules' --exclude-dir='.git' \
        | grep -v 'test_' | grep -v '__pycache__')
    if [ -n "$results" ]; then
        echo "FOUND: '$pattern'"
        echo "$results"
        FOUND=1
    fi
done

# JSON labels, titles, and documentation URLs
for pattern in "ERPNext" "erpnext.com" "frappe.io"; do
    results=$(grep -rn "\"label\".*$pattern\|\"title\".*$pattern\|\"documentation_url\".*$pattern" erpnext/ \
        --include='*.json' \
        | grep -v '__pycache__')
    if [ -n "$results" ]; then
        echo "FOUND in JSON: '$pattern'"
        echo "$results"
        FOUND=1
    fi
done

if [ $FOUND -eq 1 ]; then
    echo ""
    echo "FAIL: Forbidden branding strings found. Fix before deploying."
    exit 1
else
    echo "PASS: No forbidden branding strings found."
    exit 0
fi
```

Run as a Bitbucket Pipeline on every PR and after every upstream merge.

#### 4.5 Upstream Merge Strategy

Since this is a **standalone Bitbucket repo** (not a Bitbucket fork), add the original ERPNext as a secondary remote for pulling upstream updates:

```bash
git remote add upstream https://github.com/frappe/erpnext.git
```

When upstream releases a new version:
```bash
git fetch upstream
git checkout -b merge/upstream-v16.x version-16
git merge upstream/version-16
# Resolve conflicts — focus on hooks.py, install.py, template files
bash scripts/check-branding.sh
# Fix any new branding leaks, test, then merge to version-16
git push origin merge/upstream-v16.x
# Create PR in Bitbucket for review before merging
```

Because the companion app handles runtime logic, merge conflicts are limited to the small set of static changes in Phase 1.

**Deliverable:** All P2/P3 items done. CI check passing. Upstream merge workflow documented.

---

### Phase 5 — Client Onboarding Automation (Day 4–5)

#### 5.1 Manual Onboarding Workflow

1. **Provision server** → install Frappe bench → install Frappe + ERPNext fork + `arsostech_whitelabel`
2. **Create site** → `bench new-site client.example.com`
3. **Install apps** → `bench --site client.example.com install-app erpnext` then `install-app arsostech_whitelabel`
4. **Run setup wizard** → company name, country, chart of accounts
5. **Open White Label Settings** in desk:
   - Set Client Name, upload logos, pick colors
   - Developer credit defaults to "ArsosTech Pvt. Ltd."
   - Click **Save** → system auto-updates settings, generates CSS, clears cache
6. **Rebuild assets** if needed: `bench --site client.example.com build`
7. **Done** — deployment is fully branded

#### 5.2 Scripted Onboarding (future)

```bash
bench --site client.example.com execute arsostech_whitelabel.api.apply_brand_profile \
    --kwargs '{"client_name": "Acme Corp ERP", "primary_color": "#2E86AB", "logo_path": "/path/to/logo.svg"}'
```

Or a custom bench command:
```bash
bench --site client.example.com whitelabel \
    --name "Acme Corp ERP" \
    --logo /path/to/logo.svg \
    --favicon /path/to/favicon.svg \
    --primary-color "#2E86AB"
```

**Deliverable:** `docs/whitelabel/onboarding-runbook.md` + optional scripted onboarding.

---

## 5. Complete File Manifest

### Files to Modify in ERPNext Fork

| # | File | What Changes | Phase |
|---|------|-------------|-------|
| 1 | `erpnext/hooks.py` | app_title, app_publisher, app_email, source_link, mail footer | P1 |
| 2 | `erpnext/setup/install.py` | mail footer, navbar help items, app_name | P1 |
| 3 | `erpnext/templates/includes/footer/footer_powered.html` | "Powered by ArsosTech ERP" | P1 |
| 4 | `erpnext/public/js/help_links.js` | `docsUrl` variable | P1 |
| 5 | `erpnext/crm/workspace/crm/crm.json` | Remove Frappe CRM deprecation banner | P1 |
| 6 | `erpnext/support/workspace/support/support.json` | Remove Frappe Helpdesk deprecation banner | P1 |
| 7 | `erpnext/public/images/` (6+ files) | Replace content with ArsosTech assets | P1 |
| 8 | `erpnext/public/desktop_icons/` (3 files) | Replace icon SVGs | P1 |
| 9 | `erpnext/startup/__init__.py` | `product_name` | P1 |
| 10 | `pyproject.toml` | Authors, URLs | P1 |
| 11 | `erpnext/patches/v13_0/set_app_name.py` | "ERPNext" → "ERP" | P1 |
| 12 | `erpnext/patches.txt` | Inline patch app name | P1 |
| 13 | `erpnext/desktop_icon/*.json` (11 files) | Labels, names, parent_icon | P3 |
| 14 | `erpnext/setup/workspace/erpnext_settings/erpnext_settings.json` | Labels | P3 |
| 15 | `erpnext/workspace_sidebar/erpnext_settings.json` | Labels | P3 |
| 16 | `erpnext/buying/doctype/buying_settings/buying_settings.js` | Field descriptions | P3 |
| 17 | `erpnext/stock/doctype/item/item.js` | Field descriptions, doc link | P3 |
| 18 | `erpnext/accounts/doctype/bank_account/bank_account.js` | Dialog text | P3 |
| 19 | `erpnext/manufacturing/doctype/production_plan/production_plan.js` | Doc link | P3 |
| 20 | `erpnext/public/js/conf.js` | Breadcrumb label | P3 |
| 21 | `erpnext/stock/reorder_item.py` | Email subject | P3 |
| 22 | `erpnext/stock/stock_ledger.py` | Doc link in msgprint | P3 |
| 23 | `erpnext/setup/utils.py` | Test email, fallback name | P3 |
| 24 | `erpnext/crm/frappe_crm_api.py` | "Frappe CRM Deal" labels | P3 |
| 25 | 6 DocType JSONs | `documentation_url` fields | P4 |
| 26 | `erpnext/setup/doctype/employee_group_table/employee_group_table.json` | Field label | P4 |
| 27 | `erpnext/modules.txt` | Module name (deferred) | P4 |
| 28 | 11 patch files | Deprecation warning text | P4 |

### Files to Create (in `arsostech_whitelabel` app)

| # | File | Purpose |
|---|------|---------|
| 1 | `arsostech_whitelabel/hooks.py` | App hooks (bootinfo, website context, CSS/JS includes) |
| 2 | `arsostech_whitelabel/whitelabel.py` | Hook function implementations |
| 3 | `arsostech_whitelabel/doctype/white_label_settings/white_label_settings.json` | DocType definition |
| 4 | `arsostech_whitelabel/doctype/white_label_settings/white_label_settings.py` | Controller |
| 5 | `arsostech_whitelabel/public/css/whitelabel.css` | Generated theme CSS |
| 6 | `arsostech_whitelabel/public/js/whitelabel.js` | Runtime JS overrides |
| 7 | `arsostech_whitelabel/templates/includes/footer/footer_powered.html` | Dynamic footer (optional) |
| 8 | `scripts/check-branding.sh` | CI branding check script |

---

## 6. Verification Checklist

After implementing all changes and configuring White Label Settings:

| # | Check | Where | Expected |
|---|-------|-------|----------|
| 1 | Login page logo | `/login` | Client logo, not ERPNext |
| 2 | Login page title | Browser tab on `/login` | Client name, not ERPNext |
| 3 | Browser favicon | Any page | Client favicon |
| 4 | Desk navbar | Top bar after login | Client name and logo |
| 5 | Primary color | Buttons, links, sidebar | Client brand color |
| 6 | Help dropdown | Navbar "?" menu | ArsosTech links, no Frappe/ERPNext |
| 7 | Help icons ("?") | Any form with "?" icons | Your docs URL or no link |
| 8 | Outgoing email | Send any email | Client logo in header, ArsosTech in footer |
| 9 | Website footer | Public portal pages | "Powered by ArsosTech ERP" |
| 10 | CRM workspace | Open CRM module | No "Frappe CRM" deprecation banner |
| 11 | Support workspace | Open Support module | No "Frappe Helpdesk" deprecation banner |
| 12 | Settings workspace | Sidebar navigation | "ERP Settings" not "ERPNext Settings" |
| 13 | Buying Settings | Open form | No "ERPNext" in field descriptions |
| 14 | Item form | Open any item | No "ERPNext" in descriptions |
| 15 | Auto Reorder email | Trigger reorder error | No "[ERPNext]" in subject |
| 16 | Source code headers | `.py` files | `# Copyright (c) Frappe Technologies` intact (GPL) |
| 17 | Branding CI check | `bash scripts/check-branding.sh` | PASS |

---

## 7. Acceptance Criteria (Ship Gate)

A release is approved only if ALL pass:

1. No ERPNext/Frappe visible branding on login, desk navbar, footer, outgoing emails, help links, workspace labels
2. White Label Settings update applies branding without manual code edits or server restart
3. New client onboarding from zero to branded site in ≤ 30 minutes
4. Upgrade dry-run from upstream branch does not break white-label behavior
5. Automated branding leak scan passes
6. Source code GPL copyright headers remain intact

---

## 8. Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Branding reappears after upstream merge | Automated leak scans + small isolated diffs in fork + companion app overrides |
| Hook misuse breaks boot/session | Append/compose hooks, never replace existing ERPNext list hooks |
| Per-site CSS conflicts with upstream assets | Use scoped CSS variables and fallback tokens; test common desk pages |
| Ops complexity across many clients | Scripted onboarding and profile-driven config |
| Frappe framework surfaces not coverable via settings | Start with Option B (runtime overrides); fork specific templates as needed |

---

## 9. Custom Client Integrations Architecture

> For clients requiring custom workflow automations (email-to-document processing, PDF generation, SMS/email dispatch).

### 9.1 Philosophy

**Do NOT build a generic automation/workflow builder.** Frappe already has automation primitives (Server Scripts, Webhooks, Email Rules, Scheduled Jobs). Each client's automation is unique — the email format, PDF layout, and business rules differ per client. Build **structured custom dev with reusable building blocks**, not a visual drag-and-drop engine.

### 9.2 Separate App: `arsostech_integrations`

```
arsostech_integrations/
├── arsostech_integrations/
│   ├── hooks.py                   # Scheduled jobs, email hooks
│   ├── shared/                    # Reusable utilities (build once)
│   │   ├── email_ingestion.py     # Email polling, attachment extraction
│   │   ├── pdf_parser.py          # PDF table/text extraction (pdfplumber + LLM fallback)
│   │   ├── document_creator.py    # Create DN/PI/SO from structured data
│   │   ├── pdf_generator.py       # Generate PDFs from Print Formats
│   │   ├── notification.py        # SMS and email notifications
│   │   └── field_mapper.py        # Map external names → ERPNext masters
│   ├── client_acme/               # Acme Corp specific automations
│   │   ├── config.py              # Acme-specific settings
│   │   ├── order_email_parser.py  # Parse Acme's order confirmation format
│   │   └── dispatch_workflow.py   # DN creation + driver SMS logic
│   ├── client_beta/               # Beta Inc specific automations
│   └── templates/                 # Shared Jinja templates for custom PDFs
```

### 9.3 Three-Layer Pattern Per Integration

```
┌─────────────────────────────────────────────────┐
│  Layer A: Ingestion (REUSABLE)                   │
│  Email Account polling, webhook, cron, manual    │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────┐
│  Layer B: Parser / Transformer (PER-CLIENT)      │
│  Extract structured data, validate, map fields   │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────┐
│  Layer C: Action (REUSABLE)                      │
│  Create docs, generate PDFs, send SMS/email      │
└─────────────────────────────────────────────────┘
```

The per-client work is **almost entirely in Layer B** (the parser). Layers A and C are built once and reused.

### 9.4 PDF Parsing Strategy

| Approach | When | Pros | Cons |
|----------|------|------|------|
| **Structured (pdfplumber)** | Known fixed format from supplier | Fast, free, deterministic | Breaks if format changes |
| **LLM-based (Claude API)** | Variable/messy formats | Handles any format, adapts | ~$0.01-0.05/page, needs validation |

**Start with structured** for each known supplier format. Add **LLM as fallback** for new/unknown formats.

### 9.5 Error Handling

Every automation MUST have a failure path — emails are never silently dropped.

- Use Frappe **Error Log** as a failed import queue
- Optionally create an **Integration Log** DocType for visibility into processed vs failed items
- Deduplication via `Message-ID` + attachment hash (idempotency)
- Full audit trail: each created document links back to source

### 9.6 Rollout Strategy (Risk-Controlled)

| Phase | Mode | Description |
|-------|------|-------------|
| A | Assist | Parse and prepare draft documents only. Human approval before submit. |
| B | Semi-auto | Auto-process high-confidence suppliers. Low-confidence → approval queue. |
| C | Full auto | Only for proven templates with stable accuracy. |

### 9.7 Governance

| Role | Access |
|------|--------|
| ArsosTech Automation Admin | Full create/edit/deploy |
| ArsosTech Automation Operator | Reprocess, approve, monitor |
| Client Automation Viewer | Read-only on run status/results |

### 9.8 Estimated Effort

| Component | First Client | Each Additional |
|-----------|-------------|----------------|
| Shared utilities | 3–4 days | 0 (reuse) |
| Per-client parser + business rules | 5–8 days | 3–6 days |
| Testing + edge cases | 2–3 days | 1–2 days |
| **Total** | **~2 weeks** | **~1 week** |

---

## 10. Open Decisions

### Whitelabeling
- [ ] **Frappe fork vs runtime overrides:** Start with Option B; evaluate if any surfaces require forking
- [ ] **Docs hosting:** Where will `help_links.js` point? Host own docs, remove links, or "coming soon" page
- [ ] **Logo assets:** Create ArsosTech branded SVG/PNG/favicon defaults
- [ ] **Bitbucket repos:** Ensure standalone repos are set up for both the ERPNext codebase and the companion app
- [ ] **"ERPNext Integrations" module rename:** Worth the directory rename effort? Or acceptable as admin-only?
- [ ] **Test on clean bench:** After Phase 1, fresh `bench new-site` + full UI walkthrough

### Custom Integrations
- [ ] **Create `arsostech_integrations` app** scaffold
- [ ] **First client identification:** Get sample order emails/PDFs to build the parser
- [ ] **SMS provider:** Choose gateway (Twilio, local provider)
- [ ] **PDF parsing library:** Install `pdfplumber` as dependency
- [ ] **Claude API key:** Provision for LLM-based parsing if needed
- [ ] **Integration Log DocType:** Need from day one or add later?

---

## 11. 5-Day Execution Timeline

| Day | Focus | Deliverable |
|-----|-------|------------|
| 0 | Baseline scan, branch setup, app scaffold | Inventory report, `arsostech_whitelabel` skeleton |
| 1 | Phase 1 P0 fork fixes | PR with all ship-blocking branding plugs |
| 2 | Phase 2 companion app (DocType + hooks + CSS) | Working White Label Settings with live branding |
| 3 | Phase 3 P1 polish + Frappe overrides | Full desk/portal branding clean |
| 4 | Phase 4 P2/P3 hardening + CI check + docs | Branding scan passing, onboarding runbook |
| 5 | Phase 5 test with 2 sample client profiles | End-to-end verification, ready for first client |
