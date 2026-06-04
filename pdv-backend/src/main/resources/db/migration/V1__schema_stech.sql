--
-- PostgreSQL database dump

-- V1__schema_stech.sql
--



-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: documento_fiscal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documento_fiscal (
    id_documento integer NOT NULL,
    id_tipo_doc integer NOT NULL,
    id_pedido integer NOT NULL,
    referencia character varying(30) NOT NULL,
    numero_seq integer NOT NULL,
    ano integer NOT NULL,
    codigo_at character varying(50) NOT NULL,
    id_usuario bigint NOT NULL,
    emitido_em timestamp with time zone DEFAULT now() NOT NULL,
    anulado boolean DEFAULT false NOT NULL,
    motivo_anulacao text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    sync_status character varying(20) DEFAULT 'PENDING_CREATE'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version bigint DEFAULT 1 NOT NULL
);


--
-- Name: emitir_documento_fiscal(integer, character varying, integer, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.emitir_documento_fiscal(p_id_pedido integer, p_codigo_tipo character varying, p_id_usuario integer, p_codigo_at character varying) RETURNS public.documento_fiscal
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_tipo   tipo_documento_fiscal%ROWTYPE;
    v_num    INT;
    v_ano    INT := EXTRACT(YEAR FROM NOW());
    v_ref    VARCHAR;
    v_doc    documento_fiscal%ROWTYPE;
BEGIN
    SELECT * INTO v_tipo FROM tipo_documento_fiscal WHERE codigo = p_codigo_tipo;
    IF NOT FOUND THEN RAISE EXCEPTION 'Tipo de documento inválido: %', p_codigo_tipo; END IF;

    -- Avança a sequência correcta
    EXECUTE format('SELECT nextval(%L)', v_tipo.seq_name) INTO v_num;

    -- Referência: FAT-0001/2026
    v_ref := format('%s-%s/%s', v_tipo.prefixo, lpad(v_num::TEXT, 4, '0'), v_ano);

    INSERT INTO documento_fiscal
        (id_tipo_doc, id_pedido, referencia, numero_seq, ano, codigo_at, id_usuario)
    VALUES
        (v_tipo.id_tipo_doc, p_id_pedido, v_ref, v_num, v_ano, p_codigo_at, p_id_usuario)
    RETURNING * INTO v_doc;

    RETURN v_doc;
END;
$$;


--
-- Name: emitir_documento_fiscal_multiplos(integer[], character varying, integer, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.emitir_documento_fiscal_multiplos(p_ids_pedido integer[], p_codigo_tipo character varying, p_id_usuario integer, p_codigo_at character varying) RETURNS public.documento_fiscal
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_tipo   tipo_documento_fiscal%ROWTYPE;
    v_num    INT;
    v_ano    INT := EXTRACT(YEAR FROM NOW());
    v_ref    VARCHAR;
    v_doc    documento_fiscal%ROWTYPE;
    v_id     INT;
BEGIN
    SELECT * INTO v_tipo FROM tipo_documento_fiscal WHERE codigo = p_codigo_tipo;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tipo de documento inválido: %', p_codigo_tipo;
    END IF;

    -- Usa o primeiro idPedido como referência principal na tabela
    EXECUTE format('SELECT nextval(%L)', v_tipo.seq_name) INTO v_num;
    v_ref := format('%s-%s/%s', v_tipo.prefixo, lpad(v_num::TEXT, 4, '0'), v_ano);

    INSERT INTO documento_fiscal
        (id_tipo_doc, id_pedido, referencia, numero_seq, ano, codigo_at, id_usuario)
    VALUES
        (v_tipo.id_tipo_doc, p_ids_pedido[1], v_ref, v_num, v_ano, p_codigo_at, p_id_usuario)
    RETURNING * INTO v_doc;

    -- Associa todos os pedidos
    FOREACH v_id IN ARRAY p_ids_pedido LOOP
        INSERT INTO documento_fiscal_pedido (id_documento, id_pedido)
        VALUES (v_doc.id_documento, v_id);
    END LOOP;

    RETURN v_doc;
END;
$$;


--
-- Name: categoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categoria (
    id_categoria bigint NOT NULL,
    nome_categoria character varying(100) NOT NULL,
    descricao text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted boolean DEFAULT false,
    sync_status character varying(50),
    version bigint DEFAULT 0
);


--
-- Name: categoria_id_categoria_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.categoria_id_categoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categoria_id_categoria_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.categoria_id_categoria_seq OWNED BY public.categoria.id_categoria;


--
-- Name: categoria_marca; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categoria_marca (
    id_categoria bigint NOT NULL,
    id_marca bigint NOT NULL
);


--
-- Name: cliente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cliente (
    id_cliente bigint NOT NULL,
    nome character varying(250),
    apelido character varying(250),
    email character varying(250),
    nuit character varying(250),
    contacto character varying(250),
    morada character varying(250),
    id_perfil_cliente bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    sync_status character varying(20) DEFAULT 'SYNCED'::character varying NOT NULL,
    version bigint DEFAULT 1 NOT NULL
);


--
-- Name: cliente_id_cliente_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cliente_id_cliente_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cliente_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cliente_id_cliente_seq OWNED BY public.cliente.id_cliente;


--
-- Name: documento_fiscal_id_documento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.documento_fiscal_id_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: documento_fiscal_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.documento_fiscal_id_documento_seq OWNED BY public.documento_fiscal.id_documento;


--
-- Name: documento_fiscal_pedido; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documento_fiscal_pedido (
    id_documento integer NOT NULL,
    id_pedido integer NOT NULL
);


--
-- Name: flyway_schema_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flyway_schema_history (
    installed_rank integer NOT NULL,
    version character varying(50),
    description character varying(200) NOT NULL,
    type character varying(20) NOT NULL,
    script character varying(1000) NOT NULL,
    checksum integer,
    installed_by character varying(100) NOT NULL,
    installed_on timestamp without time zone DEFAULT now() NOT NULL,
    execution_time integer NOT NULL,
    success boolean NOT NULL
);


--
-- Name: historico_senhas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.historico_senhas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: historico_senhas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historico_senhas (
    id_historico bigint DEFAULT nextval('public.historico_senhas_id_seq'::regclass) NOT NULL,
    id_usuario bigint NOT NULL,
    senha_hash text NOT NULL,
    data_alteracao timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: historico_senhas_id_historico_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.historico_senhas_id_historico_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: historico_senhas_id_historico_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.historico_senhas_id_historico_seq OWNED BY public.historico_senhas.id_historico;


--
-- Name: item_pedido; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_pedido (
    id_item_pedido integer NOT NULL,
    id_pedido integer NOT NULL,
    id_produto integer NOT NULL,
    quantidade integer NOT NULL,
    preco_unitario numeric(12,2) NOT NULL,
    subtotal numeric(12,2) GENERATED ALWAYS AS (((quantidade)::numeric * preco_unitario)) STORED,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT item_pedido_preco_unitario_check CHECK ((preco_unitario >= (0)::numeric)),
    CONSTRAINT item_pedido_quantidade_check CHECK ((quantidade > 0))
);


--
-- Name: item_pedido_id_item_pedido_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.item_pedido_id_item_pedido_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_pedido_id_item_pedido_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.item_pedido_id_item_pedido_seq OWNED BY public.item_pedido.id_item_pedido;


--
-- Name: item_pedido_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.item_pedido_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_pedido_servico; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_pedido_servico (
    id_item_servico integer NOT NULL,
    id_pedido integer NOT NULL,
    id_servico integer NOT NULL,
    quantidade integer NOT NULL,
    preco_unitario numeric(12,2) NOT NULL,
    subtotal numeric(12,2) GENERATED ALWAYS AS (((quantidade)::numeric * preco_unitario)) STORED,
    observacoes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT item_pedido_servico_preco_unitario_check CHECK ((preco_unitario >= (0)::numeric)),
    CONSTRAINT item_pedido_servico_quantidade_check CHECK ((quantidade > 0))
);


--
-- Name: item_pedido_servico_id_item_servico_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.item_pedido_servico_id_item_servico_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_pedido_servico_id_item_servico_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.item_pedido_servico_id_item_servico_seq OWNED BY public.item_pedido_servico.id_item_servico;


--
-- Name: item_pedido_servico_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.item_pedido_servico_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.logs (
    id_log bigint DEFAULT nextval('public.logs_id_seq'::regclass) NOT NULL,
    id_usuario bigint,
    acao text,
    detalhes jsonb,
    ip inet,
    data_hora timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: logs_id_log_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.logs_id_log_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logs_id_log_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.logs_id_log_seq OWNED BY public.logs.id_log;


--
-- Name: marca; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marca (
    id_marca bigint NOT NULL,
    nome_marca character varying(100) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    sync_status character varying(50) DEFAULT 'SYNCED'::character varying NOT NULL,
    version bigint DEFAULT 1 NOT NULL
);


--
-- Name: marca_id_marca_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.marca_id_marca_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: marca_id_marca_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.marca_id_marca_seq OWNED BY public.marca.id_marca;


--
-- Name: movimento_estoque_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.movimento_estoque_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: movimento_estoque; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.movimento_estoque (
    id_movimento integer DEFAULT nextval('public.movimento_estoque_id_seq'::regclass) NOT NULL,
    id_produto integer NOT NULL,
    id_usuario integer NOT NULL,
    tipo_movimento character varying(20) NOT NULL,
    quantidade integer NOT NULL,
    quantidade_anterior integer NOT NULL,
    quantidade_nova integer NOT NULL,
    motivo text,
    data_movimento timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    sync_status character varying(20) DEFAULT 'PENDING_CREATE'::character varying NOT NULL,
    CONSTRAINT movimento_estoque_tipo_movimento_check CHECK (((tipo_movimento)::text = ANY (ARRAY[('entrada'::character varying)::text, ('saida'::character varying)::text, ('ajuste'::character varying)::text])))
);


--
-- Name: notificacao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notificacao (
    id_notificacao integer NOT NULL,
    tipo character varying(50),
    mensagem text,
    id_pedido integer,
    lida boolean DEFAULT false NOT NULL,
    criado_em timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: notificacao_id_notificacao_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notificacao_id_notificacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notificacao_id_notificacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notificacao_id_notificacao_seq OWNED BY public.notificacao.id_notificacao;


--
-- Name: notificacao_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notificacao_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: password_resets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.password_resets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: password_resets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_resets (
    id_reset bigint DEFAULT nextval('public.password_resets_id_seq'::regclass) NOT NULL,
    id_usuario bigint NOT NULL,
    token_hash text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used_at timestamp with time zone,
    ip_solicitacao inet,
    user_agent text,
    criado_em timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: password_resets_id_reset_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.password_resets_id_reset_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: password_resets_id_reset_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.password_resets_id_reset_seq OWNED BY public.password_resets.id_reset;


--
-- Name: pedido; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pedido (
    id_pedido integer NOT NULL,
    referencia character varying(50) NOT NULL,
    id_usuario integer NOT NULL,
    id_cliente bigint,
    id_tipo_pagamento integer NOT NULL,
    status_pedido character varying(50) DEFAULT 'aberto'::character varying NOT NULL,
    total numeric(12,2) NOT NULL,
    valor_pago numeric(12,2) DEFAULT 0 NOT NULL,
    troco numeric(12,2) GENERATED ALWAYS AS (GREATEST((valor_pago - total), (0)::numeric)) STORED,
    ponto_referencia text,
    observacoes text,
    data_pedido timestamp with time zone DEFAULT now() NOT NULL,
    data_finalizacao timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    sync_status character varying(20) DEFAULT 'PENDING_CREATE'::character varying NOT NULL,
    version bigint DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pedido_status_pedido_check CHECK (((status_pedido)::text = ANY ((ARRAY['aberto'::character varying, 'finalizado'::character varying, 'cancelado'::character varying, 'em dívida'::character varying])::text[]))),
    CONSTRAINT pedido_total_check CHECK ((total >= (0)::numeric)),
    CONSTRAINT pedido_valor_pago_check CHECK ((valor_pago >= (0)::numeric))
);


--
-- Name: pedido_cancelamento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pedido_cancelamento (
    id_cancelamento integer NOT NULL,
    id_pedido integer NOT NULL,
    id_usuario_cancelou integer NOT NULL,
    motivo text,
    data_cancelamento timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: pedido_cancelamento_id_cancelamento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pedido_cancelamento_id_cancelamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pedido_cancelamento_id_cancelamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pedido_cancelamento_id_cancelamento_seq OWNED BY public.pedido_cancelamento.id_cancelamento;


--
-- Name: pedido_cancelamento_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pedido_cancelamento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pedido_id_pedido_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pedido_id_pedido_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pedido_id_pedido_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pedido_id_pedido_seq OWNED BY public.pedido.id_pedido;


--
-- Name: pedido_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pedido_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: perfil; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.perfil (
    id_perfil bigint NOT NULL,
    nome_perfil character varying(100) NOT NULL,
    descricao text
);


--
-- Name: perfil_cliente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.perfil_cliente (
    id_perfil_cliente bigint NOT NULL,
    nome_perfil_cliente character varying(100) NOT NULL,
    descricao text
);


--
-- Name: perfil_cliente_id_perfil_cliente_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.perfil_cliente_id_perfil_cliente_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: perfil_cliente_id_perfil_cliente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.perfil_cliente_id_perfil_cliente_seq OWNED BY public.perfil_cliente.id_perfil_cliente;


--
-- Name: perfil_id_perfil_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.perfil_id_perfil_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: perfil_id_perfil_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.perfil_id_perfil_seq OWNED BY public.perfil.id_perfil;


--
-- Name: produto_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.produto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: produto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.produto (
    id_produto integer DEFAULT nextval('public.produto_id_seq'::regclass) NOT NULL,
    nome_produto character varying(200) NOT NULL,
    descricao text,
    preco numeric(10,2) NOT NULL,
    quantidade_estoque integer DEFAULT 0 NOT NULL,
    preco_promocional numeric(10,2),
    ativo smallint DEFAULT 1,
    data_cadastro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    sync_status character varying(20) DEFAULT 'SYNCED'::character varying NOT NULL,
    version bigint DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: produto_categoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.produto_categoria (
    id_produto integer NOT NULL,
    id_categoria integer NOT NULL
);


--
-- Name: produto_id_produto_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.produto_id_produto_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: produto_imagem_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.produto_imagem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: produto_imagem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.produto_imagem (
    id_imagem integer DEFAULT nextval('public.produto_imagem_id_seq'::regclass) NOT NULL,
    id_produto integer NOT NULL,
    caminho_imagem character varying(255) NOT NULL,
    legenda text,
    imagem_principal smallint DEFAULT 0
);


--
-- Name: produto_imagem_id_imagem_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.produto_imagem_id_imagem_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: produto_marca; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.produto_marca (
    id_produto integer NOT NULL,
    id_marca integer NOT NULL
);


--
-- Name: seq_cot; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seq_cot
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seq_fat; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seq_fat
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seq_nco; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seq_nco
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seq_rec; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seq_rec
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seq_vd; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seq_vd
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: servico; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.servico (
    id_servico bigint NOT NULL,
    nome_servico character varying(150) NOT NULL,
    descricao text,
    preco_unitario numeric(12,2) NOT NULL,
    unidade character varying(50) DEFAULT 'página'::character varying NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    sync_status character varying(20) DEFAULT 'SYNCED'::character varying NOT NULL,
    version bigint DEFAULT 1 NOT NULL,
    CONSTRAINT servico_preco_unitario_check CHECK ((preco_unitario >= (0)::numeric))
);


--
-- Name: servico_id_servico_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.servico_id_servico_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: servico_id_servico_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.servico_id_servico_seq OWNED BY public.servico.id_servico;


--
-- Name: tipo_documento_fiscal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipo_documento_fiscal (
    id_tipo_doc integer NOT NULL,
    codigo character varying(10) NOT NULL,
    nome character varying(100) NOT NULL,
    prefixo character varying(10) NOT NULL,
    seq_name character varying(60) NOT NULL
);


--
-- Name: tipo_documento_fiscal_id_tipo_doc_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipo_documento_fiscal_id_tipo_doc_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipo_documento_fiscal_id_tipo_doc_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipo_documento_fiscal_id_tipo_doc_seq OWNED BY public.tipo_documento_fiscal.id_tipo_doc;


--
-- Name: tipo_pagamento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipo_pagamento (
    id_tipo_pagamento bigint NOT NULL,
    tipo_pagamento character varying(100) NOT NULL
);


--
-- Name: tipo_pagamento_id_tipo_pagamento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipo_pagamento_id_tipo_pagamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipo_pagamento_id_tipo_pagamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipo_pagamento_id_tipo_pagamento_seq OWNED BY public.tipo_pagamento.id_tipo_pagamento;


--
-- Name: usuario_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuario (
    id_usuario bigint DEFAULT nextval('public.usuario_id_seq'::regclass) NOT NULL,
    nome character varying(250) NOT NULL,
    apelido character varying(100),
    email character varying(250) NOT NULL,
    senha_hash text NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    id_perfil bigint NOT NULL,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp with time zone DEFAULT now() NOT NULL,
    primeira_senha boolean DEFAULT true NOT NULL,
    telefone character varying(30),
    deleted boolean DEFAULT false NOT NULL,
    sync_status character varying(20) DEFAULT 'SYNCED'::character varying NOT NULL,
    version bigint DEFAULT 1 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    local_id bigint
);


--
-- Name: usuario_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuario_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usuario_id_usuario_seq OWNED BY public.usuario.id_usuario;


--
-- Name: categoria id_categoria; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categoria ALTER COLUMN id_categoria SET DEFAULT nextval('public.categoria_id_categoria_seq'::regclass);


--
-- Name: cliente id_cliente; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente ALTER COLUMN id_cliente SET DEFAULT nextval('public.cliente_id_cliente_seq'::regclass);


--
-- Name: documento_fiscal id_documento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documento_fiscal ALTER COLUMN id_documento SET DEFAULT nextval('public.documento_fiscal_id_documento_seq'::regclass);


--
-- Name: item_pedido id_item_pedido; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_pedido ALTER COLUMN id_item_pedido SET DEFAULT nextval('public.item_pedido_id_item_pedido_seq'::regclass);


--
-- Name: item_pedido_servico id_item_servico; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_pedido_servico ALTER COLUMN id_item_servico SET DEFAULT nextval('public.item_pedido_servico_id_item_servico_seq'::regclass);


--
-- Name: marca id_marca; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marca ALTER COLUMN id_marca SET DEFAULT nextval('public.marca_id_marca_seq'::regclass);


--
-- Name: notificacao id_notificacao; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificacao ALTER COLUMN id_notificacao SET DEFAULT nextval('public.notificacao_id_notificacao_seq'::regclass);


--
-- Name: pedido id_pedido; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido ALTER COLUMN id_pedido SET DEFAULT nextval('public.pedido_id_pedido_seq'::regclass);


--
-- Name: pedido_cancelamento id_cancelamento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido_cancelamento ALTER COLUMN id_cancelamento SET DEFAULT nextval('public.pedido_cancelamento_id_cancelamento_seq'::regclass);


--
-- Name: perfil id_perfil; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfil ALTER COLUMN id_perfil SET DEFAULT nextval('public.perfil_id_perfil_seq'::regclass);


--
-- Name: perfil_cliente id_perfil_cliente; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfil_cliente ALTER COLUMN id_perfil_cliente SET DEFAULT nextval('public.perfil_cliente_id_perfil_cliente_seq'::regclass);


--
-- Name: servico id_servico; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servico ALTER COLUMN id_servico SET DEFAULT nextval('public.servico_id_servico_seq'::regclass);


--
-- Name: tipo_documento_fiscal id_tipo_doc; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_documento_fiscal ALTER COLUMN id_tipo_doc SET DEFAULT nextval('public.tipo_documento_fiscal_id_tipo_doc_seq'::regclass);


--
-- Name: tipo_pagamento id_tipo_pagamento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_pagamento ALTER COLUMN id_tipo_pagamento SET DEFAULT nextval('public.tipo_pagamento_id_tipo_pagamento_seq'::regclass);


--
-- Data for Name: categoria; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.categoria (id_categoria, nome_categoria, descricao, created_at, updated_at, deleted, sync_status, version) FROM stdin;
1	Toner	\N	\N	\N	f	\N	0
2	Electrónicos	\N	\N	\N	f	\N	0
3	Material de Rede	\N	\N	\N	f	\N	0
4	Material Didáctico	\N	\N	\N	f	\N	0
5	Equipamento de impressão	\N	\N	\N	f	\N	0
\.


--
-- Data for Name: categoria_marca; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.categoria_marca (id_categoria, id_marca) FROM stdin;
1	1
2	2
3	1
4	3
4	4
5	1
3	5
3	6
3	7
\.


--
-- Data for Name: cliente; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cliente (id_cliente, nome, apelido, email, nuit, contacto, morada, id_perfil_cliente, created_at, updated_at, deleted, sync_status, version) FROM stdin;
1	Vulcan	\N	geral@vulcan.co.mz	858949939	876821594	Moatize	1	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
2	ICVL lda.	\N	info@icvl.co.mz	124423330	879821694	Matema	1	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
\.


--
-- Data for Name: documento_fiscal; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.documento_fiscal (id_documento, id_tipo_doc, id_pedido, referencia, numero_seq, ano, codigo_at, id_usuario, emitido_em, anulado, motivo_anulacao, updated_at, sync_status, created_at, deleted, version) FROM stdin;
2	2	7	COT-0002/2026	2	2026	STECH-MZ-2026-XXXX	1	2026-06-01 07:56:05.334791+00	f	\N	2026-06-02 11:37:00.500753+00	PENDING_CREATE	2026-06-02 20:05:03.896658+00	f	1
4	3	7	REC-0001/2026	1	2026	STECH-MZ-2026-XXXX	1	2026-06-01 09:53:00.70003+00	f	\N	2026-06-02 11:37:00.500753+00	PENDING_CREATE	2026-06-02 20:05:03.896658+00	f	1
5	1	7	FAT-0001/2026	1	2026	STECH-MZ-2026-XXXX	1	2026-06-01 09:53:34.320965+00	f	\N	2026-06-02 11:37:00.500753+00	PENDING_CREATE	2026-06-02 20:05:03.896658+00	f	1
3	4	7	NCO-0001/2026	1	2026	STECH-MZ-2026-XXXX	1	2026-06-01 09:33:55.910049+00	t	erro da periodicidade	2026-06-02 11:37:00.500753+00	PENDING_CREATE	2026-06-02 20:05:03.896658+00	f	1
6	1	13	FAT-0002/2026	2	2026	STECH-MZ-2026-XXXX	1	2026-06-02 07:59:12.215791+00	f	\N	2026-06-02 11:37:00.500753+00	PENDING_CREATE	2026-06-02 20:05:03.896658+00	f	1
7	5	13	VD-0001/2026	1	2026	STECH-MZ-2026-XXXX	1	2026-06-02 08:57:16.944864+00	f	\N	2026-06-02 11:37:00.500753+00	PENDING_CREATE	2026-06-02 20:05:03.896658+00	f	1
8	5	11	VD-0002/2026	2	2026	STECH-MZ-2026-XXXX	1	2026-06-02 09:03:56.227699+00	f	\N	2026-06-02 11:37:00.500753+00	PENDING_CREATE	2026-06-02 20:05:03.896658+00	f	1
9	5	13	VD-0003/2026	3	2026	STECH-MZ-2026-XXXX	1	2026-06-02 09:10:11.255443+00	f	\N	2026-06-02 11:37:00.500753+00	PENDING_CREATE	2026-06-02 20:05:03.896658+00	f	1
10	5	13	VD-0004/2026	4	2026	STECH-MZ-2026-XXXX	1	2026-06-02 09:10:30.01841+00	f	\N	2026-06-02 11:37:00.500753+00	PENDING_CREATE	2026-06-02 20:05:03.896658+00	f	1
11	4	13	NCO-0002/2026	2	2026	STECH-MZ-2026-XXXX	1	2026-06-02 09:42:40.34063+00	f	\N	2026-06-02 11:37:00.500753+00	PENDING_CREATE	2026-06-02 20:05:03.896658+00	f	1
12	1	13	FAT-0003/2026	3	2026	STECH-MZ-2026-XXXX	1	2026-06-02 11:54:56.918644+00	f	\N	2026-06-02 11:54:56.918644+00	PENDING_CREATE	2026-06-02 20:05:03.896658+00	f	1
13	3	13	REC-0002/2026	2	2026	STECH-MZ-2026-XXXX	1	2026-06-02 11:55:47.140409+00	f	\N	2026-06-02 11:55:47.140409+00	PENDING_CREATE	2026-06-02 20:05:03.896658+00	f	1
14	5	13	VD-0005/2026	5	2026	STECH-MZ-2026-XXXX	1	2026-06-02 11:56:30.807438+00	f	\N	2026-06-02 11:56:30.807438+00	PENDING_CREATE	2026-06-02 20:05:03.896658+00	f	1
15	1	13	FAT-0004/2026	4	2026	STECH-MZ-2026-XXXX	1	2026-06-03 07:40:39.52625+00	f	\N	2026-06-03 07:40:39.52625+00	PENDING_CREATE	2026-06-03 07:40:39.52625+00	f	1
\.


--
-- Data for Name: documento_fiscal_pedido; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.documento_fiscal_pedido (id_documento, id_pedido) FROM stdin;
2	7
2	6
2	5
3	7
3	6
3	5
4	7
4	6
4	5
5	7
5	6
5	5
6	13
6	8
6	7
6	6
6	5
7	13
7	8
8	11
8	9
9	13
9	8
9	7
9	6
9	5
10	13
11	13
11	8
11	7
11	6
11	5
12	13
12	8
12	7
12	6
12	5
13	13
13	8
13	7
13	6
13	5
14	13
14	8
14	7
14	6
14	5
15	13
15	8
15	7
15	6
15	5
\.


--
-- Data for Name: flyway_schema_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success) FROM stdin;
1	0	<< Flyway Baseline >>	BASELINE	<< Flyway Baseline >>	\N	postgres	2026-05-22 11:11:07.760064	0	t
\.


--
-- Data for Name: historico_senhas; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.historico_senhas (id_historico, id_usuario, senha_hash, data_alteracao) FROM stdin;
1	3	$2a$10$8ZINOFAF1MXKxa4YnAt0duyvqU8YmxEPN9Y0t/OLD2Mib43Zxkuuq	2026-05-28 07:37:39.010348+00
\.


--
-- Data for Name: item_pedido; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.item_pedido (id_item_pedido, id_pedido, id_produto, quantidade, preco_unitario, created_at) FROM stdin;
1	5	3	1	3000.00	2026-06-02 20:10:42.378776+00
2	6	1	1	4500.00	2026-06-02 20:10:42.378776+00
3	7	3	1	3000.00	2026-06-02 20:10:42.378776+00
4	8	1	1	4500.00	2026-06-02 20:10:42.378776+00
5	10	3	1	3000.00	2026-06-02 20:10:42.378776+00
6	11	1	1	4500.00	2026-06-02 20:10:42.378776+00
7	12	3	1	3000.00	2026-06-02 20:10:42.378776+00
8	13	1	1	4500.00	2026-06-02 20:10:42.378776+00
\.


--
-- Data for Name: item_pedido_servico; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.item_pedido_servico (id_item_servico, id_pedido, id_servico, quantidade, preco_unitario, observacoes, created_at) FROM stdin;
1	6	22	1	2500.00	\N	2026-06-02 20:10:42.378776+00
2	9	22	1	2500.00	\N	2026-06-02 20:10:42.378776+00
\.


--
-- Data for Name: logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.logs (id_log, id_usuario, acao, detalhes, ip, data_hora) FROM stdin;
\.


--
-- Data for Name: marca; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.marca (id_marca, nome_marca, created_at, updated_at, deleted, sync_status, version) FROM stdin;
1	HP	2026-06-02 20:07:18.64184+00	2026-06-02 20:07:18.64184+00	f	SYNCED	1
2	Aramco	2026-06-02 20:07:18.64184+00	2026-06-02 20:07:18.64184+00	f	SYNCED	1
3	Nataraj	2026-06-02 20:07:18.64184+00	2026-06-02 20:07:18.64184+00	f	SYNCED	1
4	Bic	2026-06-02 20:07:18.64184+00	2026-06-02 20:07:18.64184+00	f	SYNCED	1
5	TpLink	2026-06-02 20:07:18.64184+00	2026-06-02 20:07:18.64184+00	f	SYNCED	1
6	D-Link	2026-06-02 20:07:18.64184+00	2026-06-02 20:07:18.64184+00	f	SYNCED	1
7	Cisco	2026-06-02 20:07:18.64184+00	2026-06-02 20:07:18.64184+00	f	SYNCED	1
\.


--
-- Data for Name: movimento_estoque; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.movimento_estoque (id_movimento, id_produto, id_usuario, tipo_movimento, quantidade, quantidade_anterior, quantidade_nova, motivo, data_movimento, sync_status) FROM stdin;
\.


--
-- Data for Name: notificacao; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notificacao (id_notificacao, tipo, mensagem, id_pedido, lida, criado_em) FROM stdin;
\.


--
-- Data for Name: password_resets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.password_resets (id_reset, id_usuario, token_hash, expires_at, used_at, ip_solicitacao, user_agent, criado_em) FROM stdin;
\.


--
-- Data for Name: pedido; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pedido (id_pedido, referencia, id_usuario, id_cliente, id_tipo_pagamento, status_pedido, total, valor_pago, ponto_referencia, observacoes, data_pedido, data_finalizacao, updated_at, deleted, sync_status, version, created_at) FROM stdin;
5	PED-A356C97B	1	1	1	finalizado	3000.00	300.00	\N	\N	2026-05-30 13:57:13.956449+00	2026-05-30 13:57:53.976296+00	2026-06-02 11:37:00.500753+00	f	PENDING_CREATE	1	2026-06-02 20:09:09.016244+00
6	PED-BB503938	1	1	1	finalizado	7000.00	7000.00	\N	\N	2026-05-30 13:58:11.944247+00	2026-05-30 13:59:11.345403+00	2026-06-02 11:37:00.500753+00	f	PENDING_CREATE	1	2026-06-02 20:09:09.016244+00
7	PED-A6AFA472	1	1	1	finalizado	3000.00	3000.00	\N	\N	2026-06-01 06:19:03.264008+00	2026-06-01 06:19:15.071519+00	2026-06-02 11:37:00.500753+00	f	PENDING_CREATE	1	2026-06-02 20:09:09.016244+00
8	PED-C2FFA6A7	1	1	3	finalizado	4500.00	4500.00	\N	\N	2026-06-01 13:30:45.760949+00	2026-06-02 06:18:22.731314+00	2026-06-02 11:37:00.500753+00	f	PENDING_CREATE	1	2026-06-02 20:09:09.016244+00
9	PED-66600AE2	1	2	3	finalizado	2500.00	2500.00	\N	\N	2026-06-02 06:19:02.013023+00	2026-06-02 06:19:15.666947+00	2026-06-02 11:37:00.500753+00	f	PENDING_CREATE	1	2026-06-02 20:09:09.016244+00
10	PED-3FCC6AE1	1	\N	4	finalizado	3000.00	3000.00	\N	\N	2026-06-02 06:48:37.536404+00	2026-06-02 06:48:52.398462+00	2026-06-02 11:37:00.500753+00	f	PENDING_CREATE	1	2026-06-02 20:09:09.016244+00
11	PED-5DAFC6E7	1	2	2	finalizado	4500.00	4500.00	\N	\N	2026-06-02 06:49:07.636409+00	2026-06-02 06:49:24.221769+00	2026-06-02 11:37:00.500753+00	f	PENDING_CREATE	1	2026-06-02 20:09:09.016244+00
13	PED-02A80571	1	1	2	finalizado	4500.00	4500.00	\N	\N	2026-06-02 07:56:44.306918+00	2026-06-02 07:58:02.553556+00	2026-06-02 11:37:00.500753+00	f	PENDING_CREATE	1	2026-06-02 20:09:09.016244+00
12	PED-0DDBBE93	1	\N	1	cancelado	3000.00	0.00	\N	\N	2026-06-02 06:58:45.293238+00	2026-06-02 07:58:17.369946+00	2026-06-02 11:37:00.500753+00	f	PENDING_CREATE	1	2026-06-02 20:09:09.016244+00
\.


--
-- Data for Name: pedido_cancelamento; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pedido_cancelamento (id_cancelamento, id_pedido, id_usuario_cancelou, motivo, data_cancelamento, created_at) FROM stdin;
1	12	1	Cancelado pelo operador	2026-06-02 07:58:17.387899+00	2026-06-02 20:10:42.378776+00
\.


--
-- Data for Name: perfil; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.perfil (id_perfil, nome_perfil, descricao) FROM stdin;
1	Administrador	\N
2	Gerente	\N
3	Funcionário	\N
\.


--
-- Data for Name: perfil_cliente; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.perfil_cliente (id_perfil_cliente, nome_perfil_cliente, descricao) FROM stdin;
1	Empresas	\N
2	Clientes Singulares	\N
\.


--
-- Data for Name: produto; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.produto (id_produto, nome_produto, descricao, preco, quantidade_estoque, preco_promocional, ativo, data_cadastro, updated_at, deleted, sync_status, version, created_at) FROM stdin;
2	Cisco Switch	\N	6000.00	4	\N	1	2026-05-26 21:23:48.630991	2026-06-02 11:37:00.500753+00	f	SYNCED	1	2026-06-02 20:10:42.378776+00
1	Tp Link Switch	\N	4500.00	0	\N	1	2026-05-26 21:05:35.593723	2026-06-02 11:37:00.500753+00	f	SYNCED	1	2026-06-02 20:10:42.378776+00
3	Impressora térmica 80 mm	\N	3000.00	3	\N	1	2026-05-26 21:25:53.077022	2026-06-02 11:37:00.500753+00	f	SYNCED	1	2026-06-02 20:10:42.378776+00
4	Switch D-Link	\N	5500.00	1	\N	1	2026-05-26 21:40:12.348064	2026-06-02 11:37:00.500753+00	f	PENDING_UPDATE	3	2026-06-02 20:10:42.378776+00
\.


--
-- Data for Name: produto_categoria; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.produto_categoria (id_produto, id_categoria) FROM stdin;
1	3
2	3
3	5
4	3
\.


--
-- Data for Name: produto_imagem; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.produto_imagem (id_imagem, id_produto, caminho_imagem, legenda, imagem_principal) FROM stdin;
1	1	/uploads/produtos/1779823086092_Tp-link_Tplink_24_Port_Gigabit_Ethernet_Switch__Desktop_Rackmount__Limited_Lifetime_Protection__Plug__Play__Shielded_Ports__Sturdy_Metal__Fanless_Quie.jfif	\N	1
2	2	/uploads/produtos/1779823428823_Why_You_Should_Go_For_Used_Network_Equipment__-_Digital_Warehouse.jfif	\N	1
3	3	/uploads/produtos/1779823553231_Gemini_Generated_Image_7b8wkt7b8wkt7b8w.png	\N	1
4	4	/uploads/produtos/1779824412586_Switch.jfif	\N	1
\.


--
-- Data for Name: produto_marca; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.produto_marca (id_produto, id_marca) FROM stdin;
1	5
2	7
3	1
4	6
\.


--
-- Data for Name: servico; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.servico (id_servico, nome_servico, descricao, preco_unitario, unidade, ativo, created_at, updated_at, deleted, sync_status, version) FROM stdin;
3	Cópia de cartões á preto e branco	Papel A4	10.00	página	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
4	Impressão á Preto e Branco	Papel A4	5.00	página	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
5	Impressão á cor	Papel A4	50.00	página	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
6	Impressão á cor na cartolina	Cartolina A4	100.00	página	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
7	Impressão de foto	Papel foto A4	150.00	página	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
8	Cópia á Preto e Branco	Papel A3	10.00	página	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
10	Impressão á preto e Branco	Papel A3	10.00	página	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
11	Impressão á cor	papel A3	50.00	página	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
12	Digitação	Por página	35.00	página	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
13	Editar Documento	Por página	25.00	página	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
14	SCAN	Por página	25.00	página	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
15	Edição de PDF	Por página	100.00	página	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
16	Curriculum Vitae	Simples	300.00	completo	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
17	Curriculum Vitae	Profissional	800.00	completo	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
18	Edição de design	por página	100.00	página	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
19	Criar Logotipo	design	2500.00	completo	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
20	Redesenhar Logotipo	design	1500.00	completo	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
21	Flyer	design	1200.00	completo	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
9	Cópia á cor	Papel A3	50.00	página	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
22	Montagem de câmeras	por remessa	2500.00	cada	t	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
2	Cópia á cor	Papel A4	50.00	página	f	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
1	Cópia á Preto e Branco	Papel A4	3.00	página	f	2026-06-02 11:37:00.500753+00	2026-06-02 11:37:00.500753+00	f	SYNCED	1
\.


--
-- Data for Name: tipo_documento_fiscal; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tipo_documento_fiscal (id_tipo_doc, codigo, nome, prefixo, seq_name) FROM stdin;
1	FAT	Factura	FAT	seq_fat
2	COT	Cotação	COT	seq_cot
3	REC	Recibo	REC	seq_rec
4	NCO	Nota de Compra	NCO	seq_nco
5	VD	Venda á Dinheiro	VD	seq_vd
\.


--
-- Data for Name: tipo_pagamento; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tipo_pagamento (id_tipo_pagamento, tipo_pagamento) FROM stdin;
1	Dinheiro em Espécie
2	POS
3	M-pesa
4	Emola
\.


--
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.usuario (id_usuario, nome, apelido, email, senha_hash, ativo, id_perfil, criado_em, atualizado_em, primeira_senha, telefone, deleted, sync_status, version, created_at, updated_at, local_id) FROM stdin;
1	Matias	Matavel	matiasmatavel1233@gmail.com	$2a$12$iQavzsnBPdaoFq/T80RiMuq/LxQsUmKlOwDivJvHpgIdvFhCItkFO	t	1	2026-05-23 08:05:34.93191+00	2026-05-23 22:13:00.876315+00	f	876821594	f	SYNCED	1	2026-06-02 13:03:32.852622	2026-06-02 13:03:32.852622	\N
3	Funcionario	1	Funcionario@gmail.com	$2a$10$jLJl1FGs4Moy1.vZNnT7BusW53C/kOfFHol0u1dmXtofNR1vHBA.a	t	3	2026-05-23 22:45:22.114106+00	2026-05-28 07:37:39.134167+00	f	876821595	f	SYNCED	1	2026-06-02 13:03:32.852622	2026-06-02 13:03:32.852622	\N
4	Gerente	1	Gerente1@gmail.com	$2a$10$e8d5WPplsKbzH.AHVlZL4O1yMm8xQkBotD6KnCwbm1BNBLWshJm/S	t	2	2026-05-23 23:07:18.325673+00	2026-05-23 23:07:52.291506+00	t	876821596	f	SYNCED	1	2026-06-02 13:03:32.852622	2026-06-02 13:03:32.852622	\N
\.


--
-- Name: categoria_id_categoria_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.categoria_id_categoria_seq', 5, true);


--
-- Name: cliente_id_cliente_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cliente_id_cliente_seq', 2, true);


--
-- Name: documento_fiscal_id_documento_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.documento_fiscal_id_documento_seq', 15, true);


--
-- Name: historico_senhas_id_historico_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.historico_senhas_id_historico_seq', 1, false);


--
-- Name: historico_senhas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.historico_senhas_id_seq', 1, true);


--
-- Name: item_pedido_id_item_pedido_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.item_pedido_id_item_pedido_seq', 8, true);


--
-- Name: item_pedido_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.item_pedido_id_seq', 16, true);


--
-- Name: item_pedido_servico_id_item_servico_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.item_pedido_servico_id_item_servico_seq', 2, true);


--
-- Name: item_pedido_servico_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.item_pedido_servico_id_seq', 7, true);


--
-- Name: logs_id_log_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.logs_id_log_seq', 1, false);


--
-- Name: logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.logs_id_seq', 1, false);


--
-- Name: marca_id_marca_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.marca_id_marca_seq', 7, true);


--
-- Name: movimento_estoque_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.movimento_estoque_id_seq', 1, false);


--
-- Name: notificacao_id_notificacao_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notificacao_id_notificacao_seq', 1, false);


--
-- Name: notificacao_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notificacao_id_seq', 1, false);


--
-- Name: password_resets_id_reset_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.password_resets_id_reset_seq', 1, false);


--
-- Name: password_resets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.password_resets_id_seq', 1, false);


--
-- Name: pedido_cancelamento_id_cancelamento_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pedido_cancelamento_id_cancelamento_seq', 1, true);


--
-- Name: pedido_cancelamento_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pedido_cancelamento_id_seq', 9, true);


--
-- Name: pedido_id_pedido_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pedido_id_pedido_seq', 13, true);


--
-- Name: pedido_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pedido_id_seq', 15, true);


--
-- Name: perfil_cliente_id_perfil_cliente_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.perfil_cliente_id_perfil_cliente_seq', 2, true);


--
-- Name: perfil_id_perfil_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.perfil_id_perfil_seq', 3, true);


--
-- Name: produto_id_produto_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.produto_id_produto_seq', 1, true);


--
-- Name: produto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.produto_id_seq', 4, true);


--
-- Name: produto_imagem_id_imagem_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.produto_imagem_id_imagem_seq', 1, true);


--
-- Name: produto_imagem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.produto_imagem_id_seq', 4, true);


--
-- Name: seq_cot; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.seq_cot', 2, true);


--
-- Name: seq_fat; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.seq_fat', 4, true);


--
-- Name: seq_nco; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.seq_nco', 2, true);


--
-- Name: seq_rec; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.seq_rec', 2, true);


--
-- Name: seq_vd; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.seq_vd', 5, true);


--
-- Name: servico_id_servico_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.servico_id_servico_seq', 22, true);


--
-- Name: tipo_documento_fiscal_id_tipo_doc_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipo_documento_fiscal_id_tipo_doc_seq', 5, true);


--
-- Name: tipo_pagamento_id_tipo_pagamento_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipo_pagamento_id_tipo_pagamento_seq', 4, true);


--
-- Name: usuario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.usuario_id_seq', 5, false);


--
-- Name: usuario_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.usuario_id_usuario_seq', 4, true);


--
-- Name: categoria_marca categoria_marca_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categoria_marca
    ADD CONSTRAINT categoria_marca_pkey PRIMARY KEY (id_categoria, id_marca);


--
-- Name: categoria categoria_nome_categoria_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_nome_categoria_key UNIQUE (nome_categoria);


--
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id_categoria);


--
-- Name: cliente cliente_contacto_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_contacto_key UNIQUE (contacto);


--
-- Name: cliente cliente_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_email_key UNIQUE (email);


--
-- Name: cliente cliente_morada_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_morada_key UNIQUE (morada);


--
-- Name: cliente cliente_nuit_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_nuit_key UNIQUE (nuit);


--
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (id_cliente);


--
-- Name: documento_fiscal_pedido documento_fiscal_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documento_fiscal_pedido
    ADD CONSTRAINT documento_fiscal_pedido_pkey PRIMARY KEY (id_documento, id_pedido);


--
-- Name: documento_fiscal documento_fiscal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documento_fiscal
    ADD CONSTRAINT documento_fiscal_pkey PRIMARY KEY (id_documento);


--
-- Name: documento_fiscal documento_fiscal_referencia_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documento_fiscal
    ADD CONSTRAINT documento_fiscal_referencia_key UNIQUE (referencia);


--
-- Name: flyway_schema_history flyway_schema_history_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);


--
-- Name: historico_senhas historico_senhas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_senhas
    ADD CONSTRAINT historico_senhas_pkey PRIMARY KEY (id_historico);


--
-- Name: item_pedido item_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_pedido
    ADD CONSTRAINT item_pedido_pkey PRIMARY KEY (id_item_pedido);


--
-- Name: item_pedido_servico item_pedido_servico_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_pedido_servico
    ADD CONSTRAINT item_pedido_servico_pkey PRIMARY KEY (id_item_servico);


--
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id_log);


--
-- Name: marca marca_nome_marca_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marca
    ADD CONSTRAINT marca_nome_marca_key UNIQUE (nome_marca);


--
-- Name: marca marca_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marca
    ADD CONSTRAINT marca_pkey PRIMARY KEY (id_marca);


--
-- Name: movimento_estoque movimento_estoque_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimento_estoque
    ADD CONSTRAINT movimento_estoque_pkey PRIMARY KEY (id_movimento);


--
-- Name: notificacao notificacao_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificacao
    ADD CONSTRAINT notificacao_pkey PRIMARY KEY (id_notificacao);


--
-- Name: password_resets password_resets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_resets
    ADD CONSTRAINT password_resets_pkey PRIMARY KEY (id_reset);


--
-- Name: pedido_cancelamento pedido_cancelamento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido_cancelamento
    ADD CONSTRAINT pedido_cancelamento_pkey PRIMARY KEY (id_cancelamento);


--
-- Name: pedido pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido
    ADD CONSTRAINT pedido_pkey PRIMARY KEY (id_pedido);


--
-- Name: pedido pedido_referencia_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido
    ADD CONSTRAINT pedido_referencia_key UNIQUE (referencia);


--
-- Name: perfil_cliente perfil_cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfil_cliente
    ADD CONSTRAINT perfil_cliente_pkey PRIMARY KEY (id_perfil_cliente);


--
-- Name: perfil perfil_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfil
    ADD CONSTRAINT perfil_pkey PRIMARY KEY (id_perfil);


--
-- Name: produto_categoria produto_categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produto_categoria
    ADD CONSTRAINT produto_categoria_pkey PRIMARY KEY (id_produto, id_categoria);


--
-- Name: produto_imagem produto_imagem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produto_imagem
    ADD CONSTRAINT produto_imagem_pkey PRIMARY KEY (id_imagem);


--
-- Name: produto_marca produto_marca_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produto_marca
    ADD CONSTRAINT produto_marca_pkey PRIMARY KEY (id_produto, id_marca);


--
-- Name: produto produto_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produto
    ADD CONSTRAINT produto_pkey PRIMARY KEY (id_produto);


--
-- Name: servico servico_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servico
    ADD CONSTRAINT servico_pkey PRIMARY KEY (id_servico);


--
-- Name: tipo_documento_fiscal tipo_documento_fiscal_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_documento_fiscal
    ADD CONSTRAINT tipo_documento_fiscal_codigo_key UNIQUE (codigo);


--
-- Name: tipo_documento_fiscal tipo_documento_fiscal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_documento_fiscal
    ADD CONSTRAINT tipo_documento_fiscal_pkey PRIMARY KEY (id_tipo_doc);


--
-- Name: tipo_documento_fiscal tipo_documento_fiscal_prefixo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_documento_fiscal
    ADD CONSTRAINT tipo_documento_fiscal_prefixo_key UNIQUE (prefixo);


--
-- Name: tipo_documento_fiscal tipo_documento_fiscal_seq_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_documento_fiscal
    ADD CONSTRAINT tipo_documento_fiscal_seq_name_key UNIQUE (seq_name);


--
-- Name: tipo_pagamento tipo_pagamento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_pagamento
    ADD CONSTRAINT tipo_pagamento_pkey PRIMARY KEY (id_tipo_pagamento);


--
-- Name: tipo_pagamento tipo_pagamento_tipo_pagamento_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_pagamento
    ADD CONSTRAINT tipo_pagamento_tipo_pagamento_key UNIQUE (tipo_pagamento);


--
-- Name: usuario usuario_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_email_key UNIQUE (email);


--
-- Name: usuario usuario_local_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_local_id_key UNIQUE (local_id);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);


--
-- Name: flyway_schema_history_s_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


--
-- Name: idx_cliente_sync; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cliente_sync ON public.cliente USING btree (sync_status) WHERE (deleted = false);


--
-- Name: idx_doc_fiscal_emitido; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_doc_fiscal_emitido ON public.documento_fiscal USING btree (emitido_em);


--
-- Name: idx_doc_fiscal_pedido; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_doc_fiscal_pedido ON public.documento_fiscal USING btree (id_pedido);


--
-- Name: idx_doc_fiscal_sync; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_doc_fiscal_sync ON public.documento_fiscal USING btree (sync_status);


--
-- Name: idx_doc_fiscal_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_doc_fiscal_tipo ON public.documento_fiscal USING btree (id_tipo_doc);


--
-- Name: idx_logs_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_logs_data ON public.logs USING btree (data_hora);


--
-- Name: idx_logs_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_logs_usuario ON public.logs USING btree (id_usuario);


--
-- Name: idx_marca_sync; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_marca_sync ON public.marca USING btree (sync_status) WHERE (deleted = false);


--
-- Name: idx_mov_estoque_sync; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mov_estoque_sync ON public.movimento_estoque USING btree (sync_status);


--
-- Name: idx_pedido_sync; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pedido_sync ON public.pedido USING btree (sync_status);


--
-- Name: idx_prod_cat_vinculo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prod_cat_vinculo ON public.produto_categoria USING btree (id_categoria);


--
-- Name: idx_prod_mrc_vinculo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prod_mrc_vinculo ON public.produto_marca USING btree (id_marca);


--
-- Name: idx_produto_sync; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_produto_sync ON public.produto USING btree (sync_status) WHERE (deleted = false);


--
-- Name: idx_servico_sync; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_servico_sync ON public.servico USING btree (sync_status) WHERE (deleted = false);


--
-- Name: categoria_marca categoria_marca_id_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categoria_marca
    ADD CONSTRAINT categoria_marca_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES public.categoria(id_categoria) ON DELETE CASCADE;


--
-- Name: categoria_marca categoria_marca_id_marca_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categoria_marca
    ADD CONSTRAINT categoria_marca_id_marca_fkey FOREIGN KEY (id_marca) REFERENCES public.marca(id_marca) ON DELETE CASCADE;


--
-- Name: cliente cliente_id_perfil_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_id_perfil_cliente_fkey FOREIGN KEY (id_perfil_cliente) REFERENCES public.perfil_cliente(id_perfil_cliente);


--
-- Name: documento_fiscal documento_fiscal_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documento_fiscal
    ADD CONSTRAINT documento_fiscal_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedido(id_pedido);


--
-- Name: documento_fiscal documento_fiscal_id_tipo_doc_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documento_fiscal
    ADD CONSTRAINT documento_fiscal_id_tipo_doc_fkey FOREIGN KEY (id_tipo_doc) REFERENCES public.tipo_documento_fiscal(id_tipo_doc);


--
-- Name: documento_fiscal documento_fiscal_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documento_fiscal
    ADD CONSTRAINT documento_fiscal_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);


--
-- Name: documento_fiscal_pedido documento_fiscal_pedido_id_documento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documento_fiscal_pedido
    ADD CONSTRAINT documento_fiscal_pedido_id_documento_fkey FOREIGN KEY (id_documento) REFERENCES public.documento_fiscal(id_documento) ON DELETE CASCADE;


--
-- Name: documento_fiscal_pedido documento_fiscal_pedido_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documento_fiscal_pedido
    ADD CONSTRAINT documento_fiscal_pedido_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedido(id_pedido);


--
-- Name: produto_imagem fk_imagem_produto; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produto_imagem
    ADD CONSTRAINT fk_imagem_produto FOREIGN KEY (id_produto) REFERENCES public.produto(id_produto) ON DELETE CASCADE;


--
-- Name: historico_senhas historico_senhas_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_senhas
    ADD CONSTRAINT historico_senhas_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;


--
-- Name: item_pedido item_pedido_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_pedido
    ADD CONSTRAINT item_pedido_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedido(id_pedido) ON DELETE CASCADE;


--
-- Name: item_pedido item_pedido_id_produto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_pedido
    ADD CONSTRAINT item_pedido_id_produto_fkey FOREIGN KEY (id_produto) REFERENCES public.produto(id_produto);


--
-- Name: item_pedido_servico item_pedido_servico_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_pedido_servico
    ADD CONSTRAINT item_pedido_servico_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedido(id_pedido) ON DELETE CASCADE;


--
-- Name: item_pedido_servico item_pedido_servico_id_servico_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_pedido_servico
    ADD CONSTRAINT item_pedido_servico_id_servico_fkey FOREIGN KEY (id_servico) REFERENCES public.servico(id_servico);


--
-- Name: logs logs_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- Name: notificacao notificacao_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificacao
    ADD CONSTRAINT notificacao_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedido(id_pedido) ON DELETE CASCADE;


--
-- Name: password_resets password_resets_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_resets
    ADD CONSTRAINT password_resets_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;


--
-- Name: pedido_cancelamento pedido_cancelamento_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido_cancelamento
    ADD CONSTRAINT pedido_cancelamento_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedido(id_pedido) ON DELETE CASCADE;


--
-- Name: pedido_cancelamento pedido_cancelamento_id_usuario_cancelou_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido_cancelamento
    ADD CONSTRAINT pedido_cancelamento_id_usuario_cancelou_fkey FOREIGN KEY (id_usuario_cancelou) REFERENCES public.usuario(id_usuario);


--
-- Name: pedido pedido_id_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido
    ADD CONSTRAINT pedido_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.cliente(id_cliente);


--
-- Name: pedido pedido_id_tipo_pagamento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido
    ADD CONSTRAINT pedido_id_tipo_pagamento_fkey FOREIGN KEY (id_tipo_pagamento) REFERENCES public.tipo_pagamento(id_tipo_pagamento);


--
-- Name: pedido pedido_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido
    ADD CONSTRAINT pedido_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);


--
-- Name: usuario usuario_id_perfil_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_id_perfil_fkey FOREIGN KEY (id_perfil) REFERENCES public.perfil(id_perfil);


--
-- PostgreSQL database dump complete
--


