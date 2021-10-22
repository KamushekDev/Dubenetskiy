CREATE OR REPLACE FUNCTION public.CheckRole(
    roleId bigint) RETURNS void
AS
$func$
declare
BEGIN
    if NOT EXISTS(select 1 from roles p where p.id = roleId and is_deleted = false) then
        raise exception 'Role does not exist';
    end if;
END
$func$ LANGUAGE plpgsql;
