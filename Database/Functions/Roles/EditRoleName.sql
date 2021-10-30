create or replace function public.EditRoleName(
    roleId bigint,
    newRoleName varchar
)
    returns void
as
$func$
BEGIN
    perform CheckRole(roleId);

    update roles
    set name=newRoleName
    where id = roleId;
END
$func$ LANGUAGE plpgsql;