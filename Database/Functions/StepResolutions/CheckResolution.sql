CREATE OR REPLACE FUNCTION public.CheckResolution(
    resolutionId bigint) RETURNS void
AS
$func$
declare
BEGIN
    if not exists(select 1 from process_step_resolutions u where u.id = resolutionId and is_deleted = false) then
        raise exception 'Resolution does not exist';
    end if;
END
$func$ LANGUAGE plpgsql;