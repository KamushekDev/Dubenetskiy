CREATE OR REPLACE FUNCTION public.RevokeRole(
    userId bigint,
    roleId bigint)
    returns void
AS
$func$
BEGIN
    perform CheckUser(userId);
    perform CheckRole(roleId);

    update user_roles
    set is_deleted = true
    where user_id = userId
      and role_id = roleId;
END
$func$ LANGUAGE plpgsql;