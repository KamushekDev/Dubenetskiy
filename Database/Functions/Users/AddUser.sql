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