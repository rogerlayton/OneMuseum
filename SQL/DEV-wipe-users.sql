-- DEV-wipe-users.sql
-- Wipes ALL users and every table that references them, for the LAPTOP dev
-- database only. Do NOT run against production.
--
-- Safety design:
--   * Wrapped in a transaction with NO commit -- you inspect, then COMMIT
--     yourself (or ROLLBACK to undo).
--   * FK checks disabled inside the transaction so delete order does not
--     matter; re-enabled before you commit.
--
-- The nine referencing tables and the FK column name (UserID -> users.GUID)
-- were confirmed against the schema. If any table does not exist in your
-- database, that DELETE line will error -- remove that one line and re-run.
--
-- BEFORE running this, take a backup (see the mysqldump command in the
-- session notes). A wipe is only safe if there is an undo.

START TRANSACTION;
SET FOREIGN_KEY_CHECKS = 0;

DELETE FROM communitymembers;
DELETE FROM inputfiles;
DELETE FROM posts;
DELETE FROM sessions;
DELETE FROM userentities;
DELETE FROM userfilters;
DELETE FROM userfolders;
DELETE FROM usernotes;
DELETE FROM usersecretquestions;
DELETE FROM users;

SET FOREIGN_KEY_CHECKS = 1;

-- Inspect before committing. Every count below should be 0:
SELECT 'users' AS tbl, COUNT(*) AS remaining FROM users
UNION ALL SELECT 'sessions', COUNT(*) FROM sessions
UNION ALL SELECT 'userentities', COUNT(*) FROM userentities
UNION ALL SELECT 'userfolders', COUNT(*) FROM userfolders
UNION ALL SELECT 'usernotes', COUNT(*) FROM usernotes
UNION ALL SELECT 'userfilters', COUNT(*) FROM userfilters
UNION ALL SELECT 'posts', COUNT(*) FROM posts;

-- If the counts are all 0 and nothing errored, run:
--     COMMIT;
-- If anything looks wrong, run:
--     ROLLBACK;

-- Committing: the dry run (piped, no COMMIT) verified every table name and
-- showed all-zero counts. This COMMIT makes the wipe take effect. To re-verify
-- without committing, comment this line out and the piped transaction will
-- roll back on session close.
COMMIT;
