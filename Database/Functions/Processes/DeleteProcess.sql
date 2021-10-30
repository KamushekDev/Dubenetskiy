CREATE OR REPLACE FUNCTION public.DeleteProcess(
    processId bigint, isForce bool default false)
    RETURNS bool
AS
$func$
declare
    tempId bigint;
BEGIN
    perform CheckProcess(processId);

    if not isForce and
       exists (select 1 from process_permissions where process_id = processId) then
        raise exception 'Process has dependencies';
    end if;

    for tempId in (select id
                   from process_permissions
                   where process_id = processId
                     and is_deleted = false)
        loop
            perform DeleteProcessPermission(tempId);
        end loop;

    UPDATE public.processes
    set is_deleted = true
    where id = processId;

    return true;
END
$func$ LANGUAGE plpgsql;