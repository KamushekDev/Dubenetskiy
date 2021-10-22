CREATE OR REPLACE FUNCTION public.StartProcess(
    runnableProcessId bigint,
    userId bigint)
    returns bigint
AS
$func$
declare
    template        record;
    requiredRole    record;
    isSuitable      bool = false;
    resultProcessId bigint;
BEGIN
    perform checkrunnableprocess(runnableProcessId);
    perform checkuser(userId);

    select into template * from runnable_processes where id = runnableProcessId;

    --Should never fail
    perform CheckStep(template.start_step_id);

    for requiredRole in (select * from process_permissions pm where pm.process_id = template.id and is_deleted = false)
        loop
            select into isSuitable from IsUserSuitable(userId, requiredRole.id);
            if isSuitable = true then
                exit;
            end if;
        end loop;

    if isSuitable = false then
        raise exception 'User has no permission to start that process';
    end if;

    INSERT INTO processes (created_from_process_id, current_step_id)
    values (template.id, template.start_step_id)
    RETURNING id INTO resultProcessId;

    insert into process_history (process_id, performed_at, performed_by_user_id, resolution_id)
    values (resultProcessId, UtcNow(), userId, null);

    return resultProcessId;
END
$func$ LANGUAGE plpgsql;