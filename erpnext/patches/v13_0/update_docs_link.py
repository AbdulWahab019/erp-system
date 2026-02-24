# Copyright (c) 2023, Frappe Technologies Pvt. Ltd. and Contributors
# License: MIT. See LICENSE


import frappe


def execute():
	navbar_settings = frappe.get_single("Navbar Settings")
	for item in navbar_settings.help_dropdown:
		if item.is_standard and item.route in (
			"https://erpnext.com/docs/user/manual",
			"https://docs.erpnext.com/docs/v14/user/manual/en/introduction",
			"https://arsostech.com/docs",
		):
			item.route = "https://arsostech.com/docs"

	navbar_settings.save()
