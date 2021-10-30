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
    perform CheckResolution(resolutionId);

    for requiredRole in (select * from resolution_permissions rp where rp.resolution_id = resolutionId and is_deleted = false)
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