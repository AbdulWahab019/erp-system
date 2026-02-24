# ArsosTech ERP — Whitelabeling & Multi-Client Deployment Plan (v2: Custom App Architecture)

## Context

This is a forked ERPNext/Frappe repo (GPL v3 licensed) that ArsosTech Pvt. Ltd. will whitelabel, customize, and deploy for multiple clients as a managed ERP product. The goals are:

- Remove all Frappe Technologies / ERPNext branding from the user-facing UI, emails, and public pages
- Replace with each client's own branding (name, logo, colors)
- Present the product as an **ArsosTech offering** to end-users (clients see it as "ArsosTech ERP" or their own branded app)
- Make onboarding a new client fast and repeatable via a config-driven system

### GPL v3 Compliance Note

Since the upstream ERPNext and Frappe are GPL v3 licensed:
- **Allowed:** Removing Frappe/ERPNext branding from the UI entirely — the license does not require showing Frappe's brand to end users
- **Allowed:** Presenting the product under ArsosTech's brand — this is standard whitelabeling practice
- **Required:** Keep all copyright notices intact in the **source code files** (do not strip `# Copyright (c) Frappe Technologies` headers from `.py` files)
- **Required:** Provide clients with access to the source code of this fork upon request (or point them to the repo), since they receive the GPL software
- **Not required:** Advertising that this is built on ERPNext/Frappe in the UI or marketing material

**Attribution in UI:** Use neutral, honest language like "Powered by ArsosTech ERP" or simply show ArsosTech branding with no mention of the underlying platform. Do not say "Built from scratch by ArsosTech" in writing, but presenting it as an ArsosTech product is standard reseller/whitelabeling practice.

---

## Recommended Deployment Model

**One Frappe bench per client** (separate server or VM per client). Reasons:
- Each client's data is fully isolated
- Independent upgrade cycles per client
- Simple mental model — each deployment is one client
- Frappe's multi-site mode is an alternative but adds complexity

**Workflow for each new client:**
1. Provision server → install Frappe bench → install Frappe + this ERPNext fork + `arsoserp_core` Custom App
2. Create site → run setup wizard
3. Fill in **White Label Settings** (name, logo, colors) in the UI → done

---

## Architecture Strategy: The Custom App Approach

Instead of hacking the `erpnext/hooks.py` and core Python files directly (which guarantees painful merge conflicts during upgrades to v15.1, v16, etc.), we will build a **Custom Frappe App** (e.g., `arsoserp_core`).

- This app will contain the `White Label Settings` DocType.
- This app's `hooks.py` will contain overrides that execute *after* ERPNext, replacing CSS, bootinfo, and website context dynamically.
- The only direct modifications to the `erpnext` and `frappe` forks will be static assets (replacing SVGs/PNGs) and standard `pyproject.toml` text.

---

## What Needs to Change

### Layer 1 — Static Assert Replacement (Applies to Frappe & ERPNext Forks)

These are hardcoded assets and metadata that must be carefully replaced in the forks themselves.

#### 1. `pyproject.toml` (in both `frappe` and `erpnext` forks)
- `authors` → `ArsosTech Pvt. Ltd.` with your contact email
- `description` → generic ERP description
- Remove `[project.urls]` pointing to Frappe/ERPNext GitHub (or replace with your repo)

#### 2. Static image assets in `erpnext/public/images/` and `frappe/public/images/`
Replace logo files with generic/ArsosTech placeholder assets. **Keep filenames the same** so all existing references still resolve — just swap the file content with an ArsosTech placeholder SVG.

Files to replace in `erpnext` and `frappe`:
- `erpnext-logo.svg` / `frappe-logo.svg`
- `erpnext-favicon.svg` / `frappe-favicon.svg`
- `erpnext-logo.png` / `frappe-logo.png`
- `erpnext-logo.jpg` / `frappe-logo.jpg`
- `erpnext-logo-blue.png`
- *Any other explicit Frappe logo SVGs found in the codebase.*

#### 3. Default Mail Footer in core files
- In `erpnext/hooks.py` and `frappe/hooks.py`, adjust `default_mail_footer` to use generic generic or ArsosTech text (you will likely get a merge conflict here eventually, but it's minimal).

---

### Layer 2 — The `arsoserp_core` Custom App

Create a new app: `bench new-app arsoserp_core`

#### 1. White Label Settings DocType (Single)
Path: `arsoserp_core/arsoserp_core/doctype/white_label_settings/`

| Fieldname | Type | Label | Notes |
|-----------|------|-------|-------|
| `client_name` | Data | App / Client Name | Shown in navbar, login page, emails |
| `client_logo` | Attach Image | App Logo | Login splash + navbar logo |
| `client_favicon` | Attach Image | Favicon | Browser tab icon |
| `login_background_image` | Attach Image | Login Background | Custom background for the `/login` page |
| `email_logo` | Attach Image | Email Header Logo | Used in outgoing emails |
| `primary_color` | Color | Primary Color | Buttons, sidebar, links |
| `secondary_color` | Color | Secondary Color | Accents |
| `custom_css` | Code (CSS) | Additional Custom CSS | Freeform overrides |
| `developer_credit` | Data | Developer Credit | Default: "ArsosTech Pvt. Ltd." |
| `show_developer_credit` | Check | Show "Powered by" in footer | Default: 1 |

**Python controller (`white_label_settings.py`):**
- `on_update()`: When saved, automatically:
  1. Update `System Settings.app_name` to `client_name`
  2. Update `System Settings.app_logo` to `client_logo`
  3. Update `Website Settings.splash_image` and `Website Settings.favicon`
  4. Write generated CSS to a custom public file (e.g., `arsoserp_core/public/css/whitelabel.css`)

#### 2. Hiding the Frappe "Help" Menu (Desk Navbar)

In the custom app, create a JavaScript file (`arsoserp_core/public/js/hide_help.js`):
```javascript
// Hide the help dropdown in the navbar on load
frappe.ui.toolbar.setup = frappe.ui.toolbar.setup || function() {};
$(document).ready(function() {
    setTimeout(function() {
        $('#navbar-help').hide();
    }, 100);
});
```
Include this script in your `arsoserp_core/hooks.py` under `app_include_js`.

#### 3. Dynamic App Name and Bootinfo Injection

In `arsoserp_core/hooks.py`, use standard hooks to override the UI dynamically.

**`extend_bootinfo` hook:** Inject branding into desk session:
```python
extend_bootinfo = "arsoserp_core.whitelabel.extend_bootinfo"

# In arsoserp_core/whitelabel.py
def extend_bootinfo(bootinfo):
    settings = frappe.get_cached_doc("White Label Settings")
    bootinfo.whitelabel = {
        "client_name": settings.client_name,
        "client_logo": settings.client_logo,
        "primary_color": settings.primary_color,
    }
    bootinfo.app_name = settings.client_name # Forces the navbar string
```

**`website_context` hook:** Inject custom context on public pages.
```python
website_context = "arsoserp_core.whitelabel.get_website_context"

# In arsoserp_core/whitelabel.py
def get_website_context(context):
    settings = frappe.get_cached_doc("White Label Settings")
    if settings.client_favicon:
        context["favicon"] = settings.client_favicon
    if settings.client_logo:
        context["splash_image"] = settings.client_logo
    if settings.login_background_image:
        context["background_image"] = settings.login_background_image
```

#### 4. CSS Color Variable Injection

In `arsoserp_core/hooks.py`, ensure your generated CSS file is loaded:
```python
app_include_css = "/assets/arsoserp_core/css/whitelabel.css"
web_include_css = "/assets/arsoserp_core/css/whitelabel.css"
```

The `white_label_settings.on_update()` will write standard CSS overrides to this file:
```css
:root {
    --primary: #HEXCOLOR;
    --primary-color: #HEXCOLOR;
    --btn-primary-bg: #HEXCOLOR;
}
/* Hide Frappe generator meta tag via CSS trick if needed, or remove via hooks */
```

#### 5. Footer Powered By Override

In `arsoserp_core/templates/includes/footer/footer_powered.html`:
```html
{{ _("Powered by {0}").format('<a href="https://arsostech.com" target="_blank" class="text-muted">ArsosTech ERP</a>') }}
```

---

## Critical Files to Modify (Forks)

| File | What Changes |
|------|-------------|
| `erpnext/hooks.py` | `default_mail_footer` |
| `frappe/hooks.py` | `default_mail_footer`, `app_publisher` |
| `pyproject.toml` (both) | Authors → ArsosTech, remove Frappe URLs |
| `/public/images/*.svg` | Replace file content with placeholder SVG (keep filenames) |
| `/public/images/*.png` | Replace with placeholder |

---

## Verification Checklist

After configuring White Label Settings for a test client:

| Check | Location | Expected |
|-------|----------|---------|
| Login page logo & bg | `/login` | Client logo and Background, not ERPNext/Frappe |
| Browser tab | Any page | Client favicon |
| Desk navbar | After login | Client name in top bar |
| Help Menu | Desk Navbar | `?` icon should be hidden or stripped |
| Primary color | Buttons, sidebar | Client brand color |
| Outgoing email | Send any email | Client logo in header, ArsosTech footer |
| Website footer | Public pages | "Powered by ArsosTech ERP" |
| Source code headers | `.py` files | Copyright notices still intact (GPL compliance) |
| No ERPNext/Frappe text | Search all rendered pages | No visible "ERPNext" or "Frappe Technologies" |

---

## Technical Debt / Known Limitations
- Modifying `pyproject.toml` or `default_mail_footer` in the core forks handles global metadata but may occasionally require manual resolution during massive upstream git merges.
- The Custom App approach relies on JavaScript (`hide_help.js`) to visually hide the Help menu. While effective, technically savvy users could still inspect the page. We accept this as a tradeoff for zero-conflict upgradability.
