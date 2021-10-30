create or replace function public.EditStepResolutionNextStepId(
    stepResolutionId bigint,
    newNextStepId bigint
)
    returns bool
as
$func$
BEGIN
    perform CheckResolution(stepResolutionId);
    perform CheckStep(newNextStepId);

    if exists(select 1
              from process_step_resolutions
              where current_step_id =
                    (select current_step_id from public.process_step_resolutions where id = stepResolutionId)
                and next_step_id = newNextStepId
                and is_deleted = false
        ) then
        raise exception 'Resolution already exists';
    end if;

    update process_step_resolutions
    set next_step_id=newNextStepId
    where id = stepResolutionId;

    return true;
END
$func$ LANGUAGE plpgsql;