CREATE OR REPLACE FUNCTION public.DeleteRunnableProcess(
    runnableProcessId bigint, isForce bool default false)
    RETURNS bool
AS
$func$
declare
    tempId bigint;
BEGIN
    perform CheckRunnableProcess(runnableProcessId);

    if not isForce and (
            exists(select 1 from processes where created_from_process_id = runnableProcessId) or
            exists(select 1 from process_permissions where process_id = runnableProcessId)
        ) then
        raise exception 'Runnable process has dependencies';
    end if;

    for tempId in (select id
                   from processes
                   where created_from_process_id = runnableProcessId
                     and is_deleted = false)
        loop
            perform DeleteProcess(tempId);
        end loop;

    for tempId in (select id
                   from process_permissions
                   where process_id = runnableProcessId
                     and is_deleted = false)
        loop
            perform DeleteProcessPermission(tempId);
        end loop;

    UPDATE runnable_processes
    set is_deleted = true
    where id = runnableProcessId;

    return true;
END
$func$ LANGUAGE plpgsql;