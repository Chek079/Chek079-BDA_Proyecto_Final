--
-- PostgreSQL database dump
--

\restrict XM2Xt4gqLnw4RUEZwSxr85PETmCB3m0ivCQIO3byeeap3IfSXJd8xq1wyo2ybUB

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

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
-- Name: fn_trg_beacon_llegada(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_trg_beacon_llegada() RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
v_area_lower TEXT;
BEGIN
  v_area_lower := LOWER(
    (SELECT b.habitacion FROM beacons b WHERE b.id_beacon = NEW.id_beacon)
  );

  -- Solo actúa si el paciente llega al consultorio
  IF v_area_lower ILIKE '%consultorio%' THEN
    UPDATE sesiones s
    SET    asistencia = TRUE
    FROM   paciente_sesion ps
    WHERE  ps.id_sesion   = s.id_sesion
    AND  ps.id_paciente = NEW.id_paciente
    AND  s.fecha        = NEW.fecha
    AND  s.asistencia   = FALSE;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_trg_beacon_llegada() OWNER TO postgres;

--
-- Name: fn_trg_confirmar_asistencia_nfc(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_trg_confirmar_asistencia_nfc() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.asistencia_confirmada = TRUE THEN
    UPDATE sesiones
    SET    asistencia = TRUE
    WHERE  id_sesion  = NEW.id_sesion;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_trg_confirmar_asistencia_nfc() OWNER TO postgres;

--
-- Name: fn_trg_crear_usuario_paciente(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_trg_crear_usuario_paciente() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO usuarios (login, password, rol, ref_id)
  VALUES ( 'fam_' || NEW.id_paciente, '1234', 'familiar', NEW.id_paciente)
  ON CONFLICT (login) DO NOTHING;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_trg_crear_usuario_paciente() OWNER TO postgres;

--
-- Name: fn_trg_crear_usuario_terapeuta(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_trg_crear_usuario_terapeuta() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO usuarios (login, password, rol, ref_id)
  VALUES ( 'ter_' || NEW.id_terapeuta, '1234', 'terapeuta', NEW.id_terapeuta)
  ON CONFLICT (login) DO NOTHING;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_trg_crear_usuario_terapeuta() OWNER TO postgres;

--
-- Name: fn_trg_validar_horario(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_trg_validar_horario() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.hora_fin <= NEW.hora_inicio THEN
    RAISE EXCEPTION 'La hora de fin (%) debe ser mayor que la hora de inicio (%).',
    NEW.hora_fin, NEW.hora_inicio;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_trg_validar_horario() OWNER TO postgres;

--
-- Name: sp_actualizar_paciente(integer, character varying, character varying, character varying, date, integer, character varying, character varying, character varying, character varying, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_actualizar_paciente(IN p_id_paciente integer, IN p_nombre character varying, IN p_ap_paterno character varying, IN p_ap_materno character varying, IN p_fecha_nac date, IN p_id_sexo integer, IN p_telefono character varying, IN p_correo character varying, IN p_direccion character varying, IN p_diagnostico character varying, IN p_antecedentes text)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE pacientes SET
  nombre               = p_nombre,
  apellido_paterno     = p_ap_paterno,
  apellido_materno     = p_ap_materno,
  fecha_nacimiento     = p_fecha_nac,
  id_sexo              = p_id_sexo,
  telefono             = p_telefono,
  correo               = p_correo,
  direccion            = p_direccion,
  diagnostico_principal = p_diagnostico,
  antecedentes_medicos = p_antecedentes
  WHERE id_paciente = p_id_paciente;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Paciente con ID % no encontrado.', p_id_paciente;
  END IF;
END;
$$;


ALTER PROCEDURE public.sp_actualizar_paciente(IN p_id_paciente integer, IN p_nombre character varying, IN p_ap_paterno character varying, IN p_ap_materno character varying, IN p_fecha_nac date, IN p_id_sexo integer, IN p_telefono character varying, IN p_correo character varying, IN p_direccion character varying, IN p_diagnostico character varying, IN p_antecedentes text) OWNER TO postgres;

--
-- Name: sp_actualizar_sesion(integer, date, time without time zone, time without time zone, integer, boolean, integer, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_actualizar_sesion(IN p_id_sesion integer, IN p_fecha date, IN p_hora_inicio time without time zone, IN p_hora_fin time without time zone, IN p_id_tipo integer, IN p_asistencia boolean, IN p_id_metodo integer, IN p_observaciones text)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE sesiones SET
  fecha                  = p_fecha,
  hora_inicio            = p_hora_inicio,
  hora_fin               = p_hora_fin,
  id_tipo_sesion         = p_id_tipo,
  asistencia             = p_asistencia,
  id_metodo              = p_id_metodo,
  observaciones_clinicas = p_observaciones
  WHERE id_sesion = p_id_sesion;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sesión con ID % no encontrada.', p_id_sesion;
  END IF;
END;
$$;


ALTER PROCEDURE public.sp_actualizar_sesion(IN p_id_sesion integer, IN p_fecha date, IN p_hora_inicio time without time zone, IN p_hora_fin time without time zone, IN p_id_tipo integer, IN p_asistencia boolean, IN p_id_metodo integer, IN p_observaciones text) OWNER TO postgres;

--
-- Name: sp_actualizar_terapeuta(integer, character varying, character varying, character varying, integer, character varying, character varying, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_actualizar_terapeuta(IN p_id_terapeuta integer, IN p_nombre character varying, IN p_ap_paterno character varying, IN p_ap_materno character varying, IN p_id_especialidad integer, IN p_telefono character varying, IN p_correo character varying, IN p_observaciones text)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE terapeutas SET
  nombre           = p_nombre,
  apellido_paterno = p_ap_paterno,
  apellido_materno = p_ap_materno,
  id_especialidad  = p_id_especialidad,
  telefono         = p_telefono,
  correo           = p_correo,
  observaciones    = p_observaciones
  WHERE id_terapeuta = p_id_terapeuta;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Terapeuta con ID % no encontrado.', p_id_terapeuta;
  END IF;
END;
$$;


ALTER PROCEDURE public.sp_actualizar_terapeuta(IN p_id_terapeuta integer, IN p_nombre character varying, IN p_ap_paterno character varying, IN p_ap_materno character varying, IN p_id_especialidad integer, IN p_telefono character varying, IN p_correo character varying, IN p_observaciones text) OWNER TO postgres;

--
-- Name: sp_eliminar_paciente(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_eliminar_paciente(IN p_id_paciente integer)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Las tablas hijas tienen ON DELETE CASCADE, así que basta con esto:
  DELETE FROM pacientes WHERE id_paciente = p_id_paciente;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Paciente con ID % no encontrado.', p_id_paciente;
  END IF;
END;
$$;


ALTER PROCEDURE public.sp_eliminar_paciente(IN p_id_paciente integer) OWNER TO postgres;

--
-- Name: sp_eliminar_sesion(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_eliminar_sesion(IN p_id_sesion integer)
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM asistencias_nfc WHERE id_sesion = p_id_sesion;
  DELETE FROM sesiones WHERE id_sesion = p_id_sesion;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sesión con ID % no encontrada.', p_id_sesion;
  END IF;
END;
$$;


ALTER PROCEDURE public.sp_eliminar_sesion(IN p_id_sesion integer) OWNER TO postgres;

--
-- Name: sp_eliminar_terapeuta(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_eliminar_terapeuta(IN p_id_terapeuta integer)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Verifica que no tenga sesiones futuras activas
  IF EXISTS (
    SELECT 1 FROM terapeuta_sesion ts
    JOIN sesiones s ON s.id_sesion = ts.id_sesion
    WHERE ts.id_terapeuta = p_id_terapeuta
    AND s.fecha >= CURRENT_DATE
    ) THEN
    RAISE EXCEPTION 'No se puede eliminar: el terapeuta tiene sesiones programadas.';
  END IF;

  DELETE FROM terapeutas WHERE id_terapeuta = p_id_terapeuta;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Terapeuta con ID % no encontrado.', p_id_terapeuta;
  END IF;
END;
$$;


ALTER PROCEDURE public.sp_eliminar_terapeuta(IN p_id_terapeuta integer) OWNER TO postgres;

--
-- Name: sp_finalizar_sesion_real(integer, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_finalizar_sesion_real(IN p_id_sesion integer, IN p_observaciones text DEFAULT NULL::text)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE sesiones
  SET    hora_fin_real         = NOW(),
  estado_sesion         = 'FINALIZADA',
  observaciones_clinicas = COALESCE(p_observaciones, observaciones_clinicas)
  WHERE  id_sesion     = p_id_sesion
  AND  estado_sesion = 'EN_CURSO';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sesión % no está en curso.', p_id_sesion;
  END IF;
END;
$$;


ALTER PROCEDURE public.sp_finalizar_sesion_real(IN p_id_sesion integer, IN p_observaciones text) OWNER TO postgres;

--
-- Name: sp_iniciar_sesion_real(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_iniciar_sesion_real(IN p_id_sesion integer)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE sesiones
  SET    hora_inicio_real = NOW(),
  estado_sesion    = 'EN_CURSO',
  asistencia       = TRUE
  WHERE  id_sesion     = p_id_sesion
  AND  estado_sesion = 'PROGRAMADA';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sesión % no está programada o ya fue iniciada.', p_id_sesion;
  END IF;
END;
$$;


ALTER PROCEDURE public.sp_iniciar_sesion_real(IN p_id_sesion integer) OWNER TO postgres;

--
-- Name: sp_insertar_paciente(character varying, character varying, character varying, date, integer, character varying, character varying, character varying, character varying, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_insertar_paciente(IN p_nombre character varying, IN p_ap_paterno character varying, IN p_ap_materno character varying, IN p_fecha_nac date, IN p_id_sexo integer, IN p_telefono character varying, IN p_correo character varying, IN p_direccion character varying, IN p_diagnostico character varying, IN p_antecedentes text)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO pacientes (
    nombre, apellido_paterno, apellido_materno,
    fecha_nacimiento, id_sexo, telefono, correo,
    direccion, diagnostico_principal, antecedentes_medicos
    ) VALUES (
    p_nombre, p_ap_paterno, p_ap_materno,
    p_fecha_nac, p_id_sexo, p_telefono, p_correo,
    p_direccion, p_diagnostico, p_antecedentes
  );
END;
$$;


ALTER PROCEDURE public.sp_insertar_paciente(IN p_nombre character varying, IN p_ap_paterno character varying, IN p_ap_materno character varying, IN p_fecha_nac date, IN p_id_sexo integer, IN p_telefono character varying, IN p_correo character varying, IN p_direccion character varying, IN p_diagnostico character varying, IN p_antecedentes text) OWNER TO postgres;

--
-- Name: sp_insertar_terapeuta(character varying, character varying, character varying, integer, character varying, character varying, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_insertar_terapeuta(IN p_nombre character varying, IN p_ap_paterno character varying, IN p_ap_materno character varying, IN p_id_especialidad integer, IN p_telefono character varying, IN p_correo character varying, IN p_observaciones text)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO terapeutas (
    nombre, apellido_paterno, apellido_materno,
    id_especialidad, telefono, correo, observaciones
    ) VALUES (
    p_nombre, p_ap_paterno, p_ap_materno,
    p_id_especialidad, p_telefono, p_correo, p_observaciones
  );
END;
$$;


ALTER PROCEDURE public.sp_insertar_terapeuta(IN p_nombre character varying, IN p_ap_paterno character varying, IN p_ap_materno character varying, IN p_id_especialidad integer, IN p_telefono character varying, IN p_correo character varying, IN p_observaciones text) OWNER TO postgres;

--
-- Name: sp_kpis_terapeuta(integer, date); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_kpis_terapeuta(IN p_id_terapeuta integer, IN p_fecha date, OUT o_total_citas bigint, OUT o_atendidos bigint, OUT o_en_espera bigint, OUT o_faltas bigint, OUT o_pac_unicos bigint)
LANGUAGE plpgsql
AS $$
BEGIN
  SELECT
  COUNT(*),
  COUNT(CASE WHEN s.asistencia = TRUE  THEN 1 END),
  COUNT(CASE WHEN s.asistencia = FALSE AND s.fecha = CURRENT_DATE THEN 1 END),
  COUNT(CASE WHEN s.asistencia = FALSE AND s.fecha < CURRENT_DATE THEN 1 END),
  COUNT(DISTINCT ps.id_paciente)
  INTO o_total_citas, o_atendidos, o_en_espera, o_faltas, o_pac_unicos
  FROM  terapeuta_sesion ts_rel
  JOIN  sesiones s  ON s.id_sesion  = ts_rel.id_sesion
  JOIN  paciente_sesion ps ON ps.id_sesion = s.id_sesion
  WHERE ts_rel.id_terapeuta = p_id_terapeuta
  AND s.fecha             = p_fecha;

  o_total_citas := COALESCE(o_total_citas, 0);
  o_atendidos   := COALESCE(o_atendidos,   0);
  o_en_espera   := COALESCE(o_en_espera,   0);
  o_faltas      := COALESCE(o_faltas,      0);
  o_pac_unicos  := COALESCE(o_pac_unicos,  0);
END;
$$;


ALTER PROCEDURE public.sp_kpis_terapeuta(IN p_id_terapeuta integer, IN p_fecha date, OUT o_total_citas bigint, OUT o_atendidos bigint, OUT o_en_espera bigint, OUT o_faltas bigint, OUT o_pac_unicos bigint) OWNER TO postgres;

--
-- Name: sp_login(character varying, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_login(IN p_login character varying, IN p_password character varying, OUT o_autenticado boolean, OUT o_user_id integer, OUT o_rol character varying, OUT o_nombre character varying, OUT o_ref_id integer)
LANGUAGE plpgsql
AS $$
BEGIN
  SELECT
  TRUE,
  u.id_usuario,
  u.rol,
  CASE u.rol
  WHEN 'terapeuta' THEN
    (SELECT t.nombre FROM terapeutas t WHERE t.id_terapeuta = u.ref_id)
  WHEN 'familiar' THEN
    (SELECT p.nombre FROM pacientes p WHERE p.id_paciente = u.ref_id)
  ELSE 'Administrador'
  END,
  u.ref_id
  INTO o_autenticado, o_user_id, o_rol, o_nombre, o_ref_id
  FROM usuarios u
  WHERE u.login    = p_login
  AND u.password = p_password
  AND u.activo   = TRUE;

  IF o_user_id IS NULL THEN
    o_autenticado := FALSE;
  END IF;
END;
$$;


ALTER PROCEDURE public.sp_login(IN p_login character varying, IN p_password character varying, OUT o_autenticado boolean, OUT o_user_id integer, OUT o_rol character varying, OUT o_nombre character varying, OUT o_ref_id integer) OWNER TO postgres;

--
-- Name: sp_registrar_sesion(integer, integer, date, time without time zone, time without time zone, integer, boolean, integer, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_registrar_sesion(IN p_id_paciente integer, IN p_id_terapeuta integer, IN p_fecha date, IN p_hora_inicio time without time zone, IN p_hora_fin time without time zone, IN p_id_tipo integer, IN p_asistencia boolean, IN p_id_metodo integer, IN p_observaciones text)
LANGUAGE plpgsql
AS $$
DECLARE
v_id_sesion INTEGER;
BEGIN
  IF EXISTS (
    SELECT 1 FROM terapeuta_sesion ts
    JOIN sesiones s ON s.id_sesion = ts.id_sesion
    WHERE ts.id_terapeuta = p_id_terapeuta
    AND s.fecha = p_fecha
    AND (p_hora_inicio, p_hora_fin) OVERLAPS (s.hora_inicio, s.hora_fin)
    ) THEN
    RAISE EXCEPTION 'El terapeuta ya tiene una sesión en ese horario.';
  END IF;

  INSERT INTO sesiones (
    fecha, hora_inicio, hora_fin,
    id_tipo_sesion, observaciones_clinicas,
    asistencia, id_metodo, estado_sesion
    ) VALUES (
    p_fecha, p_hora_inicio, p_hora_fin,
    p_id_tipo, p_observaciones,
    p_asistencia, p_id_metodo, 'PROGRAMADA'
  )
  RETURNING id_sesion INTO v_id_sesion;

  INSERT INTO paciente_sesion  (id_paciente,  id_sesion) VALUES (p_id_paciente,  v_id_sesion);
  INSERT INTO terapeuta_sesion (id_terapeuta, id_sesion) VALUES (p_id_terapeuta, v_id_sesion);

  -- Vincular paciente con terapeuta si no existe ya
  INSERT INTO paciente_terapeuta (id_paciente, id_terapeuta)
  VALUES (p_id_paciente, p_id_terapeuta)
  ON CONFLICT DO NOTHING;
END;
$$;


ALTER PROCEDURE public.sp_registrar_sesion(IN p_id_paciente integer, IN p_id_terapeuta integer, IN p_fecha date, IN p_hora_inicio time without time zone, IN p_hora_fin time without time zone, IN p_id_tipo integer, IN p_asistencia boolean, IN p_id_metodo integer, IN p_observaciones text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: asistencias_nfc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.asistencias_nfc (
  id_asistencia integer NOT NULL,
  id_paciente integer NOT NULL,
  id_sesion integer NOT NULL,
  fecha date NOT NULL,
  hora_entrada time without time zone NOT NULL,
  asistencia_confirmada boolean NOT NULL,
  id_dispositivo integer NOT NULL
);


ALTER TABLE public.asistencias_nfc OWNER TO postgres;

--
-- Name: asistencias_nfc_id_asistencia_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.asistencias_nfc ALTER COLUMN id_asistencia ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.asistencias_nfc_id_asistencia_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: beacon_evento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.beacon_evento (
  id_evento integer NOT NULL,
  id_beacon integer NOT NULL,
  id_paciente integer NOT NULL,
  fecha date NOT NULL,
  hora time without time zone NOT NULL
);


ALTER TABLE public.beacon_evento OWNER TO postgres;

--
-- Name: beacon_evento_id_evento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.beacon_evento ALTER COLUMN id_evento ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.beacon_evento_id_evento_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: beacons; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.beacons (
  id_beacon integer NOT NULL,
  area character varying(50) NOT NULL,
  habitacion character varying(50) NOT NULL,
  id_estado integer NOT NULL
);


ALTER TABLE public.beacons OWNER TO postgres;

--
-- Name: beacons_id_beacon_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.beacons ALTER COLUMN id_beacon ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.beacons_id_beacon_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: cat_especialidades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cat_especialidades (
  id_especialidad integer NOT NULL,
  nombre character varying(100) NOT NULL,
  activo boolean DEFAULT true NOT NULL
);


ALTER TABLE public.cat_especialidades OWNER TO postgres;

--
-- Name: cat_especialidades_id_especialidad_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.cat_especialidades ALTER COLUMN id_especialidad ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.cat_especialidades_id_especialidad_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: cat_estados_beacon; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cat_estados_beacon (
  id_estado integer NOT NULL,
  nombre character(8) NOT NULL,
  activo boolean DEFAULT true NOT NULL
);


ALTER TABLE public.cat_estados_beacon OWNER TO postgres;

--
-- Name: cat_estados_beacon_id_estado_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.cat_estados_beacon ALTER COLUMN id_estado ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.cat_estados_beacon_id_estado_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: cat_estados_dispositivo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cat_estados_dispositivo (
  id_estado integer NOT NULL,
  nombre character varying(20) NOT NULL,
  activo boolean DEFAULT true NOT NULL
);


ALTER TABLE public.cat_estados_dispositivo OWNER TO postgres;

--
-- Name: cat_estados_dispositivo_id_estado_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.cat_estados_dispositivo ALTER COLUMN id_estado ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.cat_estados_dispositivo_id_estado_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: cat_estados_gps; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cat_estados_gps (
  id_estado integer NOT NULL,
  nombre character(10) NOT NULL,
  activo boolean DEFAULT true NOT NULL
);


ALTER TABLE public.cat_estados_gps OWNER TO postgres;

--
-- Name: cat_estados_gps_id_estado_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.cat_estados_gps ALTER COLUMN id_estado ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.cat_estados_gps_id_estado_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: cat_estados_vehiculo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cat_estados_vehiculo (
  id_estado integer NOT NULL,
  nombre character(20) NOT NULL,
  activo boolean DEFAULT true NOT NULL
);


ALTER TABLE public.cat_estados_vehiculo OWNER TO postgres;

--
-- Name: cat_estados_vehiculo_id_estado_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.cat_estados_vehiculo ALTER COLUMN id_estado ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.cat_estados_vehiculo_id_estado_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: cat_metodos_registro; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cat_metodos_registro (
  id_metodo integer NOT NULL,
  nombre character varying(20) NOT NULL,
  activo boolean DEFAULT true NOT NULL
);


ALTER TABLE public.cat_metodos_registro OWNER TO postgres;

--
-- Name: cat_metodos_registro_id_metodo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.cat_metodos_registro ALTER COLUMN id_metodo ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.cat_metodos_registro_id_metodo_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: cat_nivel_dificultad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cat_nivel_dificultad (
  id_nivel integer NOT NULL,
  nombre character(5) NOT NULL,
  activo boolean DEFAULT true NOT NULL
);


ALTER TABLE public.cat_nivel_dificultad OWNER TO postgres;

--
-- Name: cat_nivel_dificultad_id_nivel_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.cat_nivel_dificultad ALTER COLUMN id_nivel ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.cat_nivel_dificultad_id_nivel_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: cat_sexo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cat_sexo (
  id_sexo integer NOT NULL,
  nombre character varying(20) NOT NULL,
  activo boolean DEFAULT true NOT NULL
);


ALTER TABLE public.cat_sexo OWNER TO postgres;

--
-- Name: cat_sexo_id_sexo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.cat_sexo ALTER COLUMN id_sexo ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.cat_sexo_id_sexo_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: cat_tipos_ejercicio; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cat_tipos_ejercicio (
  id_tipo_ejercicio integer NOT NULL,
  nombre character varying(50) NOT NULL,
  activo boolean DEFAULT true NOT NULL
);


ALTER TABLE public.cat_tipos_ejercicio OWNER TO postgres;

--
-- Name: cat_tipos_ejercicio_id_tipo_ejercicio_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.cat_tipos_ejercicio ALTER COLUMN id_tipo_ejercicio ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.cat_tipos_ejercicio_id_tipo_ejercicio_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: cat_tipos_sesion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cat_tipos_sesion (
  id_tipo_sesion integer NOT NULL,
  nombre character varying(30) NOT NULL,
  activo boolean DEFAULT true NOT NULL
);


ALTER TABLE public.cat_tipos_sesion OWNER TO postgres;

--
-- Name: cat_tipos_sesion_id_tipo_sesion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.cat_tipos_sesion ALTER COLUMN id_tipo_sesion ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.cat_tipos_sesion_id_tipo_sesion_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: dispositivos_nfc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dispositivos_nfc (
  id_dispositivo integer NOT NULL,
  tipo_dispositivo character varying(50) NOT NULL,
  ubicacion character varying(100) NOT NULL,
  id_estado integer NOT NULL,
  descripcion text
);


ALTER TABLE public.dispositivos_nfc OWNER TO postgres;

--
-- Name: dispositivos_nfc_id_dispositivo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.dispositivos_nfc ALTER COLUMN id_dispositivo ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.dispositivos_nfc_id_dispositivo_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: ejercicio_sesion_detalle; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ejercicio_sesion_detalle (
  id_sesion integer NOT NULL,
  id_ejercicio integer NOT NULL,
  repeticiones smallint NOT NULL,
  duracion_min smallint NOT NULL,
  observaciones text,
  CONSTRAINT ejercicio_sesion_detalle_duracion_min_check CHECK ((duracion_min > 0)),
  CONSTRAINT ejercicio_sesion_detalle_repeticiones_check CHECK ((repeticiones > 0))
);


ALTER TABLE public.ejercicio_sesion_detalle OWNER TO postgres;

--
-- Name: ejercicios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ejercicios (
  id_ejercicio integer NOT NULL,
  nombre_ejercicio character varying(100) NOT NULL,
  descripcion text NOT NULL,
  id_tipo_ejercicio integer NOT NULL,
  id_nivel_dificultad integer NOT NULL
);


ALTER TABLE public.ejercicios OWNER TO postgres;

--
-- Name: ejercicios_id_ejercicio_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.ejercicios ALTER COLUMN id_ejercicio ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.ejercicios_id_ejercicio_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: evaluacion_terapeuta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.evaluacion_terapeuta (
  id_evaluacion integer NOT NULL,
  id_terapeuta integer NOT NULL
);


ALTER TABLE public.evaluacion_terapeuta OWNER TO postgres;

--
-- Name: evaluaciones_progreso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.evaluaciones_progreso (
  id_evaluacion integer NOT NULL,
  fecha date NOT NULL,
  tipo_evaluacion character varying(50) NOT NULL,
  nivel_movilidad smallint NOT NULL,
  nivel_dolor smallint NOT NULL,
  resistencia smallint NOT NULL,
  progreso_observado text,
  recomendaciones text,
  ajustes_plan text,
  CONSTRAINT evaluaciones_progreso_nivel_dolor_check CHECK (((nivel_dolor >= 0) AND (nivel_dolor <= 10))),
  CONSTRAINT evaluaciones_progreso_nivel_movilidad_check CHECK (((nivel_movilidad >= 0) AND (nivel_movilidad <= 10))),
  CONSTRAINT evaluaciones_progreso_resistencia_check CHECK (((resistencia >= 0) AND (resistencia <= 10)))
);


ALTER TABLE public.evaluaciones_progreso OWNER TO postgres;

--
-- Name: evaluaciones_progreso_id_evaluacion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.evaluaciones_progreso ALTER COLUMN id_evaluacion ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.evaluaciones_progreso_id_evaluacion_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: gps_registros; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gps_registros (
  id_registro integer NOT NULL,
  id_paciente integer NOT NULL,
  id_terapeuta integer NOT NULL,
  latitud numeric(8,6) NOT NULL,
  longitud numeric(9,6) NOT NULL,
  fecha date NOT NULL,
  hora time without time zone NOT NULL,
  id_estado integer NOT NULL,
  CONSTRAINT gps_registros_latitud_check CHECK (((latitud >= ('-90'::integer)::numeric) AND (latitud <= (90)::numeric))),
  CONSTRAINT gps_registros_longitud_check CHECK (((longitud >= ('-180'::integer)::numeric) AND (longitud <= (180)::numeric)))
);


ALTER TABLE public.gps_registros OWNER TO postgres;

--
-- Name: gps_registros_id_registro_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.gps_registros ALTER COLUMN id_registro ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.gps_registros_id_registro_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: gps_vehiculo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gps_vehiculo (
  id_registro integer NOT NULL,
  id_vehiculo integer NOT NULL
);


ALTER TABLE public.gps_vehiculo OWNER TO postgres;

--
-- Name: paciente_alergia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.paciente_alergia (
  id_paciente integer NOT NULL,
  alergia character varying(100) NOT NULL
);


ALTER TABLE public.paciente_alergia OWNER TO postgres;

--
-- Name: paciente_evaluacion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.paciente_evaluacion (
  id_paciente integer NOT NULL,
  id_evaluacion integer NOT NULL
);


ALTER TABLE public.paciente_evaluacion OWNER TO postgres;

--
-- Name: paciente_lesion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.paciente_lesion (
  id_paciente integer NOT NULL,
  lesion_previa character varying(100) NOT NULL
);


ALTER TABLE public.paciente_lesion OWNER TO postgres;

--
-- Name: paciente_medicamento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.paciente_medicamento (
  id_paciente integer NOT NULL,
  medicamento_actual character varying(100) NOT NULL
);


ALTER TABLE public.paciente_medicamento OWNER TO postgres;

--
-- Name: paciente_sesion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.paciente_sesion (
  id_paciente integer NOT NULL,
  id_sesion integer NOT NULL
);


ALTER TABLE public.paciente_sesion OWNER TO postgres;

--
-- Name: paciente_terapeuta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.paciente_terapeuta (
  id_paciente integer NOT NULL,
  id_terapeuta integer NOT NULL
);


ALTER TABLE public.paciente_terapeuta OWNER TO postgres;

--
-- Name: pacientes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pacientes (
  id_paciente integer NOT NULL,
  nombre character varying(50) NOT NULL,
  apellido_paterno character varying(50) NOT NULL,
  apellido_materno character varying(50) NOT NULL,
  fecha_nacimiento date NOT NULL,
  id_sexo integer NOT NULL,
  telefono character varying(15),
  correo character varying(100),
  direccion character varying(150),
  diagnostico_principal character varying(100) NOT NULL,
  antecedentes_medicos text,
  nfc_uid character varying(100)
);


ALTER TABLE public.pacientes OWNER TO postgres;

--
-- Name: pacientes_id_paciente_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.pacientes ALTER COLUMN id_paciente ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.pacientes_id_paciente_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: sesiones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sesiones (
  id_sesion integer NOT NULL,
  fecha date NOT NULL,
  hora_inicio time without time zone NOT NULL,
  hora_fin time without time zone NOT NULL,
  id_tipo_sesion integer NOT NULL,
  observaciones_clinicas text,
  asistencia boolean NOT NULL,
  id_metodo integer NOT NULL,
  hora_inicio_real timestamp without time zone,
  hora_fin_real timestamp without time zone,
  estado_sesion character varying(20) DEFAULT 'PROGRAMADA'::character varying,
  CONSTRAINT check_horas CHECK ((hora_fin > hora_inicio)),
  CONSTRAINT sesiones_estado_sesion_check CHECK (((estado_sesion)::text = ANY ((ARRAY['PROGRAMADA'::character varying, 'EN_CURSO'::character varying, 'FINALIZADA'::character varying, 'CANCELADA'::character varying])::text[])))
);


ALTER TABLE public.sesiones OWNER TO postgres;

--
-- Name: sesiones_id_sesion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.sesiones ALTER COLUMN id_sesion ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.sesiones_id_sesion_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: terapeuta_sesion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.terapeuta_sesion (
  id_terapeuta integer NOT NULL,
  id_sesion integer NOT NULL
);


ALTER TABLE public.terapeuta_sesion OWNER TO postgres;

--
-- Name: terapeutas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.terapeutas (
  id_terapeuta integer NOT NULL,
  nombre character varying(50) NOT NULL,
  apellido_paterno character varying(50) NOT NULL,
  apellido_materno character varying(50) NOT NULL,
  id_especialidad integer NOT NULL,
  telefono character varying(15),
  correo character varying(100),
  observaciones text
);


ALTER TABLE public.terapeutas OWNER TO postgres;

--
-- Name: terapeutas_id_terapeuta_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.terapeutas ALTER COLUMN id_terapeuta ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.terapeutas_id_terapeuta_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios (
  id_usuario integer NOT NULL,
  login character varying(30) NOT NULL,
  password character varying(256) NOT NULL,
  rol character varying(20) NOT NULL,
  ref_id integer,
  activo boolean DEFAULT true NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT usuarios_rol_check CHECK (((rol)::text = ANY ((ARRAY['admin'::character varying, 'terapeuta'::character varying, 'familiar'::character varying])::text[])))
);


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.usuarios ALTER COLUMN id_usuario ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.usuarios_id_usuario_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: vehiculos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehiculos (
  id_vehiculo integer NOT NULL,
  tipo character varying(50) NOT NULL,
  descripcion text NOT NULL,
  id_estado integer NOT NULL
);


ALTER TABLE public.vehiculos OWNER TO postgres;

--
-- Name: vehiculos_id_vehiculo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.vehiculos ALTER COLUMN id_vehiculo ADD GENERATED BY DEFAULT AS IDENTITY (
  SEQUENCE NAME public.vehiculos_id_vehiculo_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1
);


--
-- Name: vw_agenda_terapeuta; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_agenda_terapeuta AS
SELECT s.id_sesion,
ts_rel.id_terapeuta,
s.hora_inicio,
s.hora_fin,
s.estado_sesion,
s.hora_inicio_real,
p.id_paciente,
(((p.nombre)::text || ' '::text) || (p.apellido_paterno)::text) AS paciente_nombre,
s.observaciones_clinicas AS tratamiento,
CASE
WHEN ((s.estado_sesion)::text = 'EN_CURSO'::text) THEN 'Consultorio'::text
WHEN ((s.estado_sesion)::text = 'FINALIZADA'::text) THEN 'Finalizada'::text
WHEN (((s.estado_sesion)::text = 'PROGRAMADA'::text) AND (CURRENT_TIME >= (s.hora_inicio)::time with time zone)) THEN 'Sala_Espera'::text
WHEN (((s.estado_sesion)::text = 'PROGRAMADA'::text) AND (CURRENT_TIME >= ((s.hora_inicio - '00:15:00'::interval))::time with time zone)) THEN 'Sala_Espera'::text
ELSE 'No_Llegado'::text
END AS estado_ubicacion
FROM (((public.terapeuta_sesion ts_rel
      JOIN public.sesiones s ON ((s.id_sesion = ts_rel.id_sesion)))
    JOIN public.paciente_sesion ps ON ((ps.id_sesion = s.id_sesion)))
  JOIN public.pacientes p ON ((p.id_paciente = ps.id_paciente)))
WHERE (s.fecha = CURRENT_DATE)
ORDER BY s.hora_inicio;


ALTER VIEW public.vw_agenda_terapeuta OWNER TO postgres;

--
-- Name: vw_dashboard_admin; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_dashboard_admin AS
SELECT ( SELECT count(DISTINCT ps.id_paciente) AS count
  FROM (public.paciente_sesion ps
    JOIN public.sesiones s ON ((s.id_sesion = ps.id_sesion)))
  WHERE ((s.fecha = CURRENT_DATE) AND (s.asistencia = true))) AS total_pacientes_hoy,
( SELECT count(*) AS count
  FROM (public.gps_registros g
    JOIN public.cat_estados_gps e ON ((e.id_estado = g.id_estado)))
  WHERE ((e.nombre = ANY (ARRAY['EN_RUTA'::bpchar, 'LLEGADO'::bpchar])) AND (g.fecha = CURRENT_DATE))) AS rutas_activas,
( SELECT count(*) AS count
  FROM (public.dispositivos_nfc d
    JOIN public.cat_estados_dispositivo e ON ((e.id_estado = d.id_estado)))
  WHERE ((e.nombre)::text = 'MANTENIMIENTO'::text)) AS alertas_iot;


ALTER VIEW public.vw_dashboard_admin OWNER TO postgres;

--
-- Name: vw_expediente_paciente; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_expediente_paciente AS
SELECT p.id_paciente,
p.nombre,
p.apellido_paterno,
p.apellido_materno,
p.fecha_nacimiento,
p.id_sexo,
p.telefono,
p.correo,
p.direccion,
p.diagnostico_principal,
p.antecedentes_medicos,
cs.nombre AS sexo_nombre,
(date_part('year'::text, age((p.fecha_nacimiento)::timestamp with time zone)))::integer AS edad,
ce.nombre AS especialidad_terapeuta,
(((t.nombre)::text || ' '::text) || (t.apellido_paterno)::text) AS terapeuta_asignado,
( SELECT count(*) AS count
  FROM public.paciente_sesion ps2
  WHERE (ps2.id_paciente = p.id_paciente)) AS total_sesiones,
( SELECT max(s2.fecha) AS max
  FROM (public.paciente_sesion ps3
    JOIN public.sesiones s2 ON ((s2.id_sesion = ps3.id_sesion)))
  WHERE (ps3.id_paciente = p.id_paciente)) AS fecha_ultima_sesion
FROM ((((public.pacientes p
        JOIN public.cat_sexo cs ON ((cs.id_sexo = p.id_sexo)))
      LEFT JOIN public.paciente_terapeuta pt ON ((pt.id_paciente = p.id_paciente)))
    LEFT JOIN public.terapeutas t ON ((t.id_terapeuta = pt.id_terapeuta)))
  LEFT JOIN public.cat_especialidades ce ON ((ce.id_especialidad = t.id_especialidad)));


ALTER VIEW public.vw_expediente_paciente OWNER TO postgres;

--
-- Name: vw_historial_paciente; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_historial_paciente AS
SELECT ps.id_paciente,
s.fecha AS fecha_raw,
to_char((s.fecha)::timestamp with time zone, 'DD Mon YYYY'::text) AS fecha_formateada,
to_char((s.hora_inicio)::interval, 'HH12:MI AM'::text) AS hora,
cts.nombre AS tipo_sesion,
e.nombre_ejercicio,
nd.nombre AS dificultad,
(((t.nombre)::text || ' '::text) || (t.apellido_paterno)::text) AS terapeuta,
CASE
WHEN ((ep.nivel_movilidad >= 8) AND (ep.nivel_dolor <= 2)) THEN 'excelente'::text
WHEN ((ep.nivel_movilidad >= 6) AND (ep.nivel_dolor <= 4)) THEN 'bueno'::text
WHEN (ep.nivel_movilidad >= 4) THEN 'regular'::text
ELSE 'malo'::text
END AS evaluacion_clase,
CASE
WHEN ((ep.nivel_movilidad >= 8) AND (ep.nivel_dolor <= 2)) THEN 'Excelente progreso'::text
WHEN ((ep.nivel_movilidad >= 6) AND (ep.nivel_dolor <= 4)) THEN 'Buen avance'::text
WHEN (ep.nivel_movilidad >= 4) THEN 'Avance moderado'::text
ELSE 'Requiere atención'::text
END AS evaluacion_texto,
COALESCE(s.observaciones_clinicas, ep.progreso_observado, 'Sin observaciones registradas.'::text) AS observaciones
FROM (((((((((public.paciente_sesion ps
                  JOIN public.sesiones s ON ((s.id_sesion = ps.id_sesion)))
                JOIN public.cat_tipos_sesion cts ON ((cts.id_tipo_sesion = s.id_tipo_sesion)))
              JOIN public.terapeuta_sesion ts_rel ON ((ts_rel.id_sesion = s.id_sesion)))
            JOIN public.terapeutas t ON ((t.id_terapeuta = ts_rel.id_terapeuta)))
          LEFT JOIN public.ejercicio_sesion_detalle esd ON ((esd.id_sesion = s.id_sesion)))
        LEFT JOIN public.ejercicios e ON ((e.id_ejercicio = esd.id_ejercicio)))
      LEFT JOIN public.cat_nivel_dificultad nd ON ((nd.id_nivel = e.id_nivel_dificultad)))
    LEFT JOIN public.paciente_evaluacion pev ON ((pev.id_paciente = ps.id_paciente)))
  LEFT JOIN public.evaluaciones_progreso ep ON (((ep.id_evaluacion = pev.id_evaluacion) AND (ep.fecha = s.fecha))));


ALTER VIEW public.vw_historial_paciente OWNER TO postgres;

--
-- Name: vw_historial_sesiones; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_historial_sesiones AS
SELECT s.id_sesion,
s.fecha,
s.hora_inicio,
s.hora_fin,
ts_rel.id_terapeuta,
p.id_paciente,
(((p.nombre)::text || ' '::text) || (p.apellido_paterno)::text) AS paciente_nombre,
e.nombre_ejercicio,
nd.nombre AS nivel_dificultad,
ep.nivel_movilidad,
ep.nivel_dolor,
(ep.nivel_movilidad + (10 - ep.nivel_dolor)) AS score_progreso,
CASE
WHEN ((ep.nivel_movilidad >= 8) AND (ep.nivel_dolor <= 2)) THEN 'Excelente'::text
WHEN ((ep.nivel_movilidad >= 6) AND (ep.nivel_dolor <= 4)) THEN 'Bueno'::text
WHEN (ep.nivel_movilidad >= 4) THEN 'Regular'::text
ELSE 'Malo'::text
END AS evaluacion,
ep.progreso_observado
FROM ((((((((public.terapeuta_sesion ts_rel
                JOIN public.sesiones s ON ((s.id_sesion = ts_rel.id_sesion)))
              JOIN public.paciente_sesion ps ON ((ps.id_sesion = s.id_sesion)))
            JOIN public.pacientes p ON ((p.id_paciente = ps.id_paciente)))
          LEFT JOIN public.ejercicio_sesion_detalle esd ON ((esd.id_sesion = s.id_sesion)))
        LEFT JOIN public.ejercicios e ON ((e.id_ejercicio = esd.id_ejercicio)))
      LEFT JOIN public.cat_nivel_dificultad nd ON ((nd.id_nivel = e.id_nivel_dificultad)))
    LEFT JOIN public.paciente_evaluacion pev ON ((pev.id_paciente = ps.id_paciente)))
  LEFT JOIN public.evaluaciones_progreso ep ON (((ep.id_evaluacion = pev.id_evaluacion) AND (ep.fecha = s.fecha))));


ALTER VIEW public.vw_historial_sesiones OWNER TO postgres;

--
-- Name: vw_mis_pacientes; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_mis_pacientes AS
SELECT pt.id_terapeuta,
p.id_paciente,
(((p.nombre)::text || ' '::text) || (p.apellido_paterno)::text) AS nombre,
(date_part('year'::text, age((p.fecha_nacimiento)::timestamp with time zone)))::integer AS edad,
p.diagnostico_principal AS diagnostico,
ce.nombre AS tipo_terapia,
( SELECT max(s2.fecha) AS max
  FROM (public.paciente_sesion ps2
    JOIN public.sesiones s2 ON ((s2.id_sesion = ps2.id_sesion)))
  WHERE (ps2.id_paciente = p.id_paciente)) AS ultima_sesion,
'Activo'::text AS estado
FROM (((public.paciente_terapeuta pt
      JOIN public.pacientes p ON ((p.id_paciente = pt.id_paciente)))
    JOIN public.terapeutas t ON ((t.id_terapeuta = pt.id_terapeuta)))
  JOIN public.cat_especialidades ce ON ((ce.id_especialidad = t.id_especialidad)));


ALTER VIEW public.vw_mis_pacientes OWNER TO postgres;

--
-- Name: vw_pacientes_completo; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_pacientes_completo AS
SELECT p.id_paciente,
p.nombre,
p.apellido_paterno,
p.apellido_materno,
(((((p.nombre)::text || ' '::text) || (p.apellido_paterno)::text) || ' '::text) || (p.apellido_materno)::text) AS nombre_completo,
p.fecha_nacimiento,
(date_part('year'::text, age((p.fecha_nacimiento)::timestamp with time zone)))::integer AS edad,
cs.nombre AS sexo,
p.telefono,
p.correo,
p.direccion,
p.diagnostico_principal,
p.antecedentes_medicos
FROM (public.pacientes p
  JOIN public.cat_sexo cs ON ((cs.id_sexo = p.id_sexo)));


ALTER VIEW public.vw_pacientes_completo OWNER TO postgres;

--
-- Name: vw_reporte_asistencia; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_reporte_asistencia AS
SELECT p.id_paciente,
(((p.nombre)::text || ' '::text) || (p.apellido_paterno)::text) AS paciente,
count(ps.id_sesion) AS total_sesiones,
count(
  CASE
  WHEN (s.asistencia = true) THEN 1
  ELSE NULL::integer
  END) AS sesiones_asistidas,
count(
  CASE
  WHEN (s.asistencia = false) THEN 1
  ELSE NULL::integer
  END) AS sesiones_faltadas,
round((((count(
          CASE
          WHEN (s.asistencia = true) THEN 1
          ELSE NULL::integer
          END))::numeric / (NULLIF(count(ps.id_sesion), 0))::numeric) * (100)::numeric), 1) AS porcentaje_asistencia
FROM ((public.paciente_sesion ps
    JOIN public.pacientes p ON ((p.id_paciente = ps.id_paciente)))
  JOIN public.sesiones s ON ((s.id_sesion = ps.id_sesion)))
GROUP BY p.id_paciente, p.nombre, p.apellido_paterno
ORDER BY (round((((count(
            CASE
            WHEN (s.asistencia = true) THEN 1
            ELSE NULL::integer
            END))::numeric / (NULLIF(count(ps.id_sesion), 0))::numeric) * (100)::numeric), 1)) DESC;


ALTER VIEW public.vw_reporte_asistencia OWNER TO postgres;

--
-- Name: vw_rutas_domicilio; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_rutas_domicilio AS
SELECT g.id_registro,
g.id_terapeuta,
g.id_paciente,
(((p.nombre)::text || ' '::text) || (p.apellido_paterno)::text) AS paciente_nombre,
p.direccion,
g.latitud,
g.longitud,
g.fecha,
g.hora,
eg.nombre AS estado_gps,
v.tipo AS tipo_vehiculo
FROM ((((public.gps_registros g
        JOIN public.pacientes p ON ((p.id_paciente = g.id_paciente)))
      JOIN public.cat_estados_gps eg ON ((eg.id_estado = g.id_estado)))
    LEFT JOIN public.gps_vehiculo gv ON ((gv.id_registro = g.id_registro)))
  LEFT JOIN public.vehiculos v ON ((v.id_vehiculo = gv.id_vehiculo)));


ALTER VIEW public.vw_rutas_domicilio OWNER TO postgres;

--
-- Name: vw_sesiones_detalle; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_sesiones_detalle AS
SELECT s.id_sesion,
s.fecha,
s.hora_inicio,
s.hora_fin,
cts.nombre AS tipo_sesion,
s.asistencia,
s.observaciones_clinicas,
cmr.nombre AS metodo_registro,
( SELECT (((p.nombre)::text || ' '::text) || (p.apellido_paterno)::text)
  FROM (public.paciente_sesion ps2
    JOIN public.pacientes p ON ((p.id_paciente = ps2.id_paciente)))
  WHERE (ps2.id_sesion = s.id_sesion)
  LIMIT 1) AS paciente_nombre,
( SELECT (((t.nombre)::text || ' '::text) || (t.apellido_paterno)::text)
  FROM (public.terapeuta_sesion ts2
    JOIN public.terapeutas t ON ((t.id_terapeuta = ts2.id_terapeuta)))
  WHERE (ts2.id_sesion = s.id_sesion)
  LIMIT 1) AS terapeuta_nombre
FROM ((public.sesiones s
    JOIN public.cat_tipos_sesion cts ON ((cts.id_tipo_sesion = s.id_tipo_sesion)))
  JOIN public.cat_metodos_registro cmr ON ((cmr.id_metodo = s.id_metodo)));


ALTER VIEW public.vw_sesiones_detalle OWNER TO postgres;

--
-- Name: vw_terapeutas_completo; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_terapeutas_completo AS
SELECT t.id_terapeuta,
t.nombre,
t.apellido_paterno,
t.apellido_materno,
(((t.nombre)::text || ' '::text) || (t.apellido_paterno)::text) AS nombre_completo,
ce.nombre AS especialidad,
t.telefono,
t.correo,
t.observaciones
FROM (public.terapeutas t
  JOIN public.cat_especialidades ce ON ((ce.id_especialidad = t.id_especialidad)));


ALTER VIEW public.vw_terapeutas_completo OWNER TO postgres;

--
-- Data for Name: asistencias_nfc; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.asistencias_nfc (id_asistencia, id_paciente, id_sesion, fecha, hora_entrada, asistencia_confirmada, id_dispositivo) FROM stdin;
\.


--
-- Data for Name: beacon_evento; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.beacon_evento (id_evento, id_beacon, id_paciente, fecha, hora) FROM stdin;
1	4	1	2024-11-04	08:52:00
2	1	1	2024-11-04	09:00:00
3	4	2	2024-11-04	09:54:00
4	2	2	2024-11-04	10:00:00
5	4	3	2024-11-05	08:25:00
6	1	3	2024-11-05	08:30:00
7	3	5	2024-11-06	09:10:00
8	5	7	2024-11-06	09:02:00
9	4	8	2024-11-07	07:55:00
10	2	8	2024-11-07	08:00:00
\.


--
-- Data for Name: beacons; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.beacons (id_beacon, area, habitacion, id_estado) FROM stdin;
1	Fisioterapia	Sala A	1
2	Fisioterapia	Sala B	1
3	Gimnasio	Área de máquinas	1
4	Recepción	Lobby	1
5	Hidroterapia	Piscina terapéutica	1
6	Consultorios	Consultorio 1	2
\.


--
-- Data for Name: cat_especialidades; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cat_especialidades (id_especialidad, nombre, activo) FROM stdin;
1	Fisioterapia Musculoesquelética	t
2	Neurorehabilitación	t
3	Rehabilitación Cardiopulmonar	t
4	Fisioterapia Deportiva	t
5	Fisioterapia Pediátrica	t
\.


--
-- Data for Name: cat_estados_beacon; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cat_estados_beacon (id_estado, nombre, activo) FROM stdin;
1	ACTIVO  	t
2	INACTIVO	t
\.


--
-- Data for Name: cat_estados_dispositivo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cat_estados_dispositivo (id_estado, nombre, activo) FROM stdin;
1	ACTIVO	t
2	INACTIVO	t
3	MANTENIMIENTO	t
\.


--
-- Data for Name: cat_estados_gps; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cat_estados_gps (id_estado, nombre, activo) FROM stdin;
1	EN_RUTA   	t
2	LLEGADO   	t
3	FINALIZADO	t
\.


--
-- Data for Name: cat_estados_vehiculo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cat_estados_vehiculo (id_estado, nombre, activo) FROM stdin;
1	DISPONIBLE          	t
2	EN_USO              	t
3	MANTENIMIENTO       	t
\.


--
-- Data for Name: cat_metodos_registro; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cat_metodos_registro (id_metodo, nombre, activo) FROM stdin;
1	NFC	t
2	Manual	t
\.


--
-- Data for Name: cat_nivel_dificultad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cat_nivel_dificultad (id_nivel, nombre, activo) FROM stdin;
1	BAJO 	t
2	MEDIO	t
3	ALTO 	t
\.


--
-- Data for Name: cat_sexo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cat_sexo (id_sexo, nombre, activo) FROM stdin;
1	MASCULINO	t
2	FEMENINO	t
3	OTRO	t
\.


--
-- Data for Name: cat_tipos_ejercicio; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cat_tipos_ejercicio (id_tipo_ejercicio, nombre, activo) FROM stdin;
1	Estiramiento	t
2	Fortalecimiento	t
3	Equilibrio	t
4	Cardiorrespiratorio	t
5	Movilidad Articular	t
\.


--
-- Data for Name: cat_tipos_sesion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cat_tipos_sesion (id_tipo_sesion, nombre, activo) FROM stdin;
1	Individual	t
2	Grupal	t
3	Respiratoria	t
\.


--
-- Data for Name: dispositivos_nfc; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dispositivos_nfc (id_dispositivo, tipo_dispositivo, ubicacion, id_estado, descripcion) FROM stdin;
1	Lector de pulsera	Recepción principal	1	Lector NFC para registro de entrada de pacientes
2	Lector de tarjeta	Sala de fisioterapia A	1	Dispositivo para confirmar inicio de sesión
3	Lector de pulsera	Sala de fisioterapia B	1	Dispositivo para confirmar inicio de sesión
4	Terminal fija	Pasillo central	2	Terminal en mantenimiento preventivo
5	Lector de tarjeta	Gimnasio de rehabilitación	1	Control de acceso al área de ejercicios
\.


--
-- Data for Name: ejercicio_sesion_detalle; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ejercicio_sesion_detalle (id_sesion, id_ejercicio, repeticiones, duracion_min, observaciones) FROM stdin;
\.


--
-- Data for Name: ejercicios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ejercicios (id_ejercicio, nombre_ejercicio, descripcion, id_tipo_ejercicio, id_nivel_dificultad) FROM stdin;
1	Estiramiento de isquiotibiales	Estiramiento en decúbito supino con banda elástica, 30 seg por lado.	1	1
2	Sentadilla asistida	Sentadilla con apoyo en barras paralelas, control excéntrico.	2	2
3	Equilibrio en una pierna	Mantenerse en un pie sobre superficie inestable por 30 segundos.	3	2
4	Bicicleta estática	Pedaleo continuo a ritmo moderado para trabajo cardiorrespiratorio.	4	1
5	Movilización cervical activa	Movimientos lentos de flexión, extensión y rotación cervical.	5	1
6	Prensa de pierna	Empuje bilateral en máquina, ángulo de 90° a 160°.	2	3
7	Estiramientos de pectoral	Estiramiento en marco de puerta, 3 series de 20 segundos.	1	1
8	Ejercicio respiratorio diafragmático	Respiración abdominal controlada en posición supina, 10 repeticiones.	4	1
9	Puente de glúteo	En decúbito supino, elevar cadera manteniendo core activo.	2	2
10	Marcha en paralelas	Deambulación con apoyo en barras paralelas, paso controlado.	3	1
\.


--
-- Data for Name: evaluacion_terapeuta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.evaluacion_terapeuta (id_evaluacion, id_terapeuta) FROM stdin;
1	1
2	1
4	1
5	1
6	1
\.


--
-- Data for Name: evaluaciones_progreso; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.evaluaciones_progreso (id_evaluacion, fecha, tipo_evaluacion, nivel_movilidad, nivel_dolor, resistencia, progreso_observado, recomendaciones, ajustes_plan) FROM stdin;
1	2024-10-28	Inicial	5	7	4	Limitación significativa en flexión lumbar.	Iniciar con ejercicios de bajo impacto.	Plan de 12 semanas, 3 sesiones semanales.
2	2024-10-28	Inicial	6	5	5	Buena fuerza residual, movilidad reducida en codo derecho.	Priorizar movilidad articular de codo.	Incluir ejercicios de movilización activa.
3	2024-10-29	Inicial	4	8	3	Inestabilidad marcada en rodilla izquierda.	Evitar impacto hasta reducir inflamación.	Inicio con fortalecimiento isométrico.
4	2024-11-04	Seguimiento	7	4	6	Mejora del 30% en rango de movimiento lumbar.	Incrementar progresivamente la carga.	Agregar sentadilla asistida a la rutina.
5	2024-11-05	Seguimiento	7	3	7	Reducción notable del dolor, mejor funcionalidad del codo.	Continuar con plan actual.	\N
6	2024-11-06	Final	9	2	8	Paciente alcanzó objetivos funcionales planteados.	Alta clínica con programa de mantenimiento en casa.	Reducir a 1 sesión quincenal de seguimiento.
\.


--
-- Data for Name: gps_registros; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gps_registros (id_registro, id_paciente, id_terapeuta, latitud, longitud, fecha, hora, id_estado) FROM stdin;
1	1	1	25.686614	-100.316116	2024-11-04	08:30:00	3
2	2	1	25.726168	-100.318990	2024-11-04	09:30:00	3
4	7	2	25.700000	-100.350000	2024-11-06	08:30:00	2
5	5	1	25.670000	-100.310000	2024-11-08	13:30:00	1
7	1	1	25.669724	-100.473056	2026-05-07	22:12:16.696808	1
8	1	1	25.669724	-100.473056	2026-05-07	22:12:27.689514	1
9	1	1	25.669724	-100.473056	2026-05-07	22:12:28.087396	1
10	1	1	25.669724	-100.473056	2026-05-07	22:12:29.098369	1
11	1	1	25.669724	-100.473056	2026-05-07	22:12:29.331575	1
\.


--
-- Data for Name: gps_vehiculo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gps_vehiculo (id_registro, id_vehiculo) FROM stdin;
1	2
2	2
4	1
5	2
\.


--
-- Data for Name: paciente_alergia; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.paciente_alergia (id_paciente, alergia) FROM stdin;
1	Penicilina
3	Ibuprofeno
3	Látex
5	Aspirina
7	Sulfamidas
\.


--
-- Data for Name: paciente_evaluacion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.paciente_evaluacion (id_paciente, id_evaluacion) FROM stdin;
1	1
2	2
3	3
1	4
2	5
2	6
\.


--
-- Data for Name: paciente_lesion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.paciente_lesion (id_paciente, lesion_previa) FROM stdin;
1	Hernia discal L4-L5
2	Fractura de cúbito derecho
3	Rotura de menisco medial izquierdo
5	Fractura de cadera derecha
7	Parálisis facial 2019
\.


--
-- Data for Name: paciente_medicamento; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.paciente_medicamento (id_paciente, medicamento_actual) FROM stdin;
1	Naproxeno 500mg
3	Metformina 850mg
3	Losartán 50mg
5	Ácido hialurónico intraarticular
7	Prednisolona 5mg
\.


--
-- Data for Name: paciente_sesion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.paciente_sesion (id_paciente, id_sesion) FROM stdin;
3	13
\.


--
-- Data for Name: paciente_terapeuta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.paciente_terapeuta (id_paciente, id_terapeuta) FROM stdin;
1	1
2	1
4	1
5	1
7	2
\.


--
-- Data for Name: pacientes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pacientes (id_paciente, nombre, apellido_paterno, apellido_materno, fecha_nacimiento, id_sexo, telefono, correo, direccion, diagnostico_principal, antecedentes_medicos, nfc_uid) FROM stdin;
2	María	González	Flores	1990-07-22	2	8123456789	m.gonzalez@correo.com	Calle Morelos 250, San Nicolás	Rehabilitación post-fractura	Fractura de cúbito derecho 2023	\N
3	Roberto	Hernández	Vega	1978-11-30	1	8134567890	r.hernandez@correo.com	Blvd. Díaz Ordaz 500, Monterrey	Lesión de ligamento cruzado	Diabetes tipo 2, hipertensión	\N
4	Ana	López	Martínez	2000-05-10	2	8145678901	a.lopez@correo.com	Av. Insurgentes 300, Guadalupe	Escoliosis leve	\N	\N
5	Miguel	Sánchez	Reyes	1955-09-18	1	8156789012	m.sanchez@correo.com	Calle Juárez 88, Apodaca	Artrosis de rodilla bilateral	Reemplazo de cadera derecha 2020	\N
6	Patricia	Morales	Jiménez	1995-01-25	2	8167890123	p.morales@correo.com	Av. Lázaro Cárdenas 450, Monterrey	Tendinitis rotuliana	\N	\N
7	Jorge	Castillo	Núñez	1982-06-08	1	8178901234	j.castillo@correo.com	Calle Hidalgo 77, Santa Catarina	Parálisis facial periférica	Hipertensión arterial	\N
8	Sofía	Vargas	Espinoza	2005-12-03	2	8189012345	s.vargas@correo.com	Av. Revolución 120, Monterrey	Pie plano severo	\N	\N
9	Sergio 	Ayala 	Gonzalez	2006-11-14	1	8114693524	sergio.ayala.gonzalez.2006@gmail.com	Palermo 204	me siento mal 	nada 	\N
1	Carlos	Ramírez	Torres	1985-03-15	1	8112345678	c.ramirez@correo.com	Av. Constitución 100, Monterrey	Lumbalgia crónica	Hernia discal L4-L5 en 2018	61:1c:51:3d
\.


--
-- Data for Name: sesiones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sesiones (id_sesion, fecha, hora_inicio, hora_fin, id_tipo_sesion, observaciones_clinicas, asistencia, id_metodo, hora_inicio_real, hora_fin_real, estado_sesion) FROM stdin;
13	2026-04-19	17:55:00	18:55:00	1	hola esto es la prueba 2	t	1	2026-04-19 23:55:23.671481	2026-04-19 23:55:33.793791	FINALIZADA
\.


--
-- Data for Name: terapeuta_sesion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.terapeuta_sesion (id_terapeuta, id_sesion) FROM stdin;
1	13
\.


--
-- Data for Name: terapeutas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.terapeutas (id_terapeuta, nombre, apellido_paterno, apellido_materno, id_especialidad, telefono, correo, observaciones) FROM stdin;
1	Laura	Mendoza	Cruz	1	8190123456	l.mendoza@clinica.com	Certificada en terapia manual ortopédica
2	Andrés	Fuentes	Ortega	2	8101234567	a.fuentes@clinica.com	Especialista en ACV y lesiones medulares
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios (id_usuario, login, password, rol, ref_id, activo, created_at) FROM stdin;
1	admin01	1234	admin	\N	t	2026-04-17 16:56:57.731037-06
4	fam_pac1	1234	familiar	1	t	2026-04-17 16:56:57.731037-06
5	fam_pac2	1234	familiar	2	t	2026-04-17 16:56:57.731037-06
6	fam_9	1234	familiar	9	t	2026-04-17 19:19:42.819409-06
2	laura.mendoza	1234	terapeuta	1	t	2026-04-17 16:56:57.731037-06
3	andres.fuentes	1234	terapeuta	2	t	2026-04-17 16:56:57.731037-06
\.


--
-- Data for Name: vehiculos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vehiculos (id_vehiculo, tipo, descripcion, id_estado) FROM stdin;
1	Ambulancia	Unidad de traslado médico equipada con camilla y oxígeno.	2
2	Van adaptada	Vehículo con rampa hidráulica para silla de ruedas.	1
3	Sedán clínico	Automóvil para traslado de terapeutas a domicilio.	1
\.


--
-- Name: asistencias_nfc_id_asistencia_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.asistencias_nfc_id_asistencia_seq', 10, true);


--
-- Name: beacon_evento_id_evento_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.beacon_evento_id_evento_seq', 11, true);


--
-- Name: beacons_id_beacon_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.beacons_id_beacon_seq', 6, true);


--
-- Name: cat_especialidades_id_especialidad_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cat_especialidades_id_especialidad_seq', 6, true);


--
-- Name: cat_estados_beacon_id_estado_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cat_estados_beacon_id_estado_seq', 3, true);


--
-- Name: cat_estados_dispositivo_id_estado_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cat_estados_dispositivo_id_estado_seq', 4, true);


--
-- Name: cat_estados_gps_id_estado_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cat_estados_gps_id_estado_seq', 3, true);


--
-- Name: cat_estados_vehiculo_id_estado_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cat_estados_vehiculo_id_estado_seq', 3, true);


--
-- Name: cat_metodos_registro_id_metodo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cat_metodos_registro_id_metodo_seq', 2, true);


--
-- Name: cat_nivel_dificultad_id_nivel_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cat_nivel_dificultad_id_nivel_seq', 3, true);


--
-- Name: cat_sexo_id_sexo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cat_sexo_id_sexo_seq', 3, true);


--
-- Name: cat_tipos_ejercicio_id_tipo_ejercicio_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cat_tipos_ejercicio_id_tipo_ejercicio_seq', 5, true);


--
-- Name: cat_tipos_sesion_id_tipo_sesion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cat_tipos_sesion_id_tipo_sesion_seq', 3, true);


--
-- Name: dispositivos_nfc_id_dispositivo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dispositivos_nfc_id_dispositivo_seq', 7, true);


--
-- Name: ejercicios_id_ejercicio_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ejercicios_id_ejercicio_seq', 10, true);


--
-- Name: evaluaciones_progreso_id_evaluacion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.evaluaciones_progreso_id_evaluacion_seq', 8, true);


--
-- Name: gps_registros_id_registro_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gps_registros_id_registro_seq', 11, true);


--
-- Name: pacientes_id_paciente_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pacientes_id_paciente_seq', 13, true);


--
-- Name: sesiones_id_sesion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sesiones_id_sesion_seq', 18, true);


--
-- Name: terapeutas_id_terapeuta_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.terapeutas_id_terapeuta_seq', 8, true);


--
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuarios_id_usuario_seq', 10, true);


--
-- Name: vehiculos_id_vehiculo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vehiculos_id_vehiculo_seq', 3, true);


--
-- Name: asistencias_nfc asistencias_nfc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asistencias_nfc
ADD CONSTRAINT asistencias_nfc_pkey PRIMARY KEY (id_asistencia);


--
-- Name: beacon_evento beacon_evento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.beacon_evento
ADD CONSTRAINT beacon_evento_pkey PRIMARY KEY (id_evento);


--
-- Name: beacons beacons_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.beacons
ADD CONSTRAINT beacons_pkey PRIMARY KEY (id_beacon);


--
-- Name: cat_especialidades cat_especialidades_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_especialidades
ADD CONSTRAINT cat_especialidades_nombre_key UNIQUE (nombre);


--
-- Name: cat_especialidades cat_especialidades_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_especialidades
ADD CONSTRAINT cat_especialidades_pkey PRIMARY KEY (id_especialidad);


--
-- Name: cat_estados_beacon cat_estados_beacon_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_estados_beacon
ADD CONSTRAINT cat_estados_beacon_nombre_key UNIQUE (nombre);


--
-- Name: cat_estados_beacon cat_estados_beacon_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_estados_beacon
ADD CONSTRAINT cat_estados_beacon_pkey PRIMARY KEY (id_estado);


--
-- Name: cat_estados_dispositivo cat_estados_dispositivo_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_estados_dispositivo
ADD CONSTRAINT cat_estados_dispositivo_nombre_key UNIQUE (nombre);


--
-- Name: cat_estados_dispositivo cat_estados_dispositivo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_estados_dispositivo
ADD CONSTRAINT cat_estados_dispositivo_pkey PRIMARY KEY (id_estado);


--
-- Name: cat_estados_gps cat_estados_gps_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_estados_gps
ADD CONSTRAINT cat_estados_gps_nombre_key UNIQUE (nombre);


--
-- Name: cat_estados_gps cat_estados_gps_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_estados_gps
ADD CONSTRAINT cat_estados_gps_pkey PRIMARY KEY (id_estado);


--
-- Name: cat_estados_vehiculo cat_estados_vehiculo_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_estados_vehiculo
ADD CONSTRAINT cat_estados_vehiculo_nombre_key UNIQUE (nombre);


--
-- Name: cat_estados_vehiculo cat_estados_vehiculo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_estados_vehiculo
ADD CONSTRAINT cat_estados_vehiculo_pkey PRIMARY KEY (id_estado);


--
-- Name: cat_metodos_registro cat_metodos_registro_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_metodos_registro
ADD CONSTRAINT cat_metodos_registro_nombre_key UNIQUE (nombre);


--
-- Name: cat_metodos_registro cat_metodos_registro_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_metodos_registro
ADD CONSTRAINT cat_metodos_registro_pkey PRIMARY KEY (id_metodo);


--
-- Name: cat_nivel_dificultad cat_nivel_dificultad_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_nivel_dificultad
ADD CONSTRAINT cat_nivel_dificultad_nombre_key UNIQUE (nombre);


--
-- Name: cat_nivel_dificultad cat_nivel_dificultad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_nivel_dificultad
ADD CONSTRAINT cat_nivel_dificultad_pkey PRIMARY KEY (id_nivel);


--
-- Name: cat_sexo cat_sexo_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_sexo
ADD CONSTRAINT cat_sexo_nombre_key UNIQUE (nombre);


--
-- Name: cat_sexo cat_sexo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_sexo
ADD CONSTRAINT cat_sexo_pkey PRIMARY KEY (id_sexo);


--
-- Name: cat_tipos_ejercicio cat_tipos_ejercicio_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_tipos_ejercicio
ADD CONSTRAINT cat_tipos_ejercicio_nombre_key UNIQUE (nombre);


--
-- Name: cat_tipos_ejercicio cat_tipos_ejercicio_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_tipos_ejercicio
ADD CONSTRAINT cat_tipos_ejercicio_pkey PRIMARY KEY (id_tipo_ejercicio);


--
-- Name: cat_tipos_sesion cat_tipos_sesion_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_tipos_sesion
ADD CONSTRAINT cat_tipos_sesion_nombre_key UNIQUE (nombre);


--
-- Name: cat_tipos_sesion cat_tipos_sesion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_tipos_sesion
ADD CONSTRAINT cat_tipos_sesion_pkey PRIMARY KEY (id_tipo_sesion);


--
-- Name: dispositivos_nfc dispositivos_nfc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dispositivos_nfc
ADD CONSTRAINT dispositivos_nfc_pkey PRIMARY KEY (id_dispositivo);


--
-- Name: ejercicio_sesion_detalle ejercicio_sesion_detalle_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ejercicio_sesion_detalle
ADD CONSTRAINT ejercicio_sesion_detalle_pkey PRIMARY KEY (id_sesion, id_ejercicio);


--
-- Name: ejercicios ejercicios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ejercicios
ADD CONSTRAINT ejercicios_pkey PRIMARY KEY (id_ejercicio);


--
-- Name: evaluacion_terapeuta evaluacion_terapeuta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evaluacion_terapeuta
ADD CONSTRAINT evaluacion_terapeuta_pkey PRIMARY KEY (id_evaluacion, id_terapeuta);


--
-- Name: evaluaciones_progreso evaluaciones_progreso_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evaluaciones_progreso
ADD CONSTRAINT evaluaciones_progreso_pkey PRIMARY KEY (id_evaluacion);


--
-- Name: gps_registros gps_registros_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gps_registros
ADD CONSTRAINT gps_registros_pkey PRIMARY KEY (id_registro);


--
-- Name: gps_vehiculo gps_vehiculo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gps_vehiculo
ADD CONSTRAINT gps_vehiculo_pkey PRIMARY KEY (id_registro, id_vehiculo);


--
-- Name: paciente_alergia paciente_alergia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente_alergia
ADD CONSTRAINT paciente_alergia_pkey PRIMARY KEY (id_paciente, alergia);


--
-- Name: paciente_evaluacion paciente_evaluacion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente_evaluacion
ADD CONSTRAINT paciente_evaluacion_pkey PRIMARY KEY (id_paciente, id_evaluacion);


--
-- Name: paciente_lesion paciente_lesion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente_lesion
ADD CONSTRAINT paciente_lesion_pkey PRIMARY KEY (id_paciente, lesion_previa);


--
-- Name: paciente_medicamento paciente_medicamento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente_medicamento
ADD CONSTRAINT paciente_medicamento_pkey PRIMARY KEY (id_paciente, medicamento_actual);


--
-- Name: paciente_sesion paciente_sesion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente_sesion
ADD CONSTRAINT paciente_sesion_pkey PRIMARY KEY (id_paciente, id_sesion);


--
-- Name: paciente_terapeuta paciente_terapeuta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente_terapeuta
ADD CONSTRAINT paciente_terapeuta_pkey PRIMARY KEY (id_paciente, id_terapeuta);


--
-- Name: pacientes pacientes_correo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pacientes
ADD CONSTRAINT pacientes_correo_key UNIQUE (correo);


--
-- Name: pacientes pacientes_nfc_uid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pacientes
ADD CONSTRAINT pacientes_nfc_uid_key UNIQUE (nfc_uid);


--
-- Name: pacientes pacientes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pacientes
ADD CONSTRAINT pacientes_pkey PRIMARY KEY (id_paciente);


--
-- Name: sesiones sesiones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sesiones
ADD CONSTRAINT sesiones_pkey PRIMARY KEY (id_sesion);


--
-- Name: terapeuta_sesion terapeuta_sesion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terapeuta_sesion
ADD CONSTRAINT terapeuta_sesion_pkey PRIMARY KEY (id_terapeuta, id_sesion);


--
-- Name: terapeutas terapeutas_correo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terapeutas
ADD CONSTRAINT terapeutas_correo_key UNIQUE (correo);


--
-- Name: terapeutas terapeutas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terapeutas
ADD CONSTRAINT terapeutas_pkey PRIMARY KEY (id_terapeuta);


--
-- Name: asistencias_nfc uq_asistencia_paciente_sesion; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asistencias_nfc
ADD CONSTRAINT uq_asistencia_paciente_sesion UNIQUE (id_paciente, id_sesion);


--
-- Name: usuarios usuarios_login_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
ADD CONSTRAINT usuarios_login_key UNIQUE (login);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id_usuario);


--
-- Name: vehiculos vehiculos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehiculos
ADD CONSTRAINT vehiculos_pkey PRIMARY KEY (id_vehiculo);


--
-- Name: idx_asistencia_paciente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_asistencia_paciente ON public.asistencias_nfc USING btree (id_paciente);


--
-- Name: idx_asistencia_sesion; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_asistencia_sesion ON public.asistencias_nfc USING btree (id_sesion);


--
-- Name: idx_beacon_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_beacon_fecha ON public.beacon_evento USING btree (fecha DESC);


--
-- Name: idx_beacon_paciente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_beacon_paciente ON public.beacon_evento USING btree (id_paciente);


--
-- Name: idx_esd_sesion; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_esd_sesion ON public.ejercicio_sesion_detalle USING btree (id_sesion);


--
-- Name: idx_evaluaciones_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_evaluaciones_fecha ON public.evaluaciones_progreso USING btree (fecha DESC);


--
-- Name: idx_gps_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gps_fecha ON public.gps_registros USING btree (fecha DESC);


--
-- Name: idx_gps_paciente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gps_paciente ON public.gps_registros USING btree (id_paciente);


--
-- Name: idx_sesiones_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sesiones_fecha ON public.sesiones USING btree (fecha DESC);


--
-- Name: beacon_evento trg_beacon_actualiza_agenda; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_beacon_actualiza_agenda AFTER INSERT ON public.beacon_evento FOR EACH ROW EXECUTE FUNCTION public.fn_trg_beacon_llegada();


--
-- Name: pacientes trg_crear_usuario_paciente; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_crear_usuario_paciente AFTER INSERT ON public.pacientes FOR EACH ROW EXECUTE FUNCTION public.fn_trg_crear_usuario_paciente();


--
-- Name: terapeutas trg_crear_usuario_terapeuta; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_crear_usuario_terapeuta AFTER INSERT ON public.terapeutas FOR EACH ROW EXECUTE FUNCTION public.fn_trg_crear_usuario_terapeuta();


--
-- Name: asistencias_nfc trg_log_asistencia_nfc; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_asistencia_nfc AFTER INSERT ON public.asistencias_nfc FOR EACH ROW EXECUTE FUNCTION public.fn_trg_confirmar_asistencia_nfc();


--
-- Name: sesiones trg_validar_horario_sesion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_validar_horario_sesion BEFORE INSERT OR UPDATE ON public.sesiones FOR EACH ROW EXECUTE FUNCTION public.fn_trg_validar_horario();


--
-- Name: asistencias_nfc asistencias_nfc_id_dispositivo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asistencias_nfc
ADD CONSTRAINT asistencias_nfc_id_dispositivo_fkey FOREIGN KEY (id_dispositivo) REFERENCES public.dispositivos_nfc(id_dispositivo) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: asistencias_nfc asistencias_nfc_id_paciente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asistencias_nfc
ADD CONSTRAINT asistencias_nfc_id_paciente_fkey FOREIGN KEY (id_paciente) REFERENCES public.pacientes(id_paciente) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: asistencias_nfc asistencias_nfc_id_sesion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asistencias_nfc
ADD CONSTRAINT asistencias_nfc_id_sesion_fkey FOREIGN KEY (id_sesion) REFERENCES public.sesiones(id_sesion) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: beacon_evento beacon_evento_id_beacon_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.beacon_evento
ADD CONSTRAINT beacon_evento_id_beacon_fkey FOREIGN KEY (id_beacon) REFERENCES public.beacons(id_beacon) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: beacon_evento beacon_evento_id_paciente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.beacon_evento
ADD CONSTRAINT beacon_evento_id_paciente_fkey FOREIGN KEY (id_paciente) REFERENCES public.pacientes(id_paciente) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: beacons beacons_id_estado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.beacons
ADD CONSTRAINT beacons_id_estado_fkey FOREIGN KEY (id_estado) REFERENCES public.cat_estados_beacon(id_estado) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: dispositivos_nfc dispositivos_nfc_id_estado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dispositivos_nfc
ADD CONSTRAINT dispositivos_nfc_id_estado_fkey FOREIGN KEY (id_estado) REFERENCES public.cat_estados_dispositivo(id_estado) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: ejercicio_sesion_detalle ejercicio_sesion_detalle_id_ejercicio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ejercicio_sesion_detalle
ADD CONSTRAINT ejercicio_sesion_detalle_id_ejercicio_fkey FOREIGN KEY (id_ejercicio) REFERENCES public.ejercicios(id_ejercicio) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: ejercicio_sesion_detalle ejercicio_sesion_detalle_id_sesion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ejercicio_sesion_detalle
ADD CONSTRAINT ejercicio_sesion_detalle_id_sesion_fkey FOREIGN KEY (id_sesion) REFERENCES public.sesiones(id_sesion) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ejercicios ejercicios_id_nivel_dificultad_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ejercicios
ADD CONSTRAINT ejercicios_id_nivel_dificultad_fkey FOREIGN KEY (id_nivel_dificultad) REFERENCES public.cat_nivel_dificultad(id_nivel) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: ejercicios ejercicios_id_tipo_ejercicio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ejercicios
ADD CONSTRAINT ejercicios_id_tipo_ejercicio_fkey FOREIGN KEY (id_tipo_ejercicio) REFERENCES public.cat_tipos_ejercicio(id_tipo_ejercicio) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: evaluacion_terapeuta evaluacion_terapeuta_id_evaluacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evaluacion_terapeuta
ADD CONSTRAINT evaluacion_terapeuta_id_evaluacion_fkey FOREIGN KEY (id_evaluacion) REFERENCES public.evaluaciones_progreso(id_evaluacion) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: evaluacion_terapeuta evaluacion_terapeuta_id_terapeuta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evaluacion_terapeuta
ADD CONSTRAINT evaluacion_terapeuta_id_terapeuta_fkey FOREIGN KEY (id_terapeuta) REFERENCES public.terapeutas(id_terapeuta) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: gps_registros gps_registros_id_estado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gps_registros
ADD CONSTRAINT gps_registros_id_estado_fkey FOREIGN KEY (id_estado) REFERENCES public.cat_estados_gps(id_estado) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: gps_registros gps_registros_id_paciente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gps_registros
ADD CONSTRAINT gps_registros_id_paciente_fkey FOREIGN KEY (id_paciente) REFERENCES public.pacientes(id_paciente) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: gps_registros gps_registros_id_terapeuta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gps_registros
ADD CONSTRAINT gps_registros_id_terapeuta_fkey FOREIGN KEY (id_terapeuta) REFERENCES public.terapeutas(id_terapeuta) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: gps_vehiculo gps_vehiculo_id_registro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gps_vehiculo
ADD CONSTRAINT gps_vehiculo_id_registro_fkey FOREIGN KEY (id_registro) REFERENCES public.gps_registros(id_registro) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: gps_vehiculo gps_vehiculo_id_vehiculo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gps_vehiculo
ADD CONSTRAINT gps_vehiculo_id_vehiculo_fkey FOREIGN KEY (id_vehiculo) REFERENCES public.vehiculos(id_vehiculo) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: paciente_alergia paciente_alergia_id_paciente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente_alergia
ADD CONSTRAINT paciente_alergia_id_paciente_fkey FOREIGN KEY (id_paciente) REFERENCES public.pacientes(id_paciente) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: paciente_evaluacion paciente_evaluacion_id_evaluacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente_evaluacion
ADD CONSTRAINT paciente_evaluacion_id_evaluacion_fkey FOREIGN KEY (id_evaluacion) REFERENCES public.evaluaciones_progreso(id_evaluacion) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: paciente_evaluacion paciente_evaluacion_id_paciente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente_evaluacion
ADD CONSTRAINT paciente_evaluacion_id_paciente_fkey FOREIGN KEY (id_paciente) REFERENCES public.pacientes(id_paciente) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: paciente_lesion paciente_lesion_id_paciente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente_lesion
ADD CONSTRAINT paciente_lesion_id_paciente_fkey FOREIGN KEY (id_paciente) REFERENCES public.pacientes(id_paciente) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: paciente_medicamento paciente_medicamento_id_paciente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente_medicamento
ADD CONSTRAINT paciente_medicamento_id_paciente_fkey FOREIGN KEY (id_paciente) REFERENCES public.pacientes(id_paciente) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: paciente_sesion paciente_sesion_id_paciente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente_sesion
ADD CONSTRAINT paciente_sesion_id_paciente_fkey FOREIGN KEY (id_paciente) REFERENCES public.pacientes(id_paciente) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: paciente_sesion paciente_sesion_id_sesion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente_sesion
ADD CONSTRAINT paciente_sesion_id_sesion_fkey FOREIGN KEY (id_sesion) REFERENCES public.sesiones(id_sesion) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: paciente_terapeuta paciente_terapeuta_id_paciente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente_terapeuta
ADD CONSTRAINT paciente_terapeuta_id_paciente_fkey FOREIGN KEY (id_paciente) REFERENCES public.pacientes(id_paciente) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: paciente_terapeuta paciente_terapeuta_id_terapeuta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente_terapeuta
ADD CONSTRAINT paciente_terapeuta_id_terapeuta_fkey FOREIGN KEY (id_terapeuta) REFERENCES public.terapeutas(id_terapeuta) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: pacientes pacientes_id_sexo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pacientes
ADD CONSTRAINT pacientes_id_sexo_fkey FOREIGN KEY (id_sexo) REFERENCES public.cat_sexo(id_sexo) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: sesiones sesiones_id_metodo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sesiones
ADD CONSTRAINT sesiones_id_metodo_fkey FOREIGN KEY (id_metodo) REFERENCES public.cat_metodos_registro(id_metodo) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: sesiones sesiones_id_tipo_sesion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sesiones
ADD CONSTRAINT sesiones_id_tipo_sesion_fkey FOREIGN KEY (id_tipo_sesion) REFERENCES public.cat_tipos_sesion(id_tipo_sesion) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: terapeuta_sesion terapeuta_sesion_id_sesion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terapeuta_sesion
ADD CONSTRAINT terapeuta_sesion_id_sesion_fkey FOREIGN KEY (id_sesion) REFERENCES public.sesiones(id_sesion) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: terapeuta_sesion terapeuta_sesion_id_terapeuta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terapeuta_sesion
ADD CONSTRAINT terapeuta_sesion_id_terapeuta_fkey FOREIGN KEY (id_terapeuta) REFERENCES public.terapeutas(id_terapeuta) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: terapeutas terapeutas_id_especialidad_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terapeutas
ADD CONSTRAINT terapeutas_id_especialidad_fkey FOREIGN KEY (id_especialidad) REFERENCES public.cat_especialidades(id_especialidad) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: vehiculos vehiculos_id_estado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehiculos
ADD CONSTRAINT vehiculos_id_estado_fkey FOREIGN KEY (id_estado) REFERENCES public.cat_estados_vehiculo(id_estado) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

\unrestrict XM2Xt4gqLnw4RUEZwSxr85PETmCB3m0ivCQIO3byeeap3IfSXJd8xq1wyo2ybUB

