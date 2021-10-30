create or replace function public.EditProcessPermissionsRoleId(
    processPermissionId bigint,
    newRoleId bigint
)
    returns bool
as
$func$
BEGIN
    perform CheckRole(newRoleId);
    perform CheckProcessPermission(processPermissionId);

    update process_permissions
    set role_id=newRoleId
    where id = processPermissionId;

    return true;
END
$func$ LANGUAGE plpgsql;