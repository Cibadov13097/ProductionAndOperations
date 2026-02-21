# Assignment 1 — Database Migration

**Production and Operations Management**

Run all scripts in **pgAdmin** using **Query Tool**: connect to your database → **Query Tool** → **File** → **Open** → select the `.sql` file → **Execute/Run** (F5).

---

## Run order

| Step | Script | When |
|------|--------|------|
| 1 | `/sql initiate.sql` | Run **first** if the database has no `students` and `activities` tables/data. |
| 2 | `/migration.sql` | Run **once** after tables and data exist. |
| 3 | `/rollback.sql` | **Optional:** run only to undo the migration (backup tables must still exist). |

**Summary:** If the DB is empty or missing the tables → run **sql initiate.sql**, then **migration.sql**. If the DB already has the original tables → run only **migration.sql**. To revert → **rollback.sql**.

---

## What each script does

### `sql initiate.sql`

- **Drops** `activities` and `students` if they exist (so the script is safe to re-run).
- **Creates** `students` with columns: `id` (INTEGER PRIMARY KEY), `firstname` (VARCHAR(20)), `lastname` (VARCHAR(20)).
- **Creates** `activities` with columns: `student_id` (INTEGER), `activity` (VARCHAR(25)), `level` (VARCHAR(10)).
- **Inserts** three sample students (James Reyes, Tiffany Wolf, David Palmer) and multiple activity rows (Tennis, Literature, Football, Music, Chess, Chemistry with various levels). Some rows are intentional duplicates (e.g. Tennis/Advanced twice for student 1) to match the assignment sample data.

Use this script when the database does not yet have these tables or you want a clean setup with sample data.

---

### `migration.sql`

The script runs inside **one transaction** (`BEGIN` … `COMMIT`). If any step fails, everything is rolled back and no changes are applied.

1. **Lock tables**  
   `LOCK TABLE students IN ACCESS EXCLUSIVE MODE` (and same for `activities`). No other session can read or write these tables until the transaction ends, so the migration sees a consistent snapshot.

2. **Create backups**  
   Drops `students_backup` and `activities_backup` if they exist (e.g. from a previous run). Creates new backup tables with `LIKE … INCLUDING ALL` and copies all current rows from `students` and `activities`. These backups are used by the rollback script.

3. **Rename column in `students`**  
   A PL/pgSQL block checks `information_schema`: if column `id` exists and `student_id` does not, it runs `ALTER TABLE students RENAME COLUMN id TO student_id`. This avoids errors if the column was already renamed.

4. **Extend name columns in `students`**  
   Another PL/pgSQL block reads the data type of `firstname` and `lastname`. If they are character types (e.g. varchar), it runs `ALTER COLUMN … TYPE varchar(40)` so the max length goes from 20 to 40.

5. **Build new `activities` structure**  
   - Creates a temporary table `activities_new` with columns: `student_id` (PRIMARY KEY), `activities` (TEXT[]), `levels` (TEXT[]), both defaulting to empty arrays.  
   - A CTE **cleaned** trims and normalizes the old data: `NULLIF(BTRIM(activity), '')` and same for `level`, so NULL and blank strings are treated as NULL.  
   - A CTE **distinct_pairs** does `SELECT DISTINCT student_id, activity_clean, level_clean FROM cleaned WHERE activity_clean IS NOT NULL AND level_clean IS NOT NULL`, so duplicate (activity, level) pairs per student are removed and invalid rows are dropped.  
   - A CTE **agg** groups by `student_id` and uses `ARRAY_AGG(activity ORDER BY activity, level)` and `ARRAY_AGG(level ORDER BY activity, level)` so each student gets one row with matching arrays.  
   - The final `INSERT INTO activities_new` joins `students` with `agg` (LEFT JOIN) so every student gets a row; students with no valid activities get `COALESCE(…, '{}')` i.e. empty arrays.  
   - Then the old `activities` table is dropped and `activities_new` is renamed to `activities`.

After a successful run you have: `students` (with `student_id`, longer names), `activities` (one row per student, array columns), plus `students_backup` and `activities_backup`.

---

### `rollback.sql`

The script runs inside **one transaction** (`BEGIN` … `COMMIT`).

1. **Lock tables**  
   Same as migration: `LOCK TABLE students / activities IN ACCESS EXCLUSIVE MODE`.

2. **Check backups exist**  
   PL/pgSQL checks that `students_backup` and `activities_backup` exist in `information_schema.tables`. If either is missing, it raises an exception (e.g. "students_backup table not found. Cannot rollback safely.") and the transaction rolls back—no tables are dropped.

3. **Restore original tables**  
   Drops the current `students` and `activities` (the migrated versions). Then renames `students_backup` → `students` and `activities_backup` → `activities`. After commit, table names, column names, column types, and all row data match the pre-migration state (e.g. `students` has `id` again, `activities` is row-based with `activity` and `level` columns).

---

## Requirements

- PostgreSQL (e.g. 12+), pgAdmin.
