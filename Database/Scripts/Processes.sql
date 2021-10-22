CREATE OR REPLACE FUNCTION public.CheckProcess(
    processId bigint) RETURNS void
AS
$func$
declare
BEGIN
    if (select count(*) from processes p where p.id = processId and is_deleted = false) = 0 then
        raise exception 'Process does not exist';
    end if;
END
$func$ LANGUAGE plpgsql;

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