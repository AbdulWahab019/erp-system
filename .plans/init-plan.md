# ArsosTech ERP — Whitelabeling & Multi-Client Deployment Plan

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
1. Provision server → install Frappe bench → install Frappe + this ERPNext fork
2. Create site → run setup wizard
3. Fill in **White Label Settings** (name, logo, colors) in the UI → done

---

## What Needs to Change

### Layer 1 — Fork-level cleanup (one-time, applies to ALL clients)

These are hardcoded references to Frappe/ERPNext that must be permanently cleaned from the codebase.

#### 1. `erpnext/hooks.py` (lines 1–21, 487–496)
- `app_publisher` → `"ArsosTech Pvt. Ltd."`
- `app_email` → ArsosTech contact email
- `source_link` → remove or point to private repo
- `default_mail_footer` → change ERPNext/Frappe link to ArsosTech:
  ```python
  default_mail_footer = """<div style="padding:7px;text-align:right;color:#888">
      <small>Sent via <a style="color:#888" href="https://arsostech.com">ArsosTech ERP</a></div>"""
  ```
- `website_context` → convert from static dict to a Python function (see Layer 3)

#### 2. `erpnext/setup/install.py` (line 16–17, 238)
- Remove ERPNext/Frappe reference in `default_mail_footer` variable at top of file
- Change `add_app_name()` so it sets `System Settings.app_name` to a generic value:
  ```python
  def add_app_name():
      frappe.db.set_single_value("System Settings", "app_name", "ERP")
  ```
  The actual client name will be set when White Label Settings is configured.

#### 3. `erpnext/templates/includes/footer/footer_powered.html`
Change from "Powered by ERPNext" to:
```html
{{ _("Powered by {0}").format('<a href="https://arsostech.com" target="_blank" class="text-muted">ArsosTech ERP</a>') }}
```
> This can later be made dynamic from White Label Settings.

#### 4. `pyproject.toml` (lines 3–5, 82–84)
- `authors` → `ArsosTech Pvt. Ltd.` with your contact email
- `description` → generic ERP description
- Remove `[project.urls]` pointing to Frappe/ERPNext GitHub (or replace with your repo)

#### 5. Static image assets in `erpnext/public/images/`
Replace logo files with generic/ArsosTech placeholder assets. **Keep filenames the same** so all existing references still resolve — just swap the file content.

Files to replace:
- `erpnext-logo.svg` — main logo (login splash, navbar)
- `erpnext-favicon.svg` — browser tab favicon
- `erpnext-logo.png` — raster logo
- `erpnext-logo.jpg` — used in emails
- `erpnext-logo-blue.png` — blue variant

> For the default placeholder, use a simple ArsosTech wordmark or generic "ERP" logo. Each client's specific logo is set via White Label Settings.

---

### Layer 2 — White Label Settings DocType (new)

A new **Single DocType** that acts as the per-deployment configuration store. This is the only thing an admin needs to touch to brand a new client deployment.

**Path:** `erpnext/setup/doctype/white_label_settings/`

#### Files to create:
- `__init__.py`
- `white_label_settings.json` (DocType definition)
- `white_label_settings.py` (Python controller)

#### DocType fields:
| Fieldname | Type | Label | Notes |
|-----------|------|-------|-------|
| `client_name` | Data | App / Client Name | Shown in navbar, login page, emails |
| `client_logo` | Attach Image | App Logo | Login splash + navbar logo |
| `client_favicon` | Attach Image | Favicon | Browser tab icon |
| `email_logo` | Attach Image | Email Header Logo | Used in outgoing emails |
| `primary_color` | Color | Primary Color | Buttons, sidebar, links |
| `secondary_color` | Color | Secondary Color | Accents |
| `custom_css` | Code (CSS) | Additional Custom CSS | Freeform overrides |
| `developer_credit` | Data | Developer Credit | Default: "ArsosTech Pvt. Ltd." |
| `show_developer_credit` | Check | Show "Powered by" in footer | Default: 1 |

#### Python controller (`white_label_settings.py`):
- `on_update()`: When saved, automatically:
  1. Update `System Settings.app_name` to `client_name`
  2. Update `System Settings.app_logo` to `client_logo` (Frappe reads this for the desk navbar)
  3. Write generated CSS to `erpnext/public/css/whitelabel.css` (or to `Website Settings.custom_css`)

---

### Layer 3 — Dynamic Frappe Hooks

#### A. Convert `website_context` in `hooks.py` to a function
```python
# hooks.py
website_context = "erpnext.setup.doctype.white_label_settings.white_label_settings.get_website_context"
```

Function implementation:
```python
def get_website_context(context):
    settings = frappe.get_cached_doc("White Label Settings")
    if settings.client_favicon:
        context["favicon"] = settings.client_favicon
    if settings.client_logo:
        context["splash_image"] = settings.client_logo
```

#### B. `extend_bootinfo` hook — inject branding into desk session
```python
# hooks.py
extend_bootinfo = "erpnext.setup.doctype.white_label_settings.white_label_settings.extend_bootinfo"
```

Function:
```python
def extend_bootinfo(bootinfo):
    settings = frappe.get_cached_doc("White Label Settings")
    bootinfo.whitelabel = {
        "client_name": settings.client_name,
        "client_logo": settings.client_logo,
        "primary_color": settings.primary_color,
    }
```

#### C. CSS color variable injection
In `on_update()` of White Label Settings, write a CSS file that overrides Frappe's CSS custom properties:
```css
:root {
    --primary: #HEXCOLOR;
    --primary-color: #HEXCOLOR;
    --btn-primary-bg: #HEXCOLOR;
}
```

This is added to `app_include_css` or written into `Website Settings.custom_css` via Frappe API.

#### D. Email logo in outgoing emails
Set `email_brand_image` dynamically, or update it in `on_update()`:
```python
frappe.db.set_single_value("System Settings", "email_logo", settings.email_logo)
```

---

### Layer 4 — Client Onboarding Workflow

After deploying and running the setup wizard for a new client:

1. Log in as Administrator
2. Search for **White Label Settings** in the desk
3. Fill in:
   - Client Name (e.g., `"Acme Corp ERP"`)
   - Upload logo, favicon, email logo
   - Set primary color using the color picker
   - Optional: custom CSS overrides
4. Click **Save** → system automatically updates System Settings and regenerates CSS
5. Optionally run `bench --site <site> build` if asset bundling is needed
6. Deployment is branded and ready

---

## Critical Files to Modify

| File | What Changes |
|------|-------------|
| [erpnext/hooks.py](erpnext/hooks.py) | `app_publisher`, `app_email`, `source_link`, `default_mail_footer`, convert `website_context` to function, add `extend_bootinfo` hook |
| [erpnext/setup/install.py](erpnext/setup/install.py) | `add_app_name()` → generic value, remove ERPNext from top-level `default_mail_footer` |
| [erpnext/templates/includes/footer/footer_powered.html](erpnext/templates/includes/footer/footer_powered.html) | "Powered by ArsosTech ERP" |
| [pyproject.toml](pyproject.toml) | Authors → ArsosTech, remove Frappe URLs |
| [erpnext/public/images/erpnext-logo.svg](erpnext/public/images/erpnext-logo.svg) | Replace file content with placeholder SVG |
| [erpnext/public/images/erpnext-favicon.svg](erpnext/public/images/erpnext-favicon.svg) | Replace with placeholder favicon |
| [erpnext/public/images/erpnext-logo.png](erpnext/public/images/erpnext-logo.png) | Replace with placeholder |
| [erpnext/public/images/erpnext-logo.jpg](erpnext/public/images/erpnext-logo.jpg) | Replace with placeholder (emails) |

## New Files to Create

| File | Purpose |
|------|---------|
| `erpnext/setup/doctype/white_label_settings/__init__.py` | Package init |
| `erpnext/setup/doctype/white_label_settings/white_label_settings.json` | DocType definition (Single doctype) |
| `erpnext/setup/doctype/white_label_settings/white_label_settings.py` | Controller: `on_update`, `extend_bootinfo`, `get_website_context` |

---

## Verification Checklist

After configuring White Label Settings for a test client:

| Check | Location | Expected |
|-------|----------|---------|
| Login page logo | `/login` | Client logo, not ERPNext logo |
| Browser tab | Any page | Client favicon |
| Desk navbar | After login | Client name in top bar |
| Primary color | Buttons, sidebar | Client brand color |
| Outgoing email | Send any email | Client logo in header, ArsosTech footer |
| Website footer | Public pages | "Powered by ArsosTech ERP" |
| Source code headers | `.py` files | Copyright notices still intact (GPL compliance) |
| No ERPNext/Frappe text | Search all rendered pages | No visible "ERPNext" or "Frappe Technologies" |

---

## Open Items / Future Iterations

- [ ] Add a "preview" feature in White Label Settings to see logo/color before saving
- [ ] Create a CLI bench command `bench setup-whitelabel` that takes `--name`, `--logo`, `--color` args for scripted client onboarding
- [ ] Decide on placeholder logo assets for the base deployment
- [ ] Set up a private git remote for this fork (separate from the upstream Frappe ERPNext)
- [ ] Document per-client deployment runbook
