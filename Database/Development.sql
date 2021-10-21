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

select Checkuser(2);

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

Select AddUser('Test4');

CREATE OR REPLACE FUNCTION public.EditUser(
    userId bigint,
    newUsername varchar)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from users where id = userId) = 0 then
        return false;
    end if;

    UPDATE users
    set name = newUsername
    where id = userId;

    return true;
END
$func$ LANGUAGE plpgsql;

select EditUser(4, 'Test11');
select EditUser(6, 'Vladislave');

select DeleteUser(4);

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

Select AddRole('Test1', 10);

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
    roleIds bigint[] default array []::bigint[],
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

    if cardinality(roleIds) = 0 then
        insert into resolution_permissions (resolution_id, role_id) values (step_resolution_id, null);
    end if;
END
$func$ LANGUAGE plpgsql;

Select LinkSteps(1, 3, 'Тестовая параша 4');

select *
from process_step_resolutions;

select addstep('К тестовому шагу');
select EditStepResolutionCurrentStepId(12, 1);
select editstepresolutionnextstepid(12, 8);
select EditStepResolutionText(12, 'Тестовый текст');
select DeleteStepResolution(11);
-- удалить внешние ключи

-- Процессы

CREATE OR REPLACE FUNCTION public.AddProcess(
    processName varchar,
    startStepId bigint,
    roleIds bigint[] default array []::bigint[],
    OUT process_id int) AS
$func$
declare
    roleId bigint;
BEGIN
    INSERT INTO runnable_processes (name, start_step_id)
    values (processName, startStepId)
    RETURNING id INTO process_id;

    foreach roleId in array roleIds
        loop
            INSERT INTO process_permissions (process_id, role_id) values (process_id, roleId);
        end loop;

    if cardinality(roleIds) = 0 then
        INSERT INTO process_permissions (process_id, role_id) values (process_id, null);
    end if;
END
$func$ LANGUAGE plpgsql;

Select AddProcess('Важный процесс', 1, array [8,10]);

select *
from runnable_processes;

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
                       and (select count(*)
                            from resolution_permissions rp
                            where resolution_id = psr.id
                              and IsUserSuitable(userId, rp.role_id)) > 0;
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
    resolution   record;
    process      record;
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

Select MoveProcess(2, 1, 12);

select *
from processes;

-- VIP
-- roles
create or replace function public.EditRoleName(
    roleId bigint,
    newRoleName varchar
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from roles where id = roleId) = 0 then
        return false;
    end if;
    update roles
    set name=newRoleName
    where id = roleId;

    return true;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditRoleParent(
    roleId bigint,
    newParentRoleId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from roles where id = roleId) = 0 then
        return false;
    end if;
    update roles
    set parent_id=newParentRoleId
    where id = roleId;

    return true;
END
$func$ LANGUAGE plpgsql;

select EditRoleName(11, 'Test2');
select EditRoleParent(11, 8);

CREATE OR REPLACE FUNCTION public.DeleteRole(
    roleId bigint, isForce bool)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from roles where id = roleId) = 0 then
        return false;
    end if;

    if not isForce and
       ((select count(*) from process_permissions where role_id=roleId)>0 or
       (select count(*) from user_roles where role_id=roleId)>0 or
       (select count(*) from resolution_permissions where role_id=roleId)>0 or
       (select count(*) from roles where parent_id=roleId)>0) then
        return false;
    end if;

    if (select count(*) from process_permissions where role_id=roleId)<>0 then
        update process_permissions
        set role_id=null
        where role_id=roleId;
    end if;
    if (select count(*) from user_roles where role_id=roleId)<>0 then
        update user_roles
        set role_id=null
        where role_id=roleId;
    end if;
    if (select count(*) from resolution_permissions where role_id=roleId)<>0 then
        update resolution_permissions
        set role_id=null
        where role_id=roleId;
    end if;
    if (select count(*) from roles where parent_id=roleId)<>0 then
        update roles
        set parent_id=null
        where parent_id=roleId;
    end if;

    DELETE
    from roles
    where id = roleId;

    return true;
END
$func$ LANGUAGE plpgsql;

select DeleteRole(11);

-- process_steps

create or replace function public.EditStep(
    stepId bigint,
    newStepName varchar
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from process_steps where id = stepId) = 0 then
        return false;
    end if;
    update process_steps
    set name=newStepName
    where id = stepId;

    return true;
END
$func$ LANGUAGE plpgsql;

select editstep(7, 'Очень тестовый шаг');

CREATE OR REPLACE FUNCTION public.DeleteStep(
    stepId bigint, isForce bool)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from process_steps where id = stepId) = 0 then
        return false;
    end if;

    if not isForce and
       ((select count(*) from runnable_processes where start_step_id=stepId)>0 or
       (select count(*) from process_step_resolutions where current_step_id=stepId)>0 or
       (select count(*) from process_step_resolutions where next_step_id=stepId)>0 or -- ???
       (select count(*) from processes where current_step_id=stepId)>0) then
        return false;
    end if;

    if (select count(*) from runnable_processes where start_step_id=stepId)<>0 then
        update runnable_processes
        set start_step_id=null
        where start_step_id=stepId;
    end if;
    if (select count(*) from process_step_resolutions where current_step_id=stepId)<>0 then
        update process_step_resolutions
        set current_step_id=null
        where current_step_id=stepId;
    end if;
    if (select count(*) from process_step_resolutions where next_step_id=stepId)<>0 then
        update process_step_resolutions
        set next_step_id=null
        where next_step_id=stepId;
    end if;
    if (select count(*) from processes where current_step_id=stepId)<>0 then
        update processes
        set current_step_id=null
        where current_step_id=stepId;
    end if;

    DELETE
    from process_steps
    where id = stepId;

    return true;
END
$func$ LANGUAGE plpgsql;

select DeleteStep(7);

-- process_step_resolutions

create or replace function public.EditStepResolutionCurrentStepId(
    stepResolutionId bigint,
    newCurrentStepId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from process_step_resolutions where id = stepResolutionId) = 0 or
       (select count(*) from process_steps where id = newCurrentStepId) = 0 then
        return false;
    end if;
    update process_step_resolutions
    set current_step_id=newCurrentStepId
    where id = stepResolutionId;

    return true;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditStepResolutionNextStepId(
    stepResolutionId bigint,
    newNextStepId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from process_step_resolutions where id = stepResolutionId) = 0 or
       (select count(*) from process_steps where id = newNextStepId) = 0 then
        return false;
    end if;
    update process_step_resolutions
    set next_step_id=newNextStepId
    where id = stepResolutionId;

    return true;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditStepResolutionText( -- или EditStepResolutionResolutionText?
    stepResolutionId bigint,
    newResolutionText varchar
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from process_step_resolutions where id = stepResolutionId) = 0 then
        return false;
    end if;
    update process_step_resolutions
    set resolution_text=newResolutionText
    where id = stepResolutionId;

    return true;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.DeleteProcessStepResolution(
    processStepResolutionId bigint, isForce bool)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from process_step_resolutions where id = processStepResolutionId) = 0 then
        return false;
    end if;

    if not isForce and
       ((select count(*) from resolution_permissions where resolution_id=processStepResolutionId)>0 or
       (select count(*) from process_history where resolution_id=processStepResolutionId)>0) then
        return false;
    end if;

    if (select count(*) from resolution_permissions where resolution_id=processStepResolutionId)<>0 then
        update resolution_permissions
        set resolution_id=null
        where resolution_id=processStepResolutionId;
    end if;
    if (select count(*) from process_history where resolution_id=processStepResolutionId)<>0 then
        update process_history
        set resolution_id=null
        where resolution_id=processStepResolutionId;
    end if;

    DELETE
    from process_step_resolutions
    where id = processStepResolutionId;

    return true;
END
$func$ LANGUAGE plpgsql;

-- processes

create or replace function public.EditProcessCreatedFromProcessId(
    processId bigint,
    newCreatedFromProcessId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from processes where id = processId) = 0 or
       (select count(*) from runnable_processes where id = newCreatedFromProcessId) = 0 then
        return false;
    end if;
    update processes
    set created_from_process_id=newCreatedFromProcessId
    where id = processId;

    return true;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditProcessCurrentStepId(
    processId bigint,
    newCurrentStepId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from processes where id = processId) = 0 or
       (select count(*) from process_steps where id = newCurrentStepId) = 0 then
        return false;
    end if;
    update processes
    set current_step_id=newCurrentStepId
    where id = processId;

    return true;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.DeleteProcess(
    processId bigint, isForce bool)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from processes where id = processId) = 0 then
        return false;
    end if;

    if not isForce and
       (select count(*) from process_history where process_id=processId)>0 then
        return false;
    end if;

    if (select count(*) from process_history where process_id=processId)<>0 then
        update process_history
        set process_id=null
        where process_id=processId;
    end if;

    DELETE
    from processes
    where id = processId;

    return true;
END
$func$ LANGUAGE plpgsql;

-- runnable_processes

create or replace function public.EditRunnableProcessName(
    runnableProcessId bigint,
    newRunnableProcessName varchar
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from runnable_processes where id = runnableProcessId) = 0 then
        return false;
    end if;
    update runnable_processes
    set name=newRunnableProcessName
    where id = runnableProcessId;

    return true;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditRunnableProcessStartStepId(
    runnableProcessId bigint,
    newStartStepId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from runnable_processes where id = runnableProcessId) = 0 or
       (select count(*) from process_steps where id = newStartStepId) = 0 then
        return false;
    end if;
    update runnable_processes
    set start_step_id=newStartStepId
    where id = runnableProcessId;

    return true;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.DeleteRunnableProcess(
    runnableProcessId bigint, isForce bool)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from runnable_processes where id = runnableProcessId) = 0 then
        return false;
    end if;

    if not isForce and
       ((select count(*) from processes where created_from_process_id=runnableProcessId)>0 or
       (select count(*) from process_permissions where process_id=runnableProcessId)>0) then
        return false;
    end if;

    if (select count(*) from processes where created_from_process_id=runnableProcessId)<>0 then
        update processes
        set created_from_process_id=null
        where created_from_process_id=runnableProcessId;
    end if;
    if (select count(*) from process_permissions where process_id=runnableProcessId)<>0 then
        update process_permissions
        set process_id=null
        where process_id=runnableProcessId;
    end if;

    DELETE
    from runnable_processes
    where id = runnableProcessId;

    return true;
END
$func$ LANGUAGE plpgsql;

-- users

create or replace function public.EditUser(
    userId bigint,
    newUserName varchar
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from users where id = userId) = 0 then
        return false;
    end if;
    update users
    set name=newUserName
    where id = userId;

    return true;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.DeleteUser(
    userId bigint, isForce bool)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from users where id = userId) = 0 then
        return false;
    end if;

    if not isForce and
       ((select count(*) from user_roles where user_id=userId)<>0 or
       (select count(*) from process_history where performed_by_user_id=userId)<>0) then
        return false;
    end if;

    if (select count(*) from user_roles where user_id=userId)<>0 then
        update user_roles
        set user_id=null
        where user_id=userId;
    end if;
    if (select count(*) from process_history where performed_by_user_id=userId)<>0 then
        update process_history
        set performed_by_user_id=null
        where performed_by_user_id=userId;
    end if;

    DELETE
    from users
    where id = userId;

    return true;
END
$func$ LANGUAGE plpgsql;

-- process_history

create or replace function public.EditProcessHistoryPerfomedAt(
    processHistoryId bigint,
    newPerfomedAt timestamp
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from process_history where id = processHistoryId) = 0 then
        return false;
    end if;
    update process_history
    set performed_at=newPerfomedAt
    where id = processHistoryId;

    return true;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditProcessHistoryProcessId(
    processHistoryId bigint,
    newProcessId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from process_history where id = processHistoryId) = 0 or
       (select count(*) from processes where id = newProcessId) = 0 then
        return false;
    end if;
    update process_history
    set process_id=newProcessId
    where id = processHistoryId;

    return true;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditProcessHistoryPerfomedByUserId(
    processHistoryId bigint,
    newPerfomedByUserId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from process_history where id = processHistoryId) = 0 or
       (select count(*) from users where id = newPerfomedByUserId) = 0 then
        return false;
    end if;
    update process_history
    set performed_by_user_id=newPerfomedByUserId
    where id = processHistoryId;

    return true;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditProcessHistoryResolutionId(
    processHistoryId bigint,
    newResolutionId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from process_history where id = processHistoryId) = 0 or
       (select count(*) from process_step_resolutions where id = newResolutionId) = 0 then
        return false;
    end if;
    update process_history
    set resolution_id=newResolutionId
    where id = processHistoryId;

    return true;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.DeleteProcessHistory(
    processHistoryId bigint)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from process_history where id = processHistoryId) = 0 then
        return false;
    end if;

    DELETE
    from process_history
    where id = processHistoryId;

    return true;
END
$func$ LANGUAGE plpgsql;

-- resolution_permissions

create or replace function public.EditResolutionPermissionsResolutionId(
    resolutionPermissionId bigint,
    newResolutionId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from resolution_permissions where id = resolutionPermissionId) = 0 or
       (select count(*) from process_step_resolutions where id = newResolutionId) = 0 then
        return false;
    end if;
    update resolution_permissions
    set resolution_id=newResolutionId
    where id = resolutionPermissionId;

    return true;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditResolutionPermissionsRoleId(
    resolutionPermissionId bigint,
    newRoleId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from resolution_permissions where id = resolutionPermissionId) = 0 or
       (select count(*) from users where id = newRoleId) = 0 then
        return false;
    end if;
    update resolution_permissions
    set role_id=newRoleId
    where id = resolutionPermissionId;

    return true;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.DeleteResolutionPermission(
    resolutionPermission bigint)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from resolution_permissions where id = resolutionPermission) = 0 then
        return false;
    end if;

    DELETE
    from resolution_permissions
    where id = resolutionPermission;

    return true;
END
$func$ LANGUAGE plpgsql;

-- user_roles

create or replace function public.EditUserRolesUserId(
    userRolesId bigint,
    newUserId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from user_roles where id = userRolesId) = 0 or
       (select count(*) from users where id = newUserId) = 0 then
        return false;
    end if;
    update user_roles
    set user_id=newUserId
    where id = userRolesId;

    return true;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditUserRolesRoleId(
    userRolesId bigint,
    newRoleId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from user_roles where id = userRolesId) = 0 or
       (select count(*) from roles where id = newRoleId) = 0 then
        return false;
    end if;
    update user_roles
    set role_id=newRoleId
    where id = userRolesId;

    return true;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.DeleteUserRole(
    userRoleId bigint)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from user_roles where id = userRoleId) = 0 then
        return false;
    end if;

    DELETE
    from user_roles
    where id = userRoleId;

    return true;
END
$func$ LANGUAGE plpgsql;

-- process_permissions

create or replace function public.EditProcessPermissionsProcessId(
    processPermissionId bigint,
    newProcessId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from process_permissions where id = processPermissionId) = 0 or
       (select count(*) from runnable_processes where id = newProcessId) = 0 then
        return false;
    end if;
    update process_permissions
    set process_id=newProcessId
    where id = processPermissionId;

    return true;
END
$func$ LANGUAGE plpgsql;

create or replace function public.EditProcessPermissionsRoleId(
    processPermissionId bigint,
    newRoleId bigint
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from process_permissions where id = processPermissionId) = 0 or
       (select count(*) from roles where id = newRoleId) = 0 then
        return false;
    end if;
    update process_permissions
    set role_id=newRoleId
    where id = processPermissionId;

    return true;
END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.DeleteProcessPermission(
    processPermissionId bigint, isForce bool)
    RETURNS bool
AS
$func$
BEGIN
    if (select count(*) from process_permissions where id = processPermissionId) = 0 then
        return false;
    end if;

    DELETE
    from process_permissions
    where id = processPermissionId;

    return true;
END
$func$ LANGUAGE plpgsql;

-- product_classes

create or replace function public.EditProductClassesName(
    productClassId bigint,
    newName varchar
)
    returns bool
as
$func$
BEGIN
    if (select count(*) from product_classes where id = productClassId) = 0 then
        return false;
    end if;
    update product_classes
    set name=newName
    where id = productClassId;

    return true;
END
$func$ LANGUAGE plpgsql;

-- units

-- products

-- parameters

-- product_parameters
