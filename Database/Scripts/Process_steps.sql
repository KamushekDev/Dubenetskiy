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
                  and next_step_id = nextStepId
                  and is_deleted = false);
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

CREATE OR REPLACE FUNCTION public.CheckStep(
    stepId bigint) RETURNS void
AS
$func$
declare
BEGIN
    if (select count(*) from process_steps p where p.id = stepId and is_deleted = false) = 0 then
        raise exception 'Step does not exist';
    end if;
END
$func$ LANGUAGE plpgsql;