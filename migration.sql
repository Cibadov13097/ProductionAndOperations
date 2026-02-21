BEGIN;
LOCK TABLE public.students   IN ACCESS EXCLUSIVE MODE;
LOCK TABLE public.activities IN ACCESS EXCLUSIVE MODE;


DROP TABLE IF EXISTS public.students_backup;
DROP TABLE IF EXISTS public.activities_backup;

CREATE TABLE public.students_backup (LIKE public.students INCLUDING ALL);
INSERT INTO public.students_backup SELECT * FROM public.students;

CREATE TABLE public.activities_backup (LIKE public.activities INCLUDING ALL);
INSERT INTO public.activities_backup SELECT * FROM public.activities;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema='public' AND table_name='students' AND column_name='id'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema='public' AND table_name='students' AND column_name='student_id'
  )
  THEN
    ALTER TABLE public.students RENAME COLUMN id TO student_id;
  END IF;
END $$;

DO $$
DECLARE
  fn_type text;
  ln_type text;
BEGIN
  SELECT data_type INTO fn_type
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='students' AND column_name='firstname';

  SELECT data_type INTO ln_type
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='students' AND column_name='lastname';

  IF fn_type IN ('character varying', 'character') THEN
    ALTER TABLE public.students
      ALTER COLUMN firstname TYPE varchar(40);
  END IF;

  IF ln_type IN ('character varying', 'character') THEN
    ALTER TABLE public.students
      ALTER COLUMN lastname TYPE varchar(40);
  END IF;
END $$;

DROP TABLE IF EXISTS public.activities_new;

CREATE TABLE public.activities_new (
  student_id INTEGER PRIMARY KEY,
  activities TEXT[] NOT NULL DEFAULT '{}'::text[],
  levels     TEXT[] NOT NULL DEFAULT '{}'::text[]
);

WITH cleaned AS (
  SELECT
    a.student_id,
    NULLIF(BTRIM(a.activity), '') AS activity_clean,
    NULLIF(BTRIM(a.level), '')    AS level_clean
  FROM public.activities a
),
distinct_pairs AS (
  SELECT DISTINCT
    student_id,
    activity_clean AS activity,
    level_clean    AS level
  FROM cleaned
  WHERE activity_clean IS NOT NULL
    AND level_clean IS NOT NULL
),
agg AS (
  SELECT
    student_id,
    ARRAY_AGG(activity ORDER BY activity, level) AS activities_arr,
    ARRAY_AGG(level    ORDER BY activity, level) AS levels_arr
  FROM distinct_pairs
  GROUP BY student_id
)
INSERT INTO public.activities_new (student_id, activities, levels)
SELECT
  s.student_id,
  COALESCE(a.activities_arr, '{}'::text[]),
  COALESCE(a.levels_arr,     '{}'::text[])
FROM public.students s
LEFT JOIN agg a ON a.student_id = s.student_id;


DROP TABLE public.activities;
ALTER TABLE public.activities_new RENAME TO activities;

COMMIT;