CREATE OR REPLACE FUNCTION public.CheckStep(
    stepId bigint) RETURNS void
AS
$func$
declare
BEGIN
    if not exists (select 1 from process_steps p where p.id = stepId and is_deleted = false) then
        raise exception 'Step does not exist';
    end if;
END
$func$ LANGUAGE plpgsql;