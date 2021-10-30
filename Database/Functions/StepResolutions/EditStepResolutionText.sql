create or replace function public.EditStepResolutionText(
    stepResolutionId bigint,
    newResolutionText varchar
)
    returns bool
as
$func$
BEGIN
    perform CheckResolution(stepResolutionId);

    update process_step_resolutions
    set resolution_text=newResolutionText
    where id = stepResolutionId;

    return true;
END
$func$ LANGUAGE plpgsql;