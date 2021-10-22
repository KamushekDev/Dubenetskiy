CREATE OR REPLACE FUNCTION public.DeleteProcessStepResolution(
    resolutionId bigint, isForce bool default false)
    RETURNS bool
AS
$func$
declare
    tempId bigint;
BEGIN
    perform CheckResolution(resolutionId);

    if not isForce and
       (exists(select 1
               from resolution_permissions
               where resolution_id = resolutionId
                 and is_deleted = false)
           ) then
        return false;
    end if;

    for tempId in (select id
                   from resolution_permissions
                   where resolution_id = resolutionId
                     and is_deleted = false)
        loop
            perform DeleteProcessStepResolution(tempId);
        end loop;

    UPDATE process_step_resolutions
    set is_deleted = true
    where id = resolutionId;

    return true;
END
$func$ LANGUAGE plpgsql;