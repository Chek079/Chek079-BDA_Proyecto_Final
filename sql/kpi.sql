SELECT * FROM vw_reporte_asistencia;

-- 1. Pacientes activos
SELECT COUNT(DISTINCT id_paciente) AS pacientes_activos
FROM paciente_sesion;

-- 2. Sesiones del día
SELECT COUNT(*) AS sesiones_hoy
FROM sesiones
WHERE fecha = CURRENT_DATE;

-- 3. Tasa de asistencia
SELECT ROUND( ( COUNT(CASE WHEN asistencia = TRUE THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2) AS tasa_asistencia
FROM sesiones;

-- 4. Efectividad promedio
SELECT ROUND( AVG( ( nivel_movilidad + resistencia + (10 - nivel_dolor)) / 3.0), 2) AS efectividad_promedio
FROM evaluaciones_progreso;


-- 5. Sesiones finalizadas
SELECT COUNT(*) AS sesiones_finalizadas
FROM sesiones
WHERE estado_sesion = 'FINALIZADA';


-- 6. Vehículos en uso
SELECT COUNT(*) AS vehiculos_en_uso
FROM vehiculos v
JOIN cat_estados_vehiculo cev ON v.id_estado = cev.id_estado
WHERE cev.nombre = 'EN_USO';

-- 7. Dispositivos NFC activos
SELECT COUNT(*) AS dispositivos_nfc_activos
FROM dispositivos_nfc d
JOIN cat_estados_dispositivo ced ON d.id_estado = ced.id_estado
WHERE ced.nombre = 'ACTIVO';

-- 8. Terapeuta con más sesiones
SELECT
    t.id_terapeuta,
    t.nombre,
    t.apellido_paterno,
    COUNT(ts.id_sesion) AS total_sesiones
FROM terapeutas t
JOIN terapeuta_sesion ts ON t.id_terapeuta = ts.id_terapeuta
GROUP BY
    t.id_terapeuta,
    t.nombre,
    t.apellido_paterno
ORDER BY total_sesiones DESC
LIMIT 1;

-- 9. Promedio de dolor actual
SELECT ROUND(AVG(nivel_dolor), 2) AS promedio_dolor
FROM evaluaciones_progreso;

-- 10. Promedio de movilidad
SELECT ROUND(AVG(nivel_movilidad), 2) AS promedio_movilidad
FROM evaluaciones_progreso;

-- 11. Pacientes dados de alta
SELECT COUNT(DISTINCT pe.id_paciente) AS pacientes_alta
FROM paciente_evaluacion pe
JOIN evaluaciones_progreso ep ON pe.id_evaluacion = ep.id_evaluacion
WHERE ep.tipo_evaluacion = 'Final';

-- 12. Tiempo promedio por sesion
SELECT ROUND( AVG( EXTRACT(EPOCH FROM (hora_fin_real - hora_inicio_real)) / 60), 2) AS tiempo_promedio_minutos
FROM sesiones
WHERE hora_inicio_real IS NOT NULL AND hora_fin_real IS NOT NULL;
