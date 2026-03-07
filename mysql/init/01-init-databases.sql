-- B1Stack: Initialize all ChurchApps databases
-- Run automatically by MySQL on first container start
-- Schema tables are created separately by `npm run initdb` in each API container

CREATE DATABASE IF NOT EXISTS membership CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS attendance CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS content    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS giving     CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS messaging  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS doing      CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS reporting  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS lessons    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS askapi     CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Grant the app user access to all databases
GRANT ALL PRIVILEGES ON membership.* TO 'b1stack'@'%';
GRANT ALL PRIVILEGES ON attendance.* TO 'b1stack'@'%';
GRANT ALL PRIVILEGES ON content.*    TO 'b1stack'@'%';
GRANT ALL PRIVILEGES ON giving.*     TO 'b1stack'@'%';
GRANT ALL PRIVILEGES ON messaging.*  TO 'b1stack'@'%';
GRANT ALL PRIVILEGES ON doing.*      TO 'b1stack'@'%';
GRANT ALL PRIVILEGES ON reporting.*  TO 'b1stack'@'%';
GRANT ALL PRIVILEGES ON lessons.*    TO 'b1stack'@'%';
GRANT ALL PRIVILEGES ON askapi.*     TO 'b1stack'@'%';

FLUSH PRIVILEGES;
