CREATE OR REPLACE FUNCTION public.GetFilteredRoles(
    roleIds bigint[] default array []::bigint[])
    returns table
            (
                filtered_role_id bigint
            )
AS
$func$
BEGIN
    return query select id as filtered_role_id from roles where id = ANY (roleIds) and is_deleted = false;
END
$func$ LANGUAGE plpgsql;
