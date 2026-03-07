# B1Stack Roadmap

Prioritized feature roadmap based on competitive analysis against Planning Center, Rock RMS, Tithe.ly, Breeze, and ChurchCRM. Linked issues reference [ChurchApps/ChurchAppsSupport](https://github.com/ChurchApps/ChurchAppsSupport/issues).

For contribution guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Now (Next 1-2 Releases)

### Bug Fixes
- **#802** — Message text box overlaps messages on mobile (CSS flexbox fix)
- **#801** — Messages not showing sender name on mobile (missing `personName` render)
- **#799** — Dark mode white background on sections (hardcoded `background: white` → theme variable)
- **#800** — Can't edit hyperlinks in website builder (link editor handler in rich text component)
- **#767** — Livestream SSL error on demo site (certificate/config fix)

### Developer Experience (Done)
- ~~Makefile for common tasks (`make up`, `make test`, `make health`)~~
- ~~Playwright localhost config (`BASE_URL` env override)~~
- ~~`wait-ready.sh` post-startup readiness polling~~
- ~~VS Code debug configs for API + Playwright~~
- ~~[CONTRIBUTING.md](CONTRIBUTING.md) — lower barrier for external contributors~~

### Testing Infrastructure (Done)
- ~~Mailpit local email catcher — inspect registration, password reset, notification emails~~
- ~~`make test-unit` / `make test-e2e` / `make test` — split test targets~~
- ~~CI pipeline (GitHub Actions) — docker compose up → init → demo-data → unit + E2E tests~~
- ~~Playwright HTML reports uploaded as CI artifacts~~

---

## Next (3-6 Months)

### SMS / Text Messaging
Twilio integration for mass and 1:1 messaging. Churches consistently rank texting as their #1 communication channel. Planning Center and Tithe.ly both offer this.

### PWA with Push Notifications
Service worker, Web Push API, installable app experience. Bridges the mobile gap without a native app build.

### Advanced Reporting Dashboard
Attendance trends, giving analytics, engagement scoring. Current reporting is minimal compared to Rock RMS and Planning Center.

### Event Registration with Payments
Stripe Checkout integration for retreats, VBS, camps, conferences. Currently no way to collect event-specific payments.

### GDPR Compliance ([#763](https://github.com/ChurchApps/ChurchAppsSupport/issues/763))
Data subject rights API, privacy policy templates, AWS DPA documentation. Strategic for EU/UK adoption.

### Foreign Currency Support ([#522](https://github.com/ChurchApps/ChurchAppsSupport/issues/522))
Stripe supports multi-currency natively. Main work is UI: currency selector, locale-aware formatting.

---

## Later (6-12 Months)

### Worship Planning Module
Song library, service order builder, team scheduling, chord charts. This is Planning Center's killer feature and the most common reason churches stay on their platform.

### Facility / Room Booking
Calendar integration, conflict detection, approval workflows. Required by most mid-size+ churches.

### Forms Builder
Visitor cards, volunteer applications, surveys, custom data collection. Reduces dependence on external form tools.

### Background Check Integration
Protect My Ministry or MinistrySafe API integration. Required for children's ministry compliance in most denominations.

### Enhanced Child Safety (Check-In)
Parent matching, allergy alerts, authorized pickup lists, security codes. Current check-in is basic compared to KidCheck or Planning Center Check-Ins.

### Multi-Campus Support
Campus-scoped data, cross-campus reporting, campus-specific branding. Growing requirement as multi-site churches adopt the platform.

---

## Future

### Native Mobile App
React Native or Capacitor wrapper for iOS/Android with offline support, push notifications, and native UX.

### Automated Follow-Up Workflows
Visitor follow-up sequences, assimilation paths, trigger-based emails/texts. ("First-time guest → welcome email → 3-day text → small group invite")

### AI Engagement Scoring
Predictive analytics for member retention, giving trends, attendance patterns. Surface members at risk of disengaging.

### Accounting Integration
QuickBooks Online and Xero export for giving data. Most churches need this for year-end financial reporting.

### One-Click Deploy
DigitalOcean App Platform, Railway, Render templates. Dramatically broadens the self-hosting audience beyond teams comfortable with Kubernetes.

### Onboarding Wizard ([#777](https://github.com/ChurchApps/ChurchAppsSupport/issues/777))
Route-based wizard at `/register?wizard=cloudBackup` — guided setup for new churches.

### PayPal Fee-Free Giving ([#288](https://github.com/ChurchApps/ChurchAppsSupport/issues/288))
PayPal Giving Fund integration for zero-fee charitable donations.

---

## Issue Triage Summary

| # | Type | Title | Status |
|---|------|-------|--------|
| [802](https://github.com/ChurchApps/ChurchAppsSupport/issues/802) | Bug | Message text box overlaps (mobile) | Now |
| [801](https://github.com/ChurchApps/ChurchAppsSupport/issues/801) | Bug | Messages missing sender (mobile) | Now |
| [800](https://github.com/ChurchApps/ChurchAppsSupport/issues/800) | Bug | Can't edit hyperlinks | Now |
| [799](https://github.com/ChurchApps/ChurchAppsSupport/issues/799) | Bug | Dark mode white background | Now |
| [767](https://github.com/ChurchApps/ChurchAppsSupport/issues/767) | Bug | Livestream SSL error | Now |
| [798](https://github.com/ChurchApps/ChurchAppsSupport/issues/798) | Bug | FreePlay Apple TV slides | Needs investigation (tvOS) |
| [777](https://github.com/ChurchApps/ChurchAppsSupport/issues/777) | Feature | Onboarding wizard | Future |
| [763](https://github.com/ChurchApps/ChurchAppsSupport/issues/763) | Feature | GDPR compliance | Next |
| [522](https://github.com/ChurchApps/ChurchAppsSupport/issues/522) | Feature | Foreign currency | Next |
| [507](https://github.com/ChurchApps/ChurchAppsSupport/issues/507) | DevOps | Automated AWS deploy | B1Stack Helm partially covers |
| [288](https://github.com/ChurchApps/ChurchAppsSupport/issues/288) | Feature | PayPal fee-free giving | Future |
