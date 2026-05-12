-- ============================================================
-- PRUEBAS DE TRANSACCIONES — rehabilitacion_fisica v3
-- PostgreSQL 16
-- TODAS las pruebas terminan en ROLLBACK
-- Ninguna modifica la BD permanentemente
-- ============================================================

\c rehabilitacion_fisica;


-- ============================================================
-- 1. INSERCIONES VÁLIDAS (ROLLBACK — no se guardan en BD)
-- ============================================================

-- Prueba V-1: Insertar un nuevo paciente válido
BEGIN;
    INSERT INTO pacientes (
        nombre, apellido_paterno, apellido_materno,
        fecha_nacimiento, id_sexo, telefono, correo,
        direccion, diagnostico_principal
    ) VALUES (
        'Luis', 'Pérez', 'Garza',
        '1990-05-20', 1, '8110001111', 'luis.perez@correo.com',
        'Av. Morones Prieto 100, Monterrey',
        'Rehabilitación post-fractura de tobillo'
    );
    SELECT id_paciente, nombre, apellido_paterno
    FROM   pacientes WHERE correo = 'luis.perez@correo.com';
ROLLBACK;
-- Resultado esperado: INSERT exitoso pero no se guarda en BD


-- Prueba V-2: Insertar un terapeuta válido con especialidad existente
BEGIN;
    INSERT INTO terapeutas (
        nombre, apellido_paterno, apellido_materno,
        id_especialidad, telefono, correo
    ) VALUES (
        'Carmen', 'Ibáñez', 'Soto',
        2, '8120002222', 'c.ibanez@clinica.com'
    );
    SELECT id_terapeuta, nombre FROM terapeutas
    WHERE correo = 'c.ibanez@clinica.com';
ROLLBACK;
-- Resultado esperado: INSERT exitoso pero no se guarda en BD


-- Prueba V-3: Insertar un usuario válido con rol admin
BEGIN;
    INSERT INTO usuarios (login, password, rol, ref_id)
    VALUES ('test_admin', '1234', 'admin', NULL);
    SELECT login, rol FROM usuarios WHERE login = 'test_admin';
ROLLBACK;
-- Resultado esperado: INSERT exitoso pero no se guarda en BD


-- Prueba V-4: Insertar una sesión válida para hoy
BEGIN;
    INSERT INTO sesiones (
        fecha, hora_inicio, hora_fin,
        id_tipo_sesion, observaciones_clinicas,
        asistencia, id_metodo, estado_sesion
    ) VALUES (
        CURRENT_DATE, '20:00:00', '20:45:00',
        1, 'Sesión de prueba válida.',
        FALSE, 1, 'PROGRAMADA'
    );
    SELECT id_sesion, fecha, estado_sesion
    FROM   sesiones WHERE observaciones_clinicas = 'Sesión de prueba válida.';
ROLLBACK;
-- Resultado esperado: INSERT exitoso pero no se guarda en BD


-- Prueba V-5: Insertar un dispositivo NFC válido
BEGIN;
    INSERT INTO dispositivos_nfc (
        tipo_dispositivo, ubicacion, id_estado, descripcion
    ) VALUES (
        'Lector de tarjeta', 'Sala de espera principal',
        1, 'Nuevo lector instalado en sala de espera'
    );
    SELECT id_dispositivo, tipo_dispositivo, ubicacion
    FROM   dispositivos_nfc
    WHERE  ubicacion = 'Sala de espera principal';
ROLLBACK;
-- Resultado esperado: INSERT exitoso pero no se guarda en BD


-- ============================================================
-- 2. VIOLACIÓN DE UNIQUE (ROLLBACK)
-- ============================================================

-- Prueba U-1: Correo duplicado en pacientes
BEGIN;
    INSERT INTO pacientes (
        nombre, apellido_paterno, apellido_materno,
        fecha_nacimiento, id_sexo, correo, diagnostico_principal
    ) VALUES (
        'Otro', 'Usuario', 'Prueba',
        '1985-01-01', 1,
        'c.ramirez@correo.com',
        'Diagnóstico de prueba'
    );
ROLLBACK;
-- Resultado esperado: ERROR duplicate key value violates unique constraint "pacientes_correo_key"


-- Prueba U-2: Correo duplicado en terapeutas
BEGIN;
    INSERT INTO terapeutas (
        nombre, apellido_paterno, apellido_materno,
        id_especialidad, correo
    ) VALUES (
        'Copia', 'Terapeuta', 'Prueba',
        1, 'l.mendoza@clinica.com'
    );
ROLLBACK;
-- Resultado esperado: ERROR duplicate key value violates unique constraint "terapeutas_correo_key"


-- Prueba U-3: Login duplicado en usuarios
BEGIN;
    INSERT INTO usuarios (login, password, rol)
    VALUES ('admin01', '9999', 'admin');
ROLLBACK;
-- Resultado esperado: ERROR duplicate key value violates unique constraint "usuarios_login_key"


-- Prueba U-4: Nombre duplicado en cat_especialidades
BEGIN;
    INSERT INTO cat_especialidades (nombre)
    VALUES ('Fisioterapia Musculoesquelética');
ROLLBACK;
-- Resultado esperado: ERROR duplicate key value violates unique constraint "cat_especialidades_nombre_key"


-- Prueba U-5: Asistencia NFC duplicada para mismo paciente y sesión
BEGIN;
    INSERT INTO asistencias_nfc (
        id_paciente, id_sesion, fecha,
        hora_entrada, asistencia_confirmada, id_dispositivo
    ) VALUES (
        1, 1, CURRENT_DATE,
        '09:10:00', TRUE, 1
    );
ROLLBACK;
-- Resultado esperado: ERROR duplicate key value violates unique constraint "uq_asistencia_paciente_sesion"


-- ============================================================
-- 3. VIOLACIÓN DE FOREIGN KEY (ROLLBACK)
-- ============================================================

-- Prueba F-1: Paciente con id_sexo inexistente
BEGIN;
    INSERT INTO pacientes (
        nombre, apellido_paterno, apellido_materno,
        fecha_nacimiento, id_sexo, diagnostico_principal
    ) VALUES (
        'Prueba', 'FK', 'Sexo',
        '2000-01-01', 999,
        'Diagnóstico de prueba'
    );
ROLLBACK;
-- Resultado esperado: ERROR violates foreign key constraint "pacientes_id_sexo_fkey"


-- Prueba F-2: Terapeuta con id_especialidad inexistente
BEGIN;
    INSERT INTO terapeutas (
        nombre, apellido_paterno, apellido_materno,
        id_especialidad
    ) VALUES (
        'Prueba', 'FK', 'Especialidad',
        999
    );
ROLLBACK;
-- Resultado esperado: ERROR violates foreign key constraint "terapeutas_id_especialidad_fkey"


-- Prueba F-3: Sesión con id_tipo_sesion inexistente
BEGIN;
    INSERT INTO sesiones (
        fecha, hora_inicio, hora_fin,
        id_tipo_sesion, asistencia, id_metodo
    ) VALUES (
        CURRENT_DATE, '21:00:00', '21:45:00',
        999, FALSE, 1
    );
ROLLBACK;
-- Resultado esperado: ERROR violates foreign key constraint "sesiones_id_tipo_sesion_fkey"


-- Prueba F-4: Dispositivo NFC con id_estado inexistente
BEGIN;
    INSERT INTO dispositivos_nfc (
        tipo_dispositivo, ubicacion, id_estado
    ) VALUES (
        'Lector de prueba', 'Ubicación test',
        999
    );
ROLLBACK;
-- Resultado esperado: ERROR violates foreign key constraint "dispositivos_nfc_id_estado_fkey"


-- Prueba F-5: Beacon evento con id_paciente inexistente
BEGIN;
    INSERT INTO beacon_evento (
        id_beacon, id_paciente, fecha, hora
    ) VALUES (
        1, 9999, CURRENT_DATE, CURRENT_TIME
    );
ROLLBACK;
-- Resultado esperado: ERROR violates foreign key constraint "beacon_evento_id_paciente_fkey"


-- ============================================================
-- 4. VIOLACIÓN DE CHECK (ROLLBACK)
-- ============================================================

-- Prueba C-1: Sesión con hora_fin menor que hora_inicio
BEGIN;
    INSERT INTO sesiones (
        fecha, hora_inicio, hora_fin,
        id_tipo_sesion, asistencia, id_metodo
    ) VALUES (
        CURRENT_DATE, '11:00:00', '10:00:00',
        1, FALSE, 1
    );
ROLLBACK;
-- Resultado esperado: ERROR violates check constraint "check_horas"


-- Prueba C-2: Evaluación con nivel_movilidad fuera de rango (> 10)
BEGIN;
    INSERT INTO evaluaciones_progreso (
        fecha, tipo_evaluacion,
        nivel_movilidad, nivel_dolor, resistencia
    ) VALUES (
        CURRENT_DATE, 'Inicial',
        15, 5, 5
    );
ROLLBACK;
-- Resultado esperado: ERROR violates check constraint "evaluaciones_progreso_nivel_movilidad_check"


-- Prueba C-3: Evaluación con nivel_dolor negativo (< 0)
BEGIN;
    INSERT INTO evaluaciones_progreso (
        fecha, tipo_evaluacion,
        nivel_movilidad, nivel_dolor, resistencia
    ) VALUES (
        CURRENT_DATE, 'Seguimiento',
        5, -1, 5
    );
ROLLBACK;
-- Resultado esperado: ERROR violates check constraint "evaluaciones_progreso_nivel_dolor_check"


-- Prueba C-4: Ejercicio con repeticiones = 0
BEGIN;
    INSERT INTO ejercicio_sesion_detalle (
        id_sesion, id_ejercicio, repeticiones, duracion_min
    ) VALUES (
        1, 1, 0, 10
    );
ROLLBACK;
-- Resultado esperado: ERROR violates check constraint "ejercicio_sesion_detalle_repeticiones_check"


-- Prueba C-5: Usuario con rol inválido
BEGIN;
    INSERT INTO usuarios (login, password, rol)
    VALUES ('prueba_rol', '1234', 'superadmin');
ROLLBACK;
-- Resultado esperado: ERROR violates check constraint en columna rol