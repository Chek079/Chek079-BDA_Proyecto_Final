-- ============================================================
--  VIEWS
-- ============================================================

-- ── vw_dashboard_admin ────────────────────────────────────────
DROP VIEW IF EXISTS vw_dashboard_admin;
CREATE VIEW vw_dashboard_admin AS
SELECT
(SELECT COUNT(DISTINCT ps.id_paciente)
  FROM   paciente_sesion ps
  JOIN   sesiones s ON s.id_sesion = ps.id_sesion
  WHERE  s.fecha = CURRENT_DATE AND s.asistencia = TRUE)     AS total_pacientes_hoy,
(SELECT COUNT(*)
  FROM   gps_registros g
  JOIN   cat_estados_gps e ON e.id_estado = g.id_estado
  WHERE  e.nombre IN ('EN_RUTA', 'LLEGADO')
  AND  g.fecha = CURRENT_DATE)                             AS rutas_activas,
(SELECT COUNT(*)
  FROM   dispositivos_nfc d
  JOIN   cat_estados_dispositivo e ON e.id_estado = d.id_estado
  WHERE  e.nombre = 'MANTENIMIENTO')                         AS alertas_iot;


-- ── vw_pacientes_completo ─────────────────────────────────────
DROP VIEW IF EXISTS vw_pacientes_completo;
CREATE VIEW vw_pacientes_completo AS
SELECT
p.id_paciente,
p.nombre,
p.apellido_paterno,
p.apellido_materno,
p.nombre || ' ' || p.apellido_paterno || ' ' || p.apellido_materno AS nombre_completo,
p.fecha_nacimiento,
DATE_PART('year', AGE(p.fecha_nacimiento))::INTEGER         AS edad,
cs.nombre                                                   AS sexo,
p.telefono,
p.correo,
p.direccion,
p.diagnostico_principal,
p.antecedentes_medicos
FROM  pacientes p
JOIN  cat_sexo cs ON cs.id_sexo = p.id_sexo;


-- ── vw_terapeutas_completo ────────────────────────────────────
DROP VIEW IF EXISTS vw_terapeutas_completo;
CREATE VIEW vw_terapeutas_completo AS
SELECT
t.id_terapeuta,
t.nombre,
t.apellido_paterno,
t.apellido_materno,
t.nombre || ' ' || t.apellido_paterno AS nombre_completo,
ce.nombre AS especialidad,
t.telefono,
t.correo,
t.observaciones
FROM  terapeutas t
JOIN  cat_especialidades ce ON ce.id_especialidad = t.id_especialidad;


-- ── vw_sesiones_detalle ───────────────────────────────────────
DROP VIEW IF EXISTS vw_sesiones_detalle;
CREATE VIEW vw_sesiones_detalle AS
SELECT
s.id_sesion,
s.fecha,
s.hora_inicio,
s.hora_fin,
s.estado_sesion,
s.hora_inicio_real,
s.hora_fin_real,
cts.nombre                                                  AS tipo_sesion,
s.asistencia,
s.observaciones_clinicas,
cmr.nombre                                                  AS metodo_registro,
(SELECT p.nombre || ' ' || p.apellido_paterno
  FROM   paciente_sesion ps2
  JOIN   pacientes p ON p.id_paciente = ps2.id_paciente
  WHERE  ps2.id_sesion = s.id_sesion LIMIT 1)               AS paciente_nombre,
(SELECT t.nombre || ' ' || t.apellido_paterno
  FROM   terapeuta_sesion ts2
  JOIN   terapeutas t ON t.id_terapeuta = ts2.id_terapeuta
  WHERE  ts2.id_sesion = s.id_sesion LIMIT 1)               AS terapeuta_nombre
FROM  sesiones s
JOIN  cat_tipos_sesion  cts ON cts.id_tipo_sesion = s.id_tipo_sesion
JOIN  cat_metodos_registro cmr ON cmr.id_metodo   = s.id_metodo;


-- ── vw_agenda_terapeuta ───────────────────────────────────────
DROP VIEW IF EXISTS vw_agenda_terapeuta;
CREATE VIEW vw_agenda_terapeuta AS
SELECT
s.id_sesion,
ts_rel.id_terapeuta,
s.hora_inicio,
s.hora_fin,
s.estado_sesion,
s.hora_inicio_real,
p.id_paciente,
p.nombre || ' ' || p.apellido_paterno                      AS paciente_nombre,
s.observaciones_clinicas                                   AS tratamiento,
CASE
WHEN s.estado_sesion = 'EN_CURSO'    THEN 'Consultorio'
WHEN s.estado_sesion = 'FINALIZADA'  THEN 'Finalizada'
WHEN s.estado_sesion = 'PROGRAMADA'
  AND CURRENT_TIME >= s.hora_inicio                 THEN 'Sala_Espera'
WHEN s.estado_sesion = 'PROGRAMADA'
  AND CURRENT_TIME >= (s.hora_inicio - INTERVAL '15 minutes')
  THEN 'Sala_Espera'
ELSE 'No_Llegado'
END                                                        AS estado_ubicacion
FROM  terapeuta_sesion ts_rel
JOIN  sesiones s  ON s.id_sesion = ts_rel.id_sesion
JOIN  paciente_sesion ps ON ps.id_sesion = s.id_sesion
JOIN  pacientes p ON p.id_paciente = ps.id_paciente
WHERE s.fecha = CURRENT_DATE
ORDER BY s.hora_inicio;


-- ── vw_mis_pacientes ─────────────────────────────────────────
DROP VIEW IF EXISTS vw_mis_pacientes;
CREATE VIEW vw_mis_pacientes AS
SELECT
pt.id_terapeuta,
p.id_paciente,
p.nombre || ' ' || p.apellido_paterno                      AS nombre,
DATE_PART('year', AGE(p.fecha_nacimiento))::INTEGER        AS edad,
p.diagnostico_principal                                    AS diagnostico,
ce.nombre                                                  AS tipo_terapia,
(SELECT MAX(s2.fecha)
  FROM   paciente_sesion ps2
  JOIN   sesiones s2 ON s2.id_sesion = ps2.id_sesion
  WHERE  ps2.id_paciente = p.id_paciente)                   AS ultima_sesion,
'Activo'                                                   AS estado
FROM  paciente_terapeuta pt
JOIN  pacientes      p  ON p.id_paciente    = pt.id_paciente
JOIN  terapeutas     t  ON t.id_terapeuta   = pt.id_terapeuta
JOIN  cat_especialidades ce ON ce.id_especialidad = t.id_especialidad;


-- ── vw_historial_sesiones ────────────────────────────────────
DROP VIEW IF EXISTS vw_historial_sesiones;
CREATE VIEW vw_historial_sesiones AS
SELECT
s.id_sesion,
s.fecha,
s.hora_inicio,
s.hora_fin,
ts_rel.id_terapeuta,
p.id_paciente,
p.nombre || ' ' || p.apellido_paterno                      AS paciente_nombre,
e.nombre_ejercicio,
nd.nombre                                                  AS nivel_dificultad,
ep.nivel_movilidad,
ep.nivel_dolor,
CASE
WHEN ep.nivel_movilidad >= 8 AND ep.nivel_dolor <= 2  THEN 'Excelente'
WHEN ep.nivel_movilidad >= 6 AND ep.nivel_dolor <= 4  THEN 'Bueno'
WHEN ep.nivel_movilidad >= 4                          THEN 'Regular'
ELSE 'Malo'
END                                                        AS evaluacion,
ep.progreso_observado
FROM  terapeuta_sesion ts_rel
JOIN  sesiones s ON s.id_sesion = ts_rel.id_sesion
JOIN  paciente_sesion ps ON ps.id_sesion = s.id_sesion
JOIN  pacientes p ON p.id_paciente = ps.id_paciente
LEFT JOIN ejercicio_sesion_detalle esd ON esd.id_sesion = s.id_sesion
LEFT JOIN ejercicios e ON e.id_ejercicio = esd.id_ejercicio
LEFT JOIN cat_nivel_dificultad nd ON nd.id_nivel = e.id_nivel_dificultad
LEFT JOIN paciente_evaluacion pev ON pev.id_paciente = ps.id_paciente
LEFT JOIN evaluaciones_progreso ep ON ep.id_evaluacion = pev.id_evaluacion
AND ep.fecha = s.fecha;


-- ── vw_historial_paciente ────────────────────────────────────
DROP VIEW IF EXISTS vw_historial_paciente;
CREATE VIEW vw_historial_paciente AS
SELECT
ps.id_paciente,
s.fecha                                                     AS fecha_raw,
TO_CHAR(s.fecha, 'DD Mon YYYY')                             AS fecha_formateada,
TO_CHAR(s.hora_inicio, 'HH12:MI AM')                        AS hora,
cts.nombre                                                  AS tipo_sesion,
e.nombre_ejercicio,
nd.nombre                                                   AS dificultad,
t.nombre || ' ' || t.apellido_paterno                       AS terapeuta,
CASE
WHEN ep.nivel_movilidad >= 8 AND ep.nivel_dolor <= 2   THEN 'excelente'
WHEN ep.nivel_movilidad >= 6 AND ep.nivel_dolor <= 4   THEN 'bueno'
WHEN ep.nivel_movilidad >= 4                           THEN 'regular'
ELSE 'malo'
END                                                         AS evaluacion_clase,
CASE
WHEN ep.nivel_movilidad >= 8 AND ep.nivel_dolor <= 2   THEN 'Excelente progreso'
WHEN ep.nivel_movilidad >= 6 AND ep.nivel_dolor <= 4   THEN 'Buen avance'
WHEN ep.nivel_movilidad >= 4                           THEN 'Avance moderado'
ELSE 'Requiere atención'
END                                                         AS evaluacion_texto,
COALESCE(s.observaciones_clinicas, ep.progreso_observado,
  'Sin observaciones registradas.')                  AS observaciones
FROM  paciente_sesion ps
JOIN  sesiones s ON s.id_sesion = ps.id_sesion
JOIN  cat_tipos_sesion cts ON cts.id_tipo_sesion = s.id_tipo_sesion
JOIN  terapeuta_sesion ts_rel ON ts_rel.id_sesion = s.id_sesion
JOIN  terapeutas t ON t.id_terapeuta = ts_rel.id_terapeuta
LEFT JOIN ejercicio_sesion_detalle esd ON esd.id_sesion = s.id_sesion
LEFT JOIN ejercicios e ON e.id_ejercicio = esd.id_ejercicio
LEFT JOIN cat_nivel_dificultad nd ON nd.id_nivel = e.id_nivel_dificultad
LEFT JOIN paciente_evaluacion pev ON pev.id_paciente = ps.id_paciente
LEFT JOIN evaluaciones_progreso ep ON ep.id_evaluacion = pev.id_evaluacion
AND ep.fecha = s.fecha;


-- ── vw_expediente_paciente ───────────────────────────────────
DROP VIEW IF EXISTS vw_expediente_paciente;
CREATE VIEW vw_expediente_paciente AS
SELECT
p.*,
cs.nombre                                                  AS sexo_nombre,
DATE_PART('year', AGE(p.fecha_nacimiento))::INTEGER        AS edad,
ce.nombre                                                  AS especialidad_terapeuta,
t.nombre || ' ' || t.apellido_paterno                      AS terapeuta_asignado,
(SELECT COUNT(*) FROM paciente_sesion ps2
  WHERE ps2.id_paciente = p.id_paciente)                    AS total_sesiones,
(SELECT MAX(s2.fecha) FROM paciente_sesion ps3
  JOIN sesiones s2 ON s2.id_sesion = ps3.id_sesion
  WHERE ps3.id_paciente = p.id_paciente)                    AS fecha_ultima_sesion
FROM  pacientes p
JOIN  cat_sexo cs ON cs.id_sexo = p.id_sexo
LEFT JOIN paciente_terapeuta pt ON pt.id_paciente = p.id_paciente
LEFT JOIN terapeutas t ON t.id_terapeuta = pt.id_terapeuta
LEFT JOIN cat_especialidades ce ON ce.id_especialidad = t.id_especialidad;


-- ── vw_rutas_domicilio ────────────────────────────────────────
DROP VIEW IF EXISTS vw_rutas_domicilio;
CREATE VIEW vw_rutas_domicilio AS
SELECT
g.id_registro,
g.id_terapeuta,
g.id_paciente,
p.nombre || ' ' || p.apellido_paterno                      AS paciente_nombre,
p.direccion,
g.latitud,
g.longitud,
g.fecha,
g.hora,
eg.nombre                                                  AS estado_gps,
v.tipo                                                     AS tipo_vehiculo
FROM  gps_registros g
JOIN  pacientes p     ON p.id_paciente = g.id_paciente
JOIN  cat_estados_gps eg ON eg.id_estado = g.id_estado
LEFT JOIN gps_vehiculo gv ON gv.id_registro = g.id_registro
LEFT JOIN vehiculos v ON v.id_vehiculo = gv.id_vehiculo;


-- ── vw_reporte_asistencia ────────────────────────────────────
DROP VIEW IF EXISTS vw_reporte_asistencia;
CREATE VIEW vw_reporte_asistencia AS
SELECT
p.id_paciente,
p.nombre || ' ' || p.apellido_paterno                      AS paciente,
COUNT(ps.id_sesion)                                        AS total_sesiones,
COUNT(CASE WHEN s.asistencia = TRUE THEN 1 END)            AS sesiones_asistidas,
COUNT(CASE WHEN s.asistencia = FALSE THEN 1 END)           AS sesiones_faltadas,
ROUND(
  COUNT(CASE WHEN s.asistencia = TRUE THEN 1 END)::NUMERIC
  / NULLIF(COUNT(ps.id_sesion), 0) * 100, 1
)                                                          AS porcentaje_asistencia
FROM  paciente_sesion ps
JOIN  pacientes p ON p.id_paciente = ps.id_paciente
JOIN  sesiones  s ON s.id_sesion   = ps.id_sesion
GROUP BY p.id_paciente, p.nombre, p.apellido_paterno
ORDER BY porcentaje_asistencia DESC;

--── vw_kpi_tendencia_asistencias ────────────────────────────────────
CREATE OR REPLACE VIEW vw_kpi_tendencia_asistencias AS
SELECT 
    TO_CHAR(fecha, 'YYYY-MM-DD') AS fecha_registro,
    fecha,
    COUNT(CASE WHEN asistencia = TRUE THEN 1 END) AS total_asistencias,
    COUNT(CASE WHEN asistencia = FALSE THEN 1 END) AS total_cancelaciones
FROM vw_sesiones_detalle
GROUP BY fecha
ORDER BY fecha ASC;
