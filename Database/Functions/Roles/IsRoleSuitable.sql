CREATE OR REPLACE FUNCTION public.IsRoleSuitable(
    roleId bigint,
    requiredRoleId bigint)
    RETURNS bool
AS
$func$
declare
    current bigint = requiredRoleId;
BEGIN
    perform CheckRole(roleId);

    if (requiredRoleId is null) then
        return true;
    end if;

    perform CheckRole(requiredRoleId);

    while current is not null
        loop
            if (current = roleId) then
                return true;
            end if;
            current = (select parent_id from roles where id = current and is_deleted = false);
        end loop;
    return false;
END
$func$ LANGUAGE plpgsql;