-- ============================================================
-- B1Stack Demo Seed — Large Church (~5,000 members)
-- ============================================================
-- Represents a large multi-service church:
--   5,000 members across 1,800 households
--   5 services (3 weekend + midweek + satellite campus)
--   80 small groups / ministries
--
-- IMPORTANT: Loading 5k records with procedures takes 2-5 min.
-- Consider running with: mysql --max_allowed_packet=64M
--
-- Separate church record (CHU00000002) keeps large-church data
-- isolated from the small-church seed (CHU00000001).
--
-- Run:
--   docker exec church-mysql-1 sh -c \
--     "mysql -uroot -pb1stack_root membership" < load-tests/seed/large-church.sql
-- ============================================================

USE membership;

-- ── Church record ───────────────────────────────────────────────────────────
INSERT INTO churches (id, name, subDomain, registrationDate, address1, city, state, zip, country)
VALUES
  ('CHU00000002', 'Crossroads Fellowship', 'crossroads', NOW(), '1000 Church Blvd', 'Columbus', 'OH', '43215', 'US')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- ── Households (1,800 for ~5,000 members, avg ~2.8 per household) ──────────
DROP PROCEDURE IF EXISTS seed_large_households;
DELIMITER $$
CREATE PROCEDURE seed_large_households()
BEGIN
  DECLARE i INT DEFAULT 1;
  WHILE i <= 1800 DO
    INSERT IGNORE INTO households (id, churchId, name)
    VALUES (LPAD(CONCAT('LHH', i), 11, '0'), 'CHU00000002', CONCAT('Household ', i));
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL seed_large_households();
DROP PROCEDURE IF EXISTS seed_large_households;

-- ── People (5,000 members) ──────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS seed_large_people;
DELIMITER $$
CREATE PROCEDURE seed_large_people()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE hh INT;
  DECLARE fname VARCHAR(20);
  DECLARE lname VARCHAR(20);
  WHILE i <= 5000 DO
    SET hh = FLOOR((i - 1) / 2.78) + 1;
    SET fname = ELT(1 + (i % 20),
      'James','Mary','John','Patricia','Robert','Jennifer',
      'Michael','Linda','William','Barbara','David','Susan',
      'Richard','Jessica','Joseph','Sarah','Thomas','Karen',
      'Charles','Lisa');
    SET lname = ELT(1 + (i % 20),
      'Smith','Johnson','Williams','Brown','Jones','Garcia',
      'Miller','Davis','Wilson','Moore','Taylor','Anderson',
      'Thomas','Jackson','White','Harris','Martin','Thompson',
      'Wood','Martinez');
    INSERT IGNORE INTO people (
      id, churchId, householdId, firstName, lastName, displayName,
      email, membershipStatus, gender
    ) VALUES (
      LPAD(CONCAT('LPER', i), 11, '0'),
      'CHU00000002',
      LPAD(CONCAT('LHH', LEAST(hh, 1800)), 11, '0'),
      fname,
      lname,
      CONCAT(fname, ' ', lname),
      IF(i % 3 = 0, CONCAT('member', i, '@crossroads.church'), NULL),
      ELT(1 + (i % 4), 'Member', 'Regular Attender', 'Visitor', 'Member'),
      IF(i % 2 = 0, 'Male', 'Female')
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL seed_large_people();
DROP PROCEDURE IF EXISTS seed_large_people;

-- ── Services (3 weekend + midweek + satellite campus) ───────────────────────
INSERT IGNORE INTO attendance.services (id, churchId, name)
VALUES
  ('LSVC0000001', 'CHU00000002', 'Saturday Evening'),
  ('LSVC0000002', 'CHU00000002', 'Sunday 8am'),
  ('LSVC0000003', 'CHU00000002', 'Sunday 10:30am'),
  ('LSVC0000004', 'CHU00000002', 'Sunday 10:30am East Campus'),
  ('LSVC0000005', 'CHU00000002', 'Wednesday Night');

-- ── 80 small groups / ministries ────────────────────────────────────────────
DROP PROCEDURE IF EXISTS seed_large_groups;
DELIMITER $$
CREATE PROCEDURE seed_large_groups()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE category VARCHAR(30);
  WHILE i <= 80 DO
    SET category = ELT(1 + (i % 10),
      'Young Adults','Married Couples','Senior Fellowship','Youth',
      'Mens','Womens','Prayer','Children','Outreach','Bible Study');
    INSERT IGNORE INTO `groups` (id, churchId, categoryName, name, trackAttendance, about)
    VALUES (
      LPAD(CONCAT('LGRP', i), 11, '0'),
      'CHU00000002',
      category,
      CONCAT(category, ' Group ', i),
      IF(i % 3 = 0, 0, 1),
      CONCAT('Fellowship group number ', i)
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL seed_large_groups();
DROP PROCEDURE IF EXISTS seed_large_groups;

-- ── Group memberships (~2,000 members across 80 groups, avg 25/group) ─────
DROP PROCEDURE IF EXISTS seed_large_members;
DELIMITER $$
CREATE PROCEDURE seed_large_members()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE grp_idx INT;
  WHILE i <= 2000 DO
    SET grp_idx = 1 + (i % 80);
    INSERT IGNORE INTO groupMembers (id, churchId, groupId, personId, leader, joinDate)
    VALUES (
      LPAD(CONCAT('LGM', i), 11, '0'),
      'CHU00000002',
      LPAD(CONCAT('LGRP', grp_idx), 11, '0'),
      LPAD(CONCAT('LPER', i), 11, '0'),
      IF(i % 25 = 0, 1, 0),
      DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 365) DAY)
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL seed_large_members();
DROP PROCEDURE IF EXISTS seed_large_members;

SELECT 'Large church seed complete' AS status,
  (SELECT COUNT(*) FROM people WHERE churchId='CHU00000002')        AS people,
  (SELECT COUNT(*) FROM households WHERE churchId='CHU00000002')    AS households,
  (SELECT COUNT(*) FROM `groups` WHERE churchId='CHU00000002')      AS grps,
  (SELECT COUNT(*) FROM groupMembers WHERE churchId='CHU00000002')  AS members;
