CREATE OR REPLACE FUNCTION public.AssignRole(
    userId bigint,
    roleId bigint)
    returns bigint
AS
$func$
declare
    existing  bigint;
    newRoleId bigint;
BEGIN
    perform CheckUser(userId);
    perform CheckRole(roleId);

    existing = (select id from user_roles where user_id = userId and role_id = roleId and is_deleted = false);
    if existing is not null then
        return existing;
    end if;

    INSERT INTO user_roles (user_id, role_id, assigned_at)
    values (userId, roleId, UtcNow())
    RETURNING id INTO newRoleId;

    return newRoleId;
END
$func$ LANGUAGE plpgsql;