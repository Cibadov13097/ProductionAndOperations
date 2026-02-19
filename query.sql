BEGIN;

--1

ALTER TABLE students
RENAME COLUMN id TO student_id;



--2

ALTER TABLE students
ALTER COLUMN firstname TYPE VARCHAR(40);

ALTER TABLE students
ALTER COLUMN lastname TYPE VARCHAR(40);


--3

CREATE TABLE activities_new (
    student_id INTEGER PRIMARY KEY,
    activities TEXT[],
    levels TEXT[]
);


WITH cleaned AS (
    SELECT
        student_id,
        TRIM(activity) AS activity,
        TRIM(level) AS level
    FROM activities
    WHERE activity IS NOT NULL
      AND level IS NOT NULL
      AND activity <> ''
      AND level <> ''
),
distinct_pairs AS (
    SELECT DISTINCT student_id, activity, level
    FROM cleaned
),
aggregated AS (
    SELECT
        student_id,
        ARRAY_AGG(activity ORDER BY activity, level) AS activities_arr,
        ARRAY_AGG(level ORDER BY activity, level) AS levels_arr
    FROM distinct_pairs
    GROUP BY student_id
)

INSERT INTO activities_new
SELECT
    s.student_id,
    COALESCE(a.activities_arr, '{}'::text[]),
    COALESCE(a.levels_arr, '{}'::text[])
FROM students s
LEFT JOIN aggregated a
ON s.student_id = a.student_id;



DROP TABLE activities;

ALTER TABLE activities_new
RENAME TO activities;


COMMIT;
