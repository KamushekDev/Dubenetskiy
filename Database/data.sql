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
-- Data for Name: units; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.units (id, name) FROM stdin;
\.


--
-- Data for Name: parameters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parameters (id, name, unit_id) FROM stdin;
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
-- Data for Name: runnable_processes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.runnable_processes (id, name, start_step_id) FROM stdin;
1	Важный процесс	1
2	Важный процесс	1
3	Важный процесс	1
\.


--
-- Data for Name: processes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.processes (id, created_from_process_id, current_step_id) FROM stdin;
1	1	5
2	1	3
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name) FROM stdin;
1	Kamushek
2	Vladislave
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
-- Data for Name: process_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.process_permissions (id, process_id, role_id) FROM stdin;
1	1	7
2	2	\N
3	3	8
4	3	10
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
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.products (id, name, class_id, base_id, version) FROM stdin;
1	Гайка	2	\N	v1
\.


--
-- Data for Name: product_parameters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_parameters (product_id, parameter_id) FROM stdin;
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
-- PostgreSQL database dump complete
--

