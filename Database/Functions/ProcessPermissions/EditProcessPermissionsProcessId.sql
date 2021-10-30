create or replace function public.EditProcessPermissionsProcessId(
    processPermissionId bigint,
    newProcessId bigint
)
    returns bool
as
$func$
BEGIN
    perform CheckProcessPermission(processPermissionId);
    perform CheckRunnableProcess(newProcessId);

    update process_permissions
    set process_id=newProcessId
    where id = processPermissionId;

    return true;
END
$func$ LANGUAGE plpgsql;