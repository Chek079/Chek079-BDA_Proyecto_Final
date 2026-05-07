-- ============================================================
--  TRIGGERS
-- ============================================================

-- ── trg_validar_horario_sesion ────────────────────────────────
CREATE OR REPLACE FUNCTION fn_trg_validar_horario()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.hora_fin <= NEW.hora_inicio THEN
    RAISE EXCEPTION 'La hora de fin (%) debe ser mayor que la hora de inicio (%).',
    NEW.hora_fin, NEW.hora_inicio;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_horario_sesion ON sesiones;
CREATE TRIGGER trg_validar_horario_sesion
BEFORE INSERT OR UPDATE ON sesiones
FOR EACH ROW EXECUTE FUNCTION fn_trg_validar_horario();


  -- ── trg_log_asistencia_nfc ────────────────────────────────────
  CREATE OR REPLACE FUNCTION fn_trg_confirmar_asistencia_nfc()
  RETURNS TRIGGER LANGUAGE plpgsql AS $$
  BEGIN
    IF NEW.asistencia_confirmada = TRUE THEN
      UPDATE sesiones
      SET    asistencia = TRUE
      WHERE  id_sesion  = NEW.id_sesion;
    END IF;
    RETURN NEW;
  END;
  $$;

  DROP TRIGGER IF EXISTS trg_log_asistencia_nfc ON asistencias_nfc;
  CREATE TRIGGER trg_log_asistencia_nfc
  AFTER INSERT ON asistencias_nfc
  FOR EACH ROW EXECUTE FUNCTION fn_trg_confirmar_asistencia_nfc();


    -- ── trg_crear_usuario_terapeuta ───────────────────────────────
  CREATE OR REPLACE FUNCTION fn_trg_crear_usuario_terapeuta()
  RETURNS TRIGGER LANGUAGE plpgsql AS $$
  BEGIN
    INSERT INTO usuarios (login, password, rol, ref_id)
    VALUES ('ter_' || NEW.id_terapeuta, '1234', 'terapeuta', NEW.id_terapeuta)
    ON CONFLICT (login) DO NOTHING;
    RETURN NEW;
  END;
  $$;

    DROP TRIGGER IF EXISTS trg_crear_usuario_terapeuta ON terapeutas;
    CREATE TRIGGER trg_crear_usuario_terapeuta
    AFTER INSERT ON terapeutas
    FOR EACH ROW EXECUTE FUNCTION fn_trg_crear_usuario_terapeuta();


      -- ── trg_crear_usuario_paciente ────────────────────────────────
      CREATE OR REPLACE FUNCTION fn_trg_crear_usuario_paciente()
      RETURNS TRIGGER LANGUAGE plpgsql AS $$
      BEGIN
        INSERT INTO usuarios (login, password, rol, ref_id)
        VALUES ('fam_' || NEW.id_paciente, '1234', 'familiar', NEW.id_paciente)
        ON CONFLICT (login) DO NOTHING;
        RETURN NEW;
      END;
      $$;

      DROP TRIGGER IF EXISTS trg_crear_usuario_paciente ON pacientes;
      CREATE TRIGGER trg_crear_usuario_paciente
      AFTER INSERT ON pacientes
      FOR EACH ROW EXECUTE FUNCTION fn_trg_crear_usuario_paciente();


        -- ── trg_beacon_actualiza_agenda ───────────────────────────────
        CREATE OR REPLACE FUNCTION fn_trg_beacon_llegada()
        RETURNS TRIGGER LANGUAGE plpgsql AS $$
        DECLARE
        v_habitacion TEXT;
        BEGIN
          SELECT b.habitacion INTO v_habitacion
          FROM beacons b WHERE b.id_beacon = NEW.id_beacon;

          IF v_habitacion ILIKE '%consultorio%' THEN
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

        DROP TRIGGER IF EXISTS trg_beacon_actualiza_agenda ON beacon_evento;
        CREATE TRIGGER trg_beacon_actualiza_agenda
        AFTER INSERT ON beacon_evento
        FOR EACH ROW EXECUTE FUNCTION fn_trg_beacon_llegada();
