# Load Testing Guide

## Measured baseline: 10 concurrent users, 500-member dataset

k6 10-user test results (5 min run, 500 people, 564 iterations):

| Metric                         | Result     | Threshold  |
|--------------------------------|------------|------------|
| API p(95) latency              | 25ms       | < 1,000ms  |
| API p(99) latency              | 35ms       | < 2,000ms  |
| Failure rate                   | 0%         | < 0.5%     |
| MySQL `Max_used_connections`   | 39 / 100   | < 80       |
| Checks passed                  | 1211/1211  | all        |

**Key finding**: The API pool is hardcoded to 10 connections per module in `MultiDatabasePool.ts`
(7 modules × 10 = 70 theoretical max per pod). At 10 users only 39 connections were used.
`mysql.maxConnections=100` gives 60% headroom for a single API replica.

50-user results are not yet measured — run `50-users.js` to capture them.

---

## Running tests locally (recommended starting point)

Your local `docker compose up` stack (ports 8084, 3301, 3101) is fine for initial testing.
k6 runs on your machine and hammers the local Docker network — no bandwidth constraint.

```bash
# Start the stack
make up
make init   # first time only

# Load seed data
docker compose exec -T mysql mysql -uroot -pb1stack-root-dev membership \
  < load-tests/seed/small-church.sql

# Smoke check first
k6 run --env BASE_URL=http://localhost:8084 load-tests/scenarios/api-health.js

# 10-user baseline
k6 run --env BASE_URL=http://localhost:8084 load-tests/scenarios/10-users.js

# Watch MySQL connections in another terminal while the test runs:
watch -n2 'docker compose exec mysql mysql -uroot -pb1stack-root-dev \
  -e "SHOW STATUS LIKE '"'"'Threads_connected'"'"'; SHOW STATUS LIKE '"'"'Max_used_connections'"'"';"'
```

### What to look for in the logs

```bash
# API logs during test
make logs | grep -E "error|Error|connection|pool|429|500"

# MySQL connection count peaks
docker compose exec mysql mysql -uroot -pb1stack-root-dev \
  -e "SHOW STATUS LIKE 'Max_used_connections';"

# Memory usage during test
docker stats --no-stream | grep -E "api|mysql|b1app"
```

---

## Running tests against the Hetzner cluster

The cluster has sufficient bandwidth for load tests (Hetzner CX22 has 20 Gbps shared).
k6 from your laptop is fine for 10–50 VUs. Beyond 200 VUs you'll need distributed runners.

```bash
export BASE_URL=https://api-b1-test.hz.ledoweb.com

# Check bandwidth available first (rough test)
k6 run --env BASE_URL=$BASE_URL load-tests/scenarios/api-health.js

# 10-user baseline
k6 run --env BASE_URL=$BASE_URL load-tests/scenarios/10-users.js

# Monitor during test
kubectl --context hetzner-ledo -n b1-test exec statefulset/b1stack-mysql -- \
  mysql -uroot -p... -e "SHOW STATUS LIKE 'Threads_connected'; SHOW STATUS LIKE 'Max_used_connections';"

kubectl --context hetzner-ledo top pods -n b1-test
```

---

## Distributed load testing (>200 VUs)

For the Sunday check-in burst test at 150+ VUs, or simulating 200+ concurrent users,
your laptop's network may be the bottleneck, not the server.

### Option 1: k6 Cloud (easiest)

```bash
k6 cloud --env BASE_URL=$BASE_URL load-tests/scenarios/sunday-checkin.js
```
Free tier: 50 VUs for 10 minutes/month. Sufficient for initial sizing validation.

### Option 2: GitHub Actions runner

Add a workflow that runs k6 against the staging cluster after each deploy:

```yaml
# .github/workflows/load-test.yml (to be created)
- name: Run load test
  uses: grafana/k6-action@v0.3.1
  with:
    filename: load-tests/scenarios/10-users.js
  env:
    BASE_URL: ${{ secrets.STAGING_API_URL }}
```

### Option 3: Distributed k6 on Kubernetes (k6-operator)

For sustained large-scale testing (500+ VUs, 5k-member church scenario):

```bash
# Install k6 operator on the test cluster
kubectl apply -f https://raw.githubusercontent.com/grafana/k6-operator/main/bundle.yaml

# Run a distributed k6 job — see k6-operator docs for TestRun CRD syntax:
# https://grafana.com/docs/k6/latest/set-up/set-up-distributed-k6/
```

---

## Sizing update process

1. Run `api-health.js` → smoke passes
2. Load `small-church.sql` seed data
3. Run `10-users.js` → note `p(95)` latencies and MySQL `Max_used_connections`
4. If `Max_used_connections` > 80% of `max_connections` → increase `mysql.maxConnections`
5. If API `p(95)` > 1s → increase `api.resources` or add replica
6. Load `large-church.sql`, run `50-users.js` → repeat
7. Run `sunday-checkin.js` → verify burst handling
8. Update the sizing table in `values.yaml` with measured values
9. Update `docs/cloud-hosting.md` with validated instance recommendations

---

## Key metrics reference

| Metric                   | Good        | Needs tuning          |
|--------------------------|-------------|----------------------|
| API p(95) latency        | < 500ms     | > 1,000ms            |
| B1App SSR p(95) latency  | < 2s        | > 5s                 |
| Failure rate             | < 0.1%      | > 0.5%               |
| MySQL Max_used_conns     | < 70% cap   | > 80% cap            |
| API pod CPU              | < 60% limit | > 80% → add replica  |
| API pod memory           | stable      | growing → memory leak |
