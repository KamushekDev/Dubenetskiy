create or replace function public.EditResolutionPermissionsResolutionId(
    resolutionPermissionId bigint,
    newResolutionId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from resolution_permissions where id = resolutionPermissionId) = 0 or
       (select count(*) from process_step_resolutions where id = newResolutionId) = 0 then
        return false;
    end if;
    update resolution_permissions
    set resolution_id=newResolutionId
    where id = resolutionPermissionId;

    return true;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditResolutionPermissionsRoleId(
    resolutionPermissionId bigint,
    newRoleId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from resolution_permissions where id = resolutionPermissionId) = 0 or
       (select count(*) from users where id = newRoleId) = 0 then
        return false;
    end if;
    update resolution_permissions
    set role_id=newRoleId
    where id = resolutionPermissionId;

    return true;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.DeleteResolutionPermission(
    resolutionPermission bigint)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from resolution_permissions where id = resolutionPermission) = 0 then
        return false;
    end if;

    DELETE
    from resolution_permissions
    where id = resolutionPermission;

    return true;
END
$func$ LANGUAGE plpgsql;

