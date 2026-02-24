# ArsosTech ERP — Whitelabeling & Multi-Client Deployment Plan (Revised)

> Revised by Claude Opus 4.6 — covers the full branding surface area across both ERPNext and Frappe framework layers.

## Context

This is a forked ERPNext/Frappe repo (GPL v3 licensed) that **ArsosTech Pvt. Ltd.** will whitelabel, customize, and deploy for multiple clients as a managed ERP product. The goals are:

- Remove **all** Frappe Technologies / ERPNext branding from every user-facing surface — UI, emails, help menus, error messages, portal pages, tooltips, and field descriptions
- Replace with each client's own branding (name, logo, colors) via a config-driven system
- Present the product as an **ArsosTech offering** (clients see "ArsosTech ERP" or their own branded name)
- Make onboarding a new client fast and repeatable
- Maintain ability to pull upstream ERPNext updates without re-introducing branding

---

## GPL v3 Compliance

Since upstream ERPNext and Frappe are GPL v3:

- **Allowed:** Removing Frappe/ERPNext branding from the UI — the license does not require showing Frappe's brand
- **Allowed:** Presenting the product under ArsosTech's brand — standard whitelabeling practice
- **Required:** Keep all `# Copyright (c) Frappe Technologies` headers in source code files intact
- **Required:** Provide clients with access to the source code of this fork upon request (GPL obligation)
- **Not required:** Advertising that this is built on ERPNext/Frappe in the UI or marketing material

**Attribution approach:** Use "Powered by ArsosTech ERP" or simply show ArsosTech/client branding with no mention of the underlying platform.

---

## Deployment Model

**One Frappe bench per client** (separate server or VM). Reasons:
- Full data isolation per client
- Independent upgrade cycles
- Simple mental model — one deployment = one client
- Frappe multi-site is an alternative but adds operational complexity

**New client workflow:**
1. Provision server → install Frappe bench → install Frappe + this ERPNext fork
2. Create site → run setup wizard
3. Open **White Label Settings** → fill in client name, logo, colors → Save → done

---

## Architecture Overview

The whitelabeling system has **two layers** that work together:

```
┌─────────────────────────────────────────────────────┐
│  Layer 1: Fork-Level Cleanup (one-time, all clients) │
│  - Remove/replace all hardcoded ERPNext/Frappe text  │
│  - Replace logo assets with ArsosTech defaults       │
│  - Neutralize help links, deprecation banners        │
│  - Fix Frappe framework branding via overrides       │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│  Layer 2: Runtime Config (per-client, via DocType)   │
│  - White Label Settings Single DocType               │
│  - Client name, logo, favicon, colors, CSS           │
│  - on_update() syncs to System Settings + CSS vars   │
│  - Hooks: website_context, extend_bootinfo           │
└─────────────────────────────────────────────────────┘
```

---

## Layer 1 — Fork-Level Cleanup (One-Time)

These are hardcoded references that must be permanently changed in the codebase. Organized by priority.

### P0 — Ship-Blocking (clients WILL see these)

#### 1.1 `erpnext/hooks.py`

| Line(s) | Current | Change To |
|---------|---------|-----------|
| 2 | `app_title = "ERPNext"` | `app_title = "ERP"` (generic; overridden per-client by White Label Settings) |
| 3 | `app_publisher = "Frappe Technologies Pvt. Ltd."` | `app_publisher = "ArsosTech Pvt. Ltd."` |
| 7 | `app_email = "hello@frappe.io"` | `app_email = "contact@arsostech.com"` |
| 9 | `source_link = "https://github.com/frappe/erpnext"` | Remove or point to private repo |
| 10 | `app_logo_url = "/assets/erpnext/images/erpnext-logo.svg"` | Update path after renaming assets (see 1.6) |
| 16 | `"logo": "/assets/erpnext/images/erpnext-logo.svg"` | Update path |
| 118 | `"favicon": "/assets/erpnext/images/erpnext-favicon.svg"` | Update path |
| 119 | `"splash_image": "/assets/erpnext/images/erpnext-logo.svg"` | Update path |
| 487 | `email_brand_image = "assets/erpnext/images/erpnext-logo.jpg"` | Update path (NOTE: `.jpg` file may not exist — verify and use `.png` if needed) |
| 489–496 | `default_mail_footer` with "Sent via ERPNext" and `frappe.io` link | Replace with ArsosTech footer (see below) |

New mail footer:
```python
default_mail_footer = """<div style="padding:7px;text-align:right;color:#888">
    <small>Sent via <a style="color:#888" href="https://arsostech.com">ArsosTech ERP</a></small></div>"""
```

Also add/modify these hooks (detailed in Layer 2):
```python
website_context = "erpnext.whitelabel.overrides.get_website_context"
extend_bootinfo = "erpnext.whitelabel.overrides.extend_bootinfo"
```

#### 1.2 `erpnext/setup/install.py`

| Line(s) | Issue | Fix |
|---------|-------|-----|
| 16–17 | `default_mail_footer` with `frappe.io/erpnext` link | Replace with ArsosTech footer or remove (hooks.py already sets this) |
| 190 | Navbar help item: Documentation → `https://docs.erpnext.com/` | Change to ArsosTech docs URL or remove |
| 196 | Navbar help item: User Forum → `https://discuss.frappe.io` | Remove or replace |
| 200 | Navbar help item label: `"Frappe School"` | Remove entirely |
| 202 | Navbar help item route: `https://frappe.io/school` | Remove entirely |
| 208 | Navbar help item: Report an Issue → `https://github.com/frappe/erpnext/issues` | Change to ArsosTech support URL or remove |
| 238 | `frappe.db.set_single_value("System Settings", "app_name", "ERPNext")` | Change to `"ERP"` (White Label Settings will override per-client) |

#### 1.3 `erpnext/templates/includes/footer/footer_powered.html`

Current (line 1):
```html
{{ _("Powered by {0}").format('<a href="https://frappe.io/erpnext?source=website_footer" target="_blank" class="text-muted">ERPNext</a>') }}
```

Change to:
```html
{{ _("Powered by {0}").format('<a href="https://arsostech.com" target="_blank" class="text-muted">ArsosTech ERP</a>') }}
```

> Future: make this dynamic from White Label Settings.

#### 1.4 `erpnext/public/js/help_links.js` — Controls ALL 200+ in-app help links

Line 3:
```js
const docsUrl = "https://erpnext.com/docs/";
```

Change to your own docs URL, or a neutral route:
```js
const docsUrl = "/help/docs/";
```

If you don't have your own docs hosted yet, you could temporarily redirect this or remove the help links. But this **single variable** controls every "?" help icon in the entire desk — it's a high-visibility leak.

#### 1.5 Workspace Deprecation Banners — Clients see these in CRM and Support

**`erpnext/crm/workspace/crm/crm.json`** (line 9):
```
"This module is scheduled for deprecation ... please use Frappe CRM instead."
```

**`erpnext/support/workspace/support/support.json`** (line 4):
```
"This module is scheduled for deprecation ... please use Frappe Helpdesk instead."
```

**Fix:** Either remove the banners entirely, or rewrite them without Frappe product references:
```
"This module may be replaced in a future version. Contact ArsosTech for details."
```

#### 1.6 Static Image Assets — `erpnext/public/images/`

Replace the **content** of these files with ArsosTech branded assets. Keep filenames the same so all existing references resolve:

| File | Usage |
|------|-------|
| `erpnext-logo.svg` | Main logo (login splash, navbar, apps screen) |
| `erpnext-favicon.svg` | Browser tab favicon |
| `erpnext-logo.png` | Raster logo |
| `erpnext-logo-blue.png` | Blue variant |
| `erpnext-video-placeholder.jpg` | Video thumbnail (minor) |
| `v16/erpnext.svg` | v16 branded SVG |

Also replace desktop icon SVGs:
| File | Usage |
|------|-------|
| `erpnext/public/desktop_icons/erpnext_settings.svg` | Settings workspace icon |
| `erpnext/public/icons/desktop_icons/solid/erpnext_settings.svg` | Solid variant |
| `erpnext/public/icons/desktop_icons/subtle/erpnext_settings.svg` | Subtle variant |

> **Note:** `erpnext-logo.jpg` is referenced in `hooks.py:487` for email branding but may not exist on disk. Verify and create it, or update the hooks reference to use `.png`.

#### 1.7 `erpnext/startup/__init__.py`

Line 19: `product_name = "ERPNext"` — used as a fallback product name.

Change to:
```python
product_name = "ERP"
```

#### 1.8 `pyproject.toml`

| Line(s) | Current | Change To |
|---------|---------|-----------|
| 3–4 | `authors = [{ name = "Frappe Technologies Pvt Ltd", email = "developers@frappe.io"}]` | `authors = [{ name = "ArsosTech Pvt. Ltd.", email = "contact@arsostech.com"}]` |
| 82 | `Homepage = "https://frappe.io/erpnext"` | ArsosTech URL or remove |
| 83 | `Repository = "https://github.com/frappe/erpnext.git"` | Your private repo or remove |
| 84 | `"Bug Reports" = "https://github.com/frappe/erpnext/issues"` | ArsosTech support URL or remove |

---

### P1 — High Priority (admin-visible or contextually visible)

#### 1.9 Desktop Icon & Workspace JSON Fixtures

These define navigation elements visible in the desk sidebar and module list.

**`erpnext/desktop_icon/erpnext.json`:**
- Line 9: `"label": "ERPNext"` → `"label": "ERP"`
- Line 12: `"logo_url"` → update path
- Line 15: `"name": "ERPNext"` → `"name": "ERP"`

**`erpnext/desktop_icon/erpnext_settings.json`:**
- Line 10: `"label": "ERPNext Settings"` → `"label": "ERP Settings"`
- Line 11: `"link_to": "ERPNext Settings"` → update
- Line 16: `"name": "ERPNext Settings"` → update

**All module desktop icons** (assets, crm, buying, manufacturing, projects, quality, selling, stock, support) — each has:
- Line 17: `"parent_icon": "ERPNext"` → `"parent_icon": "ERP"`

**`erpnext/setup/workspace/erpnext_settings/erpnext_settings.json`:**
- Lines 14, 75, 131: `"ERPNext Settings"` → `"ERP Settings"`

**`erpnext/workspace_sidebar/erpnext_settings.json`:**
- Lines 233, 236: `"ERPNext Settings"` → `"ERP Settings"`

#### 1.10 User-Facing JS Field Descriptions

**`erpnext/buying/doctype/buying_settings/buying_settings.js`:**
- Line 14: Naming Series link → `https://docs.erpnext.com/...` — update or remove
- Line 28: `"...ERPNext will prevent you from creating a Purchase Invoice..."` → replace "ERPNext" with "The system"
- Line 35: Same pattern → replace "ERPNext" with "The system"

**`erpnext/stock/doctype/item/item.js`:**
- Line 1054: `"...ERPNext will make a stock ledger entry..."` → "The system will make..."
- Line 1073: Link to `docs.frappe.io/erpnext/...` → remove or update

**`erpnext/accounts/doctype/bank_account/bank_account.js`:**
- Line 36: `"...integrating ERPNext with your bank accounts."` → "...integrating the system with your bank accounts."

**`erpnext/manufacturing/doctype/production_plan/production_plan.js`:**
- Line 183: Link to `erpnext.com/docs/...` → update or remove

**`erpnext/public/js/conf.js`:**
- Line 20: `"ERPNext Integrations": "Integrations"` — breadcrumb label mapping

#### 1.11 Email Subject and Error Messages

**`erpnext/stock/reorder_item.py`:**
- Line 382: `"[Important] [ERPNext] Auto Reorder Errors"` → `"[Important] Auto Reorder Errors"`

**`erpnext/stock/stock_ledger.py`:**
- Line 804: `msgprint` with `docs.erpnext.com` link → update or remove link

#### 1.12 `erpnext/setup/utils.py`

- Line 33: `"email": "test@erpnext.com"` → change to ArsosTech test email
- Line 232: `site_name = get_default_company() or "ERPNext"` → fallback to `"ERP"` or `"ArsosTech ERP"`

#### 1.13 CRM Integration Labels

**`erpnext/crm/frappe_crm_api.py`:**
- Line 16: `"label": "Frappe CRM Deal"` → `"label": "CRM Deal"`
- Line 24: `"label": "Frappe CRM Deal"` → `"label": "CRM Deal"`

---

### P2 — Medium Priority (DocType JSON help URLs and tooltips)

#### 1.14 `documentation_url` Fields in DocType JSONs

These power the "?" help icons on individual form fields. All point to `docs.erpnext.com` or `docs.frappe.io/erpnext`.

| File | Line | URL to Replace |
|------|------|----------------|
| `accounts/doctype/accounts_settings/accounts_settings.json` | 284 | `docs.frappe.io/erpnext/...` |
| `accounts/doctype/payment_reconciliation/payment_reconciliation.json` | 207 | `docs.erpnext.com/...` |
| `accounts/doctype/process_payment_reconciliation/process_payment_reconciliation.json` | 148 | `docs.erpnext.com/...` |
| `setup/doctype/company/company.json` | 724, 734 | `docs.erpnext.com/...` |
| `stock/doctype/stock_settings/stock_settings.json` | 129 | `docs.erpnext.com/...` |
| `manufacturing/doctype/production_plan/production_plan.json` | 235, 410 | `docs.frappe.io/erpnext/...` |

**Fix:** Either point to your own docs, or remove the `documentation_url` values (the "?" icon simply won't appear).

#### 1.15 DocType Field Labels

**`erpnext/setup/doctype/employee_group_table/employee_group_table.json`:**
- Line 32: `"label": "ERPNext User ID"` → `"label": "System User ID"`

**`erpnext/erpnext_integrations/doctype/plaid_settings/plaid_settings.json`:**
- Line 75: `"module": "ERPNext Integrations"` — module name in breadcrumbs

#### 1.16 `erpnext/modules.txt`

- Line 15: `ERPNext Integrations` → `Integrations` (or rename the module — this affects breadcrumbs and the module list)

> **Warning:** Renaming a module in `modules.txt` requires also renaming the corresponding directory and updating all DocTypes that reference it. This is a larger refactor — consider doing it in a later phase, or just live with "ERPNext Integrations" in the admin-only integrations area.

#### 1.17 `erpnext/patches.txt`

- Line 194: `execute:frappe.db.set_value('System Settings', None, 'app_name', 'ERPNext')` — This inline patch will overwrite your app name if it runs. Change `'ERPNext'` to `'ERP'`.

#### 1.18 Sample Content

**`erpnext/setup/setup_wizard/data/sample_blog_post.html`:**
- Line 1: `"We have just starting using ERPNext..."` → Replace with generic text

#### 1.19 `erpnext/www/payment_setup_certification.html`

- Line 3: `{% block title %} ERPNext Certification {% endblock %}` → Update or remove

---

### P3 — Low Priority (historical patches, test data)

These patches have already run on existing installs but may execute on fresh setups:

| File | Issue |
|------|-------|
| `patches/v13_0/set_app_name.py:7` | Sets app_name to "ERPNext" |
| `patches/v13_0/healthcare_deprecation_warning.py` | "removed from ERPNext" warning |
| `patches/v13_0/hospitality_deprecation_warning.py` | "removed from ERPNext" + frappe GitHub link |
| `patches/v13_0/agriculture_deprecation_warning.py` | "removed from ERPNext" warning |
| `patches/v13_0/non_profit_deprecation_warning.py` | "removed from ERPNext" + frappe GitHub link |
| `patches/v13_0/shopify_deprecation_warning.py` | "removed from ERPNext" warning |
| `patches/v13_0/show_hr_payroll_deprecation_warning.py` | "removed from ERPNext in Version 14" |
| `patches/v13_0/show_india_localisation_deprecation_warning.py` | "removed from ERPNext in Version 14" |
| `patches/v13_0/update_docs_link.py` | References erpnext.com docs URLs |
| `patches/v14_0/show_loan_management_deprecation_warning.py` | "removed from ERPNext in Version 15" |
| `patches/v15_0/remove_exotel_integration.py` | "ERPNext in version-15" |

**Fix:** Do a bulk find-replace of "ERPNext" → "the system" in these patch warning strings. Low risk since they're one-time migration messages.

**Test data files** (not user-facing at runtime, optional cleanup):
- `test_payment_request.py` — `@erpnext.com` email addresses
- `test_project.py`, `test_task.py` — `@frappe.io` email addresses
- `test_init.py` — "ERPNext Foundation India" test company name
- Various file headers: `# ERPNext - web based ERP (http://erpnext.com)` — these are NOT copyright headers, so they can be changed

---

## Layer 2 — Frappe Framework Branding Overrides

> **This is the section the original plan was missing entirely.**

The Frappe framework (separate from ERPNext) has its own branding that your clients will see. You have two options:

### Option A: Fork Frappe too (recommended for full control)

Fork `frappe/frappe` the same way you forked ERPNext. Key files to modify:

| File | What to Change |
|------|---------------|
| `frappe/hooks.py` | `app_title`, `app_publisher`, `app_email` |
| `frappe/templates/includes/login/login.html` | Login page branding, "Powered by Frappe" |
| `frappe/templates/includes/footer/footer_extension.html` | Footer branding |
| `frappe/public/images/` | Frappe logo assets |
| `frappe/www/error.html` | Error page branding |
| `frappe/www/message.html` | System message page |
| `frappe/setup_wizard/` | Setup wizard branding/splash |

### Option B: Override via hooks and System Settings (less maintenance)

If you don't want to maintain a Frappe fork, you can override most branding at runtime:

1. **System Settings** (set by White Label Settings `on_update`):
   - `app_name` — controls the title bar text
   - `app_logo` — controls the navbar logo

2. **Website Settings** (set by White Label Settings `on_update`):
   - `splash_image` — login page splash
   - `favicon` — browser tab icon
   - `footer_powered` — override footer text
   - `custom_css` — inject theme colors

3. **Navbar Settings** (set during install or by White Label Settings):
   - Override the help dropdown items

4. **Login page** — Frappe reads `app_name` and `app_logo` from System Settings. If those are set correctly, the login page will show your branding. The "Powered by Frappe" text in the footer may need a custom template override via `frappe_hooks` or a monkey-patch.

**Recommendation:** Start with Option B for speed. If you find Frappe surfaces you can't override via settings, selectively fork those specific templates.

---

## Layer 3 — White Label Settings DocType

A new **Single DocType** that acts as the per-deployment configuration store. The only thing an admin touches to brand a new client.

**Path:** `erpnext/whitelabel/`

### Directory Structure

```
erpnext/whitelabel/
├── __init__.py
├── doctype/
│   └── white_label_settings/
│       ├── __init__.py
│       ├── white_label_settings.json    # DocType definition
│       └── white_label_settings.py      # Controller
└── overrides.py                         # Hook functions (website_context, bootinfo)
```

> **Why `erpnext/whitelabel/` instead of `erpnext/setup/doctype/`?** Keeps all whitelabel code in one place. Easier to maintain and reason about. Register the module in `modules.txt`.

### DocType Fields

| Fieldname | Type | Label | Default | Notes |
|-----------|------|-------|---------|-------|
| `client_name` | Data | App / Client Name | `"ArsosTech ERP"` | Shown in navbar, login page, emails, browser title |
| `client_logo` | Attach Image | App Logo | — | Login splash + navbar logo |
| `client_favicon` | Attach Image | Favicon | — | Browser tab icon |
| `email_logo` | Attach Image | Email Header Logo | — | Used in outgoing emails |
| `primary_color` | Color | Primary Color | — | Buttons, sidebar, links |
| `sidebar_color` | Color | Sidebar Color | — | Sidebar background |
| `navbar_color` | Color | Navbar Color | — | Top navbar background |
| `custom_css` | Code (CSS) | Additional Custom CSS | — | Freeform overrides |
| `developer_name` | Data | Developer / Provider Name | `"ArsosTech Pvt. Ltd."` | Shown in footer, about |
| `developer_url` | Data | Developer Website | `"https://arsostech.com"` | Link in footer |
| `show_powered_by` | Check | Show "Powered by" in footer | `1` | Toggle visibility |
| `help_url` | Data | Help / Docs URL | — | Override `help_links.js` base URL |
| `support_email` | Data | Support Email | — | Shown in help menu |

### Controller (`white_label_settings.py`)

```python
import frappe

class WhiteLabelSettings(Document):
    def on_update(self):
        self.update_system_settings()
        self.update_website_settings()
        self.generate_theme_css()
        frappe.clear_cache()

    def update_system_settings(self):
        if self.client_name:
            frappe.db.set_single_value("System Settings", "app_name", self.client_name)
        if self.client_logo:
            frappe.db.set_single_value("System Settings", "app_logo", self.client_logo)

    def update_website_settings(self):
        if self.client_favicon:
            frappe.db.set_single_value("Website Settings", "favicon", self.client_favicon)
        if self.client_logo:
            frappe.db.set_single_value("Website Settings", "splash_image", self.client_logo)

    def generate_theme_css(self):
        css_parts = []
        if self.primary_color:
            css_parts.append(f"""
:root {{
    --primary: {self.primary_color};
    --primary-color: {self.primary_color};
    --btn-primary-bg: {self.primary_color};
}}""")
        if self.sidebar_color:
            css_parts.append(f"""
.desk-sidebar, .standard-sidebar {{ background-color: {self.sidebar_color}; }}
""")
        if self.navbar_color:
            css_parts.append(f"""
.navbar {{ background-color: {self.navbar_color} !important; }}
""")
        if self.custom_css:
            css_parts.append(self.custom_css)

        css_content = "\n".join(css_parts)
        # Write to a CSS file that's included via app_include_css in hooks.py
        css_path = frappe.get_app_path("erpnext", "public", "css", "whitelabel.css")
        with open(css_path, "w") as f:
            f.write(css_content)
```

### Hook Functions (`overrides.py`)

```python
import frappe

def get_website_context(context):
    """Called by website_context hook — sets favicon and splash for portal pages."""
    try:
        settings = frappe.get_cached_doc("White Label Settings")
    except frappe.DoesNotExistError:
        return

    if settings.client_favicon:
        context["favicon"] = settings.client_favicon
    if settings.client_logo:
        context["splash_image"] = settings.client_logo

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
    }
```

### hooks.py Additions

```python
# Add to hooks.py
website_context = "erpnext.whitelabel.overrides.get_website_context"
extend_bootinfo = "erpnext.whitelabel.overrides.extend_bootinfo"
app_include_css = ["/assets/erpnext/css/whitelabel.css"]
```

---

## Layer 4 — Upstream Merge Strategy

> **This was entirely missing from the original plan and is critical for long-term maintenance.**

### The Problem

ERPNext releases frequently. Every upstream merge can re-introduce "ERPNext", "Frappe Technologies", `erpnext.com`, or `frappe.io` branding.

### The Solution

#### A. Branding CI Check Script

Create `scripts/check-branding.sh`:

```bash
#!/bin/bash
# Fail if any user-facing file contains forbidden branding strings.
# Run this in CI after every merge from upstream.

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

# Only check user-facing files (not Python copyright headers or test files)
FILE_PATTERNS="--include='*.html' --include='*.js' --include='*.json' --include='*.css'"

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

# Special check for JSON files (exclude copyright/description fields that are internal)
for pattern in "ERPNext" "erpnext.com" "frappe.io"; do
    results=$(grep -rn "\"label\".*$pattern\|\"title\".*$pattern\|\"description\".*$pattern\|\"documentation_url\".*$pattern" erpnext/ \
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

#### B. Merge Workflow

1. Add upstream as a remote: `git remote add upstream https://github.com/frappe/erpnext.git`
2. When upstream releases a new version:
   ```bash
   git fetch upstream
   git checkout -b merge/upstream-v16.x version-16
   git merge upstream/version-16
   # Resolve conflicts — pay attention to hooks.py, install.py, any template files
   # Run the branding check:
   bash scripts/check-branding.sh
   # Fix any new branding leaks
   # Test, then merge to your main branch
   ```
3. Optionally, run `check-branding.sh` as a GitHub Action on every PR.

---

## Layer 5 — Client Onboarding Workflow

### For each new client deployment:

1. **Provision server** → install Frappe bench → install Frappe + this ERPNext fork
2. **Create site** → `bench new-site client.example.com`
3. **Install app** → `bench --site client.example.com install-app erpnext`
4. **Run setup wizard** → set company name, country, chart of accounts, etc.
5. **Open White Label Settings** in the desk:
   - Set Client Name (e.g., "Acme Corp ERP")
   - Upload logo, favicon, email logo
   - Set primary color using color picker
   - Optional: sidebar color, navbar color, custom CSS
   - Developer credit defaults to "ArsosTech Pvt. Ltd."
   - Click **Save**
6. **Rebuild assets** if needed: `bench --site client.example.com build`
7. **Done** — deployment is fully branded

### Future Enhancement: CLI Onboarding

```bash
bench --site client.example.com whitelabel \
    --name "Acme Corp ERP" \
    --logo /path/to/logo.svg \
    --favicon /path/to/favicon.svg \
    --primary-color "#2E86AB" \
    --developer "ArsosTech Pvt. Ltd."
```

This can be implemented as a custom bench command that programmatically creates/updates the White Label Settings DocType.

---

## Complete File Manifest

### Files to Modify

| # | File | What Changes | Priority |
|---|------|-------------|----------|
| 1 | `erpnext/hooks.py` | app_title, app_publisher, app_email, source_link, logos, mail footer, add hooks | P0 |
| 2 | `erpnext/setup/install.py` | mail footer, navbar help items, app_name | P0 |
| 3 | `erpnext/templates/includes/footer/footer_powered.html` | "Powered by ArsosTech ERP" | P0 |
| 4 | `erpnext/public/js/help_links.js` | `docsUrl` variable | P0 |
| 5 | `erpnext/crm/workspace/crm/crm.json` | Remove Frappe CRM deprecation banner | P0 |
| 6 | `erpnext/support/workspace/support/support.json` | Remove Frappe Helpdesk deprecation banner | P0 |
| 7 | `erpnext/public/images/erpnext-logo.svg` | Replace with ArsosTech logo | P0 |
| 8 | `erpnext/public/images/erpnext-favicon.svg` | Replace with ArsosTech favicon | P0 |
| 9 | `erpnext/public/images/erpnext-logo.png` | Replace with ArsosTech logo | P0 |
| 10 | `erpnext/public/images/erpnext-logo-blue.png` | Replace with ArsosTech logo | P0 |
| 11 | `erpnext/startup/__init__.py` | `product_name` | P0 |
| 12 | `pyproject.toml` | Authors, URLs | P0 |
| 13 | `erpnext/desktop_icon/erpnext.json` | Label, name, logo | P1 |
| 14 | `erpnext/desktop_icon/erpnext_settings.json` | Label, link_to, name | P1 |
| 15 | `erpnext/desktop_icon/*.json` (9 files) | `parent_icon` field | P1 |
| 16 | `erpnext/setup/workspace/erpnext_settings/erpnext_settings.json` | Labels and title | P1 |
| 17 | `erpnext/workspace_sidebar/erpnext_settings.json` | Name and title | P1 |
| 18 | `erpnext/buying/doctype/buying_settings/buying_settings.js` | Field descriptions | P1 |
| 19 | `erpnext/stock/doctype/item/item.js` | Field descriptions and doc link | P1 |
| 20 | `erpnext/accounts/doctype/bank_account/bank_account.js` | Confirmation dialog text | P1 |
| 21 | `erpnext/manufacturing/doctype/production_plan/production_plan.js` | Doc link in tooltip | P1 |
| 22 | `erpnext/public/js/conf.js` | Breadcrumb label mapping | P1 |
| 23 | `erpnext/stock/reorder_item.py` | Email subject | P1 |
| 24 | `erpnext/stock/stock_ledger.py` | Doc link in msgprint | P1 |
| 25 | `erpnext/setup/utils.py` | Test email, fallback name | P1 |
| 26 | `erpnext/crm/frappe_crm_api.py` | "Frappe CRM Deal" labels | P1 |
| 27 | `erpnext/accounts/doctype/accounts_settings/accounts_settings.json` | Doc link | P2 |
| 28 | `erpnext/accounts/doctype/payment_reconciliation/payment_reconciliation.json` | documentation_url | P2 |
| 29 | `erpnext/accounts/doctype/process_payment_reconciliation/process_payment_reconciliation.json` | documentation_url | P2 |
| 30 | `erpnext/setup/doctype/company/company.json` | documentation_url (2 fields) | P2 |
| 31 | `erpnext/stock/doctype/stock_settings/stock_settings.json` | documentation_url | P2 |
| 32 | `erpnext/manufacturing/doctype/production_plan/production_plan.json` | Doc links in descriptions | P2 |
| 33 | `erpnext/setup/doctype/employee_group_table/employee_group_table.json` | "ERPNext User ID" label | P2 |
| 34 | `erpnext/modules.txt` | "ERPNext Integrations" module name | P2 |
| 35 | `erpnext/patches.txt` | Line 194 inline patch | P2 |
| 36 | `erpnext/setup/setup_wizard/data/sample_blog_post.html` | Sample content | P2 |
| 37 | `erpnext/www/payment_setup_certification.html` | Page title | P2 |
| 38 | `erpnext/patches/v13_0/set_app_name.py` | "ERPNext" → "ERP" | P3 |
| 39 | 10+ patch files in `patches/v13_0/`, `v14_0/`, `v15_0/` | Deprecation warning text | P3 |

### Files to Create

| # | File | Purpose |
|---|------|---------|
| 1 | `erpnext/whitelabel/__init__.py` | Package init |
| 2 | `erpnext/whitelabel/overrides.py` | Hook functions (website_context, extend_bootinfo) |
| 3 | `erpnext/whitelabel/doctype/__init__.py` | Package init |
| 4 | `erpnext/whitelabel/doctype/white_label_settings/__init__.py` | Package init |
| 5 | `erpnext/whitelabel/doctype/white_label_settings/white_label_settings.json` | DocType definition |
| 6 | `erpnext/whitelabel/doctype/white_label_settings/white_label_settings.py` | Controller |
| 7 | `erpnext/public/css/whitelabel.css` | Generated theme CSS (created by controller) |
| 8 | `scripts/check-branding.sh` | CI branding check script |

---

## Verification Checklist

After implementing all changes and configuring White Label Settings for a test client:

| # | Check | Where to Look | Expected Result |
|---|-------|--------------|-----------------|
| 1 | Login page logo | `/login` | Client logo, not ERPNext |
| 2 | Login page title | `/login` browser tab | Client name, not ERPNext |
| 3 | Browser tab favicon | Any page | Client favicon |
| 4 | Desk navbar | Top bar after login | Client name and logo |
| 5 | Primary color | Buttons, links, sidebar | Client brand color |
| 6 | Help dropdown | Navbar "?" menu | ArsosTech links, no Frappe/ERPNext links |
| 7 | Help icons ("?") | Any form with "?" icons | Your docs URL or no link |
| 8 | Outgoing email | Send any email from the system | Client logo in header, ArsosTech in footer |
| 9 | Website footer | Public portal pages | "Powered by ArsosTech ERP" |
| 10 | CRM workspace | Open CRM module | No "Frappe CRM" deprecation banner |
| 11 | Support workspace | Open Support module | No "Frappe Helpdesk" deprecation banner |
| 12 | Settings workspace | Sidebar navigation | "ERP Settings" not "ERPNext Settings" |
| 13 | Buying Settings | Open form | No "ERPNext" in field descriptions |
| 14 | Item form | Open any item | No "ERPNext" in descriptions |
| 15 | Auto Reorder email | Trigger a reorder error | No "[ERPNext]" in email subject |
| 16 | Full text search | `grep -rn "ERPNext\|Frappe Technologies\|frappe.io\|erpnext.com" erpnext/` on rendered pages | Zero user-facing hits |
| 17 | Source code headers | `.py` files | `# Copyright (c) Frappe Technologies` still intact (GPL compliance) |
| 18 | Branding CI check | `bash scripts/check-branding.sh` | PASS |

---

## Implementation Order

### Phase 1 — Ship-Blocking (do this first, ~1-2 days of work)

1. All P0 file modifications (items 1–12 in the manifest)
2. Create White Label Settings DocType + overrides
3. Replace logo assets with ArsosTech defaults
4. Test with a local bench deployment

### Phase 2 — Polish (before first client delivery)

5. All P1 file modifications (items 13–26)
6. Frappe framework branding overrides (Option B)
7. Create `scripts/check-branding.sh` and run it
8. Full verification checklist pass

### Phase 3 — Hardening (before scaling to multiple clients)

9. All P2 file modifications (items 27–37)
10. Set up upstream merge workflow
11. Optional: CLI onboarding command
12. Optional: P3 patch file cleanup

---

---

## Layer 6 — Custom Client Integrations

> For some clients, ArsosTech will build custom workflow automations (e.g., email-to-document processing, PDF generation, SMS/email dispatch). This section defines the architecture and approach for delivering these integrations cleanly and repeatably.

### Philosophy: Structured Custom Dev, Not a Generic Automation Engine

**Do NOT build a visual automation/workflow builder.** Here's why:

1. **Frappe already has automation primitives** — Server Scripts, Webhooks, Email Rules, Workflow DocType, Scheduled Jobs. Building another layer on top would duplicate what already exists, poorly.
2. **Each client's automation is unique** — the email format is different, the PDF layout is different, the business rules are different ("send SMS to driver only if route is local", "create PI only if amount > 50k"). A generic engine either can't express these rules, or becomes so complex it's unusable.
3. **80% of dev time goes into edge cases** — malformed PDFs, supplier names not matching, unexpected line items. These are per-client problems, not solvable by a generic tool.
4. **Clients don't want to configure automations** — they're paying ArsosTech precisely so things "just work". They want to see documents appearing and notifications being sent, not drag-and-drop a workflow.

**Instead:** Build a **separate Frappe app** (`arsostech_integrations`) with reusable building blocks and per-client modules. Each client's automations are server-side code that ArsosTech deploys and maintains. Clients see the automations working but cannot edit the logic.

### App Architecture

```
bench/
├── apps/
│   ├── frappe/                            # Framework
│   ├── erpnext/                           # Whitelabeled ERPNext fork
│   └── arsostech_integrations/            # Custom integrations app
│       ├── arsostech_integrations/
│       │   ├── hooks.py                   # Register scheduled jobs, email hooks, etc.
│       │   ├── shared/                    # Reusable utilities (build once, use everywhere)
│       │   │   ├── __init__.py
│       │   │   ├── email_ingestion.py     # Email polling, attachment extraction
│       │   │   ├── pdf_parser.py          # PDF table/text extraction
│       │   │   ├── document_creator.py    # Create DN/PI/SO from structured data
│       │   │   ├── pdf_generator.py       # Generate PDFs from Print Formats
│       │   │   ├── notification.py        # Send SMS and email notifications
│       │   │   └── field_mapper.py        # Map external names → ERPNext masters
│       │   ├── client_acme/               # Acme Corp specific automations
│       │   │   ├── __init__.py
│       │   │   ├── config.py              # Acme-specific settings (email rules, field maps)
│       │   │   ├── order_email_parser.py  # Parse Acme's specific order confirmation format
│       │   │   └── dispatch_workflow.py   # Acme's DN creation + driver SMS logic
│       │   ├── client_beta/               # Beta Inc specific automations
│       │   │   ├── __init__.py
│       │   │   └── ...
│       │   └── templates/                 # Shared Jinja templates for custom PDFs
│       │       └── dispatch_note.html
│       └── pyproject.toml
```

### Why a Separate App (Not Inside ERPNext Fork)

| Concern | Inside ERPNext Fork | Separate App |
|---------|-------------------|--------------|
| Upstream merge conflicts | High — client code mixed with ERPNext code | Zero — completely separate |
| Per-client deployment | Messy — all client code on all servers | Clean — install only the modules needed |
| Code ownership | Blurred | Clear — ArsosTech owns this entirely |
| Testing | Coupled to ERPNext test suite | Independent test suite |
| Billing/IP | Hard to separate | Easy — this is your proprietary code |

### The Three-Layer Pattern for Each Integration

Every client integration follows the same structure:

```
┌─────────────────────────────────────────────────┐
│  Layer A: Ingestion                              │
│  - What triggers the automation?                 │
│  - Email Account polling (Frappe built-in)       │
│  - Webhook receiver                              │
│  - Scheduled job (cron)                          │
│  - Manual trigger (button on a DocType)          │
│  REUSABLE: Yes — shared/email_ingestion.py       │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────┐
│  Layer B: Parser / Transformer                   │
│  - Extract structured data from input            │
│  - Email body → dict, PDF table → dict           │
│  - Validate and map to ERPNext fields            │
│  PER-CLIENT: Yes — this is where formats differ  │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────┐
│  Layer C: Action                                 │
│  - Create documents (DN, PI, SO, etc.)           │
│  - Generate PDFs from Print Formats              │
│  - Send SMS / email notifications                │
│  - Update status, create follow-up tasks         │
│  REUSABLE: Mostly — shared/document_creator.py   │
└─────────────────────────────────────────────────┘
```

The per-client work is **almost entirely in Layer B** (the parser). Layers A and C are built once and reused across all clients.

### Reference Implementation: Email → Delivery Note → PDF → SMS

This is the most common integration pattern. Here's how it works end-to-end using Frappe's built-in capabilities:

#### Step 1: Email Ingestion (Frappe built-in)

Configure an **Email Account** in Frappe to poll the client's inbox (IMAP). Frappe does this automatically — no custom code needed for the polling itself.

Hook into incoming emails via `hooks.py`:
```python
# arsostech_integrations/hooks.py
doc_events = {
    "Communication": {
        "after_insert": "arsostech_integrations.client_acme.dispatch_workflow.on_email_received"
    }
}
```

#### Step 2: Parse the Email / PDF (per-client)

```python
# arsostech_integrations/client_acme/order_email_parser.py

import frappe
from arsostech_integrations.shared.pdf_parser import extract_tables_from_pdf

def parse_order_email(communication):
    """Parse Acme Corp's order confirmation email into structured data.

    This is Acme-specific — their supplier sends a PDF attachment
    with a table of items, quantities, and rates.
    """
    # Get PDF attachment
    attachments = frappe.get_all("File", filters={
        "attached_to_doctype": "Communication",
        "attached_to_name": communication.name,
        "file_url": ["like", "%.pdf"]
    }, fields=["file_url"])

    if not attachments:
        return None

    # Extract table data from PDF (shared utility)
    tables = extract_tables_from_pdf(attachments[0].file_url)

    # Acme-specific field mapping
    items = []
    for row in tables[0]:  # First table in the PDF
        items.append({
            "item_code": map_supplier_sku_to_item(row["SKU"]),
            "qty": row["Quantity"],
            "rate": row["Unit Price"],
            "warehouse": "Stores - ACME",  # Acme's default warehouse
        })

    return {
        "supplier": map_supplier_name(communication.sender),
        "items": items,
        "posting_date": frappe.utils.today(),
        "reference_email": communication.name,
    }
```

#### Step 3: Create Documents + Notify (shared utilities)

```python
# arsostech_integrations/client_acme/dispatch_workflow.py

import frappe
from arsostech_integrations.shared.document_creator import create_delivery_note, create_purchase_invoice
from arsostech_integrations.shared.pdf_generator import generate_document_pdf
from arsostech_integrations.shared.notification import send_sms, send_email_with_attachment
from arsostech_integrations.client_acme.order_email_parser import parse_order_email

def on_email_received(doc, method):
    """Triggered when a new Communication (email) is inserted."""
    # Only process emails from configured suppliers
    if not is_order_confirmation_email(doc):
        return

    try:
        order_data = parse_order_email(doc)
        if not order_data:
            log_failed_import(doc, "Could not parse email/PDF")
            return

        # Create Delivery Note
        dn = create_delivery_note(order_data)

        # Create Purchase Invoice
        pi = create_purchase_invoice(order_data)

        # Generate PDFs
        dn_pdf = generate_document_pdf("Delivery Note", dn.name)
        pi_pdf = generate_document_pdf("Purchase Invoice", pi.name)

        # Notify driver via SMS
        driver = get_assigned_driver(dn)
        if driver and driver.cell_phone:
            send_sms(
                to=driver.cell_phone,
                message=f"New delivery assigned: {dn.name}. {len(order_data['items'])} items. Check your email for details."
            )

        # Email PDF to concerned persons
        send_email_with_attachment(
            recipients=get_dispatch_team_emails(),
            subject=f"Delivery Note {dn.name} — Auto-generated from order email",
            attachments=[dn_pdf, pi_pdf],
        )

        # Link the Communication to the created documents
        doc.reference_doctype = "Delivery Note"
        doc.reference_name = dn.name
        doc.save(ignore_permissions=True)

    except Exception:
        log_failed_import(doc, frappe.get_traceback())

def log_failed_import(communication, error):
    """Log failed email imports for human review."""
    frappe.get_doc({
        "doctype": "Error Log",
        "method": "Email Order Import",
        "error": f"Failed to process email {communication.name}:\n{error}",
    }).insert(ignore_permissions=True)
```

#### Step 4: Shared Utilities (built once)

```python
# arsostech_integrations/shared/document_creator.py

import frappe

def create_delivery_note(data):
    """Create a Delivery Note from structured order data."""
    dn = frappe.get_doc({
        "doctype": "Delivery Note",
        "customer": data.get("customer"),
        "posting_date": data.get("posting_date"),
        "items": [{
            "item_code": item["item_code"],
            "qty": item["qty"],
            "rate": item.get("rate"),
            "warehouse": item.get("warehouse"),
        } for item in data["items"]],
    })
    dn.insert(ignore_permissions=True)
    dn.submit()
    return dn

def create_purchase_invoice(data):
    """Create a Purchase Invoice from structured order data."""
    pi = frappe.get_doc({
        "doctype": "Purchase Invoice",
        "supplier": data.get("supplier"),
        "posting_date": data.get("posting_date"),
        "items": [{
            "item_code": item["item_code"],
            "qty": item["qty"],
            "rate": item.get("rate"),
        } for item in data["items"]],
    })
    pi.insert(ignore_permissions=True)
    pi.submit()
    return pi
```

```python
# arsostech_integrations/shared/pdf_parser.py

import frappe

def extract_tables_from_pdf(file_url):
    """Extract tabular data from a PDF attachment.

    Uses pdfplumber for structured tables. For unstructured PDFs,
    consider using Claude API for LLM-based extraction.
    """
    import pdfplumber

    file_path = frappe.get_site_path("public", file_url.lstrip("/"))
    tables = []
    with pdfplumber.open(file_path) as pdf:
        for page in pdf.pages:
            page_tables = page.extract_tables()
            for table in page_tables:
                if table and len(table) > 1:
                    headers = [h.strip() if h else "" for h in table[0]]
                    rows = [dict(zip(headers, row)) for row in table[1:]]
                    tables.append(rows)
    return tables
```

```python
# arsostech_integrations/shared/pdf_generator.py

import frappe

def generate_document_pdf(doctype, name, print_format=None):
    """Generate a PDF from a document's Print Format."""
    html = frappe.get_print(doctype, name, print_format=print_format)
    pdf_content = frappe.utils.pdf.get_pdf(html)

    # Save as a File record
    file_name = f"{doctype.replace(' ', '-')}_{name}.pdf"
    file_doc = frappe.get_doc({
        "doctype": "File",
        "file_name": file_name,
        "content": pdf_content,
        "attached_to_doctype": doctype,
        "attached_to_name": name,
        "is_private": 1,
    })
    file_doc.save(ignore_permissions=True)
    return file_doc
```

```python
# arsostech_integrations/shared/notification.py

import frappe

def send_sms(to, message):
    """Send SMS using Frappe's SMS Settings or a custom provider."""
    from frappe.core.doctype.sms_settings.sms_settings import send_sms as frappe_send_sms
    frappe_send_sms([to], message)

def send_email_with_attachment(recipients, subject, attachments, message=""):
    """Send email with PDF attachments."""
    frappe.sendmail(
        recipients=recipients,
        subject=subject,
        message=message or subject,
        attachments=[{
            "fname": att.file_name,
            "fcontent": att.get_content(),
        } for att in attachments],
    )
```

### PDF Parsing: Structured vs LLM-Based

For the email/PDF → document flow, the hardest part is **parsing the incoming PDF**. Two approaches:

| Approach | When to Use | Pros | Cons |
|----------|------------|------|------|
| **Structured (pdfplumber/tabula)** | Supplier always sends the same format | Fast, free, deterministic, no API dependency | Breaks if format changes |
| **LLM-based (Claude API)** | Formats vary, multiple suppliers, messy PDFs | Handles any format, adapts to variations | Costs per-request (~$0.01-0.05/page), needs validation |

**Recommendation:** Start with structured parsing for each known supplier format. Add LLM-based as a fallback for new/unknown formats. The shared `pdf_parser.py` can expose both methods and the per-client parser chooses which to use.

#### LLM Parsing Example (Claude API)

```python
# arsostech_integrations/shared/pdf_parser.py (LLM method)

def extract_order_data_with_llm(file_url):
    """Use Claude API to extract structured order data from a PDF."""
    import anthropic
    import json

    file_path = frappe.get_site_path("public", file_url.lstrip("/"))

    with open(file_path, "rb") as f:
        pdf_bytes = f.read()

    client = anthropic.Anthropic(api_key=frappe.conf.get("anthropic_api_key"))

    message = client.messages.create(
        model="claude-sonnet-4-5-20250514",
        max_tokens=2000,
        messages=[{
            "role": "user",
            "content": [
                {
                    "type": "document",
                    "source": {"type": "base64", "media_type": "application/pdf", "data": base64.b64encode(pdf_bytes).decode()},
                },
                {
                    "type": "text",
                    "text": """Extract all order line items from this document. Return JSON:
                    {
                        "supplier_name": "...",
                        "order_date": "YYYY-MM-DD",
                        "items": [{"description": "...", "sku": "...", "qty": 0, "rate": 0.0}]
                    }
                    Return ONLY valid JSON, no other text."""
                }
            ]
        }]
    )

    return json.loads(message.content[0].text)
```

### Error Handling: The "Failed Imports" Queue

Every automation MUST have a failure path. When email parsing fails, the email should not be silently dropped.

**Approach:** Use Frappe's built-in **Error Log** as a failed import queue. ArsosTech monitors these for each client.

Optionally, create a lightweight **Integration Log** DocType:

| Fieldname | Type | Notes |
|-----------|------|-------|
| `integration_name` | Data | e.g., "Acme Order Email Import" |
| `status` | Select | Success / Failed / Pending Review |
| `source_reference` | Data | Communication name or email ID |
| `created_documents` | Small Text | Links to DN, PI created |
| `error_message` | Long Text | Traceback or parse failure reason |
| `raw_data` | Code (JSON) | The parsed data before document creation |

This gives the client's admin (or ArsosTech support) visibility into what was processed and what failed.

### Estimated Effort Per Client

| Component | First Client | Each Additional Client |
|-----------|-------------|----------------------|
| Shared utilities (email, PDF, SMS, doc creation) | 3–4 days | 0 (reuse) |
| Integration Log DocType (optional) | 1 day | 0 (reuse) |
| Per-client email parser | 3–5 days | 2–4 days |
| Per-client business rules & field mapping | 2–3 days | 1–2 days |
| Testing & edge case handling | 2–3 days | 1–2 days |
| **Total** | **~2 weeks** | **~1 week** |

### Deployment Per Client

The `arsostech_integrations` app is installed on every client bench that needs custom integrations:

```bash
# On the client's bench
bench get-app arsostech_integrations <private-repo-url>
bench --site client.example.com install-app arsostech_integrations
```

Client-specific modules are activated via a config flag or a settings DocType within the integrations app. Only the relevant client module runs on each deployment.

### What Clients See

From the client's perspective:
- Emails arrive in their inbox → documents magically appear in the system
- PDFs are auto-generated and sent to the right people
- SMS notifications go out to drivers/staff
- A log shows what was processed (if Integration Log is enabled)
- They **cannot** edit the automation logic — it's server-side code deployed by ArsosTech
- If something fails, ArsosTech support handles it (or the admin sees it in the log)

This is the "it just works" experience they're paying for.

---

## Open Items / Decisions Needed

### Whitelabeling

- [ ] **Frappe fork vs override:** Decide whether to fork Frappe framework or use runtime overrides (Option A vs B in Layer 2). Affects login page, error pages, setup wizard.
- [ ] **Docs hosting:** Where will `help_links.js` point? Options: host your own docs, remove help links entirely, or redirect to a "coming soon" page.
- [ ] **Logo assets:** Create ArsosTech branded SVG/PNG/favicon assets as the default placeholders.
- [ ] **Private git remote:** Set up a private repo for this fork (if not already done).
- [ ] **"ERPNext Integrations" module rename:** Decide if worth the effort (requires directory rename + DocType updates) or acceptable as admin-only.
- [ ] **Test on a clean bench install:** After Phase 1, do a fresh `bench new-site` and walk through the entire UI to catch any remaining branding leaks.

### Custom Integrations

- [ ] **Create the `arsostech_integrations` Frappe app** scaffold using `bench new-app arsostech_integrations`.
- [ ] **Set up private repo** for the integrations app (separate from the ERPNext fork).
- [ ] **First client identification:** Which client needs the email → DN workflow first? Get a sample of their order confirmation emails/PDFs to build the parser.
- [ ] **SMS provider:** Choose and configure an SMS gateway (Twilio, local provider, etc.) for driver notifications.
- [ ] **PDF parsing library:** Install `pdfplumber` (or `tabula-py`) as a dependency for structured PDF extraction.
- [ ] **Claude API key:** If LLM-based parsing is needed, provision an Anthropic API key and add to `site_config.json` as `anthropic_api_key`.
- [ ] **Integration Log DocType:** Decide if needed from day one or can be added later.
