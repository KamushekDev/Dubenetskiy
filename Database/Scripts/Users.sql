CREATE OR REPLACE FUNCTION public.AddUser(
    username varchar,
    OUT user_id int) AS
$func$
BEGIN
    INSERT INTO users (name)
    values (username)
    RETURNING id INTO user_id;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.EditUser(
    userId bigint,
    newUsername varchar)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from users where id = userId) = 0 then
        return false;
    end if;

    UPDATE users
    set name = newUsername
    where id = userId;

    return true;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.IsUserSuitable(
    userId bigint,
    requiredRoleId bigint,
    OUT is_suitable bool) AS
$func$
declare
    currentRole record;
BEGIN
    perform checkuser(userId);

    if requiredRoleId is null then
        is_suitable = true;
        return;
    end if;

    for currentRole in select * from user_roles where user_id = userId and is_deleted = false
        loop
            if IsRoleSuitable(currentRole.role_id, requiredRoleId) = true then
                is_suitable = true;
                return;
            end if;
        end loop;
    is_suitable = false;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.CheckUser(
    userId bigint) RETURNS void
AS
$func$
declare
BEGIN
    if (select count(*) from users u where u.id = userId and is_deleted = false) = 0 then
        raise exception 'User does not exist';
    end if;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditUser(
    userId bigint,
    newUserName varchar
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from users where id = userId) = 0 then
        return false;
    end if;
    update users
    set name=newUserName
    where id = userId;

    return true;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.DeleteUser(
    userId bigint, isForce bool)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from users where id = userId) = 0 then
        return false;
    end if;

    if not isForce and
       ((select count(*) from user_roles where user_id=userId)<>0 or
       (select count(*) from process_history where performed_by_user_id=userId)<>0) then
        return false;
    end if;

    if (select count(*) from user_roles where user_id=userId)<>0 then
        update user_roles
        set user_id=null
        where user_id=userId;
    end if;
    if (select count(*) from process_history where performed_by_user_id=userId)<>0 then
        update process_history
        set performed_by_user_id=null
        where performed_by_user_id=userId;
    end if;

    DELETE
    from users
    where id = userId;

    return true;
END
$func$ LANGUAGE plpgsql;

