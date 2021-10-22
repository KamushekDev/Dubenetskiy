CREATE OR REPLACE FUNCTION public.IsUserSuitable(
    userId bigint,
    requiredRoleId bigint)
    returns bool
AS
$func$
declare
    currentRole record;
BEGIN
    perform checkuser(userId);

    if requiredRoleId is null then
        return true;
    end if;

    for currentRole in select * from user_roles where user_id = userId and is_deleted = false
        loop
            if IsRoleSuitable(currentRole.role_id, requiredRoleId) = true then
                return true;
            end if;
        end loop;
    return false;
END
$func$ LANGUAGE plpgsql;