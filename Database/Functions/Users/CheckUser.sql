CREATE OR REPLACE FUNCTION public.CheckUser(
    userId bigint) RETURNS void
AS
$func$
declare
BEGIN
    if not exists(select 1 from users u where u.id = userId and is_deleted = false) then
        raise exception 'User does not exist';
    end if;
END
$func$ LANGUAGE plpgsql;