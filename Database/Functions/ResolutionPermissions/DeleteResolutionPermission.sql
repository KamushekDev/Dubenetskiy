CREATE OR REPLACE FUNCTION public.DeleteResolutionPermission(
    resolutionPermissionId bigint)
    RETURNS bool
AS
$func$
BEGIN
    perform CheckResolutionPermission(resolutionPermissionId);

    UPDATE public.resolution_permissions
    set is_deleted = true
    where id = resolutionPermissionId;

    return true;
END
$func$ LANGUAGE plpgsql;