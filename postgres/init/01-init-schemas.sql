-- B1Stack: Initialize all ChurchApps schemas in a single PostgreSQL database.
-- Run automatically by PostgreSQL on first container start.
-- Schema tables are created separately by `npm run initdb` in each API container.

CREATE SCHEMA IF NOT EXISTS membership;
CREATE SCHEMA IF NOT EXISTS attendance;
CREATE SCHEMA IF NOT EXISTS content;
CREATE SCHEMA IF NOT EXISTS giving;
CREATE SCHEMA IF NOT EXISTS messaging;
CREATE SCHEMA IF NOT EXISTS doing;
CREATE SCHEMA IF NOT EXISTS reporting;
CREATE SCHEMA IF NOT EXISTS lessons;
CREATE SCHEMA IF NOT EXISTS askapi;

-- Grant the app user access to all schemas
GRANT ALL PRIVILEGES ON SCHEMA membership  TO b1stack;
GRANT ALL PRIVILEGES ON SCHEMA attendance  TO b1stack;
GRANT ALL PRIVILEGES ON SCHEMA content     TO b1stack;
GRANT ALL PRIVILEGES ON SCHEMA giving      TO b1stack;
GRANT ALL PRIVILEGES ON SCHEMA messaging   TO b1stack;
GRANT ALL PRIVILEGES ON SCHEMA doing       TO b1stack;
GRANT ALL PRIVILEGES ON SCHEMA reporting   TO b1stack;
GRANT ALL PRIVILEGES ON SCHEMA lessons     TO b1stack;
GRANT ALL PRIVILEGES ON SCHEMA askapi      TO b1stack;

-- Set default search_path so tables land in the right schema
ALTER DATABASE b1stack SET search_path TO public, membership, attendance, content, giving, messaging, doing, reporting;
