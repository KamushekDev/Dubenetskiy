CREATE OR REPLACE FUNCTION public.AddRole(
    roleName varchar,
    parentRoleId bigint default null,
    OUT role_id int) AS
$func$
BEGIN
    if parentRoleId is null then
        if (select count(*)
            from roles
            where parent_id is null) > 0 then
            raise exception 'Main role is already exists';
        end if;
    end if;

    INSERT INTO roles (name, parent_id)
    values (roleName, parentRoleId)
    RETURNING id INTO role_id;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.IsRoleSuitable(
    roleId bigint,
    requiredRoleId bigint,
    OUT is_suitable bool) AS
$func$
declare
    current bigint = requiredRoleId;
BEGIN
    while current is not null
        loop
            if (current = roleId) then
                is_suitable = true;
                return;
            end if;
            current = (select parent_id from roles where id = current and is_deleted = false);
        end loop;
    is_suitable = false;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditRoleName(
    roleId bigint,
    newRoleName varchar
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from roles where id = roleId) = 0 then
        return false;
    end if;
    update roles
    set name=newRoleName
    where id = roleId;

    return true;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditRoleParent(
    roleId bigint,
    newParentRoleId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from roles where id = roleId) = 0 then
        return false;
    end if;
    update roles
    set parent_id=newParentRoleId
    where id = roleId;

    return true;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.DeleteRole(
    roleId bigint, isForce bool)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from roles where id = roleId) = 0 then
        return false;
    end if;

    if not isForce and
       ((select count(*) from process_permissions where role_id=roleId)>0 or
       (select count(*) from user_roles where role_id=roleId)>0 or
       (select count(*) from resolution_permissions where role_id=roleId)>0 or
       (select count(*) from roles where parent_id=roleId)>0) then
        return false;
    end if;

    if (select count(*) from process_permissions where role_id=roleId)<>0 then
        update process_permissions
        set role_id=null
        where role_id=roleId;
    end if;
    if (select count(*) from user_roles where role_id=roleId)<>0 then
        update user_roles
        set role_id=null
        where role_id=roleId;
    end if;
    if (select count(*) from resolution_permissions where role_id=roleId)<>0 then
        update resolution_permissions
        set role_id=null
        where role_id=roleId;
    end if;
    if (select count(*) from roles where parent_id=roleId)<>0 then
        update roles
        set parent_id=null
        where parent_id=roleId;
    end if;

    DELETE
    from roles
    where id = roleId;

    return true;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.CheckRole(
    roleId bigint) RETURNS void
AS
$func$
declare
BEGIN
    if (select count(*) from roles p where p.id = roleId and is_deleted = false) = 0 then
        raise exception 'Role does not exist';
    end if;
END
$func$ LANGUAGE plpgsql;
