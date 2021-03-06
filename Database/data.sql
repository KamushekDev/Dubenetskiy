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

COPY public.process_steps (id, name, is_deleted) FROM stdin;
1	Первый шаг	f
2	Второй шаг	f
3	Третий шаг (1)	f
4	Третий шаг (2)	f
5	Четвёртый шаг	f
8	К тестовому шагу	f
\.


--
-- Data for Name: process_step_resolutions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.process_step_resolutions (current_step_id, next_step_id, resolution_text, id, is_deleted) FROM stdin;
3	5	К четвёртому шагу	4	f
4	5	К четвёртому шагу	5	f
2	3	К третьему шагу	2	f
1	2	Ко второму шагу	6	f
2	5	В обход третьего шага	7	f
2	4	К третьему шагу (2)	3	f
1	5	Тестовая параша	8	f
4	1	Тестовая параша 2	9	f
2	1	Тестовая параша 3	10	f
5	1	Тестовая параша 4	11	f
1	8	Тестовый текст	12	f
1	3	Тест говна	17	f
2	8	Тест говна	18	f
3	8	Тест говна	24	f
5	8	Тест говна	25	f
\.


--
-- Data for Name: runnable_processes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.runnable_processes (id, name, start_step_id, is_deleted) FROM stdin;
1	Важный процесс	1	f
2	Важный процесс	1	f
3	Важный процесс	1	f
\.


--
-- Data for Name: processes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.processes (id, created_from_process_id, current_step_id, is_deleted) FROM stdin;
1	1	5	f
2	1	3	f
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, is_deleted) FROM stdin;
1	Kamushek	f
2	Vladislave	f
5	Test2	f
6	Test3	f
7	Test4	f
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

COPY public.roles (id, name, parent_id, is_deleted) FROM stdin;
7	Logistic admin	6	f
8	Warehouse admin	6	f
9	Warehouse worker	8	f
10	Logistic worker	7	f
6	admin	\N	f
12	Test1	10	f
\.


--
-- Data for Name: process_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.process_permissions (id, process_id, role_id, is_deleted) FROM stdin;
1	1	7	f
2	2	\N	f
3	3	8	f
4	3	10	f
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

COPY public.resolution_permissions (id, resolution_id, role_id, is_deleted) FROM stdin;
1	8	8	f
2	8	7	f
3	9	8	f
4	9	7	f
5	10	8	f
6	10	7	f
7	11	6	f
8	12	\N	f
9	17	7	f
10	17	8	f
11	17	10	f
12	17	6	f
13	18	\N	f
14	24	\N	f
15	25	\N	f
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_roles (id, user_id, role_id, assigned_at, is_deleted) FROM stdin;
4	1	7	2021-09-24 14:05:36.378396	f
5	1	8	2021-09-24 14:12:28.08999	f
6	1	6	2021-09-27 01:46:33.26158	f
7	2	7	2021-09-27 01:53:45.758776	f
8	2	9	2021-09-27 01:53:47.209002	f
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

SELECT pg_catalog.setval('public.process_step_resolutions_id_seq', 25, true);


--
-- Name: process_steps_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.process_steps_id_seq', 2183, true);


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

SELECT pg_catalog.setval('public.resolution_permissions_id_seq', 15, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_seq', 12, true);


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

SELECT pg_catalog.setval('public.users_id_seq', 7, true);


--
-- PostgreSQL database dump complete
--

