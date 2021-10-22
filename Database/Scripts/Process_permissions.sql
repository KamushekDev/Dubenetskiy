create or replace function public.EditProcessPermissionsProcessId(
    processPermissionId bigint,
    newProcessId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from process_permissions where id = processPermissionId) = 0 or
       (select count(*) from runnable_processes where id = newProcessId) = 0 then
        return false;
    end if;
    update process_permissions
    set process_id=newProcessId
    where id = processPermissionId;

    return true;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditProcessPermissionsRoleId(
    processPermissionId bigint,
    newRoleId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from process_permissions where id = processPermissionId) = 0 or
       (select count(*) from roles where id = newRoleId) = 0 then
        return false;
    end if;
    update process_permissions
    set role_id=newRoleId
    where id = processPermissionId;

    return true;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.DeleteProcessPermission(
    processPermissionId bigint, isForce bool)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from process_permissions where id = processPermissionId) = 0 then
        return false;
    end if;

    DELETE
    from process_permissions
    where id = processPermissionId;

    return true;
END
$func$ LANGUAGE plpgsql;