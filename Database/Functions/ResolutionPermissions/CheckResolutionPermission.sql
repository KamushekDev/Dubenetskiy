CREATE OR REPLACE FUNCTION public.CheckResolutionPermission(
    resolutionPermissionId bigint) RETURNS void
AS
$func$
declare
BEGIN
    if not exists(select 1
                  from resolution_permissions rp
                  where rp.id = resolutionPermissionId and is_deleted = false) then
        raise exception 'Resolution permission does not exist';
    end if;
END
$func$ LANGUAGE plpgsql;
