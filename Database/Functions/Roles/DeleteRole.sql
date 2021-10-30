CREATE OR REPLACE FUNCTION public.DeleteRole(
    roleId bigint, isForce bool default false)
    RETURNS bool
AS
$func$
BEGIN
    perform CheckRole(roleId);

    if not isForce and
       (EXISTS(select 1 from process_permissions where role_id = roleId) or
        EXISTS(select 1 from user_roles where role_id = roleId) or
        EXISTS(select 1 from resolution_permissions where role_id = roleId) or
        EXISTS(select 1 from roles where parent_id = roleId)
           ) then
        return false;
    end if;

    UPDATE process_permissions
    set is_deleted = true
    where role_id = roleId;

    UPDATE user_roles
    set is_deleted = true
    where role_id = roleId;

    UPDATE resolution_permissions
    set is_deleted = true
    where role_id = roleId;

    UPDATE roles
    set is_deleted = true
    where id = roleId;

    return true;
END
$func$ LANGUAGE plpgsql;