-- ============================================================
-- B1Stack Demo Seed — Small Church (~500 members)
-- Adds realistic data on top of the existing initdb demo data.
-- ============================================================
-- Church: CHU00000001 (Gracious Community Church) already exists.
-- Services: SER00000001/2/3, ServiceTimes: SST00000001/2/3/4 already exist.
-- This script EXTENDS the existing 86 people with more realistic data.
--
-- Run:
--   docker exec church-mysql-1 sh -c \
--     "mysql -uroot -pb1stack_root membership" < load-tests/seed/small-church.sql
--   docker exec church-mysql-1 sh -c \
--     "mysql -uroot -pb1stack_root attendance" < load-tests/seed/small-church-attendance.sql
-- ============================================================

USE membership;

-- ── Additional households (we have 27 → extend to ~200) ──────────────────────
DROP PROCEDURE IF EXISTS seed_sm_households;
DELIMITER $$
CREATE PROCEDURE seed_sm_households()
BEGIN
  DECLARE i INT DEFAULT 28;
  WHILE i <= 200 DO
    INSERT IGNORE INTO households (id, churchId, name)
    VALUES (LPAD(CONCAT('HH', i), 11, '0'), 'CHU00000001', CONCAT('Family ', i));
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL seed_sm_households();
DROP PROCEDURE IF EXISTS seed_sm_households;

-- ── Additional people (extend from 86 → 500) ──────────────────────────────────
DROP PROCEDURE IF EXISTS seed_sm_people;
DELIMITER $$
CREATE PROCEDURE seed_sm_people()
BEGIN
  DECLARE i INT DEFAULT 87;
  DECLARE hh_num INT;
  DECLARE first_names VARCHAR(500);
  DECLARE last_names  VARCHAR(500);
  SET first_names = 'James,Mary,John,Patricia,Robert,Jennifer,Michael,Linda,William,Barbara,David,Susan,Richard,Jessica,Joseph,Sarah,Thomas,Karen,Charles,Lisa,Christopher,Nancy,Daniel,Betty,Matthew,Margaret,Anthony,Sandra,Mark,Dorothy';
  SET last_names  = 'Smith,Johnson,Williams,Brown,Jones,Garcia,Miller,Davis,Wilson,Moore,Taylor,Anderson,Thomas,Jackson,White,Harris,Martin,Thompson,Wood,Martinez';
  WHILE i <= 500 DO
    SET hh_num = 28 + FLOOR((i - 87) / 2.5);
    INSERT IGNORE INTO people (
      id, churchId, householdId,
      firstName, lastName, displayName,
      email, membershipStatus, gender
    ) VALUES (
      LPAD(CONCAT('PER', i), 11, '0'),
      'CHU00000001',
      LPAD(CONCAT('HH', LEAST(hh_num, 200)), 11, '0'),
      ELT(1 + (i % 30), 'James','Mary','John','Patricia','Robert','Jennifer','Michael','Linda','William','Barbara','David','Susan','Richard','Jessica','Joseph','Sarah','Thomas','Karen','Charles','Lisa','Christopher','Nancy','Daniel','Betty','Matthew','Margaret','Anthony','Sandra','Mark','Dorothy'),
      ELT(1 + (i % 20), 'Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Wilson','Moore','Taylor','Anderson','Thomas','Jackson','White','Harris','Martin','Thompson','Wood','Martinez'),
      CONCAT(
        ELT(1 + (i % 30), 'James','Mary','John','Patricia','Robert','Jennifer','Michael','Linda','William','Barbara','David','Susan','Richard','Jessica','Joseph','Sarah','Thomas','Karen','Charles','Lisa','Christopher','Nancy','Daniel','Betty','Matthew','Margaret','Anthony','Sandra','Mark','Dorothy'),
        ' ',
        ELT(1 + (i % 20), 'Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Wilson','Moore','Taylor','Anderson','Thomas','Jackson','White','Harris','Martin','Thompson','Wood','Martinez')
      ),
      IF(i % 4 = 0, CONCAT('member', i, '@demo.church'), NULL),
      ELT(1 + (i % 4), 'Member', 'Regular Attender', 'Visitor', 'Member'),
      IF(i % 2 = 0, 'Male', 'Female')
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL seed_sm_people();
DROP PROCEDURE IF EXISTS seed_sm_people;

-- ── Add more groups ────────────────────────────────────────────────────────────
INSERT IGNORE INTO `groups` (id, churchId, categoryName, name, trackAttendance, about)
VALUES
  ('GRP00000010', 'CHU00000001', 'Small Groups',  'Young Adults',          1, 'Ages 18-30'),
  ('GRP00000011', 'CHU00000001', 'Small Groups',  'Senior Fellowship',     1, '65+ group'),
  ('GRP00000012', 'CHU00000001', 'Small Groups',  'Young Families',        1, 'Parents with young kids'),
  ('GRP00000013', 'CHU00000001', 'Ministry',      'Prayer Team',           1, 'Intercessory prayer'),
  ('GRP00000015', 'CHU00000001', 'Ministry',      'Children Ministry',     1, 'Birth to grade 5'),
  ('GRP00000017', 'CHU00000001', 'Outreach',      'Community Service',     1, 'Local outreach'),
  ('GRP00000018', 'CHU00000001', 'Support',       'Grief Support',         0, 'Bereavement group'),
  ('GRP00000020', 'CHU00000001', 'Admin',         'Tech & AV Team',        1, 'Production volunteers'),
  ('GRP00000021', 'CHU00000001', 'Small Groups',  'Tuesday Bible Study',   1, 'Evening study'),
  ('GRP00000022', 'CHU00000001', 'Small Groups',  'Thursday Bible Study',  1, 'Morning study');

-- ── Group members (spread people across groups) ────────────────────────────────
DROP PROCEDURE IF EXISTS seed_sm_members;
DELIMITER $$
CREATE PROCEDURE seed_sm_members()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE grp_ids VARCHAR(500);
  SET grp_ids = 'GRP00000001,GRP00000004,GRP00000010,GRP00000011,GRP00000012,GRP00000013,GRP00000015,GRP00000016,GRP00000017,GRP00000019,GRP00000020,GRP00000021,GRP00000022,GRP00000023,GRP0000000b';
  WHILE i <= 500 DO
    -- Each person in 1-2 groups
    INSERT IGNORE INTO groupMembers (id, churchId, groupId, personId, leader)
    VALUES (
      LPAD(CONCAT('GM', i), 11, '0'),
      'CHU00000001',
      ELT(1 + (i % 15), 'GRP00000001','GRP00000004','GRP00000010','GRP00000011','GRP00000012','GRP00000013','GRP00000015','GRP00000016','GRP00000017','GRP00000019','GRP00000020','GRP00000021','GRP00000022','GRP00000023','GRP0000000b'),
      LPAD(CONCAT('PER', i), 11, '0'),
      IF(i % 25 = 0, 1, 0)
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL seed_sm_members();
DROP PROCEDURE IF EXISTS seed_sm_members;

SELECT 'Small church seed complete' AS status,
  (SELECT COUNT(*) FROM people WHERE churchId='CHU00000001')     AS people,
  (SELECT COUNT(*) FROM households WHERE churchId='CHU00000001') AS households,
  (SELECT COUNT(*) FROM `groups` WHERE churchId='CHU00000001')   AS grps,
  (SELECT COUNT(*) FROM groupMembers WHERE churchId='CHU00000001') AS group_members;
