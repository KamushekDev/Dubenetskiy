CREATE OR REPLACE FUNCTION public.DeleteStep(
    stepId bigint, isForce bool default false)
    RETURNS bool
AS
$func$
DECLARE
    currentResolutionId bigint;
BEGIN
    perform CheckStep(stepId);

    if not isForce and (
            exists(select 1 from runnable_processes where start_step_id = stepId) or
            exists(select 1 from process_step_resolutions where current_step_id = stepId or next_step_id = stepId) or
            exists(select 1 from processes where current_step_id = stepId)
        ) then
        raise exception 'Step has dependencies';
    end if;

    if (
            exists(select 1 from runnable_processes where start_step_id = stepId) or
            exists(select 1 from processes where current_step_id = stepId)
        ) then
        raise exception 'Step has dominator object(s) and thus can''t be deleted';
    end if;

    for currentResolutionId in (select id
                                from process_step_resolutions
                                where current_step_id = stepId
                                   or next_step_id = stepId)
        loop
            perform DeleteProcessStepResolution(currentResolutionId, true);
        end loop;

    UPDATE process_steps
    set is_deleted = true
    where id = stepId;

    return true;
END
$func$ LANGUAGE plpgsql;