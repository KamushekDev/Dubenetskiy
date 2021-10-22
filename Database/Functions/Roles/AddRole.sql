CREATE OR REPLACE FUNCTION public.AddRole(
    roleName varchar,
    parentRoleId bigint default null,
    OUT role_id int) AS
$func$
BEGIN
    if parentRoleId is null then
        if EXISTS(select 1
                  from roles
                  where parent_id is null
                    and is_deleted = false) then
            raise exception 'Main role is already exists';
        end if;
    else
        perform CheckRole(parentRoleId);
    end if;

    INSERT INTO roles (name, parent_id)
    values (roleName, parentRoleId)
    RETURNING id INTO role_id;
END
$func$ LANGUAGE plpgsql;