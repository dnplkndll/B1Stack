-- B1Stack: Create per-module PostgreSQL databases (mirrors MySQL layout).
-- Run automatically by PostgreSQL on first container start (after 01-init-schemas.sql).

CREATE DATABASE membership OWNER b1stack;
CREATE DATABASE attendance OWNER b1stack;
CREATE DATABASE content OWNER b1stack;
CREATE DATABASE giving OWNER b1stack;
CREATE DATABASE messaging OWNER b1stack;
CREATE DATABASE doing OWNER b1stack;
CREATE DATABASE reporting OWNER b1stack;
