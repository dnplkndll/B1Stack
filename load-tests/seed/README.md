# B1Stack Demo Seed Data

SQL seed scripts for realistic load testing datasets.

## Datasets

| Script               | Members | Services | Groups | Events | Target test  |
|----------------------|---------|----------|--------|--------|--------------|
| `small-church.sql`   | 500     | 3/wk     | 15     | 10/wk  | 10-user test |
| `large-church.sql`   | 5,000   | 3/wk     | 80     | 30/wk  | 50-user test |

## Loading seed data

```bash
# After running initdb (which creates tables), load seed data:
kubectl exec -i -n b1stack statefulset/b1stack-mysql -- \
  mysql -uroot -p$ROOT_PW membership < load-tests/seed/small-church.sql

# Or via docker compose (local dev):
docker compose exec -T mysql mysql -uroot -pb1stack-root-dev membership \
  < load-tests/seed/small-church.sql
```

## Data model notes

Seed data covers only the `membership` database (people, households, groups, services, service times).
The `attendance` database gets populated by the Sunday check-in load test itself.

Schema is verified against the live ChurchApps API initdb migrations. Key columns:
- `people`: id, churchId, householdId, firstName, lastName, displayName, email, membershipStatus, gender
- `households`: id, churchId, name
- `` `groups` ``: id, churchId, categoryName, name, trackAttendance, about
- `services`: id, churchId, name
