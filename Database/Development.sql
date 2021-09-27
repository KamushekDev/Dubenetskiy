-- Общее

CREATE OR REPLACE FUNCTION public.UtcNow()
    RETURNS timestamp without time zone
AS
$func$
declare
BEGIN
    return timezone('UTC', now());
END
$func$ LANGUAGE plpgsql;

select UtcNow();

select Checkuser(4);

-- Пользователи

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

Select AddUser('VladiSLAVE');

Select *
from users;

-- Роли

CREATE OR REPLACE FUNCTION public.AddRole(
    roleName varchar,
    parentRoleId bigint default null,
    OUT role_id int) AS
$func$
BEGIN
    if parentRoleId is null then
        if (select count(*)
            from roles
            where parent_id is null) > 0 then
            raise exception 'Main role is already exists';
        end if;
    end if;

    INSERT INTO roles (name, parent_id)
    values (roleName, parentRoleId)
    RETURNING id INTO role_id;
END
$func$ LANGUAGE plpgsql;

Select AddRole('Logistic worker');

Select *
from roles;

CREATE OR REPLACE FUNCTION public.IsRoleSuitable(
    roleId bigint,
    requiredRoleId bigint,
    OUT is_suitable bool) AS
$func$
declare
    current bigint = requiredRoleId;
BEGIN
    while current is not null
        loop
            if (current = roleId) then
                is_suitable = true;
                return;
            end if;
            current = (select parent_id from roles where id = current);
        end loop;
    is_suitable = false;
END
$func$ LANGUAGE plpgsql;

select IsRoleSuitable(7, 10);

CREATE OR REPLACE FUNCTION public.IsUserSuitable(
    userId bigint,
    requiredRoleId bigint,
    OUT is_suitable bool) AS
$func$
declare
    currentRole record;
BEGIN
    if requiredRoleId is null then
        is_suitable = true;
        return;
    end if;

    for currentRole in select * from user_roles where user_id = userId
        loop
            if IsRoleSuitable(currentRole.role_id, requiredRoleId) = true then
                is_suitable = true;
                return;
            end if;
        end loop;
    is_suitable = false;
END
$func$ LANGUAGE plpgsql;

select IsUserSuitable(1, 6);

CREATE OR REPLACE FUNCTION public.AssignRole(
    userId bigint,
    roleId bigint,
    OUT user_role_id int) AS
$func$
declare
    existing bigint;
BEGIN
    existing = (select id from user_roles where user_id = userId and role_id = roleId);
    if existing is not null then
        user_role_id = existing;
        return;
    end if;
    INSERT INTO user_roles (user_id, role_id, assigned_at)
    values (userId, roleId, UtcNow())
    RETURNING id INTO user_role_id;
END
$func$ LANGUAGE plpgsql;

Select AssignRole(2, 9);

CREATE OR REPLACE FUNCTION public.RevokeRole(
    userId bigint,
    roleId bigint,
    OUT user_role_id int) AS
$func$
BEGIN
    Delete
    from user_roles
    where user_id = userId
      and role_id = roleId
    RETURNING id INTO user_role_id;
END
$func$ LANGUAGE plpgsql;

Select RevokeRole(1, 6);

select *
from user_roles;

-- Шаги

CREATE OR REPLACE FUNCTION public.AddStep(
    stepName varchar,
    OUT step_id int) AS
$func$
BEGIN
    INSERT INTO process_steps (name)
    values (stepName)
    RETURNING id INTO step_id;
END
$func$ LANGUAGE plpgsql;

select AddStep('Тестовый шаг');

select *
from process_steps;

CREATE OR REPLACE FUNCTION public.LinkSteps(
    currentStepId bigint,
    nextStepId bigint,
    text varchar,
    roleIds bigint[],
    OUT step_resolution_id int) AS
$func$
declare
    existing bigint;
    roleId   bigint;
BEGIN
    existing = (select id
                from process_step_resolutions
                where current_step_id = currentStepId
                  and next_step_id = nextStepId);
    if existing is not null then
        raise exception 'Resolution already exists';
    end if;
    INSERT INTO process_step_resolutions (current_step_id, next_step_id, resolution_text)
    values (currentStepId, nextStepId, text)
    RETURNING id INTO step_resolution_id;

    foreach roleId in array roleIds
        loop
            insert into resolution_permissions (resolution_id, role_id) values (step_resolution_id, roleId);
        end loop;
END
$func$ LANGUAGE plpgsql;

Select LinkSteps(5, 1, 'Тестовая параша 4', array[6]);

select *
from process_step_resolutions;

-- Процессы

CREATE OR REPLACE FUNCTION public.AddProcess(
    processName varchar,
    startStepId bigint,
    OUT process_id int) AS
$func$
BEGIN
    INSERT INTO runnable_processes (name, start_step_id)
    values (processName, startStepId)
    RETURNING id INTO process_id;
END
$func$ LANGUAGE plpgsql;

Select AddProcess('Важный процесс', 1);

select *
from runnable_processes;

CREATE OR REPLACE FUNCTION public.AddProcessPermission(
    processId bigint,
    roleId bigint,
    OUT permission_id int) AS
$func$
BEGIN
    INSERT INTO process_permissions (process_id, role_id)
    values (processId, roleId)
    RETURNING id INTO permission_id;
END
$func$ LANGUAGE plpgsql;

Select AddProcessPermission(1, 7);

select *
from process_permissions;

CREATE OR REPLACE FUNCTION public.StartProcess(
    runnableProcessId bigint,
    userId bigint,
    OUT new_process_id int) AS
$func$
declare
    template     record;
    requiredRole record;
    isSuitable   bool = false;
BEGIN
    select into template * from runnable_processes where id = runnableProcessId;

    for requiredRole in (select * from process_permissions pm where pm.process_id = template.id)
        loop
            select into isSuitable from IsUserSuitable(userId, requiredRole.id);
            if isSuitable = true then
                exit;
            end if;
        end loop;

    if isSuitable = false then
        raise exception 'User has no permission to start that process';
    end if;

    INSERT INTO processes (created_from_process_id, current_step_id)
    values (template.id, template.start_step_id)
    RETURNING id INTO new_process_id;

    insert into process_history (process_id, performed_at, performed_by_user_id, resolution_id)
    values (new_process_id, UtcNow(), userId, null);
END
$func$ LANGUAGE plpgsql;

Select StartProcess(1, 1);

select *
from processes;

CREATE OR REPLACE FUNCTION public.CheckUser(
    userId bigint) RETURNS void
AS
$func$
declare
BEGIN
    if (select count(*) from users u where u.id = userId) = 0 then
        raise exception 'User does not exist';
    end if;
END
$func$ LANGUAGE plpgsql;

select CheckUser(4);

CREATE OR REPLACE FUNCTION public.CheckProcess(
    processId bigint) RETURNS void
AS
$func$
declare
BEGIN
    if (select count(*) from processes p where p.id = processId) = 0 then
        raise exception 'Process does not exist';
    end if;
END
$func$ LANGUAGE plpgsql;

select CheckProcess(2);

CREATE OR REPLACE FUNCTION public.GetResolutions(
    processId bigint,
    userId bigint,
    showAll bool default false)
    returns table
            (
                id           bigint,
                text         varchar,
                next_step_id bigint
            )
AS
$func$
declare
    currentStep bigint;
BEGIN
    perform CheckProcess(processId);
    perform CheckUser(userId);
    select into currentStep current_step_id from processes p where p.id = processId;

    if showAll = true then
        return query select psr.id, resolution_text, psr.next_step_id
                     from process_step_resolutions psr
                     where current_step_id = currentStep;
    else
        return query select psr.id, resolution_text, psr.next_step_id
                     from process_step_resolutions psr
                     where current_step_id = currentStep
                       and (select count(*) from resolution_permissions rp where resolution_id = psr.id and IsUserSuitable(userId, rp.role_id)) > 0;
    end if;
END
$func$ LANGUAGE plpgsql;

Select GetResolutions(2, 1, false);

select *
from processes;

CREATE OR REPLACE FUNCTION public.MoveProcess(
    processId bigint,
    userId bigint,
    resolutionId bigint)
    returns bool
AS
$func$
declare
    resolution record;
    process record;
    requiredRole record;
    isSuitable   bool = false;
BEGIN
    perform CheckProcess(processId);
    perform CheckUser(userId);

    for requiredRole in (select * from resolution_permissions rp where rp.resolution_id = resolutionId)
        loop
            select into isSuitable from IsUserSuitable(userId, requiredRole.id);
            if isSuitable = true then
                exit;
            end if;
        end loop;

    if isSuitable = false then
        raise exception 'User has no permission to perform that resolution';
    end if;

    select into resolution * from process_step_resolutions where id = resolutionId;
    select into process * from processes where id = processId;
    if (process.current_step_id != resolution.current_step_id) then
        raise exception 'Process'' current step does not allow that transition.';
    end if;

    --todo: perform predicate check

    update processes
    set current_step_id = resolution.next_step_id
    where id = processId;

    insert into process_history (process_id, performed_at, performed_by_user_id, resolution_id)
    values (processId, UtcNow(), userId, resolutionId);

    return true;
END
$func$ LANGUAGE plpgsql;

Select MoveProcess(2, 1, 10);

select *
from processes;