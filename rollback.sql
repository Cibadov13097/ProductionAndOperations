
BEGIN;

LOCK TABLE public.students   IN ACCESS EXCLUSIVE MODE;
LOCK TABLE public.activities IN ACCESS EXCLUSIVE MODE;


DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='students_backup') THEN
    RAISE EXCEPTION 'students_backup table not found. Cannot rollback safely.';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='activities_backup') THEN
    RAISE EXCEPTION 'activities_backup table not found. Cannot rollback safely.';
  END IF;
END $$;

DROP TABLE public.activities;
DROP TABLE public.students;

ALTER TABLE public.students_backup   RENAME TO students;
ALTER TABLE public.activities_backup RENAME TO activities;

COMMIT;