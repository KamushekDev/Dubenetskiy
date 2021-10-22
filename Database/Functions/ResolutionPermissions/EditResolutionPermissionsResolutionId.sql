create or replace function public.EditResolutionPermissionsResolutionId(
    resolutionPermissionId bigint,
    newResolutionId bigint
)
    returns bool
as
$func$
BEGIN
    perform CheckResolution(newResolutionId);
    perform CheckResolutionPermission(resolutionPermissionId);

    update resolution_permissions
    set resolution_id=newResolutionId
    where id = resolutionPermissionId;

    return true;
END
$func$ LANGUAGE plpgsql;