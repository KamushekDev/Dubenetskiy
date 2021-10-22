create or replace function public.EditStepResolutionCurrentStepId(
    stepResolutionId bigint,
    newCurrentStepId bigint
)
    returns bool
as
$func$
BEGIN
    perform CheckResolution(stepResolutionId);
    perform CheckStep(newCurrentStepId);

    if exists(select 1
              from process_step_resolutions
              where next_step_id =
                    (select next_step_id from public.process_step_resolutions where id = stepResolutionId)
                and current_step_id = newCurrentStepId
                and is_deleted = false
        ) then
        raise exception 'Resolution already exists';
    end if;

    update process_step_resolutions
    set current_step_id=newCurrentStepId
    where id = stepResolutionId;

    return true;
END
$func$ LANGUAGE plpgsql;