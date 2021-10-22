CREATE OR REPLACE FUNCTION public.LinkSteps(
    currentStepId bigint,
    nextStepId bigint,
    text varchar,
    roleIds bigint[] default array []::bigint[])
    returns bigint
AS
$func$
declare
    existing bigint;
    roleId   bigint;
    resultId bigint;
BEGIN
    perform CheckStep(currentStepId);
    perform CheckStep(nextStepId);

    existing = (select id
                from process_step_resolutions
                where current_step_id = currentStepId
                  and next_step_id = nextStepId
                  and is_deleted = false);
    if existing is not null then
        raise exception 'Resolution already exists';
    end if;

    INSERT INTO process_step_resolutions (current_step_id, next_step_id, resolution_text)
    values (currentStepId, nextStepId, text)
    RETURNING id INTO resultId;

    for roleId
        in select fr.filtered_role_id from GetFilteredRoles(roleIds) fr
        loop
            insert into resolution_permissions (resolution_id, role_id) values (resultId, roleId);
        end loop;

    if not exists(select 1 from resolution_permissions where resolution_id = resultId) then
        insert into resolution_permissions (resolution_id, role_id) values (resultId, null);
    end if;

    return resultId;
END
$func$ LANGUAGE plpgsql;