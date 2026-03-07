-- ============================================================
-- B1Stack Demo Seed — Large Church (~5,000 members)
-- ============================================================
-- Represents a large multi-service church:
--   5,000 members across 1,800 households
--   3 weekend services + 30+ weekly events
--   80 small groups + ministries
--   Podcast/livestream traffic on Sunday (external CDN assumed)
--
-- IMPORTANT: Loading 5k records with procedures takes 2-5 min.
-- Consider running with: mysql --max_allowed_packet=64M
--
-- TODO: Verify column names against ChurchApps API migrations first.
-- ============================================================

USE membership;

-- ── Church record ──────────────────────────────────────────
INSERT INTO churches (id, name, subDomain, registrationDate, address1, city, state, zip, country)
VALUES
  ('church-large', 'Crossroads Fellowship', 'crossroads', NOW(), '1000 Church Blvd', 'Columbus', 'OH', '43215', 'US')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- ── Households (1,800 households for ~5,000 members) ───────
DROP PROCEDURE IF EXISTS seed_large_households;
DELIMITER $$
CREATE PROCEDURE seed_large_households()
BEGIN
  DECLARE i INT DEFAULT 1;
  WHILE i <= 1800 DO
    INSERT IGNORE INTO households (id, churchId, name)
    VALUES (CONCAT('lhh-', LPAD(i, 5, '0')), 'church-large', CONCAT('Household ', i));
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL seed_large_households();
DROP PROCEDURE IF EXISTS seed_large_households;

-- ── People (5,000 members) ─────────────────────────────────
DROP PROCEDURE IF EXISTS seed_large_people;
DELIMITER $$
CREATE PROCEDURE seed_large_people()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE hh INT;
  WHILE i <= 5000 DO
    SET hh = FLOOR((i - 1) / 2.78) + 1;
    INSERT IGNORE INTO people (
      id, churchId, householdId, firstName, lastName,
      email, membershipStatus, gender, age
    ) VALUES (
      CONCAT('lperson-', LPAD(i, 6, '0')),
      'church-large',
      CONCAT('lhh-', LPAD(LEAST(hh, 1800), 5, '0')),
      ELT(1 + (i % 20),
        'James','Mary','John','Patricia','Robert','Jennifer',
        'Michael','Linda','William','Barbara','David','Susan',
        'Richard','Jessica','Joseph','Sarah','Thomas','Karen',
        'Charles','Lisa'),
      CONCAT('Jones', i),
      CONCAT('member', i, '@crossroads.church'),
      IF(i % 10 = 0, 'Regular Attender', IF(i % 7 = 0, 'Volunteer', 'Member')),
      IF(i % 2 = 0, 'M', 'F'),
      18 + (i % 65)
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL seed_large_people();
DROP PROCEDURE IF EXISTS seed_large_people;

-- ── Services (3 weekend + midweek) ────────────────────────
INSERT IGNORE INTO services (id, churchId, name, campusName)
VALUES
  ('lsvc-1', 'church-large', 'Saturday Evening',    'Main Campus'),
  ('lsvc-2', 'church-large', 'Sunday 8am',          'Main Campus'),
  ('lsvc-3', 'church-large', 'Sunday 10:30am',      'Main Campus'),
  ('lsvc-4', 'church-large', 'Sunday 10:30am East', 'East Campus'),
  ('lsvc-5', 'church-large', 'Wednesday Night',     'Main Campus');

-- ── 80 small groups / ministries ──────────────────────────
DROP PROCEDURE IF EXISTS seed_large_groups;
DELIMITER $$
CREATE PROCEDURE seed_large_groups()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE categories VARCHAR(200) DEFAULT 'Young Adults,Married,Senior,Youth,Mens,Womens,Prayer,Worship,Children,Outreach,Bible Study,Recovery,Sports,Arts,Missions,Parenting,Singles,College,Military,Grief';
  WHILE i <= 80 DO
    INSERT IGNORE INTO groups (id, churchId, name, trackAttendance, about)
    VALUES (
      CONCAT('lgrp-', LPAD(i, 3, '0')),
      'church-large',
      CONCAT('Ministry Group ', i),
      IF(i % 3 = 0, 0, 1),
      CONCAT('Fellowship group number ', i)
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL seed_large_groups();
DROP PROCEDURE IF EXISTS seed_large_groups;

SELECT 'Large church seed complete' AS status,
  (SELECT COUNT(*) FROM people WHERE churchId='church-large')    AS people,
  (SELECT COUNT(*) FROM households WHERE churchId='church-large') AS households,
  (SELECT COUNT(*) FROM groups WHERE churchId='church-large')    AS groups;
