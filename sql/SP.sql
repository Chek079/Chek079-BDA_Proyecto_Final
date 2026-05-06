-- ── sp_login ──────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_login(VARCHAR, VARCHAR, BOOLEAN, INTEGER, VARCHAR, VARCHAR, INTEGER);
CREATE OR REPLACE PROCEDURE sp_login(
  IN  p_login       VARCHAR,
  IN  p_password    VARCHAR,
  OUT o_autenticado BOOLEAN,
  OUT o_user_id     INTEGER,
  OUT o_rol         VARCHAR,
  OUT o_nombre      VARCHAR,
  OUT o_ref_id      INTEGER
)
LANGUAGE plpgsql AS $$
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


-- ── sp_kpis_terapeuta ─────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_kpis_terapeuta(INTEGER, DATE, BIGINT, BIGINT, BIGINT, BIGINT, BIGINT);
CREATE OR REPLACE PROCEDURE sp_kpis_terapeuta(
  IN  p_id_terapeuta  INTEGER,
  IN  p_fecha         DATE,
  OUT o_total_citas   BIGINT,
  OUT o_atendidos     BIGINT,
  OUT o_en_espera     BIGINT,
  OUT o_faltas        BIGINT,
  OUT o_pac_unicos    BIGINT
)
LANGUAGE plpgsql AS $$
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


-- ── sp_insertar_paciente ──────────────────────────────────────
CREATE OR REPLACE PROCEDURE sp_insertar_paciente(
  p_nombre           VARCHAR,
  p_ap_paterno       VARCHAR,
  p_ap_materno       VARCHAR,
  p_fecha_nac        DATE,
  p_id_sexo          INTEGER,
  p_telefono         VARCHAR,
  p_correo           VARCHAR,
  p_direccion        VARCHAR,
  p_diagnostico      VARCHAR,
  p_antecedentes     TEXT
)
LANGUAGE plpgsql AS $$
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


-- ── sp_actualizar_paciente ────────────────────────────────────
CREATE OR REPLACE PROCEDURE sp_actualizar_paciente(
  p_id_paciente      INTEGER,
  p_nombre           VARCHAR,
  p_ap_paterno       VARCHAR,
  p_ap_materno       VARCHAR,
  p_fecha_nac        DATE,
  p_id_sexo          INTEGER,
  p_telefono         VARCHAR,
  p_correo           VARCHAR,
  p_direccion        VARCHAR,
  p_diagnostico      VARCHAR,
  p_antecedentes     TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE pacientes SET
  nombre                = p_nombre,
  apellido_paterno      = p_ap_paterno,
  apellido_materno      = p_ap_materno,
  fecha_nacimiento      = p_fecha_nac,
  id_sexo               = p_id_sexo,
  telefono              = p_telefono,
  correo                = p_correo,
  direccion             = p_direccion,
  diagnostico_principal = p_diagnostico,
  antecedentes_medicos  = p_antecedentes
  WHERE id_paciente = p_id_paciente;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Paciente con ID % no encontrado.', p_id_paciente;
  END IF;
END;
$$;


-- ── sp_eliminar_paciente ──────────────────────────────────────
CREATE OR REPLACE PROCEDURE sp_eliminar_paciente(p_id_paciente INTEGER)
LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM pacientes WHERE id_paciente = p_id_paciente;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Paciente con ID % no encontrado.', p_id_paciente;
  END IF;
END;
$$;


-- ── sp_insertar_terapeuta ─────────────────────────────────────
CREATE OR REPLACE PROCEDURE sp_insertar_terapeuta(
  p_nombre          VARCHAR,
  p_ap_paterno      VARCHAR,
  p_ap_materno      VARCHAR,
  p_id_especialidad INTEGER,
  p_telefono        VARCHAR,
  p_correo          VARCHAR,
  p_observaciones   TEXT
)
LANGUAGE plpgsql AS $$
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


-- ── sp_actualizar_terapeuta ───────────────────────────────────
CREATE OR REPLACE PROCEDURE sp_actualizar_terapeuta(
  p_id_terapeuta    INTEGER,
  p_nombre          VARCHAR,
  p_ap_paterno      VARCHAR,
  p_ap_materno      VARCHAR,
  p_id_especialidad INTEGER,
  p_telefono        VARCHAR,
  p_correo          VARCHAR,
  p_observaciones   TEXT
)
LANGUAGE plpgsql AS $$
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


-- ── sp_eliminar_terapeuta ─────────────────────────────────────
CREATE OR REPLACE PROCEDURE sp_eliminar_terapeuta(p_id_terapeuta INTEGER)
LANGUAGE plpgsql AS $$
BEGIN
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


-- ── sp_registrar_sesion ───────────────────────────────────────
CREATE OR REPLACE PROCEDURE sp_registrar_sesion(
  p_id_paciente   INTEGER,
  p_id_terapeuta  INTEGER,
  p_fecha         DATE,
  p_hora_inicio   TIME,
  p_hora_fin      TIME,
  p_id_tipo       INTEGER,
  p_asistencia    BOOLEAN,
  p_id_metodo     INTEGER,
  p_observaciones TEXT
)
LANGUAGE plpgsql AS $$
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

  -- Vincular paciente con terapeuta si no existe
  INSERT INTO paciente_terapeuta (id_paciente, id_terapeuta)
  VALUES (p_id_paciente, p_id_terapeuta)
  ON CONFLICT DO NOTHING;
END;
$$;


-- ── sp_actualizar_sesion ──────────────────────────────────────
CREATE OR REPLACE PROCEDURE sp_actualizar_sesion(
  p_id_sesion     INTEGER,
  p_fecha         DATE,
  p_hora_inicio   TIME,
  p_hora_fin      TIME,
  p_id_tipo       INTEGER,
  p_asistencia    BOOLEAN,
  p_id_metodo     INTEGER,
  p_observaciones TEXT
)
LANGUAGE plpgsql AS $$
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


-- ── sp_eliminar_sesion ────────────────────────────────────────
CREATE OR REPLACE PROCEDURE sp_eliminar_sesion(p_id_sesion INTEGER)
LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM sesiones WHERE id_sesion = p_id_sesion;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sesión con ID % no encontrada.', p_id_sesion;
  END IF;
END;
$$;


-- ── sp_iniciar_sesion_real ────────────────────────────────────
CREATE OR REPLACE PROCEDURE sp_iniciar_sesion_real(p_id_sesion INTEGER)
LANGUAGE plpgsql AS $$
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


-- ── sp_finalizar_sesion_real ──────────────────────────────────
CREATE OR REPLACE PROCEDURE sp_finalizar_sesion_real(
  p_id_sesion     INTEGER,
  p_observaciones TEXT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE sesiones
  SET    hora_fin_real          = NOW(),
  estado_sesion          = 'FINALIZADA',
  observaciones_clinicas = COALESCE(p_observaciones, observaciones_clinicas)
  WHERE  id_sesion     = p_id_sesion
  AND  estado_sesion = 'EN_CURSO';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sesión % no está en curso.', p_id_sesion;
  END IF;
END;
$$;

