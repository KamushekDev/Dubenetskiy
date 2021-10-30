create or replace function public.EditRunnableProcessName(
    runnableProcessId bigint,
    newRunnableProcessName varchar
)
    returns bool
as
$func$
BEGIN
    perform CheckRunnableProcess(runnableProcessId);
    
    update runnable_processes
    set name=newRunnableProcessName
    where id = runnableProcessId;

    return true;
END
$func$ LANGUAGE plpgsql;