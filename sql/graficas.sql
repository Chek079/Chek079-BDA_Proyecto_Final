-- Ver los estados de las sesiones
SELECT estado_sesion, COUNT(*) AS total
FROM sesiones
GROUP BY estado_sesion;

-- Evaluacion de dolor
SELECT fecha, ROUND(AVG(nivel_dolor), 2) AS dolor_promedio
FROM evaluaciones_progreso
GROUP BY fecha
ORDER BY fecha;

-- Evolucion de movilidad
SELECT fecha, ROUND(AVG(nivel_movilidad), 2) AS movilidad_promedio
FROM evaluaciones_progreso
GROUP BY fecha
ORDER BY fecha;

-- Sesiones por terapeuta 
SELECT t.nombre || ' ' || t.apellido_paterno AS terapeuta, COUNT(ts.id_sesion) AS total_sesiones
FROM terapeutas t JOIN terapeuta_sesion ts ON t.id_terapeuta = ts.id_terapeuta
GROUP BY terapeuta
ORDER BY total_sesiones DESC;

-- Tipos de sesiones mas comunes
SELECT cts.nombre, COUNT(*) AS total
FROM sesiones s
JOIN cat_tipos_sesion cts ON s.id_tipo_sesion = cts.id_tipo_sesion
GROUP BY cts.nombre;

-- Metodos de registros mas usados
SELECT cmr.nombre, COUNT(*) AS total
FROM sesiones s
JOIN cat_metodos_registro cmr ON s.id_metodo = cmr.id_metodo
GROUP BY cmr.nombre;

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

-- Pacientes por sexo
SELECT cs.nombre, COUNT(*) AS total
FROM pacientes p
JOIN cat_sexo cs ON p.id_sexo = cs.id_sexo
GROUP BY cs.nombre;

-- Estados por vehiculos WIP
SELECT cev.nombre, COUNT(*) AS total
FROM vehiculos v
JOIN cat_estados_vehiculo cev ON v.id_estado = cev.id_estado
GROUP BY cev.nombre;

-- Sessiones por dia
SELECT fecha, COUNT(*) AS total
FROM sesiones
GROUP BY fecha
ORDER BY fecha;

-- Nivel promedio de dolor vs movilidad
SELECT fecha, ROUND(AVG(nivel_dolor),2) AS dolor, ROUND(AVG(nivel_movilidad),2) AS movilidad
FROM evaluaciones_progreso
GROUP BY fecha
ORDER BY fecha;
