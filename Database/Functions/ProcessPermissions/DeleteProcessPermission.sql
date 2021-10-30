CREATE OR REPLACE FUNCTION public.DeleteProcessPermission(
    processPermissionId bigint)
    RETURNS bool
AS
$func$
BEGIN
    perform CheckProcessPermission(processPermissionId);

    UPDATE process_permissions
    set is_deleted = true
    where id = processPermissionId;

    return true;
END
$func$ LANGUAGE plpgsql;