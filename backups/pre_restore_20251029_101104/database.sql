--
-- PostgreSQL database dump
--

\restrict 4QlaJGdDQ9YeicgXy3juuWXDgEDpaYiq8mk8nLZL9rPs8Xu741Car5rt1GC3C8H

-- Dumped from database version 15.14
-- Dumped by pg_dump version 15.14

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
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: update_last_seen(); Type: FUNCTION; Schema: public; Owner: recon_user
--

CREATE FUNCTION public.update_last_seen() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.last_seen = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_last_seen() OWNER TO recon_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: annotation_tag_entity; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.annotation_tag_entity (
    id character varying(16) NOT NULL,
    name character varying(24) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.annotation_tag_entity OWNER TO recon_user;

--
-- Name: auth_identity; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.auth_identity (
    "userId" uuid,
    "providerId" character varying(64) NOT NULL,
    "providerType" character varying(32) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.auth_identity OWNER TO recon_user;

--
-- Name: auth_provider_sync_history; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.auth_provider_sync_history (
    id integer NOT NULL,
    "providerType" character varying(32) NOT NULL,
    "runMode" text NOT NULL,
    status text NOT NULL,
    "startedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "endedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    scanned integer NOT NULL,
    created integer NOT NULL,
    updated integer NOT NULL,
    disabled integer NOT NULL,
    error text
);


ALTER TABLE public.auth_provider_sync_history OWNER TO recon_user;

--
-- Name: auth_provider_sync_history_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

CREATE SEQUENCE public.auth_provider_sync_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_provider_sync_history_id_seq OWNER TO recon_user;

--
-- Name: auth_provider_sync_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: recon_user
--

ALTER SEQUENCE public.auth_provider_sync_history_id_seq OWNED BY public.auth_provider_sync_history.id;


--
-- Name: chat_hub_messages; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.chat_hub_messages (
    id uuid NOT NULL,
    "sessionId" uuid NOT NULL,
    "previousMessageId" uuid,
    "revisionOfMessageId" uuid,
    "retryOfMessageId" uuid,
    type character varying(16) NOT NULL,
    name character varying(128) NOT NULL,
    content text NOT NULL,
    provider character varying(16),
    model character varying(64),
    "workflowId" character varying(36),
    "executionId" integer,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    status character varying(16) DEFAULT 'success'::character varying NOT NULL
);


ALTER TABLE public.chat_hub_messages OWNER TO recon_user;

--
-- Name: COLUMN chat_hub_messages.type; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.chat_hub_messages.type IS 'ChatHubMessageType enum: "human", "ai", "system", "tool", "generic"';


--
-- Name: COLUMN chat_hub_messages.provider; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.chat_hub_messages.provider IS 'ChatHubProvider enum: "openai", "anthropic", "google", "n8n"';


--
-- Name: COLUMN chat_hub_messages.model; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.chat_hub_messages.model IS 'Model name used at the respective Model node, ie. "gpt-4"';


--
-- Name: COLUMN chat_hub_messages.status; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.chat_hub_messages.status IS 'ChatHubMessageStatus enum, eg. "success", "error", "running", "cancelled"';


--
-- Name: chat_hub_sessions; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.chat_hub_sessions (
    id uuid NOT NULL,
    title character varying(256) NOT NULL,
    "ownerId" uuid NOT NULL,
    "lastMessageAt" timestamp(3) with time zone,
    "credentialId" character varying(36),
    provider character varying(16),
    model character varying(64),
    "workflowId" character varying(36),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.chat_hub_sessions OWNER TO recon_user;

--
-- Name: COLUMN chat_hub_sessions.provider; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.chat_hub_sessions.provider IS 'ChatHubProvider enum: "openai", "anthropic", "google", "n8n"';


--
-- Name: COLUMN chat_hub_sessions.model; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.chat_hub_sessions.model IS 'Model name used at the respective Model node, ie. "gpt-4"';


--
-- Name: credentials; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.credentials (
    id integer NOT NULL,
    target character varying(255) NOT NULL,
    username character varying(255),
    password text,
    hash text,
    service character varying(100),
    protocol character varying(50),
    status character varying(20),
    discovered_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.credentials OWNER TO recon_user;

--
-- Name: TABLE credentials; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON TABLE public.credentials IS 'Discovered or cracked credentials';


--
-- Name: credentials_entity; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.credentials_entity (
    name character varying(128) NOT NULL,
    data text NOT NULL,
    type character varying(128) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    id character varying(36) NOT NULL,
    "isManaged" boolean DEFAULT false NOT NULL
);


ALTER TABLE public.credentials_entity OWNER TO recon_user;

--
-- Name: credentials_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

CREATE SEQUENCE public.credentials_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.credentials_id_seq OWNER TO recon_user;

--
-- Name: credentials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: recon_user
--

ALTER SEQUENCE public.credentials_id_seq OWNED BY public.credentials.id;


--
-- Name: data_table; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.data_table (
    id character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    "projectId" character varying(36) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.data_table OWNER TO recon_user;

--
-- Name: data_table_column; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.data_table_column (
    id character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    type character varying(32) NOT NULL,
    index integer NOT NULL,
    "dataTableId" character varying(36) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.data_table_column OWNER TO recon_user;

--
-- Name: COLUMN data_table_column.type; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.data_table_column.type IS 'Expected: string, number, boolean, or date (not enforced as a constraint)';


--
-- Name: COLUMN data_table_column.index; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.data_table_column.index IS 'Column order, starting from 0 (0 = first column)';


--
-- Name: event_destinations; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.event_destinations (
    id uuid NOT NULL,
    destination jsonb NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.event_destinations OWNER TO recon_user;

--
-- Name: execution_annotation_tags; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.execution_annotation_tags (
    "annotationId" integer NOT NULL,
    "tagId" character varying(24) NOT NULL
);


ALTER TABLE public.execution_annotation_tags OWNER TO recon_user;

--
-- Name: execution_annotations; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.execution_annotations (
    id integer NOT NULL,
    "executionId" integer NOT NULL,
    vote character varying(6),
    note text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.execution_annotations OWNER TO recon_user;

--
-- Name: execution_annotations_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

CREATE SEQUENCE public.execution_annotations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.execution_annotations_id_seq OWNER TO recon_user;

--
-- Name: execution_annotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: recon_user
--

ALTER SEQUENCE public.execution_annotations_id_seq OWNED BY public.execution_annotations.id;


--
-- Name: execution_data; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.execution_data (
    "executionId" integer NOT NULL,
    "workflowData" json NOT NULL,
    data text NOT NULL
);


ALTER TABLE public.execution_data OWNER TO recon_user;

--
-- Name: execution_entity; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.execution_entity (
    id integer NOT NULL,
    finished boolean NOT NULL,
    mode character varying NOT NULL,
    "retryOf" character varying,
    "retrySuccessId" character varying,
    "startedAt" timestamp(3) with time zone,
    "stoppedAt" timestamp(3) with time zone,
    "waitTill" timestamp(3) with time zone,
    status character varying NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    "deletedAt" timestamp(3) with time zone,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.execution_entity OWNER TO recon_user;

--
-- Name: execution_entity_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

CREATE SEQUENCE public.execution_entity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.execution_entity_id_seq OWNER TO recon_user;

--
-- Name: execution_entity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: recon_user
--

ALTER SEQUENCE public.execution_entity_id_seq OWNED BY public.execution_entity.id;


--
-- Name: execution_metadata; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.execution_metadata (
    id integer NOT NULL,
    "executionId" integer NOT NULL,
    key character varying(255) NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.execution_metadata OWNER TO recon_user;

--
-- Name: execution_metadata_temp_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

CREATE SEQUENCE public.execution_metadata_temp_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.execution_metadata_temp_id_seq OWNER TO recon_user;

--
-- Name: execution_metadata_temp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: recon_user
--

ALTER SEQUENCE public.execution_metadata_temp_id_seq OWNED BY public.execution_metadata.id;


--
-- Name: folder; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.folder (
    id character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    "parentFolderId" character varying(36),
    "projectId" character varying(36) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.folder OWNER TO recon_user;

--
-- Name: folder_tag; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.folder_tag (
    "folderId" character varying(36) NOT NULL,
    "tagId" character varying(36) NOT NULL
);


ALTER TABLE public.folder_tag OWNER TO recon_user;

--
-- Name: fuzzing_results; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.fuzzing_results (
    id integer NOT NULL,
    target_url text NOT NULL,
    path text,
    status_code integer,
    content_length integer,
    content_type character varying(100),
    redirect_location text,
    discovered_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.fuzzing_results OWNER TO recon_user;

--
-- Name: TABLE fuzzing_results; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON TABLE public.fuzzing_results IS 'Web fuzzing results from ffuf, dirb, etc';


--
-- Name: fuzzing_results_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

CREATE SEQUENCE public.fuzzing_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fuzzing_results_id_seq OWNER TO recon_user;

--
-- Name: fuzzing_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: recon_user
--

ALTER SEQUENCE public.fuzzing_results_id_seq OWNED BY public.fuzzing_results.id;


--
-- Name: insights_by_period; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.insights_by_period (
    id integer NOT NULL,
    "metaId" integer NOT NULL,
    type integer NOT NULL,
    value bigint NOT NULL,
    "periodUnit" integer NOT NULL,
    "periodStart" timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.insights_by_period OWNER TO recon_user;

--
-- Name: COLUMN insights_by_period.type; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.insights_by_period.type IS '0: time_saved_minutes, 1: runtime_milliseconds, 2: success, 3: failure';


--
-- Name: COLUMN insights_by_period."periodUnit"; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.insights_by_period."periodUnit" IS '0: hour, 1: day, 2: week';


--
-- Name: insights_by_period_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

ALTER TABLE public.insights_by_period ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.insights_by_period_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: insights_metadata; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.insights_metadata (
    "metaId" integer NOT NULL,
    "workflowId" character varying(16),
    "projectId" character varying(36),
    "workflowName" character varying(128) NOT NULL,
    "projectName" character varying(255) NOT NULL
);


ALTER TABLE public.insights_metadata OWNER TO recon_user;

--
-- Name: insights_metadata_metaId_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

ALTER TABLE public.insights_metadata ALTER COLUMN "metaId" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public."insights_metadata_metaId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: insights_raw; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.insights_raw (
    id integer NOT NULL,
    "metaId" integer NOT NULL,
    type integer NOT NULL,
    value bigint NOT NULL,
    "timestamp" timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.insights_raw OWNER TO recon_user;

--
-- Name: COLUMN insights_raw.type; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.insights_raw.type IS '0: time_saved_minutes, 1: runtime_milliseconds, 2: success, 3: failure';


--
-- Name: insights_raw_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

ALTER TABLE public.insights_raw ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.insights_raw_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: installed_nodes; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.installed_nodes (
    name character varying(200) NOT NULL,
    type character varying(200) NOT NULL,
    "latestVersion" integer DEFAULT 1 NOT NULL,
    package character varying(241) NOT NULL
);


ALTER TABLE public.installed_nodes OWNER TO recon_user;

--
-- Name: installed_packages; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.installed_packages (
    "packageName" character varying(214) NOT NULL,
    "installedVersion" character varying(50) NOT NULL,
    "authorName" character varying(70),
    "authorEmail" character varying(70),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.installed_packages OWNER TO recon_user;

--
-- Name: invalid_auth_token; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.invalid_auth_token (
    token character varying(512) NOT NULL,
    "expiresAt" timestamp(3) with time zone NOT NULL
);


ALTER TABLE public.invalid_auth_token OWNER TO recon_user;

--
-- Name: migrations; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    "timestamp" bigint NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.migrations OWNER TO recon_user;

--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.migrations_id_seq OWNER TO recon_user;

--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: recon_user
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: network_scans; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.network_scans (
    id integer NOT NULL,
    target character varying(255) NOT NULL,
    scan_type character varying(50),
    port integer,
    service character varying(100),
    version character varying(255),
    vulnerabilities text,
    scan_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.network_scans OWNER TO recon_user;

--
-- Name: TABLE network_scans; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON TABLE public.network_scans IS 'Network port scanning results from nmap, naabu';


--
-- Name: network_scans_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

CREATE SEQUENCE public.network_scans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.network_scans_id_seq OWNER TO recon_user;

--
-- Name: network_scans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: recon_user
--

ALTER SEQUENCE public.network_scans_id_seq OWNED BY public.network_scans.id;


--
-- Name: nuclei_results; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.nuclei_results (
    id integer NOT NULL,
    target character varying(255) NOT NULL,
    template_id character varying(255),
    template_name character varying(255),
    severity character varying(20),
    matched_at text,
    extracted_results text,
    curl_command text,
    scan_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.nuclei_results OWNER TO recon_user;

--
-- Name: TABLE nuclei_results; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON TABLE public.nuclei_results IS 'Nuclei vulnerability scanner results';


--
-- Name: nuclei_results_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

CREATE SEQUENCE public.nuclei_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.nuclei_results_id_seq OWNER TO recon_user;

--
-- Name: nuclei_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: recon_user
--

ALTER SEQUENCE public.nuclei_results_id_seq OWNED BY public.nuclei_results.id;


--
-- Name: processed_data; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.processed_data (
    "workflowId" character varying(36) NOT NULL,
    context character varying(255) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.processed_data OWNER TO recon_user;

--
-- Name: project; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.project (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(36) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    icon json,
    description character varying(512)
);


ALTER TABLE public.project OWNER TO recon_user;

--
-- Name: project_relation; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.project_relation (
    "projectId" character varying(36) NOT NULL,
    "userId" uuid NOT NULL,
    role character varying NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.project_relation OWNER TO recon_user;

--
-- Name: recon_sessions; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.recon_sessions (
    id integer NOT NULL,
    session_name character varying(255) NOT NULL,
    target_scope text,
    start_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    end_date timestamp without time zone,
    status character varying(50) DEFAULT 'active'::character varying,
    notes text
);


ALTER TABLE public.recon_sessions OWNER TO recon_user;

--
-- Name: TABLE recon_sessions; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON TABLE public.recon_sessions IS 'Tracking different reconnaissance campaigns';


--
-- Name: recon_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

CREATE SEQUENCE public.recon_sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.recon_sessions_id_seq OWNER TO recon_user;

--
-- Name: recon_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: recon_user
--

ALTER SEQUENCE public.recon_sessions_id_seq OWNED BY public.recon_sessions.id;


--
-- Name: role; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.role (
    slug character varying(128) NOT NULL,
    "displayName" text,
    description text,
    "roleType" text,
    "systemRole" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.role OWNER TO recon_user;

--
-- Name: COLUMN role.slug; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.role.slug IS 'Unique identifier of the role for example: "global:owner"';


--
-- Name: COLUMN role."displayName"; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.role."displayName" IS 'Name used to display in the UI';


--
-- Name: COLUMN role.description; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.role.description IS 'Text describing the scope in more detail of users';


--
-- Name: COLUMN role."roleType"; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.role."roleType" IS 'Type of the role, e.g., global, project, or workflow';


--
-- Name: COLUMN role."systemRole"; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.role."systemRole" IS 'Indicates if the role is managed by the system and cannot be edited';


--
-- Name: role_scope; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.role_scope (
    "roleSlug" character varying(128) NOT NULL,
    "scopeSlug" character varying(128) NOT NULL
);


ALTER TABLE public.role_scope OWNER TO recon_user;

--
-- Name: scope; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.scope (
    slug character varying(128) NOT NULL,
    "displayName" text,
    description text
);


ALTER TABLE public.scope OWNER TO recon_user;

--
-- Name: COLUMN scope.slug; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.scope.slug IS 'Unique identifier of the scope for example: "project:create"';


--
-- Name: COLUMN scope."displayName"; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.scope."displayName" IS 'Name used to display in the UI';


--
-- Name: COLUMN scope.description; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.scope.description IS 'Text describing the scope in more detail of users';


--
-- Name: settings; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.settings (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    "loadOnStartup" boolean DEFAULT false NOT NULL
);


ALTER TABLE public.settings OWNER TO recon_user;

--
-- Name: shared_credentials; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.shared_credentials (
    "credentialsId" character varying(36) NOT NULL,
    "projectId" character varying(36) NOT NULL,
    role text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.shared_credentials OWNER TO recon_user;

--
-- Name: shared_workflow; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.shared_workflow (
    "workflowId" character varying(36) NOT NULL,
    "projectId" character varying(36) NOT NULL,
    role text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.shared_workflow OWNER TO recon_user;

--
-- Name: smb_enum; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.smb_enum (
    id integer NOT NULL,
    target character varying(255) NOT NULL,
    hostname character varying(255),
    domain character varying(255),
    smb_version character varying(100),
    shares text,
    users text,
    scan_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.smb_enum OWNER TO recon_user;

--
-- Name: TABLE smb_enum; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON TABLE public.smb_enum IS 'SMB enumeration results from NetExec';


--
-- Name: smb_enum_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

CREATE SEQUENCE public.smb_enum_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.smb_enum_id_seq OWNER TO recon_user;

--
-- Name: smb_enum_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: recon_user
--

ALTER SEQUENCE public.smb_enum_id_seq OWNED BY public.smb_enum.id;


--
-- Name: sqli_results; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.sqli_results (
    id integer NOT NULL,
    target_url text NOT NULL,
    parameter character varying(255),
    injection_type character varying(100),
    dbms character varying(100),
    payload text,
    database_name character varying(255),
    extracted_data text,
    discovered_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.sqli_results OWNER TO recon_user;

--
-- Name: TABLE sqli_results; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON TABLE public.sqli_results IS 'SQL injection vulnerability findings';


--
-- Name: sqli_results_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

CREATE SEQUENCE public.sqli_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sqli_results_id_seq OWNER TO recon_user;

--
-- Name: sqli_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: recon_user
--

ALTER SEQUENCE public.sqli_results_id_seq OWNED BY public.sqli_results.id;


--
-- Name: subdomain_intel; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.subdomain_intel (
    id integer NOT NULL,
    domain character varying(255) NOT NULL,
    subdomain character varying(255) NOT NULL,
    source character varying(100),
    ip character varying(45),
    http_status integer,
    discovered_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_seen timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.subdomain_intel OWNER TO recon_user;

--
-- Name: TABLE subdomain_intel; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON TABLE public.subdomain_intel IS 'Stores discovered subdomains and their metadata';


--
-- Name: subdomain_intel_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

CREATE SEQUENCE public.subdomain_intel_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.subdomain_intel_id_seq OWNER TO recon_user;

--
-- Name: subdomain_intel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: recon_user
--

ALTER SEQUENCE public.subdomain_intel_id_seq OWNED BY public.subdomain_intel.id;


--
-- Name: tag_entity; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.tag_entity (
    name character varying(24) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    id character varying(36) NOT NULL
);


ALTER TABLE public.tag_entity OWNER TO recon_user;

--
-- Name: test_case_execution; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.test_case_execution (
    id character varying(36) NOT NULL,
    "testRunId" character varying(36) NOT NULL,
    "executionId" integer,
    status character varying NOT NULL,
    "runAt" timestamp(3) with time zone,
    "completedAt" timestamp(3) with time zone,
    "errorCode" character varying,
    "errorDetails" json,
    metrics json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    inputs json,
    outputs json
);


ALTER TABLE public.test_case_execution OWNER TO recon_user;

--
-- Name: test_run; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.test_run (
    id character varying(36) NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    status character varying NOT NULL,
    "errorCode" character varying,
    "errorDetails" json,
    "runAt" timestamp(3) with time zone,
    "completedAt" timestamp(3) with time zone,
    metrics json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.test_run OWNER TO recon_user;

--
-- Name: user; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public."user" (
    id uuid DEFAULT uuid_in((OVERLAY(OVERLAY(md5((((random())::text || ':'::text) || (clock_timestamp())::text)) PLACING '4'::text FROM 13) PLACING to_hex((floor(((random() * (((11 - 8) + 1))::double precision) + (8)::double precision)))::integer) FROM 17))::cstring) NOT NULL,
    email character varying(255),
    "firstName" character varying(32),
    "lastName" character varying(32),
    password character varying(255),
    "personalizationAnswers" json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    settings json,
    disabled boolean DEFAULT false NOT NULL,
    "mfaEnabled" boolean DEFAULT false NOT NULL,
    "mfaSecret" text,
    "mfaRecoveryCodes" text,
    "lastActiveAt" date,
    "roleSlug" character varying(128) DEFAULT 'global:member'::character varying NOT NULL
);


ALTER TABLE public."user" OWNER TO recon_user;

--
-- Name: user_api_keys; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.user_api_keys (
    id character varying(36) NOT NULL,
    "userId" uuid NOT NULL,
    label character varying(100) NOT NULL,
    "apiKey" character varying NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    scopes json,
    audience character varying DEFAULT 'public-api'::character varying NOT NULL
);


ALTER TABLE public.user_api_keys OWNER TO recon_user;

--
-- Name: variables; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.variables (
    key character varying(50) NOT NULL,
    type character varying(50) DEFAULT 'string'::character varying NOT NULL,
    value character varying(255),
    id character varying(36) NOT NULL,
    "projectId" character varying(36)
);


ALTER TABLE public.variables OWNER TO recon_user;

--
-- Name: vulnerabilities; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.vulnerabilities (
    id integer NOT NULL,
    target character varying(255) NOT NULL,
    vulnerability_name character varying(255),
    severity character varying(20),
    cvss_score numeric(3,1),
    description text,
    cve_id character varying(50),
    remediation text,
    discovered_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.vulnerabilities OWNER TO recon_user;

--
-- Name: TABLE vulnerabilities; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON TABLE public.vulnerabilities IS 'Vulnerability scan results';


--
-- Name: vulnerabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

CREATE SEQUENCE public.vulnerabilities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.vulnerabilities_id_seq OWNER TO recon_user;

--
-- Name: vulnerabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: recon_user
--

ALTER SEQUENCE public.vulnerabilities_id_seq OWNED BY public.vulnerabilities.id;


--
-- Name: web_technologies; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.web_technologies (
    id integer NOT NULL,
    url text NOT NULL,
    technology character varying(255),
    version character varying(100),
    category character varying(100),
    discovered_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.web_technologies OWNER TO recon_user;

--
-- Name: TABLE web_technologies; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON TABLE public.web_technologies IS 'Detected web technologies and versions';


--
-- Name: web_technologies_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

CREATE SEQUENCE public.web_technologies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.web_technologies_id_seq OWNER TO recon_user;

--
-- Name: web_technologies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: recon_user
--

ALTER SEQUENCE public.web_technologies_id_seq OWNED BY public.web_technologies.id;


--
-- Name: webhook_entity; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.webhook_entity (
    "webhookPath" character varying NOT NULL,
    method character varying NOT NULL,
    node character varying NOT NULL,
    "webhookId" character varying,
    "pathLength" integer,
    "workflowId" character varying(36) NOT NULL
);


ALTER TABLE public.webhook_entity OWNER TO recon_user;

--
-- Name: workflow_dependency; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.workflow_dependency (
    id integer NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    "workflowVersionId" integer NOT NULL,
    "dependencyType" character varying(32) NOT NULL,
    "dependencyKey" character varying(255) NOT NULL,
    "dependencyInfo" character varying(255),
    "indexVersionId" smallint DEFAULT 1 NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.workflow_dependency OWNER TO recon_user;

--
-- Name: COLUMN workflow_dependency."workflowVersionId"; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.workflow_dependency."workflowVersionId" IS 'Version of the workflow';


--
-- Name: COLUMN workflow_dependency."dependencyType"; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.workflow_dependency."dependencyType" IS 'Type of dependency: "credential", "nodeType", "webhookPath", or "workflowCall"';


--
-- Name: COLUMN workflow_dependency."dependencyKey"; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.workflow_dependency."dependencyKey" IS 'ID or name of the dependency';


--
-- Name: COLUMN workflow_dependency."dependencyInfo"; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.workflow_dependency."dependencyInfo" IS 'Additional info about the dependency, interpreted based on type';


--
-- Name: COLUMN workflow_dependency."indexVersionId"; Type: COMMENT; Schema: public; Owner: recon_user
--

COMMENT ON COLUMN public.workflow_dependency."indexVersionId" IS 'Version of the index structure';


--
-- Name: workflow_dependency_id_seq; Type: SEQUENCE; Schema: public; Owner: recon_user
--

ALTER TABLE public.workflow_dependency ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.workflow_dependency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: workflow_entity; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.workflow_entity (
    name character varying(128) NOT NULL,
    active boolean NOT NULL,
    nodes json NOT NULL,
    connections json NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    settings json,
    "staticData" json,
    "pinData" json,
    "versionId" character(36),
    "triggerCount" integer DEFAULT 0 NOT NULL,
    id character varying(36) NOT NULL,
    meta json,
    "parentFolderId" character varying(36) DEFAULT NULL::character varying,
    "isArchived" boolean DEFAULT false NOT NULL
);


ALTER TABLE public.workflow_entity OWNER TO recon_user;

--
-- Name: workflow_history; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.workflow_history (
    "versionId" character varying(36) NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    authors character varying(255) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    nodes json NOT NULL,
    connections json NOT NULL
);


ALTER TABLE public.workflow_history OWNER TO recon_user;

--
-- Name: workflow_statistics; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.workflow_statistics (
    count integer DEFAULT 0,
    "latestEvent" timestamp(3) with time zone,
    name character varying(128) NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    "rootCount" integer DEFAULT 0
);


ALTER TABLE public.workflow_statistics OWNER TO recon_user;

--
-- Name: workflows_tags; Type: TABLE; Schema: public; Owner: recon_user
--

CREATE TABLE public.workflows_tags (
    "workflowId" character varying(36) NOT NULL,
    "tagId" character varying(36) NOT NULL
);


ALTER TABLE public.workflows_tags OWNER TO recon_user;

--
-- Name: auth_provider_sync_history id; Type: DEFAULT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.auth_provider_sync_history ALTER COLUMN id SET DEFAULT nextval('public.auth_provider_sync_history_id_seq'::regclass);


--
-- Name: credentials id; Type: DEFAULT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.credentials ALTER COLUMN id SET DEFAULT nextval('public.credentials_id_seq'::regclass);


--
-- Name: execution_annotations id; Type: DEFAULT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.execution_annotations ALTER COLUMN id SET DEFAULT nextval('public.execution_annotations_id_seq'::regclass);


--
-- Name: execution_entity id; Type: DEFAULT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.execution_entity ALTER COLUMN id SET DEFAULT nextval('public.execution_entity_id_seq'::regclass);


--
-- Name: execution_metadata id; Type: DEFAULT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.execution_metadata ALTER COLUMN id SET DEFAULT nextval('public.execution_metadata_temp_id_seq'::regclass);


--
-- Name: fuzzing_results id; Type: DEFAULT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.fuzzing_results ALTER COLUMN id SET DEFAULT nextval('public.fuzzing_results_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: network_scans id; Type: DEFAULT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.network_scans ALTER COLUMN id SET DEFAULT nextval('public.network_scans_id_seq'::regclass);


--
-- Name: nuclei_results id; Type: DEFAULT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.nuclei_results ALTER COLUMN id SET DEFAULT nextval('public.nuclei_results_id_seq'::regclass);


--
-- Name: recon_sessions id; Type: DEFAULT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.recon_sessions ALTER COLUMN id SET DEFAULT nextval('public.recon_sessions_id_seq'::regclass);


--
-- Name: smb_enum id; Type: DEFAULT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.smb_enum ALTER COLUMN id SET DEFAULT nextval('public.smb_enum_id_seq'::regclass);


--
-- Name: sqli_results id; Type: DEFAULT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.sqli_results ALTER COLUMN id SET DEFAULT nextval('public.sqli_results_id_seq'::regclass);


--
-- Name: subdomain_intel id; Type: DEFAULT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.subdomain_intel ALTER COLUMN id SET DEFAULT nextval('public.subdomain_intel_id_seq'::regclass);


--
-- Name: vulnerabilities id; Type: DEFAULT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.vulnerabilities ALTER COLUMN id SET DEFAULT nextval('public.vulnerabilities_id_seq'::regclass);


--
-- Name: web_technologies id; Type: DEFAULT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.web_technologies ALTER COLUMN id SET DEFAULT nextval('public.web_technologies_id_seq'::regclass);


--
-- Data for Name: annotation_tag_entity; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.annotation_tag_entity (id, name, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: auth_identity; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.auth_identity ("userId", "providerId", "providerType", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: auth_provider_sync_history; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.auth_provider_sync_history (id, "providerType", "runMode", status, "startedAt", "endedAt", scanned, created, updated, disabled, error) FROM stdin;
\.


--
-- Data for Name: chat_hub_messages; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.chat_hub_messages (id, "sessionId", "previousMessageId", "revisionOfMessageId", "retryOfMessageId", type, name, content, provider, model, "workflowId", "executionId", "createdAt", "updatedAt", status) FROM stdin;
\.


--
-- Data for Name: chat_hub_sessions; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.chat_hub_sessions (id, title, "ownerId", "lastMessageAt", "credentialId", provider, model, "workflowId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: credentials; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.credentials (id, target, username, password, hash, service, protocol, status, discovered_at) FROM stdin;
\.


--
-- Data for Name: credentials_entity; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.credentials_entity (name, data, type, "createdAt", "updatedAt", id, "isManaged") FROM stdin;
\.


--
-- Data for Name: data_table; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.data_table (id, name, "projectId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: data_table_column; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.data_table_column (id, name, type, index, "dataTableId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: event_destinations; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.event_destinations (id, destination, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: execution_annotation_tags; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.execution_annotation_tags ("annotationId", "tagId") FROM stdin;
\.


--
-- Data for Name: execution_annotations; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.execution_annotations (id, "executionId", vote, note, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: execution_data; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.execution_data ("executionId", "workflowData", data) FROM stdin;
1	{"id":"PKc7Cze7b557QkH5","name":"My workflow","active":false,"nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,64],"id":"84febbd6-6a33-4eac-8a08-3377b42c92ef","name":"When clicking ‘Execute workflow’"},{"parameters":{"notice":"","rule":{"interval":[{"field":"days","daysInterval":1,"triggerAtHour":0,"triggerAtMinute":0}]}},"type":"n8n-nodes-base.scheduleTrigger","typeVersion":1.2,"position":[-64,0],"id":"dda5f87f-3f0b-4475-9c98-92f92bccf57c","name":"Schedule Trigger"}],"connections":{},"settings":{"executionOrder":"v1"},"pinData":{}}	[{"startData":"1","resultData":"2","executionData":"3"},{"destinationNode":"4","runNodeFilter":"5"},{"runData":"6","pinData":"7","lastNodeExecuted":"4"},{"contextData":"8","nodeExecutionStack":"9","metadata":"10","waitingExecution":"11","waitingExecutionSource":"12"},"Schedule Trigger",["4"],{"Schedule Trigger":"13"},{},{},[],{},{},{},["14"],{"startTime":1761313039641,"executionIndex":0,"source":"15","hints":"16","executionTime":3,"executionStatus":"17","data":"18"},[],[],"success",{"main":"19"},["20"],["21"],{"json":"22","pairedItem":"23"},{"timestamp":"24","Readable date":"25","Readable time":"26","Day of week":"27","Year":"28","Month":"29","Day of month":"30","Hour":"31","Minute":"32","Second":"33","Timezone":"34"},{"item":0},"2025-10-24T13:37:19.643+00:00","October 24th 2025, 1:37:19 pm","1:37:19 pm","Friday","2025","October","24","13","37","19","UTC (UTC+00:00)"]
2	{"id":"PKc7Cze7b557QkH5","name":"My workflow","active":false,"nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,64],"id":"84febbd6-6a33-4eac-8a08-3377b42c92ef","name":"When clicking ‘Execute workflow’"},{"parameters":{"notice":"","rule":{"interval":[{"field":"days","daysInterval":1,"triggerAtHour":0,"triggerAtMinute":0}]}},"type":"n8n-nodes-base.scheduleTrigger","typeVersion":1.2,"position":[-64,0],"id":"dda5f87f-3f0b-4475-9c98-92f92bccf57c","name":"Schedule Trigger","alwaysOutputData":true,"notesInFlow":true}],"connections":{},"settings":{"executionOrder":"v1"},"pinData":{}}	[{"startData":"1","resultData":"2","executionData":"3"},{"destinationNode":"4","runNodeFilter":"5"},{"runData":"6","pinData":"7","lastNodeExecuted":"4"},{"contextData":"8","nodeExecutionStack":"9","metadata":"10","waitingExecution":"11","waitingExecutionSource":"12"},"Schedule Trigger",["4"],{"Schedule Trigger":"13"},{},{},[],{},{},{},["14"],{"startTime":1761313084319,"executionIndex":0,"source":"15","hints":"16","executionTime":1,"executionStatus":"17","data":"18"},[],[],"success",{"main":"19"},["20"],["21"],{"json":"22","pairedItem":"23"},{"timestamp":"24","Readable date":"25","Readable time":"26","Day of week":"27","Year":"28","Month":"29","Day of month":"30","Hour":"31","Minute":"32","Second":"33","Timezone":"34"},{"item":0},"2025-10-24T13:38:04.320+00:00","October 24th 2025, 1:38:04 pm","1:38:04 pm","Friday","2025","October","24","13","38","04","UTC (UTC+00:00)"]
3	{"id":"PKc7Cze7b557QkH5","name":"My workflow","active":false,"nodes":[{"parameters":{"pollTimes":{"item":[{"mode":"everyHour","minute":0}]},"event":"messageReceived","output":"simple","filters":{},"options":{}},"type":"n8n-nodes-base.microsoftOutlookTrigger","typeVersion":1,"position":[0,0],"id":"a533321b-7e78-4797-a9c3-14b9e3f2f818","name":"Microsoft Outlook Trigger","alwaysOutputData":false,"retryOnFail":false}],"connections":{},"settings":{"executionOrder":"v1"},"pinData":{}}	[{"startData":"1","resultData":"2","executionData":"3"},{},{"runData":"4","pinData":"5","lastNodeExecuted":"6","error":"7"},{"contextData":"8","nodeExecutionStack":"9","metadata":"10","waitingExecution":"11","waitingExecutionSource":"12"},{"Microsoft Outlook Trigger":"13"},{},"Microsoft Outlook Trigger",{"level":"14","tags":"15","timestamp":1761315845334,"context":"16","functionality":"17","name":"18","node":"19","messages":"20","httpCode":null,"message":"21","stack":"22"},{},["23"],{},{},{},["24"],"warning",{"reWrapped":true},{},"regular","NodeApiError",{"parameters":"25","type":"26","typeVersion":1,"position":"27","id":"28","name":"6","alwaysOutputData":false,"retryOnFail":false},["21"],"Node does not have any credentials set","NodeApiError: Node does not have any credentials set\\n    at PollContext.getPollResponse (/usr/local/lib/node_modules/n8n/node_modules/.pnpm/n8n-nodes-base@file+packages+nodes-base_@aws-sdk+credential-providers@3.808.0_asn1.js@5_afd197edb2c1f848eae21a96a97fab23/node_modules/n8n-nodes-base/nodes/Microsoft/Outlook/trigger/GenericFunctions.ts:79:9)\\n    at processTicksAndRejections (node:internal/process/task_queues:105:5)\\n    at PollContext.poll (/usr/local/lib/node_modules/n8n/node_modules/.pnpm/n8n-nodes-base@file+packages+nodes-base_@aws-sdk+credential-providers@3.808.0_asn1.js@5_afd197edb2c1f848eae21a96a97fab23/node_modules/n8n-nodes-base/nodes/Microsoft/Outlook/MicrosoftOutlookTrigger.node.ts:66:19)\\n    at WorkflowExecute.executePollNode (/usr/local/lib/node_modules/n8n/node_modules/.pnpm/n8n-core@file+packages+core_@opentelemetry+api@1.9.0_@opentelemetry+sdk-trace-base@1.30_08b575bec2313d5d8a4cc75358971443/node_modules/n8n-core/src/execution-engine/workflow-execute.ts:1141:19)\\n    at WorkflowExecute.runNode (/usr/local/lib/node_modules/n8n/node_modules/.pnpm/n8n-core@file+packages+core_@opentelemetry+api@1.9.0_@opentelemetry+sdk-trace-base@1.30_08b575bec2313d5d8a4cc75358971443/node_modules/n8n-core/src/execution-engine/workflow-execute.ts:1292:11)\\n    at /usr/local/lib/node_modules/n8n/node_modules/.pnpm/n8n-core@file+packages+core_@opentelemetry+api@1.9.0_@opentelemetry+sdk-trace-base@1.30_08b575bec2313d5d8a4cc75358971443/node_modules/n8n-core/src/execution-engine/workflow-execute.ts:1699:27\\n    at /usr/local/lib/node_modules/n8n/node_modules/.pnpm/n8n-core@file+packages+core_@opentelemetry+api@1.9.0_@opentelemetry+sdk-trace-base@1.30_08b575bec2313d5d8a4cc75358971443/node_modules/n8n-core/src/execution-engine/workflow-execute.ts:2315:11",{"node":"29","data":"30","source":null},{"startTime":1761315845332,"executionIndex":0,"source":"31","hints":"32","executionTime":22,"executionStatus":"33","error":"34"},{"pollTimes":"35","event":"36","output":"37","filters":"38","options":"39"},"n8n-nodes-base.microsoftOutlookTrigger",[0,0],"a533321b-7e78-4797-a9c3-14b9e3f2f818",{"parameters":"40","type":"26","typeVersion":1,"position":"41","id":"28","name":"6","alwaysOutputData":false,"retryOnFail":false},{"main":"42"},[],[],"error",{"level":"14","tags":"15","timestamp":1761315845334,"context":"16","functionality":"17","name":"18","node":"19","messages":"20","httpCode":null,"message":"21","stack":"22"},{"item":"43"},"messageReceived","simple",{},{},{"pollTimes":"44","event":"36","output":"37","filters":"45","options":"46"},[0,0],["47"],["48"],{"item":"49"},{},{},["50"],{"mode":"51","minute":0},["52"],{"json":"53","pairedItem":"54"},"everyHour",{"mode":"51","minute":0},{},{"item":0}]
\.


--
-- Data for Name: execution_entity; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.execution_entity (id, finished, mode, "retryOf", "retrySuccessId", "startedAt", "stoppedAt", "waitTill", status, "workflowId", "deletedAt", "createdAt") FROM stdin;
1	t	manual	\N	\N	2025-10-24 13:37:19.636+00	2025-10-24 13:37:19.645+00	\N	success	PKc7Cze7b557QkH5	\N	2025-10-24 13:37:19.627+00
2	t	manual	\N	\N	2025-10-24 13:38:04.317+00	2025-10-24 13:38:04.321+00	\N	success	PKc7Cze7b557QkH5	\N	2025-10-24 13:38:04.314+00
3	f	manual	\N	\N	2025-10-24 14:24:05.33+00	2025-10-24 14:24:05.354+00	\N	error	PKc7Cze7b557QkH5	\N	2025-10-24 14:24:05.326+00
\.


--
-- Data for Name: execution_metadata; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.execution_metadata (id, "executionId", key, value) FROM stdin;
\.


--
-- Data for Name: folder; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.folder (id, name, "parentFolderId", "projectId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: folder_tag; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.folder_tag ("folderId", "tagId") FROM stdin;
\.


--
-- Data for Name: fuzzing_results; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.fuzzing_results (id, target_url, path, status_code, content_length, content_type, redirect_location, discovered_at) FROM stdin;
\.


--
-- Data for Name: insights_by_period; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.insights_by_period (id, "metaId", type, value, "periodUnit", "periodStart") FROM stdin;
\.


--
-- Data for Name: insights_metadata; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.insights_metadata ("metaId", "workflowId", "projectId", "workflowName", "projectName") FROM stdin;
\.


--
-- Data for Name: insights_raw; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.insights_raw (id, "metaId", type, value, "timestamp") FROM stdin;
\.


--
-- Data for Name: installed_nodes; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.installed_nodes (name, type, "latestVersion", package) FROM stdin;
\.


--
-- Data for Name: installed_packages; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.installed_packages ("packageName", "installedVersion", "authorName", "authorEmail", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: invalid_auth_token; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.invalid_auth_token (token, "expiresAt") FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.migrations (id, "timestamp", name) FROM stdin;
1	1587669153312	InitialMigration1587669153312
2	1589476000887	WebhookModel1589476000887
3	1594828256133	CreateIndexStoppedAt1594828256133
4	1607431743768	MakeStoppedAtNullable1607431743768
5	1611144599516	AddWebhookId1611144599516
6	1617270242566	CreateTagEntity1617270242566
7	1620824779533	UniqueWorkflowNames1620824779533
8	1626176912946	AddwaitTill1626176912946
9	1630419189837	UpdateWorkflowCredentials1630419189837
10	1644422880309	AddExecutionEntityIndexes1644422880309
11	1646834195327	IncreaseTypeVarcharLimit1646834195327
12	1646992772331	CreateUserManagement1646992772331
13	1648740597343	LowerCaseUserEmail1648740597343
14	1652254514002	CommunityNodes1652254514002
15	1652367743993	AddUserSettings1652367743993
16	1652905585850	AddAPIKeyColumn1652905585850
17	1654090467022	IntroducePinData1654090467022
18	1658932090381	AddNodeIds1658932090381
19	1659902242948	AddJsonKeyPinData1659902242948
20	1660062385367	CreateCredentialsUserRole1660062385367
21	1663755770893	CreateWorkflowsEditorRole1663755770893
22	1664196174001	WorkflowStatistics1664196174001
23	1665484192212	CreateCredentialUsageTable1665484192212
24	1665754637025	RemoveCredentialUsageTable1665754637025
25	1669739707126	AddWorkflowVersionIdColumn1669739707126
26	1669823906995	AddTriggerCountColumn1669823906995
27	1671535397530	MessageEventBusDestinations1671535397530
28	1671726148421	RemoveWorkflowDataLoadedFlag1671726148421
29	1673268682475	DeleteExecutionsWithWorkflows1673268682475
30	1674138566000	AddStatusToExecutions1674138566000
31	1674509946020	CreateLdapEntities1674509946020
32	1675940580449	PurgeInvalidWorkflowConnections1675940580449
33	1676996103000	MigrateExecutionStatus1676996103000
34	1677236854063	UpdateRunningExecutionStatus1677236854063
35	1677501636754	CreateVariables1677501636754
36	1679416281778	CreateExecutionMetadataTable1679416281778
37	1681134145996	AddUserActivatedProperty1681134145996
38	1681134145997	RemoveSkipOwnerSetup1681134145997
39	1690000000000	MigrateIntegerKeysToString1690000000000
40	1690000000020	SeparateExecutionData1690000000020
41	1690000000030	RemoveResetPasswordColumns1690000000030
42	1690000000030	AddMfaColumns1690000000030
43	1690787606731	AddMissingPrimaryKeyOnExecutionData1690787606731
44	1691088862123	CreateWorkflowNameIndex1691088862123
45	1692967111175	CreateWorkflowHistoryTable1692967111175
46	1693491613982	ExecutionSoftDelete1693491613982
47	1693554410387	DisallowOrphanExecutions1693554410387
48	1694091729095	MigrateToTimestampTz1694091729095
49	1695128658538	AddWorkflowMetadata1695128658538
50	1695829275184	ModifyWorkflowHistoryNodesAndConnections1695829275184
51	1700571993961	AddGlobalAdminRole1700571993961
52	1705429061930	DropRoleMapping1705429061930
53	1711018413374	RemoveFailedExecutionStatus1711018413374
54	1711390882123	MoveSshKeysToDatabase1711390882123
55	1712044305787	RemoveNodesAccess1712044305787
56	1714133768519	CreateProject1714133768519
57	1714133768521	MakeExecutionStatusNonNullable1714133768521
58	1717498465931	AddActivatedAtUserSetting1717498465931
59	1720101653148	AddConstraintToExecutionMetadata1720101653148
60	1721377157740	FixExecutionMetadataSequence1721377157740
61	1723627610222	CreateInvalidAuthTokenTable1723627610222
62	1723796243146	RefactorExecutionIndices1723796243146
63	1724753530828	CreateAnnotationTables1724753530828
64	1724951148974	AddApiKeysTable1724951148974
65	1726606152711	CreateProcessedDataTable1726606152711
66	1727427440136	SeparateExecutionCreationFromStart1727427440136
67	1728659839644	AddMissingPrimaryKeyOnAnnotationTagMapping1728659839644
68	1729607673464	UpdateProcessedDataValueColumnToText1729607673464
69	1729607673469	AddProjectIcons1729607673469
70	1730386903556	CreateTestDefinitionTable1730386903556
71	1731404028106	AddDescriptionToTestDefinition1731404028106
72	1731582748663	MigrateTestDefinitionKeyToString1731582748663
73	1732271325258	CreateTestMetricTable1732271325258
74	1732549866705	CreateTestRun1732549866705
75	1733133775640	AddMockedNodesColumnToTestDefinition1733133775640
76	1734479635324	AddManagedColumnToCredentialsTable1734479635324
77	1736172058779	AddStatsColumnsToTestRun1736172058779
78	1736947513045	CreateTestCaseExecutionTable1736947513045
79	1737715421462	AddErrorColumnsToTestRuns1737715421462
80	1738709609940	CreateFolderTable1738709609940
81	1739549398681	CreateAnalyticsTables1739549398681
82	1740445074052	UpdateParentFolderIdColumn1740445074052
83	1741167584277	RenameAnalyticsToInsights1741167584277
84	1742918400000	AddScopesColumnToApiKeys1742918400000
85	1745322634000	ClearEvaluation1745322634000
86	1745587087521	AddWorkflowStatisticsRootCount1745587087521
87	1745934666076	AddWorkflowArchivedColumn1745934666076
88	1745934666077	DropRoleTable1745934666077
89	1747824239000	AddProjectDescriptionColumn1747824239000
90	1750252139166	AddLastActiveAtColumnToUser1750252139166
91	1750252139166	AddScopeTables1750252139166
92	1750252139167	AddRolesTables1750252139167
93	1750252139168	LinkRoleToUserTable1750252139168
94	1750252139170	RemoveOldRoleColumn1750252139170
95	1752669793000	AddInputsOutputsToTestCaseExecution1752669793000
96	1753953244168	LinkRoleToProjectRelationTable1753953244168
97	1754475614601	CreateDataStoreTables1754475614601
98	1754475614602	ReplaceDataStoreTablesWithDataTables1754475614602
99	1756906557570	AddTimestampsToRoleAndRoleIndexes1756906557570
100	1758731786132	AddAudienceColumnToApiKeys1758731786132
101	1758794506893	AddProjectIdToVariableTable1758794506893
102	1759399811000	ChangeValueTypesForInsights1759399811000
103	1760019379982	CreateChatHubTables1760019379982
104	1760020838000	UniqueRoleNames1760020838000
105	1760314000000	CreateWorkflowDependencyTable1760314000000
106	1760965142113	DropUnusedChatHubColumns1760965142113
\.


--
-- Data for Name: network_scans; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.network_scans (id, target, scan_type, port, service, version, vulnerabilities, scan_date) FROM stdin;
\.


--
-- Data for Name: nuclei_results; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.nuclei_results (id, target, template_id, template_name, severity, matched_at, extracted_results, curl_command, scan_date) FROM stdin;
\.


--
-- Data for Name: processed_data; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.processed_data ("workflowId", context, "createdAt", "updatedAt", value) FROM stdin;
\.


--
-- Data for Name: project; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.project (id, name, type, "createdAt", "updatedAt", icon, description) FROM stdin;
fcGVQ9U2ccIBOmgj	tester tester <tester@tester.com>	personal	2025-10-23 22:08:39.548+00	2025-10-24 13:36:46.775+00	\N	\N
\.


--
-- Data for Name: project_relation; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.project_relation ("projectId", "userId", role, "createdAt", "updatedAt") FROM stdin;
fcGVQ9U2ccIBOmgj	b1177606-2ff6-4682-b071-fd5f7cede5ae	project:personalOwner	2025-10-23 22:08:39.548+00	2025-10-23 22:08:39.548+00
\.


--
-- Data for Name: recon_sessions; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.recon_sessions (id, session_name, target_scope, start_date, end_date, status, notes) FROM stdin;
\.


--
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.role (slug, "displayName", description, "roleType", "systemRole", "createdAt", "updatedAt") FROM stdin;
global:owner	Owner	Owner	global	t	2025-10-23 22:08:39.842+00	2025-10-23 22:08:39.892+00
global:admin	Admin	Admin	global	t	2025-10-23 22:08:39.842+00	2025-10-23 22:08:39.892+00
global:member	Member	Member	global	t	2025-10-23 22:08:39.842+00	2025-10-23 22:08:39.892+00
project:admin	Project Admin	Full control of settings, members, workflows, credentials and executions	project	t	2025-10-23 22:08:39.842+00	2025-10-23 22:08:39.902+00
project:personalOwner	Project Owner	Project Owner	project	t	2025-10-23 22:08:39.842+00	2025-10-23 22:08:39.902+00
project:editor	Project Editor	Create, edit, and delete workflows, credentials, and executions	project	t	2025-10-23 22:08:39.842+00	2025-10-23 22:08:39.902+00
project:viewer	Project Viewer	Read-only access to workflows, credentials, and executions	project	t	2025-10-23 22:08:39.842+00	2025-10-23 22:08:39.902+00
credential:owner	Credential Owner	Credential Owner	credential	t	2025-10-23 22:08:39.907+00	2025-10-23 22:08:39.907+00
credential:user	Credential User	Credential User	credential	t	2025-10-23 22:08:39.907+00	2025-10-23 22:08:39.907+00
workflow:owner	Workflow Owner	Workflow Owner	workflow	t	2025-10-23 22:08:39.908+00	2025-10-23 22:08:39.908+00
workflow:editor	Workflow Editor	Workflow Editor	workflow	t	2025-10-23 22:08:39.908+00	2025-10-23 22:08:39.908+00
\.


--
-- Data for Name: role_scope; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.role_scope ("roleSlug", "scopeSlug") FROM stdin;
global:owner	annotationTag:create
global:owner	annotationTag:read
global:owner	annotationTag:update
global:owner	annotationTag:delete
global:owner	annotationTag:list
global:owner	auditLogs:manage
global:owner	banner:dismiss
global:owner	community:register
global:owner	communityPackage:install
global:owner	communityPackage:uninstall
global:owner	communityPackage:update
global:owner	communityPackage:list
global:owner	credential:share
global:owner	credential:move
global:owner	credential:create
global:owner	credential:read
global:owner	credential:update
global:owner	credential:delete
global:owner	credential:list
global:owner	externalSecretsProvider:sync
global:owner	externalSecretsProvider:create
global:owner	externalSecretsProvider:read
global:owner	externalSecretsProvider:update
global:owner	externalSecretsProvider:delete
global:owner	externalSecretsProvider:list
global:owner	externalSecret:list
global:owner	externalSecret:use
global:owner	eventBusDestination:test
global:owner	eventBusDestination:create
global:owner	eventBusDestination:read
global:owner	eventBusDestination:update
global:owner	eventBusDestination:delete
global:owner	eventBusDestination:list
global:owner	ldap:sync
global:owner	ldap:manage
global:owner	license:manage
global:owner	logStreaming:manage
global:owner	orchestration:read
global:owner	project:create
global:owner	project:read
global:owner	project:update
global:owner	project:delete
global:owner	project:list
global:owner	saml:manage
global:owner	securityAudit:generate
global:owner	sourceControl:pull
global:owner	sourceControl:push
global:owner	sourceControl:manage
global:owner	tag:create
global:owner	tag:read
global:owner	tag:update
global:owner	tag:delete
global:owner	tag:list
global:owner	user:resetPassword
global:owner	user:changeRole
global:owner	user:enforceMfa
global:owner	user:create
global:owner	user:read
global:owner	user:update
global:owner	user:delete
global:owner	user:list
global:owner	variable:create
global:owner	variable:read
global:owner	variable:update
global:owner	variable:delete
global:owner	variable:list
global:owner	projectVariable:create
global:owner	projectVariable:read
global:owner	projectVariable:update
global:owner	projectVariable:delete
global:owner	projectVariable:list
global:owner	workersView:manage
global:owner	workflow:share
global:owner	workflow:execute
global:owner	workflow:move
global:owner	workflow:create
global:owner	workflow:read
global:owner	workflow:update
global:owner	workflow:delete
global:owner	workflow:list
global:owner	folder:create
global:owner	folder:read
global:owner	folder:update
global:owner	folder:delete
global:owner	folder:list
global:owner	folder:move
global:owner	insights:list
global:owner	oidc:manage
global:owner	dataTable:list
global:owner	role:manage
global:owner	mcp:manage
global:owner	mcpApiKey:create
global:owner	mcpApiKey:rotate
global:owner	chatHub:manage
global:owner	chatHub:message
global:admin	annotationTag:create
global:admin	annotationTag:read
global:admin	annotationTag:update
global:admin	annotationTag:delete
global:admin	annotationTag:list
global:admin	auditLogs:manage
global:admin	banner:dismiss
global:admin	community:register
global:admin	communityPackage:install
global:admin	communityPackage:uninstall
global:admin	communityPackage:update
global:admin	communityPackage:list
global:admin	credential:share
global:admin	credential:move
global:admin	credential:create
global:admin	credential:read
global:admin	credential:update
global:admin	credential:delete
global:admin	credential:list
global:admin	externalSecretsProvider:sync
global:admin	externalSecretsProvider:create
global:admin	externalSecretsProvider:read
global:admin	externalSecretsProvider:update
global:admin	externalSecretsProvider:delete
global:admin	externalSecretsProvider:list
global:admin	externalSecret:list
global:admin	externalSecret:use
global:admin	eventBusDestination:test
global:admin	eventBusDestination:create
global:admin	eventBusDestination:read
global:admin	eventBusDestination:update
global:admin	eventBusDestination:delete
global:admin	eventBusDestination:list
global:admin	ldap:sync
global:admin	ldap:manage
global:admin	license:manage
global:admin	logStreaming:manage
global:admin	orchestration:read
global:admin	project:create
global:admin	project:read
global:admin	project:update
global:admin	project:delete
global:admin	project:list
global:admin	saml:manage
global:admin	securityAudit:generate
global:admin	sourceControl:pull
global:admin	sourceControl:push
global:admin	sourceControl:manage
global:admin	tag:create
global:admin	tag:read
global:admin	tag:update
global:admin	tag:delete
global:admin	tag:list
global:admin	user:resetPassword
global:admin	user:changeRole
global:admin	user:enforceMfa
global:admin	user:create
global:admin	user:read
global:admin	user:update
global:admin	user:delete
global:admin	user:list
global:admin	variable:create
global:admin	variable:read
global:admin	variable:update
global:admin	variable:delete
global:admin	variable:list
global:admin	projectVariable:create
global:admin	projectVariable:read
global:admin	projectVariable:update
global:admin	projectVariable:delete
global:admin	projectVariable:list
global:admin	workersView:manage
global:admin	workflow:share
global:admin	workflow:execute
global:admin	workflow:move
global:admin	workflow:create
global:admin	workflow:read
global:admin	workflow:update
global:admin	workflow:delete
global:admin	workflow:list
global:admin	folder:create
global:admin	folder:read
global:admin	folder:update
global:admin	folder:delete
global:admin	folder:list
global:admin	folder:move
global:admin	insights:list
global:admin	oidc:manage
global:admin	dataTable:list
global:admin	role:manage
global:admin	mcp:manage
global:admin	mcpApiKey:create
global:admin	mcpApiKey:rotate
global:admin	chatHub:manage
global:admin	chatHub:message
global:member	annotationTag:create
global:member	annotationTag:read
global:member	annotationTag:update
global:member	annotationTag:delete
global:member	annotationTag:list
global:member	eventBusDestination:test
global:member	eventBusDestination:list
global:member	tag:create
global:member	tag:read
global:member	tag:update
global:member	tag:list
global:member	user:list
global:member	variable:read
global:member	variable:list
global:member	dataTable:list
global:member	mcpApiKey:create
global:member	mcpApiKey:rotate
global:member	chatHub:message
project:admin	credential:share
project:admin	credential:move
project:admin	credential:create
project:admin	credential:read
project:admin	credential:update
project:admin	credential:delete
project:admin	credential:list
project:admin	project:read
project:admin	project:update
project:admin	project:delete
project:admin	project:list
project:admin	sourceControl:push
project:admin	projectVariable:create
project:admin	projectVariable:read
project:admin	projectVariable:update
project:admin	projectVariable:delete
project:admin	projectVariable:list
project:admin	workflow:execute
project:admin	workflow:move
project:admin	workflow:create
project:admin	workflow:read
project:admin	workflow:update
project:admin	workflow:delete
project:admin	workflow:list
project:admin	folder:create
project:admin	folder:read
project:admin	folder:update
project:admin	folder:delete
project:admin	folder:list
project:admin	folder:move
project:admin	dataTable:create
project:admin	dataTable:read
project:admin	dataTable:update
project:admin	dataTable:delete
project:admin	dataTable:readRow
project:admin	dataTable:writeRow
project:admin	dataTable:listProject
project:personalOwner	credential:share
project:personalOwner	credential:move
project:personalOwner	credential:create
project:personalOwner	credential:read
project:personalOwner	credential:update
project:personalOwner	credential:delete
project:personalOwner	credential:list
project:personalOwner	project:read
project:personalOwner	project:list
project:personalOwner	workflow:share
project:personalOwner	workflow:execute
project:personalOwner	workflow:move
project:personalOwner	workflow:create
project:personalOwner	workflow:read
project:personalOwner	workflow:update
project:personalOwner	workflow:delete
project:personalOwner	workflow:list
project:personalOwner	folder:create
project:personalOwner	folder:read
project:personalOwner	folder:update
project:personalOwner	folder:delete
project:personalOwner	folder:list
project:personalOwner	folder:move
project:personalOwner	dataTable:create
project:personalOwner	dataTable:read
project:personalOwner	dataTable:update
project:personalOwner	dataTable:delete
project:personalOwner	dataTable:readRow
project:personalOwner	dataTable:writeRow
project:personalOwner	dataTable:listProject
project:editor	credential:create
project:editor	credential:read
project:editor	credential:update
project:editor	credential:delete
project:editor	credential:list
project:editor	project:read
project:editor	project:list
project:editor	projectVariable:create
project:editor	projectVariable:read
project:editor	projectVariable:update
project:editor	projectVariable:delete
project:editor	projectVariable:list
project:editor	workflow:execute
project:editor	workflow:create
project:editor	workflow:read
project:editor	workflow:update
project:editor	workflow:delete
project:editor	workflow:list
project:editor	folder:create
project:editor	folder:read
project:editor	folder:update
project:editor	folder:delete
project:editor	folder:list
project:editor	dataTable:create
project:editor	dataTable:read
project:editor	dataTable:update
project:editor	dataTable:delete
project:editor	dataTable:readRow
project:editor	dataTable:writeRow
project:editor	dataTable:listProject
project:viewer	credential:read
project:viewer	credential:list
project:viewer	project:read
project:viewer	project:list
project:viewer	projectVariable:read
project:viewer	projectVariable:list
project:viewer	workflow:read
project:viewer	workflow:list
project:viewer	folder:read
project:viewer	folder:list
project:viewer	dataTable:read
project:viewer	dataTable:readRow
project:viewer	dataTable:listProject
credential:owner	credential:share
credential:owner	credential:move
credential:owner	credential:read
credential:owner	credential:update
credential:owner	credential:delete
credential:user	credential:read
workflow:owner	workflow:share
workflow:owner	workflow:execute
workflow:owner	workflow:move
workflow:owner	workflow:read
workflow:owner	workflow:update
workflow:owner	workflow:delete
workflow:editor	workflow:execute
workflow:editor	workflow:read
workflow:editor	workflow:update
global:owner	provisioning:manage
global:admin	provisioning:manage
\.


--
-- Data for Name: scope; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.scope (slug, "displayName", description) FROM stdin;
annotationTag:create	Create Annotation Tag	Allows creating new annotation tags.
annotationTag:read	annotationTag:read	\N
annotationTag:update	annotationTag:update	\N
annotationTag:delete	annotationTag:delete	\N
annotationTag:list	annotationTag:list	\N
annotationTag:*	annotationTag:*	\N
auditLogs:manage	auditLogs:manage	\N
auditLogs:*	auditLogs:*	\N
banner:dismiss	banner:dismiss	\N
banner:*	banner:*	\N
community:register	community:register	\N
community:*	community:*	\N
communityPackage:install	communityPackage:install	\N
communityPackage:uninstall	communityPackage:uninstall	\N
communityPackage:update	communityPackage:update	\N
communityPackage:list	communityPackage:list	\N
communityPackage:manage	communityPackage:manage	\N
communityPackage:*	communityPackage:*	\N
credential:share	credential:share	\N
credential:move	credential:move	\N
credential:create	credential:create	\N
credential:read	credential:read	\N
credential:update	credential:update	\N
credential:delete	credential:delete	\N
credential:list	credential:list	\N
credential:*	credential:*	\N
externalSecretsProvider:sync	externalSecretsProvider:sync	\N
externalSecretsProvider:create	externalSecretsProvider:create	\N
externalSecretsProvider:read	externalSecretsProvider:read	\N
externalSecretsProvider:update	externalSecretsProvider:update	\N
externalSecretsProvider:delete	externalSecretsProvider:delete	\N
externalSecretsProvider:list	externalSecretsProvider:list	\N
externalSecretsProvider:*	externalSecretsProvider:*	\N
externalSecret:list	externalSecret:list	\N
externalSecret:use	externalSecret:use	\N
externalSecret:*	externalSecret:*	\N
eventBusDestination:test	eventBusDestination:test	\N
eventBusDestination:create	eventBusDestination:create	\N
eventBusDestination:read	eventBusDestination:read	\N
eventBusDestination:update	eventBusDestination:update	\N
eventBusDestination:delete	eventBusDestination:delete	\N
eventBusDestination:list	eventBusDestination:list	\N
eventBusDestination:*	eventBusDestination:*	\N
ldap:sync	ldap:sync	\N
ldap:manage	ldap:manage	\N
ldap:*	ldap:*	\N
license:manage	license:manage	\N
license:*	license:*	\N
logStreaming:manage	logStreaming:manage	\N
logStreaming:*	logStreaming:*	\N
orchestration:read	orchestration:read	\N
orchestration:list	orchestration:list	\N
orchestration:*	orchestration:*	\N
project:create	project:create	\N
project:read	project:read	\N
project:update	project:update	\N
project:delete	project:delete	\N
project:list	project:list	\N
project:*	project:*	\N
saml:manage	saml:manage	\N
saml:*	saml:*	\N
securityAudit:generate	securityAudit:generate	\N
securityAudit:*	securityAudit:*	\N
sourceControl:pull	sourceControl:pull	\N
sourceControl:push	sourceControl:push	\N
sourceControl:manage	sourceControl:manage	\N
sourceControl:*	sourceControl:*	\N
tag:create	tag:create	\N
tag:read	tag:read	\N
tag:update	tag:update	\N
tag:delete	tag:delete	\N
tag:list	tag:list	\N
tag:*	tag:*	\N
user:resetPassword	user:resetPassword	\N
user:changeRole	user:changeRole	\N
user:enforceMfa	user:enforceMfa	\N
user:create	user:create	\N
user:read	user:read	\N
user:update	user:update	\N
user:delete	user:delete	\N
user:list	user:list	\N
user:*	user:*	\N
variable:create	variable:create	\N
variable:read	variable:read	\N
variable:update	variable:update	\N
variable:delete	variable:delete	\N
variable:list	variable:list	\N
variable:*	variable:*	\N
projectVariable:create	projectVariable:create	\N
projectVariable:read	projectVariable:read	\N
projectVariable:update	projectVariable:update	\N
projectVariable:delete	projectVariable:delete	\N
projectVariable:list	projectVariable:list	\N
projectVariable:*	projectVariable:*	\N
workersView:manage	workersView:manage	\N
workersView:*	workersView:*	\N
workflow:share	workflow:share	\N
workflow:execute	workflow:execute	\N
workflow:move	workflow:move	\N
workflow:activate	workflow:activate	\N
workflow:deactivate	workflow:deactivate	\N
workflow:create	workflow:create	\N
workflow:read	workflow:read	\N
workflow:update	workflow:update	\N
workflow:delete	workflow:delete	\N
workflow:list	workflow:list	\N
workflow:*	workflow:*	\N
folder:create	folder:create	\N
folder:read	folder:read	\N
folder:update	folder:update	\N
folder:delete	folder:delete	\N
folder:list	folder:list	\N
folder:move	folder:move	\N
folder:*	folder:*	\N
insights:list	insights:list	\N
insights:*	insights:*	\N
oidc:manage	oidc:manage	\N
oidc:*	oidc:*	\N
dataTable:create	dataTable:create	\N
dataTable:read	dataTable:read	\N
dataTable:update	dataTable:update	\N
dataTable:delete	dataTable:delete	\N
dataTable:list	dataTable:list	\N
dataTable:readRow	dataTable:readRow	\N
dataTable:writeRow	dataTable:writeRow	\N
provisioning:manage	provisioning:manage	\N
dataTable:listProject	dataTable:listProject	\N
dataTable:*	dataTable:*	\N
execution:delete	execution:delete	\N
execution:read	execution:read	\N
execution:retry	execution:retry	\N
execution:list	execution:list	\N
execution:get	execution:get	\N
execution:*	execution:*	\N
workflowTags:update	workflowTags:update	\N
workflowTags:list	workflowTags:list	\N
workflowTags:*	workflowTags:*	\N
role:manage	role:manage	\N
role:*	role:*	\N
mcp:manage	mcp:manage	\N
mcp:*	mcp:*	\N
mcpApiKey:create	mcpApiKey:create	\N
mcpApiKey:rotate	mcpApiKey:rotate	\N
mcpApiKey:*	mcpApiKey:*	\N
chatHub:manage	chatHub:manage	\N
chatHub:message	chatHub:message	\N
chatHub:*	chatHub:*	\N
*	*	\N
provisioning:*	provisioning:*	\N
\.


--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.settings (key, value, "loadOnStartup") FROM stdin;
ui.banners.dismissed	["V1"]	t
features.ldap	{"loginEnabled":false,"loginLabel":"","connectionUrl":"","allowUnauthorizedCerts":false,"connectionSecurity":"none","connectionPort":389,"baseDn":"","bindingAdminDn":"","bindingAdminPassword":"","firstNameAttribute":"","lastNameAttribute":"","emailAttribute":"","loginIdAttribute":"","ldapIdAttribute":"","userFilter":"","synchronizationEnabled":false,"synchronizationInterval":60,"searchPageSize":0,"searchTimeout":60}	t
userManagement.authenticationMethod	email	t
features.sourceControl.sshKeys	{"encryptedPrivateKey":"U2FsdGVkX1/l0XXEoa/IJOapR1ONGpeDPhOfEDz4DG3dhD5bydf5aehfiUjrwG6kbhJOQaGJF9drKV1Z25scr/1U+aiTP2Z3yWGqq/+yJVVQ5lAVSv+HTU7Jq2AvX++0+ABlHbox3dj0mLUzYaFy54rHluf/RnEaZtqF3e5QsXiB2GZ6QqHDqUTirsfjRBt+1HPCXKImUi4D0rKmJQUH7IBENvMuWxRXNYec0ZNpoSxOH3ZYFppZr4mOmykWAu61Ma0KwVrccbiokIporV0yxQkO68y129teKJw2FCbCWR+5ex2T3N4alvBpfiSKOUvfLSNx9QtDdxyvpcI2gF9LSbfvZI1e6d7btPxLWs2TV0S27QtSuJC3wqL1vLRIpQG6PC2ZL0Ohpp7MO57fvMouTLA5ruJFz/G/S96/qAZ964vPp9y36ASErpyD/vicukUnQxhAPs4A/Ap8ulEXT8qQ5BZopmJocogtQOlP7pmcbWQM8eNYH0LB/N+YMShTmN20iI8iFXelQVW1e4UoeCjAvioGZUNHpljo0FHeifZ5aXcACALHRtM/sedRrR/1QKLb","publicKey":"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFcB8SsaT1+uldrvWXV3BnMLoKGUyHquCbsREeEd6CDS n8n deploy key"}	t
features.sourceControl	{"branchName":"main","connectionType":"ssh","keyGeneratorType":"ed25519"}	t
userManagement.isInstanceOwnerSetUp	true	t
\.


--
-- Data for Name: shared_credentials; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.shared_credentials ("credentialsId", "projectId", role, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: shared_workflow; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.shared_workflow ("workflowId", "projectId", role, "createdAt", "updatedAt") FROM stdin;
PKc7Cze7b557QkH5	fcGVQ9U2ccIBOmgj	workflow:owner	2025-10-24 13:37:19.55+00	2025-10-24 13:37:19.55+00
\.


--
-- Data for Name: smb_enum; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.smb_enum (id, target, hostname, domain, smb_version, shares, users, scan_date) FROM stdin;
\.


--
-- Data for Name: sqli_results; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.sqli_results (id, target_url, parameter, injection_type, dbms, payload, database_name, extracted_data, discovered_at) FROM stdin;
\.


--
-- Data for Name: subdomain_intel; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.subdomain_intel (id, domain, subdomain, source, ip, http_status, discovered_at, last_seen) FROM stdin;
\.


--
-- Data for Name: tag_entity; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.tag_entity (name, "createdAt", "updatedAt", id) FROM stdin;
\.


--
-- Data for Name: test_case_execution; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.test_case_execution (id, "testRunId", "executionId", status, "runAt", "completedAt", "errorCode", "errorDetails", metrics, "createdAt", "updatedAt", inputs, outputs) FROM stdin;
\.


--
-- Data for Name: test_run; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.test_run (id, "workflowId", status, "errorCode", "errorDetails", "runAt", "completedAt", metrics, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public."user" (id, email, "firstName", "lastName", password, "personalizationAnswers", "createdAt", "updatedAt", settings, disabled, "mfaEnabled", "mfaSecret", "mfaRecoveryCodes", "lastActiveAt", "roleSlug") FROM stdin;
c980f87a-c42f-4271-bea2-7d0a48f72c45	test@example.com	Test	User	$2a$10$1j63MkdaOdxQ9uHAAFjX3O2IqjFMUhGZPnWApOr/1FH57g1.p6hh2	\N	2025-10-28 18:13:16.108+00	2025-10-28 18:13:16.108+00	\N	f	f	\N	\N	\N	global:member
b1177606-2ff6-4682-b071-fd5f7cede5ae	tester@tester.com	tester	tester	$2a$10$E5UhWrPrWRh1Smv0CmCNLe6YxWy6V2AJfNTnGVK35/qi0SRMvEa/.	{"version":"v4","personalization_survey_submitted_at":"2025-10-24T13:36:51.746Z","personalization_survey_n8n_version":"1.116.2"}	2025-10-23 22:08:39.297+00	2025-10-29 13:10:17.41+00	{"userActivated": false}	f	f	\N	\N	2025-10-29	global:owner
\.


--
-- Data for Name: user_api_keys; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.user_api_keys (id, "userId", label, "apiKey", "createdAt", "updatedAt", scopes, audience) FROM stdin;
\.


--
-- Data for Name: variables; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.variables (key, type, value, id, "projectId") FROM stdin;
\.


--
-- Data for Name: vulnerabilities; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.vulnerabilities (id, target, vulnerability_name, severity, cvss_score, description, cve_id, remediation, discovered_at) FROM stdin;
\.


--
-- Data for Name: web_technologies; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.web_technologies (id, url, technology, version, category, discovered_at) FROM stdin;
\.


--
-- Data for Name: webhook_entity; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.webhook_entity ("webhookPath", method, node, "webhookId", "pathLength", "workflowId") FROM stdin;
\.


--
-- Data for Name: workflow_dependency; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.workflow_dependency (id, "workflowId", "workflowVersionId", "dependencyType", "dependencyKey", "dependencyInfo", "indexVersionId", "createdAt") FROM stdin;
\.


--
-- Data for Name: workflow_entity; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.workflow_entity (name, active, nodes, connections, "createdAt", "updatedAt", settings, "staticData", "pinData", "versionId", "triggerCount", id, meta, "parentFolderId", "isArchived") FROM stdin;
My workflow	f	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,64],"id":"84febbd6-6a33-4eac-8a08-3377b42c92ef","name":"When clicking ‘Execute workflow’"},{"parameters":{"rule":{"interval":[{}]}},"type":"n8n-nodes-base.scheduleTrigger","typeVersion":1.2,"position":[-64,0],"id":"dda5f87f-3f0b-4475-9c98-92f92bccf57c","name":"Schedule Trigger"}]	{}	2025-10-24 13:37:19.55+00	2025-10-24 13:37:19.55+00	{"executionOrder":"v1"}	\N	{}	be046aa1-769f-4207-a98a-bcbec281ed76	0	PKc7Cze7b557QkH5	\N	\N	f
\.


--
-- Data for Name: workflow_history; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.workflow_history ("versionId", "workflowId", authors, "createdAt", "updatedAt", nodes, connections) FROM stdin;
\.


--
-- Data for Name: workflow_statistics; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.workflow_statistics (count, "latestEvent", name, "workflowId", "rootCount") FROM stdin;
2	2025-10-24 13:38:04.333+00	manual_success	PKc7Cze7b557QkH5	0
1	2025-10-24 14:24:05.373+00	manual_error	PKc7Cze7b557QkH5	0
\.


--
-- Data for Name: workflows_tags; Type: TABLE DATA; Schema: public; Owner: recon_user
--

COPY public.workflows_tags ("workflowId", "tagId") FROM stdin;
\.


--
-- Name: auth_provider_sync_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.auth_provider_sync_history_id_seq', 1, false);


--
-- Name: credentials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.credentials_id_seq', 1, false);


--
-- Name: execution_annotations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.execution_annotations_id_seq', 1, false);


--
-- Name: execution_entity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.execution_entity_id_seq', 3, true);


--
-- Name: execution_metadata_temp_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.execution_metadata_temp_id_seq', 1, false);


--
-- Name: fuzzing_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.fuzzing_results_id_seq', 1, false);


--
-- Name: insights_by_period_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.insights_by_period_id_seq', 1, false);


--
-- Name: insights_metadata_metaId_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public."insights_metadata_metaId_seq"', 1, false);


--
-- Name: insights_raw_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.insights_raw_id_seq', 1, false);


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.migrations_id_seq', 106, true);


--
-- Name: network_scans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.network_scans_id_seq', 1, false);


--
-- Name: nuclei_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.nuclei_results_id_seq', 1, false);


--
-- Name: recon_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.recon_sessions_id_seq', 1, false);


--
-- Name: smb_enum_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.smb_enum_id_seq', 1, false);


--
-- Name: sqli_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.sqli_results_id_seq', 1, false);


--
-- Name: subdomain_intel_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.subdomain_intel_id_seq', 1, false);


--
-- Name: vulnerabilities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.vulnerabilities_id_seq', 1, false);


--
-- Name: web_technologies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.web_technologies_id_seq', 1, false);


--
-- Name: workflow_dependency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: recon_user
--

SELECT pg_catalog.setval('public.workflow_dependency_id_seq', 1, false);


--
-- Name: test_run PK_011c050f566e9db509a0fadb9b9; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.test_run
    ADD CONSTRAINT "PK_011c050f566e9db509a0fadb9b9" PRIMARY KEY (id);


--
-- Name: installed_packages PK_08cc9197c39b028c1e9beca225940576fd1a5804; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.installed_packages
    ADD CONSTRAINT "PK_08cc9197c39b028c1e9beca225940576fd1a5804" PRIMARY KEY ("packageName");


--
-- Name: execution_metadata PK_17a0b6284f8d626aae88e1c16e4; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.execution_metadata
    ADD CONSTRAINT "PK_17a0b6284f8d626aae88e1c16e4" PRIMARY KEY (id);


--
-- Name: project_relation PK_1caaa312a5d7184a003be0f0cb6; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.project_relation
    ADD CONSTRAINT "PK_1caaa312a5d7184a003be0f0cb6" PRIMARY KEY ("projectId", "userId");


--
-- Name: chat_hub_sessions PK_1eafef1273c70e4464fec703412; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.chat_hub_sessions
    ADD CONSTRAINT "PK_1eafef1273c70e4464fec703412" PRIMARY KEY (id);


--
-- Name: folder_tag PK_27e4e00852f6b06a925a4d83a3e; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.folder_tag
    ADD CONSTRAINT "PK_27e4e00852f6b06a925a4d83a3e" PRIMARY KEY ("folderId", "tagId");


--
-- Name: role PK_35c9b140caaf6da09cfabb0d675; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT "PK_35c9b140caaf6da09cfabb0d675" PRIMARY KEY (slug);


--
-- Name: project PK_4d68b1358bb5b766d3e78f32f57; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT "PK_4d68b1358bb5b766d3e78f32f57" PRIMARY KEY (id);


--
-- Name: workflow_dependency PK_52325e34cd7a2f0f67b0f3cad65; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.workflow_dependency
    ADD CONSTRAINT "PK_52325e34cd7a2f0f67b0f3cad65" PRIMARY KEY (id);


--
-- Name: invalid_auth_token PK_5779069b7235b256d91f7af1a15; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.invalid_auth_token
    ADD CONSTRAINT "PK_5779069b7235b256d91f7af1a15" PRIMARY KEY (token);


--
-- Name: shared_workflow PK_5ba87620386b847201c9531c58f; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.shared_workflow
    ADD CONSTRAINT "PK_5ba87620386b847201c9531c58f" PRIMARY KEY ("workflowId", "projectId");


--
-- Name: folder PK_6278a41a706740c94c02e288df8; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.folder
    ADD CONSTRAINT "PK_6278a41a706740c94c02e288df8" PRIMARY KEY (id);


--
-- Name: data_table_column PK_673cb121ee4a8a5e27850c72c51; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.data_table_column
    ADD CONSTRAINT "PK_673cb121ee4a8a5e27850c72c51" PRIMARY KEY (id);


--
-- Name: annotation_tag_entity PK_69dfa041592c30bbc0d4b84aa00; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.annotation_tag_entity
    ADD CONSTRAINT "PK_69dfa041592c30bbc0d4b84aa00" PRIMARY KEY (id);


--
-- Name: chat_hub_messages PK_7704a5add6baed43eef835f0bfb; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "PK_7704a5add6baed43eef835f0bfb" PRIMARY KEY (id);


--
-- Name: execution_annotations PK_7afcf93ffa20c4252869a7c6a23; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.execution_annotations
    ADD CONSTRAINT "PK_7afcf93ffa20c4252869a7c6a23" PRIMARY KEY (id);


--
-- Name: migrations PK_8c82d7f526340ab734260ea46be; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT "PK_8c82d7f526340ab734260ea46be" PRIMARY KEY (id);


--
-- Name: installed_nodes PK_8ebd28194e4f792f96b5933423fc439df97d9689; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.installed_nodes
    ADD CONSTRAINT "PK_8ebd28194e4f792f96b5933423fc439df97d9689" PRIMARY KEY (name);


--
-- Name: shared_credentials PK_8ef3a59796a228913f251779cff; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.shared_credentials
    ADD CONSTRAINT "PK_8ef3a59796a228913f251779cff" PRIMARY KEY ("credentialsId", "projectId");


--
-- Name: test_case_execution PK_90c121f77a78a6580e94b794bce; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.test_case_execution
    ADD CONSTRAINT "PK_90c121f77a78a6580e94b794bce" PRIMARY KEY (id);


--
-- Name: user_api_keys PK_978fa5caa3468f463dac9d92e69; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.user_api_keys
    ADD CONSTRAINT "PK_978fa5caa3468f463dac9d92e69" PRIMARY KEY (id);


--
-- Name: execution_annotation_tags PK_979ec03d31294cca484be65d11f; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.execution_annotation_tags
    ADD CONSTRAINT "PK_979ec03d31294cca484be65d11f" PRIMARY KEY ("annotationId", "tagId");


--
-- Name: webhook_entity PK_b21ace2e13596ccd87dc9bf4ea6; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.webhook_entity
    ADD CONSTRAINT "PK_b21ace2e13596ccd87dc9bf4ea6" PRIMARY KEY ("webhookPath", method);


--
-- Name: insights_by_period PK_b606942249b90cc39b0265f0575; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.insights_by_period
    ADD CONSTRAINT "PK_b606942249b90cc39b0265f0575" PRIMARY KEY (id);


--
-- Name: workflow_history PK_b6572dd6173e4cd06fe79937b58; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.workflow_history
    ADD CONSTRAINT "PK_b6572dd6173e4cd06fe79937b58" PRIMARY KEY ("versionId");


--
-- Name: scope PK_bfc45df0481abd7f355d6187da1; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.scope
    ADD CONSTRAINT "PK_bfc45df0481abd7f355d6187da1" PRIMARY KEY (slug);


--
-- Name: processed_data PK_ca04b9d8dc72de268fe07a65773; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.processed_data
    ADD CONSTRAINT "PK_ca04b9d8dc72de268fe07a65773" PRIMARY KEY ("workflowId", context);


--
-- Name: settings PK_dc0fe14e6d9943f268e7b119f69ab8bd; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT "PK_dc0fe14e6d9943f268e7b119f69ab8bd" PRIMARY KEY (key);


--
-- Name: data_table PK_e226d0001b9e6097cbfe70617cb; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.data_table
    ADD CONSTRAINT "PK_e226d0001b9e6097cbfe70617cb" PRIMARY KEY (id);


--
-- Name: user PK_ea8f538c94b6e352418254ed6474a81f; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT "PK_ea8f538c94b6e352418254ed6474a81f" PRIMARY KEY (id);


--
-- Name: insights_raw PK_ec15125755151e3a7e00e00014f; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.insights_raw
    ADD CONSTRAINT "PK_ec15125755151e3a7e00e00014f" PRIMARY KEY (id);


--
-- Name: insights_metadata PK_f448a94c35218b6208ce20cf5a1; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.insights_metadata
    ADD CONSTRAINT "PK_f448a94c35218b6208ce20cf5a1" PRIMARY KEY ("metaId");


--
-- Name: role_scope PK_role_scope; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.role_scope
    ADD CONSTRAINT "PK_role_scope" PRIMARY KEY ("roleSlug", "scopeSlug");


--
-- Name: data_table_column UQ_8082ec4890f892f0bc77473a123; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.data_table_column
    ADD CONSTRAINT "UQ_8082ec4890f892f0bc77473a123" UNIQUE ("dataTableId", name);


--
-- Name: data_table UQ_b23096ef747281ac944d28e8b0d; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.data_table
    ADD CONSTRAINT "UQ_b23096ef747281ac944d28e8b0d" UNIQUE ("projectId", name);


--
-- Name: user UQ_e12875dfb3b1d92d7d7c5377e2; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT "UQ_e12875dfb3b1d92d7d7c5377e2" UNIQUE (email);


--
-- Name: auth_identity auth_identity_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.auth_identity
    ADD CONSTRAINT auth_identity_pkey PRIMARY KEY ("providerId", "providerType");


--
-- Name: auth_provider_sync_history auth_provider_sync_history_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.auth_provider_sync_history
    ADD CONSTRAINT auth_provider_sync_history_pkey PRIMARY KEY (id);


--
-- Name: credentials_entity credentials_entity_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.credentials_entity
    ADD CONSTRAINT credentials_entity_pkey PRIMARY KEY (id);


--
-- Name: credentials credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.credentials
    ADD CONSTRAINT credentials_pkey PRIMARY KEY (id);


--
-- Name: event_destinations event_destinations_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.event_destinations
    ADD CONSTRAINT event_destinations_pkey PRIMARY KEY (id);


--
-- Name: execution_data execution_data_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.execution_data
    ADD CONSTRAINT execution_data_pkey PRIMARY KEY ("executionId");


--
-- Name: fuzzing_results fuzzing_results_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.fuzzing_results
    ADD CONSTRAINT fuzzing_results_pkey PRIMARY KEY (id);


--
-- Name: network_scans network_scans_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.network_scans
    ADD CONSTRAINT network_scans_pkey PRIMARY KEY (id);


--
-- Name: nuclei_results nuclei_results_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.nuclei_results
    ADD CONSTRAINT nuclei_results_pkey PRIMARY KEY (id);


--
-- Name: execution_entity pk_e3e63bbf986767844bbe1166d4e; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.execution_entity
    ADD CONSTRAINT pk_e3e63bbf986767844bbe1166d4e PRIMARY KEY (id);


--
-- Name: workflow_statistics pk_workflow_statistics; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.workflow_statistics
    ADD CONSTRAINT pk_workflow_statistics PRIMARY KEY ("workflowId", name);


--
-- Name: workflows_tags pk_workflows_tags; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.workflows_tags
    ADD CONSTRAINT pk_workflows_tags PRIMARY KEY ("workflowId", "tagId");


--
-- Name: recon_sessions recon_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.recon_sessions
    ADD CONSTRAINT recon_sessions_pkey PRIMARY KEY (id);


--
-- Name: recon_sessions recon_sessions_session_name_key; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.recon_sessions
    ADD CONSTRAINT recon_sessions_session_name_key UNIQUE (session_name);


--
-- Name: smb_enum smb_enum_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.smb_enum
    ADD CONSTRAINT smb_enum_pkey PRIMARY KEY (id);


--
-- Name: sqli_results sqli_results_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.sqli_results
    ADD CONSTRAINT sqli_results_pkey PRIMARY KEY (id);


--
-- Name: subdomain_intel subdomain_intel_domain_subdomain_key; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.subdomain_intel
    ADD CONSTRAINT subdomain_intel_domain_subdomain_key UNIQUE (domain, subdomain);


--
-- Name: subdomain_intel subdomain_intel_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.subdomain_intel
    ADD CONSTRAINT subdomain_intel_pkey PRIMARY KEY (id);


--
-- Name: tag_entity tag_entity_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.tag_entity
    ADD CONSTRAINT tag_entity_pkey PRIMARY KEY (id);


--
-- Name: variables variables_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.variables
    ADD CONSTRAINT variables_pkey PRIMARY KEY (id);


--
-- Name: vulnerabilities vulnerabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.vulnerabilities
    ADD CONSTRAINT vulnerabilities_pkey PRIMARY KEY (id);


--
-- Name: web_technologies web_technologies_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.web_technologies
    ADD CONSTRAINT web_technologies_pkey PRIMARY KEY (id);


--
-- Name: workflow_entity workflow_entity_pkey; Type: CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.workflow_entity
    ADD CONSTRAINT workflow_entity_pkey PRIMARY KEY (id);


--
-- Name: IDX_14f68deffaf858465715995508; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE UNIQUE INDEX "IDX_14f68deffaf858465715995508" ON public.folder USING btree ("projectId", id);


--
-- Name: IDX_1d8ab99d5861c9388d2dc1cf73; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE UNIQUE INDEX "IDX_1d8ab99d5861c9388d2dc1cf73" ON public.insights_metadata USING btree ("workflowId");


--
-- Name: IDX_1e31657f5fe46816c34be7c1b4; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX "IDX_1e31657f5fe46816c34be7c1b4" ON public.workflow_history USING btree ("workflowId");


--
-- Name: IDX_1ef35bac35d20bdae979d917a3; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE UNIQUE INDEX "IDX_1ef35bac35d20bdae979d917a3" ON public.user_api_keys USING btree ("apiKey");


--
-- Name: IDX_5f0643f6717905a05164090dde; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX "IDX_5f0643f6717905a05164090dde" ON public.project_relation USING btree ("userId");


--
-- Name: IDX_60b6a84299eeb3f671dfec7693; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE UNIQUE INDEX "IDX_60b6a84299eeb3f671dfec7693" ON public.insights_by_period USING btree ("periodStart", type, "periodUnit", "metaId");


--
-- Name: IDX_61448d56d61802b5dfde5cdb00; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX "IDX_61448d56d61802b5dfde5cdb00" ON public.project_relation USING btree ("projectId");


--
-- Name: IDX_63d7bbae72c767cf162d459fcc; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE UNIQUE INDEX "IDX_63d7bbae72c767cf162d459fcc" ON public.user_api_keys USING btree ("userId", label);


--
-- Name: IDX_8e4b4774db42f1e6dda3452b2a; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX "IDX_8e4b4774db42f1e6dda3452b2a" ON public.test_case_execution USING btree ("testRunId");


--
-- Name: IDX_97f863fa83c4786f1956508496; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE UNIQUE INDEX "IDX_97f863fa83c4786f1956508496" ON public.execution_annotations USING btree ("executionId");


--
-- Name: IDX_UniqueRoleDisplayName; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE UNIQUE INDEX "IDX_UniqueRoleDisplayName" ON public.role USING btree ("displayName");


--
-- Name: IDX_a3697779b366e131b2bbdae297; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX "IDX_a3697779b366e131b2bbdae297" ON public.execution_annotation_tags USING btree ("tagId");


--
-- Name: IDX_a4ff2d9b9628ea988fa9e7d0bf; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX "IDX_a4ff2d9b9628ea988fa9e7d0bf" ON public.workflow_dependency USING btree ("workflowId");


--
-- Name: IDX_ae51b54c4bb430cf92f48b623f; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE UNIQUE INDEX "IDX_ae51b54c4bb430cf92f48b623f" ON public.annotation_tag_entity USING btree (name);


--
-- Name: IDX_c1519757391996eb06064f0e7c; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX "IDX_c1519757391996eb06064f0e7c" ON public.execution_annotation_tags USING btree ("annotationId");


--
-- Name: IDX_cec8eea3bf49551482ccb4933e; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE UNIQUE INDEX "IDX_cec8eea3bf49551482ccb4933e" ON public.execution_metadata USING btree ("executionId", key);


--
-- Name: IDX_d6870d3b6e4c185d33926f423c; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX "IDX_d6870d3b6e4c185d33926f423c" ON public.test_run USING btree ("workflowId");


--
-- Name: IDX_e48a201071ab85d9d09119d640; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX "IDX_e48a201071ab85d9d09119d640" ON public.workflow_dependency USING btree ("dependencyKey");


--
-- Name: IDX_e7fe1cfda990c14a445937d0b9; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX "IDX_e7fe1cfda990c14a445937d0b9" ON public.workflow_dependency USING btree ("dependencyType");


--
-- Name: IDX_execution_entity_deletedAt; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX "IDX_execution_entity_deletedAt" ON public.execution_entity USING btree ("deletedAt");


--
-- Name: IDX_role_scope_scopeSlug; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX "IDX_role_scope_scopeSlug" ON public.role_scope USING btree ("scopeSlug");


--
-- Name: IDX_workflow_entity_name; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX "IDX_workflow_entity_name" ON public.workflow_entity USING btree (name);


--
-- Name: idx_07fde106c0b471d8cc80a64fc8; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_07fde106c0b471d8cc80a64fc8 ON public.credentials_entity USING btree (type);


--
-- Name: idx_16f4436789e804e3e1c9eeb240; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_16f4436789e804e3e1c9eeb240 ON public.webhook_entity USING btree ("webhookId", method, "pathLength");


--
-- Name: idx_812eb05f7451ca757fb98444ce; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE UNIQUE INDEX idx_812eb05f7451ca757fb98444ce ON public.tag_entity USING btree (name);


--
-- Name: idx_creds_service; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_creds_service ON public.credentials USING btree (service);


--
-- Name: idx_creds_status; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_creds_status ON public.credentials USING btree (status);


--
-- Name: idx_creds_target; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_creds_target ON public.credentials USING btree (target);


--
-- Name: idx_execution_entity_stopped_at_status_deleted_at; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_execution_entity_stopped_at_status_deleted_at ON public.execution_entity USING btree ("stoppedAt", status, "deletedAt") WHERE (("stoppedAt" IS NOT NULL) AND ("deletedAt" IS NULL));


--
-- Name: idx_execution_entity_wait_till_status_deleted_at; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_execution_entity_wait_till_status_deleted_at ON public.execution_entity USING btree ("waitTill", status, "deletedAt") WHERE (("waitTill" IS NOT NULL) AND ("deletedAt" IS NULL));


--
-- Name: idx_execution_entity_workflow_id_started_at; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_execution_entity_workflow_id_started_at ON public.execution_entity USING btree ("workflowId", "startedAt") WHERE (("startedAt" IS NOT NULL) AND ("deletedAt" IS NULL));


--
-- Name: idx_fuzzing_discovered; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_fuzzing_discovered ON public.fuzzing_results USING btree (discovered_at);


--
-- Name: idx_fuzzing_status; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_fuzzing_status ON public.fuzzing_results USING btree (status_code);


--
-- Name: idx_fuzzing_target; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_fuzzing_target ON public.fuzzing_results USING btree (target_url);


--
-- Name: idx_network_port; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_network_port ON public.network_scans USING btree (port);


--
-- Name: idx_network_scan_date; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_network_scan_date ON public.network_scans USING btree (scan_date);


--
-- Name: idx_network_target; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_network_target ON public.network_scans USING btree (target);


--
-- Name: idx_nuclei_severity; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_nuclei_severity ON public.nuclei_results USING btree (severity);


--
-- Name: idx_nuclei_target; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_nuclei_target ON public.nuclei_results USING btree (target);


--
-- Name: idx_nuclei_template; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_nuclei_template ON public.nuclei_results USING btree (template_id);


--
-- Name: idx_session_start; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_session_start ON public.recon_sessions USING btree (start_date);


--
-- Name: idx_session_status; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_session_status ON public.recon_sessions USING btree (status);


--
-- Name: idx_smb_domain; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_smb_domain ON public.smb_enum USING btree (domain);


--
-- Name: idx_smb_target; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_smb_target ON public.smb_enum USING btree (target);


--
-- Name: idx_sqli_dbms; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_sqli_dbms ON public.sqli_results USING btree (dbms);


--
-- Name: idx_sqli_target; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_sqli_target ON public.sqli_results USING btree (target_url);


--
-- Name: idx_subdomain_discovered; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_subdomain_discovered ON public.subdomain_intel USING btree (discovered_at);


--
-- Name: idx_subdomain_domain; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_subdomain_domain ON public.subdomain_intel USING btree (domain);


--
-- Name: idx_subdomain_ip; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_subdomain_ip ON public.subdomain_intel USING btree (ip);


--
-- Name: idx_vuln_cve; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_vuln_cve ON public.vulnerabilities USING btree (cve_id);


--
-- Name: idx_vuln_cvss; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_vuln_cvss ON public.vulnerabilities USING btree (cvss_score);


--
-- Name: idx_vuln_severity; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_vuln_severity ON public.vulnerabilities USING btree (severity);


--
-- Name: idx_vuln_target; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_vuln_target ON public.vulnerabilities USING btree (target);


--
-- Name: idx_webtech_tech; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_webtech_tech ON public.web_technologies USING btree (technology);


--
-- Name: idx_webtech_url; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_webtech_url ON public.web_technologies USING btree (url);


--
-- Name: idx_workflows_tags_workflow_id; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX idx_workflows_tags_workflow_id ON public.workflows_tags USING btree ("workflowId");


--
-- Name: pk_credentials_entity_id; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE UNIQUE INDEX pk_credentials_entity_id ON public.credentials_entity USING btree (id);


--
-- Name: pk_tag_entity_id; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE UNIQUE INDEX pk_tag_entity_id ON public.tag_entity USING btree (id);


--
-- Name: pk_workflow_entity_id; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE UNIQUE INDEX pk_workflow_entity_id ON public.workflow_entity USING btree (id);


--
-- Name: project_relation_role_idx; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX project_relation_role_idx ON public.project_relation USING btree (role);


--
-- Name: project_relation_role_project_idx; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX project_relation_role_project_idx ON public.project_relation USING btree ("projectId", role);


--
-- Name: user_role_idx; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE INDEX user_role_idx ON public."user" USING btree ("roleSlug");


--
-- Name: variables_global_key_unique; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE UNIQUE INDEX variables_global_key_unique ON public.variables USING btree (key) WHERE ("projectId" IS NULL);


--
-- Name: variables_project_key_unique; Type: INDEX; Schema: public; Owner: recon_user
--

CREATE UNIQUE INDEX variables_project_key_unique ON public.variables USING btree ("projectId", key) WHERE ("projectId" IS NOT NULL);


--
-- Name: subdomain_intel update_subdomain_last_seen; Type: TRIGGER; Schema: public; Owner: recon_user
--

CREATE TRIGGER update_subdomain_last_seen BEFORE UPDATE ON public.subdomain_intel FOR EACH ROW EXECUTE FUNCTION public.update_last_seen();


--
-- Name: processed_data FK_06a69a7032c97a763c2c7599464; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.processed_data
    ADD CONSTRAINT "FK_06a69a7032c97a763c2c7599464" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: insights_metadata FK_1d8ab99d5861c9388d2dc1cf733; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.insights_metadata
    ADD CONSTRAINT "FK_1d8ab99d5861c9388d2dc1cf733" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE SET NULL;


--
-- Name: workflow_history FK_1e31657f5fe46816c34be7c1b4b; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.workflow_history
    ADD CONSTRAINT "FK_1e31657f5fe46816c34be7c1b4b" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: chat_hub_messages FK_1f4998c8a7dec9e00a9ab15550e; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_1f4998c8a7dec9e00a9ab15550e" FOREIGN KEY ("revisionOfMessageId") REFERENCES public.chat_hub_messages(id) ON DELETE CASCADE;


--
-- Name: insights_metadata FK_2375a1eda085adb16b24615b69c; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.insights_metadata
    ADD CONSTRAINT "FK_2375a1eda085adb16b24615b69c" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE SET NULL;


--
-- Name: chat_hub_messages FK_25c9736e7f769f3a005eef4b372; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_25c9736e7f769f3a005eef4b372" FOREIGN KEY ("retryOfMessageId") REFERENCES public.chat_hub_messages(id) ON DELETE CASCADE;


--
-- Name: execution_metadata FK_31d0b4c93fb85ced26f6005cda3; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.execution_metadata
    ADD CONSTRAINT "FK_31d0b4c93fb85ced26f6005cda3" FOREIGN KEY ("executionId") REFERENCES public.execution_entity(id) ON DELETE CASCADE;


--
-- Name: shared_credentials FK_416f66fc846c7c442970c094ccf; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.shared_credentials
    ADD CONSTRAINT "FK_416f66fc846c7c442970c094ccf" FOREIGN KEY ("credentialsId") REFERENCES public.credentials_entity(id) ON DELETE CASCADE;


--
-- Name: variables FK_42f6c766f9f9d2edcc15bdd6e9b; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.variables
    ADD CONSTRAINT "FK_42f6c766f9f9d2edcc15bdd6e9b" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: project_relation FK_5f0643f6717905a05164090dde7; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.project_relation
    ADD CONSTRAINT "FK_5f0643f6717905a05164090dde7" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: project_relation FK_61448d56d61802b5dfde5cdb002; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.project_relation
    ADD CONSTRAINT "FK_61448d56d61802b5dfde5cdb002" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: insights_by_period FK_6414cfed98daabbfdd61a1cfbc0; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.insights_by_period
    ADD CONSTRAINT "FK_6414cfed98daabbfdd61a1cfbc0" FOREIGN KEY ("metaId") REFERENCES public.insights_metadata("metaId") ON DELETE CASCADE;


--
-- Name: chat_hub_messages FK_6afb260449dd7a9b85355d4e0c9; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_6afb260449dd7a9b85355d4e0c9" FOREIGN KEY ("executionId") REFERENCES public.execution_entity(id) ON DELETE SET NULL;


--
-- Name: insights_raw FK_6e2e33741adef2a7c5d66befa4e; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.insights_raw
    ADD CONSTRAINT "FK_6e2e33741adef2a7c5d66befa4e" FOREIGN KEY ("metaId") REFERENCES public.insights_metadata("metaId") ON DELETE CASCADE;


--
-- Name: installed_nodes FK_73f857fc5dce682cef8a99c11dbddbc969618951; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.installed_nodes
    ADD CONSTRAINT "FK_73f857fc5dce682cef8a99c11dbddbc969618951" FOREIGN KEY (package) REFERENCES public.installed_packages("packageName") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_hub_sessions FK_7bc13b4c7e6afbfaf9be326c189; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.chat_hub_sessions
    ADD CONSTRAINT "FK_7bc13b4c7e6afbfaf9be326c189" FOREIGN KEY ("credentialId") REFERENCES public.credentials_entity(id) ON DELETE SET NULL;


--
-- Name: folder FK_804ea52f6729e3940498bd54d78; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.folder
    ADD CONSTRAINT "FK_804ea52f6729e3940498bd54d78" FOREIGN KEY ("parentFolderId") REFERENCES public.folder(id) ON DELETE CASCADE;


--
-- Name: shared_credentials FK_812c2852270da1247756e77f5a4; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.shared_credentials
    ADD CONSTRAINT "FK_812c2852270da1247756e77f5a4" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: test_case_execution FK_8e4b4774db42f1e6dda3452b2af; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.test_case_execution
    ADD CONSTRAINT "FK_8e4b4774db42f1e6dda3452b2af" FOREIGN KEY ("testRunId") REFERENCES public.test_run(id) ON DELETE CASCADE;


--
-- Name: data_table_column FK_930b6e8faaf88294cef23484160; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.data_table_column
    ADD CONSTRAINT "FK_930b6e8faaf88294cef23484160" FOREIGN KEY ("dataTableId") REFERENCES public.data_table(id) ON DELETE CASCADE;


--
-- Name: folder_tag FK_94a60854e06f2897b2e0d39edba; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.folder_tag
    ADD CONSTRAINT "FK_94a60854e06f2897b2e0d39edba" FOREIGN KEY ("folderId") REFERENCES public.folder(id) ON DELETE CASCADE;


--
-- Name: execution_annotations FK_97f863fa83c4786f19565084960; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.execution_annotations
    ADD CONSTRAINT "FK_97f863fa83c4786f19565084960" FOREIGN KEY ("executionId") REFERENCES public.execution_entity(id) ON DELETE CASCADE;


--
-- Name: chat_hub_sessions FK_9f9293d9f552496c40e0d1a8f80; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.chat_hub_sessions
    ADD CONSTRAINT "FK_9f9293d9f552496c40e0d1a8f80" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE SET NULL;


--
-- Name: execution_annotation_tags FK_a3697779b366e131b2bbdae2976; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.execution_annotation_tags
    ADD CONSTRAINT "FK_a3697779b366e131b2bbdae2976" FOREIGN KEY ("tagId") REFERENCES public.annotation_tag_entity(id) ON DELETE CASCADE;


--
-- Name: shared_workflow FK_a45ea5f27bcfdc21af9b4188560; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.shared_workflow
    ADD CONSTRAINT "FK_a45ea5f27bcfdc21af9b4188560" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: workflow_dependency FK_a4ff2d9b9628ea988fa9e7d0bf8; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.workflow_dependency
    ADD CONSTRAINT "FK_a4ff2d9b9628ea988fa9e7d0bf8" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: folder FK_a8260b0b36939c6247f385b8221; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.folder
    ADD CONSTRAINT "FK_a8260b0b36939c6247f385b8221" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: chat_hub_messages FK_acf8926098f063cdbbad8497fd1; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_acf8926098f063cdbbad8497fd1" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE SET NULL;


--
-- Name: execution_annotation_tags FK_c1519757391996eb06064f0e7c8; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.execution_annotation_tags
    ADD CONSTRAINT "FK_c1519757391996eb06064f0e7c8" FOREIGN KEY ("annotationId") REFERENCES public.execution_annotations(id) ON DELETE CASCADE;


--
-- Name: data_table FK_c2a794257dee48af7c9abf681de; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.data_table
    ADD CONSTRAINT "FK_c2a794257dee48af7c9abf681de" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: project_relation FK_c6b99592dc96b0d836d7a21db91; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.project_relation
    ADD CONSTRAINT "FK_c6b99592dc96b0d836d7a21db91" FOREIGN KEY (role) REFERENCES public.role(slug);


--
-- Name: test_run FK_d6870d3b6e4c185d33926f423c8; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.test_run
    ADD CONSTRAINT "FK_d6870d3b6e4c185d33926f423c8" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: shared_workflow FK_daa206a04983d47d0a9c34649ce; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.shared_workflow
    ADD CONSTRAINT "FK_daa206a04983d47d0a9c34649ce" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: folder_tag FK_dc88164176283de80af47621746; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.folder_tag
    ADD CONSTRAINT "FK_dc88164176283de80af47621746" FOREIGN KEY ("tagId") REFERENCES public.tag_entity(id) ON DELETE CASCADE;


--
-- Name: user_api_keys FK_e131705cbbc8fb589889b02d457; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.user_api_keys
    ADD CONSTRAINT "FK_e131705cbbc8fb589889b02d457" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: chat_hub_messages FK_e22538eb50a71a17954cd7e076c; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_e22538eb50a71a17954cd7e076c" FOREIGN KEY ("sessionId") REFERENCES public.chat_hub_sessions(id) ON DELETE CASCADE;


--
-- Name: test_case_execution FK_e48965fac35d0f5b9e7f51d8c44; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.test_case_execution
    ADD CONSTRAINT "FK_e48965fac35d0f5b9e7f51d8c44" FOREIGN KEY ("executionId") REFERENCES public.execution_entity(id) ON DELETE SET NULL;


--
-- Name: chat_hub_messages FK_e5d1fa722c5a8d38ac204746662; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_e5d1fa722c5a8d38ac204746662" FOREIGN KEY ("previousMessageId") REFERENCES public.chat_hub_messages(id) ON DELETE CASCADE;


--
-- Name: chat_hub_sessions FK_e9ecf8ede7d989fcd18790fe36a; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.chat_hub_sessions
    ADD CONSTRAINT "FK_e9ecf8ede7d989fcd18790fe36a" FOREIGN KEY ("ownerId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user FK_eaea92ee7bfb9c1b6cd01505d56; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT "FK_eaea92ee7bfb9c1b6cd01505d56" FOREIGN KEY ("roleSlug") REFERENCES public.role(slug);


--
-- Name: role_scope FK_role; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.role_scope
    ADD CONSTRAINT "FK_role" FOREIGN KEY ("roleSlug") REFERENCES public.role(slug) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: role_scope FK_scope; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.role_scope
    ADD CONSTRAINT "FK_scope" FOREIGN KEY ("scopeSlug") REFERENCES public.scope(slug) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: auth_identity auth_identity_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.auth_identity
    ADD CONSTRAINT "auth_identity_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."user"(id);


--
-- Name: execution_data execution_data_fk; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.execution_data
    ADD CONSTRAINT execution_data_fk FOREIGN KEY ("executionId") REFERENCES public.execution_entity(id) ON DELETE CASCADE;


--
-- Name: execution_entity fk_execution_entity_workflow_id; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.execution_entity
    ADD CONSTRAINT fk_execution_entity_workflow_id FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: webhook_entity fk_webhook_entity_workflow_id; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.webhook_entity
    ADD CONSTRAINT fk_webhook_entity_workflow_id FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: workflow_entity fk_workflow_parent_folder; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.workflow_entity
    ADD CONSTRAINT fk_workflow_parent_folder FOREIGN KEY ("parentFolderId") REFERENCES public.folder(id) ON DELETE CASCADE;


--
-- Name: workflow_statistics fk_workflow_statistics_workflow_id; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.workflow_statistics
    ADD CONSTRAINT fk_workflow_statistics_workflow_id FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: workflows_tags fk_workflows_tags_tag_id; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.workflows_tags
    ADD CONSTRAINT fk_workflows_tags_tag_id FOREIGN KEY ("tagId") REFERENCES public.tag_entity(id) ON DELETE CASCADE;


--
-- Name: workflows_tags fk_workflows_tags_workflow_id; Type: FK CONSTRAINT; Schema: public; Owner: recon_user
--

ALTER TABLE ONLY public.workflows_tags
    ADD CONSTRAINT fk_workflows_tags_workflow_id FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: recon_user
--

ALTER DEFAULT PRIVILEGES FOR ROLE recon_user IN SCHEMA public GRANT ALL ON SEQUENCES  TO recon_user;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: recon_user
--

ALTER DEFAULT PRIVILEGES FOR ROLE recon_user IN SCHEMA public GRANT ALL ON FUNCTIONS  TO recon_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: recon_user
--

ALTER DEFAULT PRIVILEGES FOR ROLE recon_user IN SCHEMA public GRANT ALL ON TABLES  TO recon_user;


--
-- PostgreSQL database dump complete
--

\unrestrict 4QlaJGdDQ9YeicgXy3juuWXDgEDpaYiq8mk8nLZL9rPs8Xu741Car5rt1GC3C8H

