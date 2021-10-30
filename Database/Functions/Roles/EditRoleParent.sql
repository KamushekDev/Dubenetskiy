create or replace function public.EditRoleParent(
    roleId bigint,
    newParentRoleId bigint
)
    returns bool
as
$func$
BEGIN
    perform CheckRole(roleId);
    perform CheckRole(newParentRoleId);

    update roles
    set parent_id=newParentRoleId
    where id = roleId;

    return true;
END
$func$ LANGUAGE plpgsql;