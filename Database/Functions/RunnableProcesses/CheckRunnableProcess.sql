CREATE OR REPLACE FUNCTION public.CheckRunnableProcess(
    processId bigint) RETURNS void
AS
$func$
declare
BEGIN
    if not exists(select 1 from runnable_processes p where p.id = processId and is_deleted = false) then
        raise exception 'Runnable process does not exist';
    end if;
END
$func$ LANGUAGE plpgsql;