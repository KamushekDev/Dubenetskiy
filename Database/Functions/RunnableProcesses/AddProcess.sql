CREATE OR REPLACE FUNCTION public.AddProcess(
    processName varchar,
    startStepId bigint,
    roleIds bigint[] default array []::bigint[])
    RETURNS bigint AS
$func$
declare
    roleId       bigint;
    newProcessId bigint;
BEGIN
    perform CheckStep(startStepId);

    INSERT INTO runnable_processes (name, start_step_id)
    values (processName, startStepId)
    RETURNING id INTO newProcessId;

    for roleId in select fr.filtered_role_id from GetFilteredRoles(roleIds) fr
        loop
            INSERT INTO process_permissions (process_id, role_id) values (newProcessId, roleId);
        end loop;

    if not exists(select 1 from process_permissions where process_id = newProcessId) then
        INSERT INTO process_permissions (process_id, role_id) values (newProcessId, null);
    end if;

    return newProcessId;
END
$func$ LANGUAGE plpgsql;