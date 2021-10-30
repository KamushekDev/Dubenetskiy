CREATE OR REPLACE FUNCTION public.EditUserName(
    userId bigint,
    newUsername varchar)
    RETURNS bool
AS
$func$
BEGIN
    perform CheckUser(userId);

    UPDATE users
    set name = newUsername
    where id = userId;

    return true;
END
$func$ LANGUAGE plpgsql;