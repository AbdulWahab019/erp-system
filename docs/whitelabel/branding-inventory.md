# Branding Inventory Scan Report: ERPNext Codebase

**Scan Date:** 2026-02-24
**Repository:** arsostech/erp-system
**Branch:** whitelabel-foundation

---

## Executive Summary

This scan identified **26+ user-facing occurrences** of Frappe/ERPNext branding across the codebase.

| Priority | Category | Count | Action |
|----------|----------|-------|--------|
| P0 | Config (hooks.py, install.py, startup) | 8 | Replace with ArsosTech branding |
| P1 | Help, Documentation, Workspaces | 15 | Update URLs or remove references |
| P2 | Changelogs & Patches | 3 | Update or leave as historical |
| P3 | Copyright Headers | 200+ | **DO NOT CHANGE** (GPL v3) |

---

## P0: Critical - Direct User-Visible Branding

| # | File | Line(s) | Current Content | Action |
|---|------|---------|----------------|--------|
| 1 | `erpnext/hooks.py` | 2 | `app_title = "ERPNext"` | Change to `"ERP"` |
| 2 | `erpnext/hooks.py` | 3 | `app_publisher = "Frappe Technologies Pvt. Ltd."` | Change to `"ArsosTech Pvt. Ltd."` |
| 3 | `erpnext/hooks.py` | 7 | `app_email = "hello@frappe.io"` | Change to `"contact@arsostech.com"` |
| 4 | `erpnext/startup/__init__.py` | 19 | `product_name = "ERPNext"` | Change to `"ERP"` |
| 5 | `erpnext/setup/install.py` | 238 | `app_name` set to `"ERPNext"` | Change to `"ERP"` |
| 6 | `erpnext/setup/install.py` | 16-17 | Mail footer with `frappe.io/erpnext` link | Replace with ArsosTech footer |
| 7 | `erpnext/setup/install.py` | 190 | Documentation link to `docs.erpnext.com` | Replace or remove |
| 8 | `erpnext/setup/install.py` | 196 | User Forum link to `discuss.frappe.io` | Replace or remove |

---

## P1: Important - Secondary UI and Help

| # | File | Line(s) | Issue | Action |
|---|------|---------|-------|--------|
| 9 | `erpnext/setup/install.py` | 200-202 | "Frappe School" + `frappe.io/school` | Remove entirely |
| 10 | `erpnext/public/js/help_links.js` | 3 | `docsUrl = "https://erpnext.com/docs/"` | Change base URL |
| 11 | `erpnext/setup/doctype/company/company.json` | 724, 734 | `documentation_url` to `docs.erpnext.com` | Remove or update |
| 12 | `erpnext/stock/doctype/stock_settings/stock_settings.json` | 129 | `documentation_url` to `docs.erpnext.com` | Remove or update |
| 13 | `erpnext/buying/doctype/buying_settings/buying_settings.js` | 14 | Help text with `docs.erpnext.com` link | Update link |
| 14 | `erpnext/crm/workspace/crm/crm.json` | 9 | "Frappe CRM" deprecation banner | Replace text |
| 15 | `erpnext/support/workspace/support/support.json` | 4 | "Frappe Helpdesk" deprecation banner | Replace text |
| 16 | `erpnext/manufacturing/doctype/production_plan/production_plan.js` | 183 | `erpnext.com/docs` link | Remove or update |
| 17 | `erpnext/locale/main.pot` + 25+ `.po` files | Various | Translatable strings with branding | Regenerate after code changes |

---

## P2: Moderate - Patches & Historical

| # | File | Issue |
|---|------|-------|
| 18 | `erpnext/patches/v13_0/update_docs_link.py` | Old docs URL migration |
| 19 | `erpnext/change_log/v5/*.md` through `v13/*.md` | Historical release notes |
| 20 | Various deprecation warning patches | "ERPNext" in warning messages |

---

## P3: Non-Actionable - Copyright Headers (GPL v3)

- **~200+ files** contain `# Copyright (c) Frappe Technologies Pvt. Ltd.`
- These **MUST remain unchanged** per GPL v3 license requirements
- Removing them would violate the license

---

## Files Requiring Changes (Quick Reference)

### Must Change (Phase 1)
- `erpnext/hooks.py`
- `erpnext/startup/__init__.py`
- `erpnext/setup/install.py`
- `erpnext/templates/includes/footer/footer_powered.html`
- `erpnext/public/js/help_links.js`
- `pyproject.toml`
- `erpnext/patches/v13_0/set_app_name.py`
- `erpnext/patches.txt`

### Should Change (Phase 3)
- `erpnext/setup/doctype/company/company.json`
- `erpnext/stock/doctype/stock_settings/stock_settings.json`
- `erpnext/buying/doctype/buying_settings/buying_settings.js`
- `erpnext/crm/workspace/crm/crm.json`
- `erpnext/support/workspace/support/support.json`
- `erpnext/manufacturing/doctype/production_plan/production_plan.js`
- Desktop icon JSON files (11 files)
- Workspace JSON files

### Do NOT Edit
- Copyright headers in all `.py` and `.js` files
- Locale `.po`/`.pot` files (regenerate instead)
