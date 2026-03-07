# B1Stack Load Tests

Uses [k6](https://k6.io/) — a modern, Go-based load testing tool.

## Install k6

```bash
# macOS
brew install k6

# Docker (no install)
docker run --rm -i grafana/k6 run - < load-tests/scenarios/10-users.js
```

## Quick start

```bash
# Set target base URL
export BASE_URL=https://b1-test.hz.ledoweb.com

# Run 10-user baseline test
k6 run --env BASE_URL=$BASE_URL load-tests/scenarios/10-users.js

# Run 50-user stress test
k6 run --env BASE_URL=$BASE_URL load-tests/scenarios/50-users.js

# Run Sunday morning burst (check-in simulation)
k6 run --env BASE_URL=$BASE_URL load-tests/scenarios/sunday-checkin.js
```

## Test scenarios

| File                          | VUs  | Duration | Purpose                                  |
|-------------------------------|------|----------|------------------------------------------|
| `scenarios/10-users.js`       | 10   | 5 min    | Baseline: verify sizing for 10 users     |
| `scenarios/50-users.js`       | 50   | 10 min   | Stress: validate 50-user capacity        |
| `scenarios/sunday-checkin.js` | 150  | 5 min    | Burst: Sunday morning check-in spike     |
| `scenarios/api-health.js`     | 1    | 30s      | Smoke: quick pre-load sanity check       |

## Interpreting results

Key metrics to watch:

- `http_req_duration p(95)` — 95th-percentile response time. Target: < 1s for API, < 3s for SSR
- `http_req_failed` — failure rate. Target: < 0.1%
- `mysql_connections` — check via `SHOW STATUS LIKE 'Threads_connected'` during test

```bash
# Watch MySQL connections live during a test
kubectl exec -n b1stack statefulset/b1stack-mysql -- \
  mysql -uroot -p$ROOT_PW -e "SHOW STATUS LIKE 'Threads_connected'; SHOW STATUS LIKE 'Max_used_connections';"
```

## Sizing validation checklist

After each test, verify:
- [ ] No `http_req_failed` during steady state
- [ ] `p(95) < 1000ms` for API endpoints
- [ ] `p(95) < 3000ms` for B1App SSR pages
- [ ] MySQL `Max_used_connections` < `max_connections * 0.8` (20% headroom)
- [ ] API pod CPU < 80% of limit
- [ ] No OOMKilled events: `kubectl get events --field-selector reason=OOMKilling`
