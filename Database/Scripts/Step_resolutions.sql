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

create or replace function public.EditStepResolutionText(
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

