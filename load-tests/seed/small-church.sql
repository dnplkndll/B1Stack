-- ============================================================
-- B1Stack Demo Seed — Small Church (~500 members)
-- ============================================================
-- Represents a mid-size suburban church:
--   500 members across 200 households
--   3 weekend services, 10 weekly events
--   15 small groups
--
-- TODO: Verify column names against actual ChurchApps API migrations
-- before running. Schema below is inferred from the API source.
-- Run: kubectl exec -n b1stack statefulset/b1stack-mysql -- \
--        mysql -uroot -p... membership < small-church.sql
-- ============================================================

USE membership;

-- ── Church record ──────────────────────────────────────────
INSERT INTO churches (id, name, subDomain, registrationDate, address1, city, state, zip, country)
VALUES
  ('church-demo', 'Grace Community Church', 'demo', NOW(), '123 Main St', 'Springfield', 'IL', '62701', 'US')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- ── Households (200 households for ~500 members) ───────────
-- Generated via a stored procedure for brevity
DROP PROCEDURE IF EXISTS seed_households;
DELIMITER $$
CREATE PROCEDURE seed_households()
BEGIN
  DECLARE i INT DEFAULT 1;
  WHILE i <= 200 DO
    INSERT IGNORE INTO households (id, churchId, name)
    VALUES (CONCAT('hh-', LPAD(i, 4, '0')), 'church-demo', CONCAT('Family ', i));
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL seed_households();
DROP PROCEDURE IF EXISTS seed_households;

-- ── People (500 members across 200 households) ─────────────
DROP PROCEDURE IF EXISTS seed_people;
DELIMITER $$
CREATE PROCEDURE seed_people()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE hh INT;
  DECLARE role VARCHAR(20);
  WHILE i <= 500 DO
    SET hh = FLOOR((i - 1) / 2.5) + 1;   -- ~2.5 people per household
    SET role = IF(i % 5 = 0, 'Admin', IF(i % 3 = 0, 'Staff', 'Member'));
    INSERT IGNORE INTO people (
      id, churchId, householdId, firstName, lastName,
      email, membershipStatus, gender, age, photoUpdated
    ) VALUES (
      CONCAT('person-', LPAD(i, 5, '0')),
      'church-demo',
      CONCAT('hh-', LPAD(hh, 4, '0')),
      ELT(1 + (i % 10), 'James','Mary','John','Patricia','Robert','Jennifer','Michael','Linda','William','Barbara'),
      CONCAT('Smith', i),
      CONCAT('member', i, '@demo.church'),
      'Member',
      IF(i % 2 = 0, 'M', 'F'),
      18 + (i % 60),
      NULL
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL seed_people();
DROP PROCEDURE IF EXISTS seed_people;

-- ── Services (3 weekend services) ─────────────────────────
INSERT IGNORE INTO services (id, churchId, name, campusName)
VALUES
  ('svc-1', 'church-demo', 'Saturday Evening',  'Main Campus'),
  ('svc-2', 'church-demo', 'Sunday 9am',         'Main Campus'),
  ('svc-3', 'church-demo', 'Sunday 11am',        'Main Campus');

-- ── Service times (recurring weekly) ──────────────────────
INSERT IGNORE INTO serviceTimes (id, serviceId, churchId, name, frequency, dayOfWeek, timeOfDay)
VALUES
  ('st-1', 'svc-1', 'church-demo', 'Sat 5:00pm',  'weekly', 6, '17:00'),
  ('st-2', 'svc-2', 'church-demo', 'Sun 9:00am',  'weekly', 0, '09:00'),
  ('st-3', 'svc-3', 'church-demo', 'Sun 11:00am', 'weekly', 0, '11:00');

-- ── Groups (15 small groups) ──────────────────────────────
INSERT IGNORE INTO groups (id, churchId, name, trackAttendance, about)
VALUES
  ('grp-01', 'church-demo', 'Young Adults',          1, 'Ages 18-30 small group'),
  ('grp-02', 'church-demo', 'Married Couples',       1, 'Marriage enrichment'),
  ('grp-03', 'church-demo', 'Senior Saints',         1, '55+ fellowship'),
  ('grp-04', 'church-demo', 'Youth Group',           1, 'Grades 6-12'),
  ('grp-05', 'church-demo', 'Mens Ministry',         1, 'Weekly mens gathering'),
  ('grp-06', 'church-demo', 'Womens Ministry',       1, 'Weekly womens gathering'),
  ('grp-07', 'church-demo', 'Prayer Team',           1, 'Intercessory prayer'),
  ('grp-08', 'church-demo', 'Worship Team',          1, 'Musicians and singers'),
  ('grp-09', 'church-demo', 'Children Ministry',     1, 'Birth to grade 5'),
  ('grp-10', 'church-demo', 'Community Outreach',    1, 'Local service projects'),
  ('grp-11', 'church-demo', 'Bible Study Monday',    1, 'Monday evening study'),
  ('grp-12', 'church-demo', 'Bible Study Wednesday', 1, 'Midweek study'),
  ('grp-13', 'church-demo', 'New Members Class',     0, 'Membership orientation'),
  ('grp-14', 'church-demo', 'Grief Support',         0, 'Bereavement group'),
  ('grp-15', 'church-demo', 'Tech & AV Team',        1, 'Production volunteers');

-- ── Group members (spread 500 people across groups) ───────
DROP PROCEDURE IF EXISTS seed_group_members;
DELIMITER $$
CREATE PROCEDURE seed_group_members()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE grpNum INT;
  WHILE i <= 500 DO
    -- Each person belongs to 1-3 groups
    SET grpNum = 1 + (i % 15);
    INSERT IGNORE INTO groupMembers (id, groupId, personId, role)
    VALUES (
      CONCAT('gm-', LPAD(i, 5, '0')),
      CONCAT('grp-', LPAD(grpNum, 2, '0')),
      CONCAT('person-', LPAD(i, 5, '0')),
      IF(i % 20 = 0, 'Leader', 'Member')
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL seed_group_members();
DROP PROCEDURE IF EXISTS seed_group_members;

SELECT 'Seed complete' AS status,
  (SELECT COUNT(*) FROM people WHERE churchId='church-demo')    AS people,
  (SELECT COUNT(*) FROM households WHERE churchId='church-demo') AS households,
  (SELECT COUNT(*) FROM groups WHERE churchId='church-demo')    AS groups;
