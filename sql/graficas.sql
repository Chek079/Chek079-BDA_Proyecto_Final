-- Tiempo promedio por terapeuta
SELECT t.nombre || ' ' || t.apellido_paterno AS terapeuta, ROUND( AVG( EXTRACT(EPOCH FROM ( s.hora_fin_real - s.hora_inicio_real)) / 60), 2) AS promedio_minutos
FROM sesiones s
JOIN terapeuta_sesion ts ON s.id_sesion = ts.id_sesion
JOIN terapeutas t ON ts.id_terapeuta = t.id_terapeuta
WHERE s.hora_inicio_real IS NOT NULL AND s.hora_fin_real IS NOT NULL
GROUP BY terapeuta;

-- Ejercicios mas usados
SELECT e.nombre_ejercicio, COUNT(*) AS veces_usado
FROM ejercicio_sesion_detalle esd
JOIN ejercicios e ON esd.id_ejercicio = e.id_ejercicio
GROUP BY e.nombre_ejercicio
ORDER BY veces_usado DESC;

-- Nivel promedio de dolor vs movilidad
SELECT fecha, ROUND(AVG(nivel_dolor),2) AS dolor, ROUND(AVG(nivel_movilidad),2) AS movilidad
FROM evaluaciones_progreso
GROUP BY fecha
ORDER BY fecha;
