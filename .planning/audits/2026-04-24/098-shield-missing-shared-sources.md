---
id: 098
title: Shield extension does not include Shared/ sources — verified safe (no AppGroupConstants use)
severity: P3
area: infra
status: open
---

## Problem

The Shield extension (`Project.swift:167`) has `sources: ["Shield/**"]` with no `Shared/` glob, unlike ScreenTimeMonitor and DeenFirstActivityReport which both include `deenfirst/Sources/Shared/**`.

This is a potential issue IF Shield ever needs to read from the App Group (e.g., to read the block rule name to display in the shield UI, or to check unblock expiry).

## Evidence

`Project.swift:167`: `sources: ["Shield/**"]` — no Shared/ glob.

`Shield/ShieldConfigurationExtension.swift` — reviewed in full. It does NOT import AppGroupConstants or UserDefaults. It uses only hardcoded subtitle strings. It does not read from the App Group at all currently.

Contrast with ScreenTimeMonitor (`Project.swift:115-118`) which includes `Shared/**` explicitly.

## Solution

No immediate action needed — Shield does not use Shared/ code. 

If a future feature requires Shield to read App Group data (e.g., displaying rule name in shield title), add `"deenfirst/Sources/Shared/**"` to Shield's sources array in `Project.swift` at that time.

Document as a known omission (intentional) so future contributors don't add AppGroupConstants usage to Shield without also updating Project.swift.

## Why

Including Shared/ in Shield unnecessarily would increase binary size and compile time slightly. Since Shield is already sparse (one Swift file, no dependencies), keeping it minimal is correct. The audit finding is informational: the omission is intentional and currently correct.
