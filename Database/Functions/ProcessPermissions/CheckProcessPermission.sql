CREATE OR REPLACE FUNCTION public.CheckProcessPermission(
    processPermissionId bigint) RETURNS void
AS
$func$
declare
BEGIN
    if not exists (select 1 from process_permissions p where p.id = processPermissionId and is_deleted = false) then
        raise exception 'Process permission does not exist';
    end if;
END
$func$ LANGUAGE plpgsql;