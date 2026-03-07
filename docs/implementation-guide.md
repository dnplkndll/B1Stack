# B1Stack Implementation Guide

> **Status: Work In Progress — community review welcome.**
> Numbers and recommendations below are research estimates. If you have real-world experience
> deploying ChurchApps or similar church management systems, please open a PR with corrections.

---

## Overview

This guide covers what it takes to go from zero to a running B1Stack deployment at a small-to-medium church:
- Cloud hosting costs (daily/monthly)
- On-site hardware requirements
- A sample project timeline

---

## Cloud Hosting: Cost Summary

See [cloud-hosting.md](./cloud-hosting.md) for full provider comparison and CLI install steps.

| Provider    | 10-user setup  | Daily cost | Notes                            |
|-------------|----------------|------------|----------------------------------|
| Hetzner CX22 | ~€12/mo       | ~€0.40/day | Cheapest. Single VPS + k3s.      |
| DigitalOcean | ~$38/mo       | ~$1.25/day | Managed Kubernetes (DOKS).       |
| GCP (GKE)   | ~$70/mo        | ~$2.30/day | Good if church uses Google WS.   |
| AWS (EKS)   | ~$121/mo       | ~$4.00/day | Highest cost; best for compliance.|

**Recommended starting point**: Hetzner CX22 (~€12/mo, ~$13/mo). Upgrade to managed DB + larger node when you exceed 50 regular users or 500 Sunday check-ins.

---

## On-Site Hardware

### Check-in kiosks

The Sunday check-in flow in B1Stack is a web app — any device with a browser works.

| Option                        | Cost (est.) | Notes                                                      |
|-------------------------------|-------------|------------------------------------------------------------|
| iPad (10th gen) + stand       | ~$400–600   | Easiest to manage; use Guided Access to lock to kiosk URL  |
| Android tablet (Samsung A9+)  | ~$200–350   | Lower cost; Chrome in kiosk mode works well                |
| Repurposed Windows laptop     | $0–150      | Works; less polished experience at the kiosk               |
| Raspberry Pi 5 + display      | ~$150–200   | DIY; good for fixed kiosk stations                         |

**Per-station software**: just a browser pointed at `https://b1admin.YOUR_DOMAIN/checkin`.
No local install needed. Devices can share a single check-in staff login.

**How many kiosks?**
- 1 kiosk per ~75 expected arrivals per 30-minute window is a common starting point
- 500-member church with 60% attendance = 300 people across 3 services → 1–2 kiosks per service

### Label printers (check-in tags)

B1Stack can print name/security labels at check-in (requires compatible label printer and browser print support).

| Printer                          | Cost (est.) | Labels/mo | Notes                                        |
|----------------------------------|-------------|-----------|----------------------------------------------|
| DYMO LabelWriter 450             | ~$120       | ~500      | USB; works with Chrome print dialog          |
| Brother QL-820NWB                | ~$130       | ~500      | WiFi; easier for tablet kiosks               |
| Zebra ZD421 (thermal)            | ~$350–450   | 1,000+    | Durable; better for high-volume              |

> **WIP**: Verify which label formats and printer models ChurchApps B1Admin officially supports.
> The upstream ChurchApps community may have a preferred printer model.

### Network / WiFi

- Kiosks benefit from a dedicated SSID (isolated from congregation WiFi) for reliability
- Wired ethernet to kiosk stations is ideal for Sunday morning (eliminates WiFi congestion)
- Minimum: 10 Mbps upload for API traffic from kiosks; 50 Mbps if streaming

### Audio-Visual (if using B1App for livestream/podcast)

B1Stack does not handle video encoding itself — it links to external platforms.

| Need                              | Tool                        | Cost          |
|-----------------------------------|-----------------------------|---------------|
| Livestream to YouTube             | OBS Studio (free) + camera  | $0–500        |
| Podcast hosting                   | Buzzsprout / Anchor         | $0–18/mo      |
| Sermon video storage              | Vimeo / YouTube             | $0–20/mo      |
| CDN for media files               | Cloudflare free tier        | $0            |

Configure `YOUTUBE_API_KEY` and `VIMEO_TOKEN` in `api.secrets` to connect B1Stack to these services.

---

## Sample Project Plan

> **WIP** — timeline estimates based on similar open-source church tech deployments.
> Adjust based on your team's technical capacity and church size.

### Phase 1: Evaluation (Week 1–2)

- [ ] Run local stack: `make setup && make up && make init` (~30 min)
- [ ] Log in to B1Admin (`http://localhost:3101`) and explore features
- [ ] Review feature coverage against your current church management software
- [ ] Identify gaps (giving platform, child check-in security, etc.)
- [ ] Decision: proceed or evaluate alternatives

**Cost**: $0 (local only)

### Phase 2: Cloud Pilot (Week 2–4)

- [ ] Choose hosting provider (start with Hetzner for lowest cost)
- [ ] Follow CLI install in [cloud-hosting.md](./cloud-hosting.md) (~2 hours)
- [ ] Point a test subdomain at the server
- [ ] Import/migrate a small member dataset (50–100 people)
- [ ] Train 2–3 staff on B1Admin
- [ ] Run a Sunday check-in pilot with 1 tablet

**Cost**: ~$13–38/mo depending on provider

### Phase 3: Full Migration (Week 4–8)

- [ ] Export full member database from current system (CSV)
- [ ] Write/run SQL import script to populate B1Stack membership DB
- [ ] Migrate historical giving records (if applicable)
- [ ] Set up SSL/TLS and production domain
- [ ] Configure email (SMTP relay or AWS SES)
- [ ] Set up file storage (S3-compatible if using media uploads)
- [ ] Train all staff

### Phase 4: Sunday Morning Production (Month 2+)

- [ ] Purchase and configure check-in kiosks (1–2 tablets + stands)
- [ ] Purchase label printer if using name tags
- [ ] Run load test before go-live: `k6 run load-tests/scenarios/sunday-checkin.js`
- [ ] Configure monitoring (kube-prometheus-stack or Grafana Cloud free tier)
- [ ] Establish backup process (daily MySQL snapshot)
- [ ] Go live

---

## One-Time Hardware Budget Estimate

For a 200–500 member church with Sunday check-in:

| Item                              | Qty | Unit cost | Total     |
|-----------------------------------|-----|-----------|-----------|
| iPad (10th gen) + kiosk stand     | 2   | ~$500     | ~$1,000   |
| Label printer (Brother QL-820NWB) | 1   | ~$130     | ~$130     |
| Label rolls (1 yr supply)         | 4   | ~$25      | ~$100     |
| Network switch (if adding ports)  | 1   | ~$50      | ~$50      |
| **Total hardware**                |     |           | **~$1,280** |

**Ongoing**: ~$13–40/mo cloud hosting + label supplies.

---

## What B1Stack Does Not Cover (yet)

These are gaps relative to commercial church management software — research before committing:

- **Integrated online giving processing** — giving module exists but requires Stripe setup; no built-in ACH
- **Child check-in security labels** — label printing exists; guardian-matching security codes are WIP upstream
- **Mobile app for members** — B1App is a web app, not a native iOS/Android app
- **HIPAA / pastoral care confidentiality** — no encrypted notes or counseling module
- **Event registration with payment** — basic event listing exists; paid registration is not built-in
- **Accounting / QuickBooks integration** — not in scope for B1Stack

> Open an issue if you'd like to track any of these gaps or contribute solutions.
