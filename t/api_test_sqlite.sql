--
-- Name: address; Type: TABLE; Schema: public;
--

CREATE TABLE address (
    id integer primary key autoincrement NOT NULL,
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

CREATE TABLE author (
   id integer primary key autoincrement NOT NULL,
    fname text,
    mname text,
    lname text
);

--
-- Name: book; Type: TABLE; Schema: public; 
--

CREATE TABLE book (
    id integer primary key autoincrement NOT NULL,
    isbn text,
    author integer,
    title text,
    printing text,
    publish_date date,
    publisher integer,
    CONSTRAINT book_author_fkey FOREIGN KEY (author) REFERENCES author(id),
    CONSTRAINT book_publisher_fkey FOREIGN KEY (publisher) REFERENCES publisher(id)
);

--
-- Name: publisher; Type: TABLE; Schema: public; 
--

CREATE TABLE publisher (
    id integer primary key autoincrement NOT NULL,
    publisher_name text,
    address integer,
    CONSTRAINT publisher_address_fkey FOREIGN KEY (address) REFERENCES address(id)
);

--
-- Data for Name: address; Type: TABLE DATA; Schema: public; 
--

INSERT INTO address VALUES (1, '', '1745 Braodway', '', 'New York', 'NY', 'US', '10019');


--
-- Data for Name: author; Type: TABLE DATA; Schema: public; 
--

INSERT INTO author VALUES (2, 'William', '', 'Gibson');
INSERT INTO author VALUES (3, 'Robert', 'Anson', 'Heinlein');
INSERT INTO author VALUES (4, 'Tim', '', 'Powers');
INSERT INTO author VALUES (5, 'Ursula', 'K.', 'Le Guin');


--
-- Data for Name: publisher; Type: TABLE DATA; Schema: public; 
--

INSERT INTO publisher VALUES (6, 'Penguin Random House LLC.', 1);

--
-- Data for Name: book; Type: TABLE DATA; Schema: public; 
--

INSERT INTO book VALUES (7, 'Fake-ISBN-Num', 2, 'Neuromancer', '1', '1984-06-01', NULL);
INSERT INTO book VALUES (8, 'Fake-ISBN-Num2', 2, 'Idoru', '1', '1985-06-01', NULL);
INSERT INTO book VALUES (9, 'Fake-ISBN-Num3', 2, 'All Tomorrow''s Parties', '1', '1986-06-01', NULL);
INSERT INTO book VALUES (10, 'Fake-ISBN-Num5', 3, 'Stranger in a Strange Land', '1', '1964-07-01', NULL);
INSERT INTO book VALUES (11, 'Fake-ISBN-Num6', 4, 'Declare', '1', '1998-01-01', NULL);
INSERT INTO book VALUES (12, 'Fake-ISBN-Num4', 2, 'All You Need Is 💙', '1', '2024-01-09', 6);




--
-- Name: address address_pkey; Type: CONSTRAINT; Schema: public; 
--

-- ALTER TABLE ONLY address
--     ADD CONSTRAINT address_pkey PRIMARY KEY (id);


--
-- Name: author author_pkey; Type: CONSTRAINT; Schema: public; 
--

-- ALTER TABLE ONLY author
--     ADD CONSTRAINT author_pkey PRIMARY KEY (id);


--
-- Name: book book_pkey; Type: CONSTRAINT; Schema: ; 
--

-- ALTER TABLE ONLY book
--     ADD CONSTRAINT book_pkey PRIMARY KEY (id);


--
-- Name: publisher publisher_pkey; Type: CONSTRAINT; Schema: public; 
--

-- ALTER TABLE ONLY publisher
--     ADD CONSTRAINT publisher_pkey PRIMARY KEY (id);


--
-- Name: book book_author_fkey; Type: FK CONSTRAINT; Schema: public; 
--

-- ALTER TABLE ONLY book
--     ADD CONSTRAINT book_author_fkey FOREIGN KEY (author) REFERENCES author(id);


--
-- Name: publisher publisher_address_fkey; Type: FK CONSTRAINT; Schema: public; 
--

-- ALTER TABLE ONLY publisher
--     ADD CONSTRAINT publisher_address_fkey FOREIGN KEY (address) REFERENCES address(id);



