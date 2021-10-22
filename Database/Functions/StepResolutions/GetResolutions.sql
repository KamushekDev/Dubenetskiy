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
                     where current_step_id = currentStep
                       and psr.is_deleted = false;
    else
        return query select psr.id, resolution_text, psr.next_step_id
                     from process_step_resolutions psr
                     where current_step_id = currentStep
                       and psr.is_deleted = false
                       and exists(select 1
                                  from resolution_permissions rp
                                  where resolution_id = psr.id
                                    and rp.is_deleted = false
                                    and IsUserSuitable(userId, rp.role_id));
    end if;
END
$func$ LANGUAGE plpgsql;