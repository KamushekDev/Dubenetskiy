create or replace function public.EditRunnableProcessStartStepId(
    runnableProcessId bigint,
    newStartStepId bigint
)
    returns bool
as
$func$
BEGIN
    perform CheckRunnableProcess(runnableProcessId);
    perform CheckStep(newStartStepId);

    update runnable_processes
    set start_step_id=newStartStepId
    where id = runnableProcessId;

    return true;
END
$func$ LANGUAGE plpgsql;