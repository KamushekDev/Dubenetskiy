CREATE OR REPLACE FUNCTION public.AddStep(
    stepName varchar,
    OUT step_id int) AS
$func$
BEGIN
    INSERT INTO process_steps (name)
    values (stepName)
    RETURNING id INTO step_id;
END
$func$ LANGUAGE plpgsql;