-- =====================================================================
-- F-014 — Least-privilege database user for OneMuseum
-- =====================================================================
--
-- The application currently connects as MariaDB root. This script creates
-- a dedicated user holding only the privileges the application actually
-- uses, determined by auditing every SQL statement in onemuseum/:
--
--     SELECT, INSERT, UPDATE, DELETE   — CRUD in dbutils.py and routes
--     EXECUTE                          — callproc() in dbutils.py,
--                                        categories/routes.py
--
-- Deliberately NOT granted:
--     CREATE, DROP, ALTER, INDEX       — no DDL anywhere in the app; schema
--                                        changes are applied from SQL/ by
--                                        hand, as root
--     GRANT OPTION                     — the app never manages users
--     FILE, PROCESS, SUPER, RELOAD     — server-level, never needed
--     LOCK TABLES, REFERENCES          — unused; add only if a real need
--                                        appears
--
-- Note on REPLACE: `REPLACE INTO` is covered by INSERT + DELETE, which are
-- both granted. No separate privilege exists.
--
-- ---------------------------------------------------------------------
-- BEFORE RUNNING
-- ---------------------------------------------------------------------
--
-- 1. Choose a password. Generate one rather than inventing it:
--
--        python -c "import secrets; print(secrets.token_urlsafe(24))"
--
-- 2. Replace CHANGE_ME below with that value. Do not commit the result —
--    save the edited copy outside the repository, or edit, run, and revert.
--
-- 3. Run as root inside the container:
--
--        docker exec -i <container> mariadb -uroot -p onemuseum2 \
--            < SQL/F-014-app-user.sql
--
-- 4. Put the same password in .env as MYSQLCONN_PASSWORD, and set
--    MYSQLCONN_USER=onemuseum_app
--
-- ---------------------------------------------------------------------
-- HOST SCOPING
-- ---------------------------------------------------------------------
--
-- '%' allows connection from any host. That is appropriate here because the
-- app connects to the container across Docker's bridge network from an
-- address that is not stable, and the port is published only to 127.0.0.1
-- on the host.
--
-- For production this should be tightened to the specific application host
-- or subnet. Flagged in the handover as a follow-up, not done here.
--
-- =====================================================================

-- Idempotent: safe to re-run. DROP first so a re-run resets privileges
-- cleanly rather than accumulating them.
DROP USER IF EXISTS 'onemuseum_app'@'%';

CREATE USER 'onemuseum_app'@'%'
    IDENTIFIED BY 'CHANGE_ME';

-- Data manipulation across the application schema.
GRANT SELECT, INSERT, UPDATE, DELETE
    ON `onemuseum2`.*
    TO 'onemuseum_app'@'%';

-- Stored procedures: GenCategories, GetCommonData, UPLOAD_*, and others
-- invoked via callproc() in dbutils.py.
GRANT EXECUTE
    ON `onemuseum2`.*
    TO 'onemuseum_app'@'%';

FLUSH PRIVILEGES;

-- ---------------------------------------------------------------------
-- VERIFICATION — run these after the script and check the output
-- ---------------------------------------------------------------------
--
--   SHOW GRANTS FOR 'onemuseum_app'@'%';
--
-- Expect exactly two lines: a USAGE grant on *.* (which conveys no
-- privileges — it only records that the user exists), and the
-- SELECT/INSERT/UPDATE/DELETE/EXECUTE grant on onemuseum2.*
--
-- Anything mentioning ALL PRIVILEGES, GRANT OPTION, or *.* with real
-- privileges attached means this did not do what was intended.
--
-- Then confirm the app user can read but not alter structure:
--
--   docker exec -it <container> mariadb -uonemuseum_app -p onemuseum2
--   > SELECT COUNT(*) FROM Collections;   -- should succeed
--   > CREATE TABLE _privtest (i INT);     -- should fail: command denied
--   > DROP TABLE Collections;             -- should fail: command denied
--
-- The two failures are the point of the exercise. If they succeed, the
-- grants are wrong.
-- =====================================================================
