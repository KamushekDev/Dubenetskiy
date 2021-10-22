CREATE OR REPLACE FUNCTION public.UtcNow()
    RETURNS timestamp without time zone
AS
$func$
declare
BEGIN
    return timezone('UTC', now());
END
$func$ LANGUAGE plpgsql;

