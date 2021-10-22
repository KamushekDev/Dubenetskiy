create or replace function public.EditProcessCurrentStepId(
    processId bigint,
    newCurrentStepId bigint
)
    returns bool
as
$func$
BEGIN
    perform CheckProcess(processId);
    perform CheckStep(newCurrentStepId);

    UPDATE processes
    set current_step_id=newCurrentStepId
    where id = processId;

    return true;
END
$func$ LANGUAGE plpgsql;