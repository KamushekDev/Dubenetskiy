CREATE OR REPLACE FUNCTION public.DeleteUser(
    userId bigint, isForce bool default false)
    RETURNS bool
AS
$func$
declare
    tempId bigint;
BEGIN
    perform CheckUser(userId);

    if not isForce and (
            exists(select 1 from user_roles where user_id = userId)
        ) then
        return false;
    end if;

    for tempId in (select id
                   from user_roles
                   where user_id = userId
                     and is_deleted = false)
        loop
            perform DeleteRole(tempId, true);
        end loop;

    UPDATE users
    set is_deleted = true
    where id = userId;

    return true;
END
$func$ LANGUAGE plpgsql;