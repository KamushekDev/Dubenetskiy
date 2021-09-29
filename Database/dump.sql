--
-- PostgreSQL database dump
--

-- Dumped from database version 13.2 (Debian 13.2-1.pgdg100+1)
-- Dumped by pg_dump version 13.4 (Ubuntu 13.4-1.pgdg20.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: addprocess(character varying, bigint, bigint[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.addprocess(processname character varying, startstepid bigint, roleids bigint[] DEFAULT ARRAY[]::bigint[], OUT process_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
    roleId bigint;
BEGIN
    INSERT INTO runnable_processes (name, start_step_id)
    values (processName, startStepId)
    RETURNING id INTO process_id;

    foreach roleId in array roleIds
        loop
            INSERT INTO process_permissions (process_id, role_id)    values (process_id, roleId);
        end loop;

    if cardinality(roleIds) = 0 then
        INSERT INTO process_permissions (process_id, role_id)    values (process_id, null);
    end if;
END
$$;


ALTER FUNCTION public.addprocess(processname character varying, startstepid bigint, roleids bigint[], OUT process_id integer) OWNER TO postgres;

--
-- Name: addrole(character varying, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.addrole(rolename character varying, parentroleid bigint DEFAULT NULL::bigint, OUT role_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    if parentRoleId is null then
        if (select count(*)
            from roles
            where parent_id is null) > 0 then
            raise exception 'Main role is already exists';
        end if;
    end if;

    INSERT INTO roles (name, parent_id)
    values (roleName, parentRoleId)
    RETURNING id INTO role_id;
END
$$;


ALTER FUNCTION public.addrole(rolename character varying, parentroleid bigint, OUT role_id integer) OWNER TO postgres;

--
-- Name: addstep(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.addstep(stepname character varying, OUT step_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO process_steps (name)
    values (stepName)
    RETURNING id INTO step_id;
END
$$;


ALTER FUNCTION public.addstep(stepname character varying, OUT step_id integer) OWNER TO postgres;

--
-- Name: adduser(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.adduser(username character varying, OUT user_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO users (name)
    values (username)
    RETURNING id INTO user_id;
END
$$;


ALTER FUNCTION public.adduser(username character varying, OUT user_id integer) OWNER TO postgres;

--
-- Name: assignrole(bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.assignrole(userid bigint, roleid bigint, OUT user_role_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
    existing bigint;
BEGIN
    existing = (select id from user_roles where user_id = userId and role_id = roleId);
    if existing is not null then
        user_role_id = existing;
        return;
    end if;
    INSERT INTO user_roles (user_id, role_id, assigned_at)
    values (userId, roleId, UtcNow())
    RETURNING id INTO user_role_id;
END
$$;


ALTER FUNCTION public.assignrole(userid bigint, roleid bigint, OUT user_role_id integer) OWNER TO postgres;

--
-- Name: checkprocess(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.checkprocess(processid bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
BEGIN
   if (select count(*) from processes p where p.id = processId) = 0 then
        raise exception 'Process does not exist';
    end if;
END
$$;


ALTER FUNCTION public.checkprocess(processid bigint) OWNER TO postgres;

--
-- Name: checkuser(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.checkuser(userid bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
BEGIN
    if (select count(*) from users u where u.id = userId) = 0 then
        raise exception 'User does not exist';
    end if;
END
$$;


ALTER FUNCTION public.checkuser(userid bigint) OWNER TO postgres;

--
-- Name: deleteuser(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.deleteuser(userid bigint) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    if (select count(*) from users where id = userId) = 0 then
        return false;
    end if;

    DELETE from users
    where id = userId;

    return true;
END
$$;


ALTER FUNCTION public.deleteuser(userid bigint) OWNER TO postgres;

--
-- Name: edituser(bigint, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.edituser(userid bigint, newusername character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    if (select count(*) from users where id = userId) = 0 then
        return false;
    end if;

    UPDATE users
    set name = newUsername
    where id = userId;

    return true;
END
$$;


ALTER FUNCTION public.edituser(userid bigint, newusername character varying) OWNER TO postgres;

--
-- Name: getresolutions(bigint, bigint, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getresolutions(processid bigint, userid bigint, showall boolean DEFAULT false) RETURNS TABLE(id bigint, text character varying, next_step_id bigint)
    LANGUAGE plpgsql
    AS $$
declare
    currentStep bigint;
BEGIN
    perform CheckProcess(processId);
    perform CheckUser(userId);
    select into currentStep current_step_id from processes p where p.id = processId;

    if showAll = true then
        return query select psr.id, resolution_text, psr.next_step_id
                     from process_step_resolutions psr
                     where current_step_id = currentStep;
    else
        return query select psr.id, resolution_text, psr.next_step_id
                     from process_step_resolutions psr
                     where current_step_id = currentStep
                       and (select count(*) from resolution_permissions rp where resolution_id = psr.id and IsUserSuitable(userId, rp.role_id)) > 0;
    end if;
END
$$;


ALTER FUNCTION public.getresolutions(processid bigint, userid bigint, showall boolean) OWNER TO postgres;

--
-- Name: isrolesuitable(bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isrolesuitable(roleid bigint, requiredroleid bigint, OUT is_suitable boolean) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare
    current bigint = requiredRoleId;
BEGIN
    while current is not null
        loop
            if (current = roleId) then
                is_suitable = true;
                return;
            end if;
            current = (select parent_id from roles where id = current);
        end loop;
    is_suitable = false;
END
$$;


ALTER FUNCTION public.isrolesuitable(roleid bigint, requiredroleid bigint, OUT is_suitable boolean) OWNER TO postgres;

--
-- Name: isusersuitable(bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.isusersuitable(userid bigint, requiredroleid bigint, OUT is_suitable boolean) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare
    currentRole record;
BEGIN
    if requiredRoleId is null then
        is_suitable = true;
        return;
    end if;

    for currentRole in select * from user_roles where user_id = userId
        loop
            if IsRoleSuitable(currentRole.role_id, requiredRoleId) = true then
                is_suitable = true;
                return;
            end if;
        end loop;
    is_suitable = false;
END
$$;


ALTER FUNCTION public.isusersuitable(userid bigint, requiredroleid bigint, OUT is_suitable boolean) OWNER TO postgres;

--
-- Name: linksteps(bigint, bigint, character varying, bigint[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.linksteps(currentstepid bigint, nextstepid bigint, text character varying, roleids bigint[] DEFAULT ARRAY[]::bigint[], OUT step_resolution_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
    existing bigint;
    roleId   bigint;
BEGIN
    existing = (select id
                from process_step_resolutions
                where current_step_id = currentStepId
                  and next_step_id = nextStepId);
    if existing is not null then
        raise exception 'Resolution already exists';
    end if;
    INSERT INTO process_step_resolutions (current_step_id, next_step_id, resolution_text)
    values (currentStepId, nextStepId, text)
    RETURNING id INTO step_resolution_id;

    foreach roleId in array roleIds
        loop
            insert into resolution_permissions (resolution_id, role_id) values (step_resolution_id, roleId);
        end loop;

    if cardinality(roleIds) = 0 then
        insert into resolution_permissions (resolution_id, role_id) values (step_resolution_id, null);
    end if;
END
$$;


ALTER FUNCTION public.linksteps(currentstepid bigint, nextstepid bigint, text character varying, roleids bigint[], OUT step_resolution_id integer) OWNER TO postgres;

--
-- Name: moveprocess(bigint, bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.moveprocess(processid bigint, userid bigint, resolutionid bigint) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare
    resolution record;
    process record;
    requiredRole record;
    isSuitable   bool = false;
BEGIN
    perform CheckProcess(processId);
    perform CheckUser(userId);

    for requiredRole in (select * from resolution_permissions rp where rp.resolution_id = resolutionId)
        loop
            select into isSuitable from IsUserSuitable(userId, requiredRole.id);
            if isSuitable = true then
                exit;
            end if;
        end loop;

    if isSuitable = false then
        raise exception 'User has no permission to perform that resolution';
    end if;

    select into resolution * from process_step_resolutions where id = resolutionId;
    select into process * from processes where id = processId;
    if (process.current_step_id != resolution.current_step_id) then
        raise exception 'Process'' current step does not allow that transition.';
    end if;

    update processes
    set current_step_id = resolution.next_step_id
    where id = processId;

    insert into process_history (process_id, performed_at, performed_by_user_id, resolution_id)
    values (processId, UtcNow(), userId, resolutionId);

    return true;
END
$$;


ALTER FUNCTION public.moveprocess(processid bigint, userid bigint, resolutionid bigint) OWNER TO postgres;

--
-- Name: revokerole(bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.revokerole(userid bigint, roleid bigint, OUT user_role_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    Delete from user_roles where user_id = userId and role_id = roleId
    RETURNING id INTO user_role_id;
END
$$;


ALTER FUNCTION public.revokerole(userid bigint, roleid bigint, OUT user_role_id integer) OWNER TO postgres;

--
-- Name: startprocess(bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.startprocess(runnableprocessid bigint, userid bigint, OUT new_process_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
    template     record;
    requiredRole record;
    isSuitable   bool = false;
BEGIN
    select into template * from runnable_processes where id = runnableProcessId;

    for requiredRole in (select * from process_permissions pm where pm.process_id = template.id)
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
    RETURNING id INTO new_process_id;

    insert into process_history (process_id, performed_at, performed_by_user_id, resolution_id)
    values (new_process_id, UtcNow(), userId, null);
END
$$;


ALTER FUNCTION public.startprocess(runnableprocessid bigint, userid bigint, OUT new_process_id integer) OWNER TO postgres;

--
-- Name: utcnow(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.utcnow() RETURNS timestamp without time zone
    LANGUAGE plpgsql
    AS $$
declare
BEGIN
    return timezone('UTC', now());
END
$$;


ALTER FUNCTION public.utcnow() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: parameters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parameters (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    unit_id bigint NOT NULL
);


ALTER TABLE public.parameters OWNER TO postgres;

--
-- Name: parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parameters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.parameters_id_seq OWNER TO postgres;

--
-- Name: parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parameters_id_seq OWNED BY public.parameters.id;


--
-- Name: process_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.process_history (
    id bigint NOT NULL,
    process_id bigint NOT NULL,
    performed_at timestamp without time zone NOT NULL,
    performed_by_user_id bigint NOT NULL,
    resolution_id bigint
);


ALTER TABLE public.process_history OWNER TO postgres;

--
-- Name: process_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.process_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.process_history_id_seq OWNER TO postgres;

--
-- Name: process_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.process_history_id_seq OWNED BY public.process_history.id;


--
-- Name: process_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.process_permissions (
    id bigint NOT NULL,
    process_id bigint NOT NULL,
    role_id bigint
);


ALTER TABLE public.process_permissions OWNER TO postgres;

--
-- Name: process_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.process_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.process_permissions_id_seq OWNER TO postgres;

--
-- Name: process_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.process_permissions_id_seq OWNED BY public.process_permissions.id;


--
-- Name: process_step_resolutions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.process_step_resolutions (
    current_step_id bigint NOT NULL,
    next_step_id bigint NOT NULL,
    resolution_text character varying(100) NOT NULL,
    id bigint NOT NULL
);


ALTER TABLE public.process_step_resolutions OWNER TO postgres;

--
-- Name: process_step_resolutions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.process_step_resolutions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.process_step_resolutions_id_seq OWNER TO postgres;

--
-- Name: process_step_resolutions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.process_step_resolutions_id_seq OWNED BY public.process_step_resolutions.id;


--
-- Name: process_steps; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.process_steps (
    id bigint NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.process_steps OWNER TO postgres;

--
-- Name: process_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.process_steps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.process_steps_id_seq OWNER TO postgres;

--
-- Name: process_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.process_steps_id_seq OWNED BY public.process_steps.id;


--
-- Name: processes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.processes (
    id bigint NOT NULL,
    created_from_process_id bigint NOT NULL,
    current_step_id bigint NOT NULL
);


ALTER TABLE public.processes OWNER TO postgres;

--
-- Name: runnable_processes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.runnable_processes (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    start_step_id bigint NOT NULL
);


ALTER TABLE public.runnable_processes OWNER TO postgres;

--
-- Name: processes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.processes_id_seq OWNER TO postgres;

--
-- Name: processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.processes_id_seq OWNED BY public.runnable_processes.id;


--
-- Name: processes_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.processes_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.processes_id_seq1 OWNER TO postgres;

--
-- Name: processes_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.processes_id_seq1 OWNED BY public.processes.id;


--
-- Name: product_classes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_classes (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    parent_id bigint
);


ALTER TABLE public.product_classes OWNER TO postgres;

--
-- Name: product_classes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_classes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_classes_id_seq OWNER TO postgres;

--
-- Name: product_classes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_classes_id_seq OWNED BY public.product_classes.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    class_id bigint NOT NULL,
    base_id bigint,
    version character varying(50) DEFAULT '1'::character varying NOT NULL
);


ALTER TABLE public.products OWNER TO postgres;

--
-- Name: product_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_id_seq OWNER TO postgres;

--
-- Name: product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_id_seq OWNED BY public.products.id;


--
-- Name: product_parameters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_parameters (
    product_id bigint NOT NULL,
    parameter_id bigint NOT NULL
);


ALTER TABLE public.product_parameters OWNER TO postgres;

--
-- Name: resolution_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resolution_permissions (
    id bigint NOT NULL,
    resolution_id bigint NOT NULL,
    role_id bigint
);


ALTER TABLE public.resolution_permissions OWNER TO postgres;

--
-- Name: resolution_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.resolution_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.resolution_permissions_id_seq OWNER TO postgres;

--
-- Name: resolution_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.resolution_permissions_id_seq OWNED BY public.resolution_permissions.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    parent_id bigint
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.roles_id_seq OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: units; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.units (
    id bigint NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.units OWNER TO postgres;

--
-- Name: units_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.units_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.units_id_seq OWNER TO postgres;

--
-- Name: units_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.units_id_seq OWNED BY public.units.id;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_roles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    role_id bigint NOT NULL,
    assigned_at timestamp without time zone NOT NULL
);


ALTER TABLE public.user_roles OWNER TO postgres;

--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_roles_id_seq OWNER TO postgres;

--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_roles_id_seq OWNED BY public.user_roles.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: parameters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parameters ALTER COLUMN id SET DEFAULT nextval('public.parameters_id_seq'::regclass);


--
-- Name: process_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.process_history ALTER COLUMN id SET DEFAULT nextval('public.process_history_id_seq'::regclass);


--
-- Name: process_permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.process_permissions ALTER COLUMN id SET DEFAULT nextval('public.process_permissions_id_seq'::regclass);


--
-- Name: process_step_resolutions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.process_step_resolutions ALTER COLUMN id SET DEFAULT nextval('public.process_step_resolutions_id_seq'::regclass);


--
-- Name: process_steps id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.process_steps ALTER COLUMN id SET DEFAULT nextval('public.process_steps_id_seq'::regclass);


--
-- Name: processes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processes ALTER COLUMN id SET DEFAULT nextval('public.processes_id_seq1'::regclass);


--
-- Name: product_classes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_classes ALTER COLUMN id SET DEFAULT nextval('public.product_classes_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.product_id_seq'::regclass);


--
-- Name: resolution_permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resolution_permissions ALTER COLUMN id SET DEFAULT nextval('public.resolution_permissions_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: runnable_processes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.runnable_processes ALTER COLUMN id SET DEFAULT nextval('public.processes_id_seq'::regclass);


--
-- Name: units id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.units ALTER COLUMN id SET DEFAULT nextval('public.units_id_seq'::regclass);


--
-- Name: user_roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN id SET DEFAULT nextval('public.user_roles_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: parameters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parameters (id, name, unit_id) FROM stdin;
\.


--
-- Data for Name: process_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.process_history (id, process_id, performed_at, performed_by_user_id, resolution_id) FROM stdin;
1	1	2021-09-27 01:16:49.955759	1	\N
2	1	2021-09-27 01:20:09.356508	1	6
3	1	2021-09-27 01:20:26.840938	1	3
4	1	2021-09-27 01:20:36.873881	1	5
5	1	2021-09-27 01:43:24.070803	1	5
6	1	2021-09-27 01:48:25.815081	1	11
7	1	2021-09-27 01:49:39.438574	1	11
8	1	2021-09-27 01:51:05.676417	1	8
9	2	2021-09-27 01:51:38.214288	1	10
10	2	2021-09-29 05:22:49.626052	1	12
\.


--
-- Data for Name: process_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.process_permissions (id, process_id, role_id) FROM stdin;
1	1	7
2	2	\N
3	3	8
4	3	10
\.


--
-- Data for Name: process_step_resolutions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.process_step_resolutions (current_step_id, next_step_id, resolution_text, id) FROM stdin;
3	5	К четвёртому шагу	4
4	5	К четвёртому шагу	5
2	3	К третьему шагу	2
1	2	Ко второму шагу	6
2	5	В обход третьего шага	7
2	4	К третьему шагу (2)	3
1	5	Тестовая параша	8
4	1	Тестовая параша 2	9
2	1	Тестовая параша 3	10
5	1	Тестовая параша 4	11
1	3	Тестовая параша 4	12
\.


--
-- Data for Name: process_steps; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.process_steps (id, name) FROM stdin;
1	Первый шаг
2	Второй шаг
3	Третий шаг (1)
4	Третий шаг (2)
5	Четвёртый шаг
\.


--
-- Data for Name: processes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.processes (id, created_from_process_id, current_step_id) FROM stdin;
1	1	5
2	1	3
\.


--
-- Data for Name: product_classes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_classes (id, name, parent_id) FROM stdin;
1	Hello	\N
2	Second	\N
3	Third (Second's son)	2
4	Fourth (Second's son)	2
5	Sixth	\N
\.


--
-- Data for Name: product_parameters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_parameters (product_id, parameter_id) FROM stdin;
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.products (id, name, class_id, base_id, version) FROM stdin;
1	Гайка	2	\N	v1
\.


--
-- Data for Name: resolution_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.resolution_permissions (id, resolution_id, role_id) FROM stdin;
1	8	8
2	8	7
3	9	8
4	9	7
5	10	8
6	10	7
7	11	6
8	12	\N
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, name, parent_id) FROM stdin;
7	Logistic admin	6
8	Warehouse admin	6
9	Warehouse worker	8
10	Logistic worker	7
6	admin	\N
\.


--
-- Data for Name: runnable_processes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.runnable_processes (id, name, start_step_id) FROM stdin;
1	Важный процесс	1
2	Важный процесс	1
3	Важный процесс	1
\.


--
-- Data for Name: units; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.units (id, name) FROM stdin;
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_roles (id, user_id, role_id, assigned_at) FROM stdin;
4	1	7	2021-09-24 14:05:36.378396
5	1	8	2021-09-24 14:12:28.08999
6	1	6	2021-09-27 01:46:33.26158
7	2	7	2021-09-27 01:53:45.758776
8	2	9	2021-09-27 01:53:47.209002
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name) FROM stdin;
1	Kamushek
2	Vladislave
\.


--
-- Name: parameters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parameters_id_seq', 1, false);


--
-- Name: process_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.process_history_id_seq', 10, true);


--
-- Name: process_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.process_permissions_id_seq', 4, true);


--
-- Name: process_step_resolutions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.process_step_resolutions_id_seq', 12, true);


--
-- Name: process_steps_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.process_steps_id_seq', 6, true);


--
-- Name: processes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.processes_id_seq', 3, true);


--
-- Name: processes_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.processes_id_seq1', 2, true);


--
-- Name: product_classes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_classes_id_seq', 5, true);


--
-- Name: product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_id_seq', 1, true);


--
-- Name: resolution_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.resolution_permissions_id_seq', 8, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_seq', 10, true);


--
-- Name: units_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.units_id_seq', 1, false);


--
-- Name: user_roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_roles_id_seq', 8, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 3, true);


--
-- Name: parameters parameters_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parameters
    ADD CONSTRAINT parameters_pk PRIMARY KEY (id);


--
-- Name: process_history process_history_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.process_history
    ADD CONSTRAINT process_history_pk PRIMARY KEY (id);


--
-- Name: process_permissions process_permissions_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.process_permissions
    ADD CONSTRAINT process_permissions_pk PRIMARY KEY (id);


--
-- Name: process_step_resolutions process_step_resolutions_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.process_step_resolutions
    ADD CONSTRAINT process_step_resolutions_pk PRIMARY KEY (id);


--
-- Name: process_steps process_steps_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.process_steps
    ADD CONSTRAINT process_steps_pk PRIMARY KEY (id);


--
-- Name: processes processes2_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processes
    ADD CONSTRAINT processes2_pk PRIMARY KEY (id);


--
-- Name: runnable_processes processes_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.runnable_processes
    ADD CONSTRAINT processes_pk PRIMARY KEY (id);


--
-- Name: product_classes product_classes_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_classes
    ADD CONSTRAINT product_classes_pk PRIMARY KEY (id);


--
-- Name: product_parameters product_parameters_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_parameters
    ADD CONSTRAINT product_parameters_pk PRIMARY KEY (product_id, parameter_id);


--
-- Name: products product_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT product_pk PRIMARY KEY (id);


--
-- Name: resolution_permissions resolution_permissions_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resolution_permissions
    ADD CONSTRAINT resolution_permissions_pk PRIMARY KEY (id);


--
-- Name: roles roles_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pk PRIMARY KEY (id);


--
-- Name: units units_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_pk PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pk PRIMARY KEY (id);


--
-- Name: users users_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pk PRIMARY KEY (id);


--
-- Name: parameters_name_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX parameters_name_uindex ON public.parameters USING btree (name);


--
-- Name: process_step_resolutions_step_in_id_step_out_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX process_step_resolutions_step_in_id_step_out_id_uindex ON public.process_step_resolutions USING btree (current_step_id, next_step_id);


--
-- Name: units_name_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX units_name_uindex ON public.units USING btree (name);


--
-- Name: parameters parameters_units_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parameters
    ADD CONSTRAINT parameters_units_id_fk FOREIGN KEY (unit_id) REFERENCES public.units(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: process_history process_history_process_step_resolutions_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.process_history
    ADD CONSTRAINT process_history_process_step_resolutions_id_fk FOREIGN KEY (resolution_id) REFERENCES public.process_step_resolutions(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: process_history process_history_processes_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.process_history
    ADD CONSTRAINT process_history_processes_id_fk FOREIGN KEY (process_id) REFERENCES public.processes(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: process_history process_history_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.process_history
    ADD CONSTRAINT process_history_users_id_fk FOREIGN KEY (performed_by_user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: process_permissions process_permissions_roles_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.process_permissions
    ADD CONSTRAINT process_permissions_roles_id_fk FOREIGN KEY (role_id) REFERENCES public.roles(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: process_permissions process_permissions_runnable_processes_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.process_permissions
    ADD CONSTRAINT process_permissions_runnable_processes_id_fk FOREIGN KEY (process_id) REFERENCES public.runnable_processes(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: process_step_resolutions process_step_resolutions_process_steps_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.process_step_resolutions
    ADD CONSTRAINT process_step_resolutions_process_steps_id_fk FOREIGN KEY (current_step_id) REFERENCES public.process_steps(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: process_step_resolutions process_step_resolutions_process_steps_id_fk_2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.process_step_resolutions
    ADD CONSTRAINT process_step_resolutions_process_steps_id_fk_2 FOREIGN KEY (next_step_id) REFERENCES public.process_steps(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: runnable_processes processes_process_steps_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.runnable_processes
    ADD CONSTRAINT processes_process_steps_id_fk FOREIGN KEY (start_step_id) REFERENCES public.process_steps(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: processes processes_process_steps_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processes
    ADD CONSTRAINT processes_process_steps_id_fk FOREIGN KEY (current_step_id) REFERENCES public.process_steps(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: processes processes_runnable_processes_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processes
    ADD CONSTRAINT processes_runnable_processes_id_fk FOREIGN KEY (created_from_process_id) REFERENCES public.runnable_processes(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: product_parameters product_parameters_parameters_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_parameters
    ADD CONSTRAINT product_parameters_parameters_id_fk FOREIGN KEY (parameter_id) REFERENCES public.parameters(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: product_parameters product_parameters_products_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_parameters
    ADD CONSTRAINT product_parameters_products_id_fk FOREIGN KEY (product_id) REFERENCES public.products(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: products product_product_classes_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT product_product_classes_id_fk FOREIGN KEY (class_id) REFERENCES public.product_classes(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: resolution_permissions resolution_permissions_process_step_resolutions_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resolution_permissions
    ADD CONSTRAINT resolution_permissions_process_step_resolutions_id_fk FOREIGN KEY (resolution_id) REFERENCES public.process_step_resolutions(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: resolution_permissions resolution_permissions_roles_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resolution_permissions
    ADD CONSTRAINT resolution_permissions_roles_id_fk FOREIGN KEY (role_id) REFERENCES public.roles(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: roles roles_roles_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_roles_id_fk FOREIGN KEY (parent_id) REFERENCES public.roles(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: user_roles user_roles_roles_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_roles_id_fk FOREIGN KEY (role_id) REFERENCES public.roles(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: user_roles user_roles_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_users_id_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

