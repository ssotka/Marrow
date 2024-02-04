--
-- Name: address; Type: TABLE; Schema: public;
--

CREATE TABLE public.address (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    building text,
    street1 text,
    street2 text,
    city text,
    state_region text,
    country character varying(2),
    zip character varying(10)
);

--
-- Name: author; Type: TABLE; Schema: public; 
--

CREATE TABLE public.author (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fname text,
    mname text,
    lname text
);

--
-- Name: book; Type: TABLE; Schema: public; 
--

CREATE TABLE public.book (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    isbn text,
    author uuid,
    title text,
    printing text,
    publish_date date,
    publisher uuid
);

--
-- Name: publisher; Type: TABLE; Schema: public; 
--

CREATE TABLE public.publisher (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    publisher_name text,
    address uuid
);

--
-- Data for Name: address; Type: TABLE DATA; Schema: public; 
--

INSERT INTO public.address VALUES ('c5fcc275-5174-4243-a4b2-eea91c07627e', '', '1745 Braodway', '', 'New York', 'NY', 'US', '10019');


--
-- Data for Name: author; Type: TABLE DATA; Schema: public; 
--

INSERT INTO public.author VALUES ('9b090798-0d09-43d6-8898-9b5c8ad2995f', 'William', '', 'Gibson');
INSERT INTO public.author VALUES ('dc35bc81-3f00-48f5-8f42-8e185aa1e515', 'Robert', 'Anson', 'Heinlein');
INSERT INTO public.author VALUES ('f691d9ce-6d8d-462c-8e8f-1c8a5bcfc591', 'Tim', '', 'Powers');
INSERT INTO public.author VALUES ('6ab84f37-51fe-4c38-883c-681ace68d919', 'Ursula', 'K.', 'Le Guin');


--
-- Data for Name: book; Type: TABLE DATA; Schema: public; 
--

INSERT INTO public.book VALUES ('c3287a53-81d6-41f3-8f7f-ffd01443084c', 'Fake-ISBN-Num', '9b090798-0d09-43d6-8898-9b5c8ad2995f', 'Neuromancer', '1', '1984-06-01', NULL);
INSERT INTO public.book VALUES ('343a921e-118b-4f09-ba08-a18318469048', 'Fake-ISBN-Num2', '9b090798-0d09-43d6-8898-9b5c8ad2995f', 'Idoru', '1', '1985-06-01', NULL);
INSERT INTO public.book VALUES ('809aa73b-9f6e-49ad-ac58-a5f1da8ec246', 'Fake-ISBN-Num3', '9b090798-0d09-43d6-8898-9b5c8ad2995f', 'All Tomorrow''s Parties', '1', '1986-06-01', NULL);
INSERT INTO public.book VALUES ('a14b4869-357a-4dae-98d4-595e39894440', 'Fake-ISBN-Num5', 'dc35bc81-3f00-48f5-8f42-8e185aa1e515', 'Stranger in a Strange Land', '1', '1964-07-01', NULL);
INSERT INTO public.book VALUES ('14326d00-377c-457d-847c-d33a0c696104', 'Fake-ISBN-Num6', 'f691d9ce-6d8d-462c-8e8f-1c8a5bcfc591', 'Declare', '1', '1998-01-01', NULL);
INSERT INTO public.book VALUES ('955e74fc-6843-42bc-8b8a-aac17dbced00', 'Fake-ISBN-Num4', '9b090798-0d09-43d6-8898-9b5c8ad2995f', 'All You Need Is 💙', '1', '2024-01-09', 'd85e2529-9467-4387-9335-0fd12632b147');


--
-- Data for Name: publisher; Type: TABLE DATA; Schema: public; 
--

INSERT INTO public.publisher VALUES ('d85e2529-9467-4387-9335-0fd12632b147', 'Penguin Random House LLC.', 'c5fcc275-5174-4243-a4b2-eea91c07627e');


--
-- Name: address address_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY public.address
    ADD CONSTRAINT address_pkey PRIMARY KEY (id);


--
-- Name: author author_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT author_pkey PRIMARY KEY (id);


--
-- Name: book book_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY public.book
    ADD CONSTRAINT book_pkey PRIMARY KEY (id);


--
-- Name: publisher publisher_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY public.publisher
    ADD CONSTRAINT publisher_pkey PRIMARY KEY (id);


--
-- Name: book book_author_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY public.book
    ADD CONSTRAINT book_author_fkey FOREIGN KEY (author) REFERENCES public.author(id);


--
-- Name: publisher publisher_address_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY public.publisher
    ADD CONSTRAINT publisher_address_fkey FOREIGN KEY (address) REFERENCES public.address(id);



