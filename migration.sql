-- 1 up
CREATE TABLE IF NOT EXISTS public.url (
	id int primary key GENERATED ALWAYS AS IDENTITY,
	location varchar(1000) NOT NULL,
	code integer NOT NULL DEFAULT 0, -- 0   - Mojo::UserAgent hasn't visited the address yet
									         -- > 0 - address verified
	content text DEFAULT NULL,
	created_at timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc'),
	updated_at timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc'),
	headers jsonb
);
ALTER TABLE public.url OWNER TO sevstar;
-- CREATE SEQUENCE public.url_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
-- ALTER TABLE public.url_id_seq OWNER TO sevstar;
-- ALTER SEQUENCE public.url_id_seq OWNED BY public.url.id;
-- ALTER TABLE ONLY public.url ALTER COLUMN id SET DEFAULT nextval('public.url_id_seq'::regclass);
-- SELECT pg_catalog.setval('public.url_id_seq', 1, false);

-- ALTER TABLE ONLY public.url ADD CONSTRAINT url_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.url ADD CONSTRAINT url_location_key UNIQUE (location);

CREATE OR REPLACE FUNCTION last_upd_trig() RETURNS trigger
   LANGUAGE plpgsql AS
$$BEGIN
   NEW.updated_at := current_timestamp at time zone 'utc';
   RETURN NEW;
END;$$;

CREATE TRIGGER last_upd_trigger
   BEFORE INSERT OR UPDATE ON url
   FOR EACH ROW
   EXECUTE PROCEDURE last_upd_trig();

--1 down
DROP TABLE IF EXISTS public.url CASCADE;
DROP FUNCTION IF EXISTS last_upd_trig;
