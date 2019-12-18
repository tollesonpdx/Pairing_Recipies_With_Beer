--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.17
-- Dumped by pg_dump version 10.8 (Ubuntu 10.8-0ubuntu0.18.04.1)

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
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: beers; Type: TABLE; Schema: public; Owner: dbgroup1
--

CREATE TABLE public.beers (
    id integer NOT NULL,
    brewery_id integer,
    name text,
    cat_id integer,
    style_id integer,
    abv double precision DEFAULT 0.0,
    ibu double precision DEFAULT 0.0,
    srm double precision DEFAULT 0.0,
    upc double precision DEFAULT 0.0,
    filepath text,
    description text,
    add_user text,
    last_mod text
);


ALTER TABLE public.beers OWNER TO dbgroup1;

--
-- Name: breweries; Type: TABLE; Schema: public; Owner: dbgroup1
--

CREATE TABLE public.breweries (
    id integer NOT NULL,
    name text NOT NULL,
    address1 text,
    address2 text,
    city text,
    state text,
    code text,
    country text,
    phone text,
    website text,
    description text
);


ALTER TABLE public.breweries OWNER TO dbgroup1;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: dbgroup1
--

CREATE TABLE public.categories (
    id integer NOT NULL,
    cat_name text NOT NULL
);


ALTER TABLE public.categories OWNER TO dbgroup1;

--
-- Name: ingredients; Type: TABLE; Schema: public; Owner: dbgroup1
--

CREATE TABLE public.ingredients (
    title text DEFAULT 'DELETEROW'::text,
    ingredient text DEFAULT 'DELETEROW'::text,
    meat boolean,
    veggie boolean,
    fruit boolean,
    dairy boolean
);


ALTER TABLE public.ingredients OWNER TO dbgroup1;

--
-- Name: locations; Type: TABLE; Schema: public; Owner: dbgroup1
--

CREATE TABLE public.locations (
    id integer,
    brewery_id integer NOT NULL,
    brew_lat text NOT NULL,
    brew_long text NOT NULL
);


ALTER TABLE public.locations OWNER TO dbgroup1;

--
-- Name: pairings; Type: TABLE; Schema: public; Owner: dbgroup1
--

CREATE TABLE public.pairings (
    cat_id integer,
    pair_type text NOT NULL,
    pair_link text
);


ALTER TABLE public.pairings OWNER TO dbgroup1;

--
-- Name: recipes; Type: TABLE; Schema: public; Owner: dbgroup1
--

CREATE TABLE public.recipes (
    title text NOT NULL,
    directions text,
    fat integer,
    dateload text,
    calories integer,
    description text,
    protein integer,
    rating double precision,
    sodium integer,
    vegetarian boolean DEFAULT false
);


ALTER TABLE public.recipes OWNER TO dbgroup1;

--
-- Name: styles; Type: TABLE; Schema: public; Owner: dbgroup1
--

CREATE TABLE public.styles (
    id integer NOT NULL,
    cat_id integer,
    style_name text NOT NULL
);


ALTER TABLE public.styles OWNER TO dbgroup1;

--
-- Name: tags; Type: TABLE; Schema: public; Owner: dbgroup1
--

CREATE TABLE public.tags (
    title text,
    tag_name text
);


ALTER TABLE public.tags OWNER TO dbgroup1;

--
-- Name: temp_cat_food; Type: TABLE; Schema: public; Owner: dbgroup1
--

CREATE TABLE public.temp_cat_food (
    cat_id integer,
    food_id integer
);


ALTER TABLE public.temp_cat_food OWNER TO dbgroup1;

--
-- Name: temp_foods; Type: TABLE; Schema: public; Owner: dbgroup1
--

CREATE TABLE public.temp_foods (
    food_id integer,
    food_name text
);


ALTER TABLE public.temp_foods OWNER TO dbgroup1;

--
-- Name: tempvw; Type: TABLE; Schema: public; Owner: dbgroup1
--

CREATE TABLE public.tempvw (
    title text
);


ALTER TABLE public.tempvw OWNER TO dbgroup1;

--
-- Name: vw_beerrecipepairings; Type: VIEW; Schema: public; Owner: dbgroup1
--

CREATE VIEW public.vw_beerrecipepairings AS
 SELECT i.title,
    count(b.name) AS beer_count
   FROM public.ingredients i,
    public.pairings p,
    public.beers b,
    ( SELECT ingredients.title
           FROM public.ingredients
          WHERE (ingredients.ingredient ~~ '%beer%'::text)
          GROUP BY ingredients.title) sub1
  WHERE ((i.title = sub1.title) AND (p.pair_type = 'ingredient'::text) AND (i.ingredient = p.pair_link) AND (p.cat_id = b.cat_id))
  GROUP BY i.title, b.name;


ALTER TABLE public.vw_beerrecipepairings OWNER TO dbgroup1;

--
-- Name: vw_desserts; Type: VIEW; Schema: public; Owner: dbgroup1
--

CREATE VIEW public.vw_desserts AS
 SELECT DISTINCT r.title
   FROM public.recipes r,
    public.ingredients i,
    public.tags t
  WHERE ((r.title = i.title) AND (r.title = t.title) AND ((lower(t.tag_name) ~~ lower('%dessert%'::text)) OR (lower(i.ingredient) ~~ lower('%dessert%'::text))));


ALTER TABLE public.vw_desserts OWNER TO dbgroup1;

--
-- Name: vw_mirrorp_recipes; Type: VIEW; Schema: public; Owner: dbgroup1
--

CREATE VIEW public.vw_mirrorp_recipes AS
 SELECT DISTINCT r.title
   FROM public.recipes r,
    public.ingredients i,
    public.tags t,
    ( SELECT p.pair_link,
            b.name
           FROM public.pairings p,
            public.beers b
          WHERE ((b.id = 3587) AND (p.cat_id = b.cat_id))) pb
  WHERE ((r.title = i.title) AND (r.title = t.title) AND (lower(pb.pair_link) = lower(i.ingredient)))
UNION
 SELECT DISTINCT r.title
   FROM public.recipes r,
    public.ingredients i,
    public.tags t,
    ( SELECT p.pair_link,
            b.name
           FROM public.pairings p,
            public.beers b
          WHERE ((b.id = 3587) AND (p.cat_id = b.cat_id))) pb
  WHERE ((r.title = i.title) AND (r.title = t.title) AND (lower(pb.pair_link) = lower(t.tag_name)));


ALTER TABLE public.vw_mirrorp_recipes OWNER TO dbgroup1;

--
-- Name: beers beers_pkey; Type: CONSTRAINT; Schema: public; Owner: dbgroup1
--

ALTER TABLE ONLY public.beers
    ADD CONSTRAINT beers_pkey PRIMARY KEY (id);


--
-- Name: breweries breweries_id_key; Type: CONSTRAINT; Schema: public; Owner: dbgroup1
--

ALTER TABLE ONLY public.breweries
    ADD CONSTRAINT breweries_id_key UNIQUE (id);


--
-- Name: breweries breweries_pkey; Type: CONSTRAINT; Schema: public; Owner: dbgroup1
--

ALTER TABLE ONLY public.breweries
    ADD CONSTRAINT breweries_pkey PRIMARY KEY (id, name);


--
-- Name: categories categories_id_key; Type: CONSTRAINT; Schema: public; Owner: dbgroup1
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_id_key UNIQUE (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: dbgroup1
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id, cat_name);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: dbgroup1
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (brewery_id, brew_lat, brew_long);


--
-- Name: recipes recipes_pkey; Type: CONSTRAINT; Schema: public; Owner: dbgroup1
--

ALTER TABLE ONLY public.recipes
    ADD CONSTRAINT recipes_pkey PRIMARY KEY (title);


--
-- Name: styles styles_id_key; Type: CONSTRAINT; Schema: public; Owner: dbgroup1
--

ALTER TABLE ONLY public.styles
    ADD CONSTRAINT styles_id_key UNIQUE (id);


--
-- Name: styles styles_pkey; Type: CONSTRAINT; Schema: public; Owner: dbgroup1
--

ALTER TABLE ONLY public.styles
    ADD CONSTRAINT styles_pkey PRIMARY KEY (id, style_name);


--
-- Name: beers beers_brewery_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dbgroup1
--

ALTER TABLE ONLY public.beers
    ADD CONSTRAINT beers_brewery_id_fkey FOREIGN KEY (brewery_id) REFERENCES public.breweries(id);


--
-- Name: beers beers_cat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dbgroup1
--

ALTER TABLE ONLY public.beers
    ADD CONSTRAINT beers_cat_id_fkey FOREIGN KEY (cat_id) REFERENCES public.categories(id);


--
-- Name: beers beers_style_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dbgroup1
--

ALTER TABLE ONLY public.beers
    ADD CONSTRAINT beers_style_id_fkey FOREIGN KEY (style_id) REFERENCES public.styles(id);


--
-- Name: beers c1; Type: FK CONSTRAINT; Schema: public; Owner: dbgroup1
--

ALTER TABLE ONLY public.beers
    ADD CONSTRAINT c1 FOREIGN KEY (brewery_id) REFERENCES public.breweries(id);


--
-- Name: pairings pairings_cat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dbgroup1
--

ALTER TABLE ONLY public.pairings
    ADD CONSTRAINT pairings_cat_id_fkey FOREIGN KEY (cat_id) REFERENCES public.categories(id);


--
-- Name: styles styles_cat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dbgroup1
--

ALTER TABLE ONLY public.styles
    ADD CONSTRAINT styles_cat_id_fkey FOREIGN KEY (cat_id) REFERENCES public.categories(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

