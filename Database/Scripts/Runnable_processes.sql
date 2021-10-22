CREATE OR REPLACE FUNCTION public.AddProcess(
    processName varchar,
    startStepId bigint,
    roleIds bigint[] default array []::bigint[],
    OUT process_id int) AS
$func$
declare
    roleId bigint;
BEGIN
    perform checkstep(startStepId);

    INSERT INTO runnable_processes (name, start_step_id)
    values (processName, startStepId)
    RETURNING id INTO process_id;

    foreach roleId in array roleIds
        loop
            perform checkrole(roleId);
            INSERT INTO process_permissions (process_id, role_id) values (process_id, roleId);
        end loop;

    if cardinality(roleIds) = 0 then
        INSERT INTO process_permissions (process_id, role_id) values (process_id, null);
    end if;
END
$func$ LANGUAGE plpgsql;

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
    perform checkrunnableprocess(runnableProcessId);
    perform checkuser(userId);

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

CREATE OR REPLACE FUNCTION public.CheckRunnableProcess(
    processId bigint) RETURNS void
AS
$func$
declare
BEGIN
    if (select count(*) from runnable_processes p where p.id = processId and is_deleted = false) = 0 then
        raise exception 'Runnable process does not exist';
    end if;
END
$func$ LANGUAGE plpgsql;