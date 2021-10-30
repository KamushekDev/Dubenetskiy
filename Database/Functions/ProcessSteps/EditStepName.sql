create or replace function public.EditStepName(
    stepId bigint,
    newStepName varchar
)
    returns bool
as
$func$
BEGIN
    perform CheckStep(stepId);
    
    update process_steps
    set name=newStepName
    where id = stepId;

    return true;
END
$func$ LANGUAGE plpgsql;