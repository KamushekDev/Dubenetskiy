create or replace function public.EditResolutionPermissionsRoleId(
    resolutionPermissionId bigint,
    newRoleId bigint
)
    returns bool
as
$func$
BEGIN
    perform CheckResolutionPermission(resolutionPermissionId);
    perform CheckRole(newRoleId);
    
    update resolution_permissions
    set role_id=newRoleId
    where id = resolutionPermissionId;

    return true;
END
$func$ LANGUAGE plpgsql;