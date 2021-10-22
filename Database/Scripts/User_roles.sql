create or replace function public.EditUserRolesUserId(
    userRolesId bigint,
    newUserId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from user_roles where id = userRolesId) = 0 or
       (select count(*) from users where id = newUserId) = 0 then
        return false;
    end if;
    update user_roles
    set user_id=newUserId
    where id = userRolesId;

    return true;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditUserRolesRoleId(
    userRolesId bigint,
    newRoleId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from user_roles where id = userRolesId) = 0 or
       (select count(*) from roles where id = newRoleId) = 0 then
        return false;
    end if;
    update user_roles
    set role_id=newRoleId
    where id = userRolesId;

    return true;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.DeleteUserRole(
    userRoleId bigint)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from user_roles where id = userRoleId) = 0 then
        return false;
    end if;

    DELETE
    from user_roles
    where id = userRoleId;

    return true;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.AssignRole(
    userId bigint,
    roleId bigint,
    OUT user_role_id int) AS
$func$
declare
    existing bigint;
BEGIN
    existing = (select id from user_roles where user_id = userId and role_id = roleId);
    if existing is not null then
        user_role_id = existing;
        return;
    end if;
    INSERT INTO user_roles (user_id, role_id, assigned_at)
    values (userId, roleId, UtcNow())
    RETURNING id INTO user_role_id;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.RevokeRole(
    userId bigint,
    roleId bigint,
    OUT user_role_id int) AS
$func$
BEGIN
    Delete
    from user_roles
    where user_id = userId
      and role_id = roleId
    RETURNING id INTO user_role_id;
END
$func$ LANGUAGE plpgsql;