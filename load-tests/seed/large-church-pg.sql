-- ============================================================
-- B1Stack Demo Seed — Large Church (~5,000 members) — PostgreSQL
-- ============================================================
-- Represents a large multi-service church:
--   5,000 members across 1,800 households
--   5 services (3 weekend + midweek + satellite campus)
--   80 small groups / ministries
--
-- Separate church record (CHU00000002) keeps large-church data
-- isolated from the small-church seed (CHU00000001).
--
-- Run:
--   kubectl exec -n b1-postgres b1pg-pg-1 -- psql -U app membership \
--     < load-tests/seed/large-church-pg.sql
-- ============================================================

-- ── Church record ───────────────────────────────────────────────────────────
INSERT INTO churches (id, name, "subDomain", "registrationDate", address1, city, state, zip, country)
VALUES ('CHU00000002', 'Crossroads Fellowship', 'crossroads', NOW(), '1000 Church Blvd', 'Columbus', 'OH', '43215', 'US')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- ── Households (1,800 for ~5,000 members, avg ~2.8 per household) ──────────
INSERT INTO households (id, "churchId", name)
SELECT
  LPAD('LHH' || i::text, 11, '0'),
  'CHU00000002',
  'Household ' || i
FROM generate_series(1, 1800) AS i
ON CONFLICT (id) DO NOTHING;

-- ── People (5,000 members) ──────────────────────────────────────────────────
INSERT INTO people (
  id, "churchId", "householdId", "firstName", "lastName", "displayName",
  email, "membershipStatus", gender, removed
)
SELECT
  LPAD('LPER' || i::text, 11, '0'),
  'CHU00000002',
  LPAD('LHH' || LEAST(FLOOR((i - 1) / 2.78)::int + 1, 1800)::text, 11, '0'),
  (ARRAY['James','Mary','John','Patricia','Robert','Jennifer',
         'Michael','Linda','William','Barbara','David','Susan',
         'Richard','Jessica','Joseph','Sarah','Thomas','Karen',
         'Charles','Lisa'])[1 + (i % 20)],
  (ARRAY['Smith','Johnson','Williams','Brown','Jones','Garcia',
         'Miller','Davis','Wilson','Moore','Taylor','Anderson',
         'Thomas','Jackson','White','Harris','Martin','Thompson',
         'Wood','Martinez'])[1 + (i % 20)],
  (ARRAY['James','Mary','John','Patricia','Robert','Jennifer',
         'Michael','Linda','William','Barbara','David','Susan',
         'Richard','Jessica','Joseph','Sarah','Thomas','Karen',
         'Charles','Lisa'])[1 + (i % 20)]
  || ' ' ||
  (ARRAY['Smith','Johnson','Williams','Brown','Jones','Garcia',
         'Miller','Davis','Wilson','Moore','Taylor','Anderson',
         'Thomas','Jackson','White','Harris','Martin','Thompson',
         'Wood','Martinez'])[1 + (i % 20)],
  CASE WHEN i % 3 = 0 THEN 'member' || i || '@crossroads.church' ELSE NULL END,
  (ARRAY['Member','Regular Attender','Visitor','Member'])[1 + (i % 4)],
  CASE WHEN i % 2 = 0 THEN 'Male' ELSE 'Female' END,
  false
FROM generate_series(1, 5000) AS i
ON CONFLICT (id) DO NOTHING;

-- ── Services (3 weekend + midweek + satellite campus) ───────────────────────
-- services table is in the attendance schema
INSERT INTO attendance.services (id, "churchId", name)
VALUES
  ('LSVC0000001', 'CHU00000002', 'Saturday Evening'),
  ('LSVC0000002', 'CHU00000002', 'Sunday 8am'),
  ('LSVC0000003', 'CHU00000002', 'Sunday 10:30am'),
  ('LSVC0000004', 'CHU00000002', 'Sunday 10:30am East Campus'),
  ('LSVC0000005', 'CHU00000002', 'Wednesday Night')
ON CONFLICT (id) DO NOTHING;

-- ── 80 small groups / ministries ────────────────────────────────────────────
INSERT INTO groups (id, "churchId", "categoryName", name, "trackAttendance", about)
SELECT
  LPAD('LGRP' || i::text, 11, '0'),
  'CHU00000002',
  (ARRAY['Young Adults','Married Couples','Senior Fellowship','Youth',
         'Mens','Womens','Prayer','Children','Outreach','Bible Study'])[1 + (i % 10)],
  (ARRAY['Young Adults','Married Couples','Senior Fellowship','Youth',
         'Mens','Womens','Prayer','Children','Outreach','Bible Study'])[1 + (i % 10)]
  || ' Group ' || i,
  CASE WHEN i % 3 = 0 THEN false ELSE true END,
  'Fellowship group number ' || i
FROM generate_series(1, 80) AS i
ON CONFLICT (id) DO NOTHING;

-- ── Group memberships (~2,000 members across 80 groups, avg 25/group) ─────
INSERT INTO "groupMembers" (id, "churchId", "groupId", "personId", leader, "joinDate")
SELECT
  LPAD('LGM' || i::text, 11, '0'),
  'CHU00000002',
  LPAD('LGRP' || (1 + (i % 80))::text, 11, '0'),
  LPAD('LPER' || i::text, 11, '0'),
  CASE WHEN i % 25 = 0 THEN true ELSE false END,
  CURRENT_DATE - (RANDOM() * 365)::int
FROM generate_series(1, 2000) AS i
ON CONFLICT (id) DO NOTHING;

SELECT 'Large church seed complete' AS status,
  (SELECT COUNT(*) FROM people WHERE "churchId"='CHU00000002') AS people,
  (SELECT COUNT(*) FROM households WHERE "churchId"='CHU00000002') AS households,
  (SELECT COUNT(*) FROM groups WHERE "churchId"='CHU00000002') AS grps,
  (SELECT COUNT(*) FROM "groupMembers" WHERE "churchId"='CHU00000002') AS members;
