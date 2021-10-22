CREATE OR REPLACE FUNCTION public.CheckProcess(
    processId bigint) RETURNS void
AS
$func$
declare
BEGIN
    if not exists(select 1 from processes p where p.id = processId and is_deleted = false) then
        raise exception 'Process does not exist';
    end if;
END
$func$ LANGUAGE plpgsql;