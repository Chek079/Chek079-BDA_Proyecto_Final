-- ============================================================
-- DML: rehabilitacion_fisica v3
-- Actualizado con todos los cambios del proyecto:
--   + Tabla usuarios con logins por nombre
--   + Tabla nfc_uids
--   + Solo 2 terapeutas (Laura y Andrés)
--   + Sesiones con estado_sesion
-- ============================================================

\c rehabilitacion_fisica;


-- ============================================================
-- 1. CATÁLOGOS DE DOMINIO
-- ============================================================

INSERT INTO cat_sexo (nombre) VALUES
    ('MASCULINO'),
    ('FEMENINO'),
    ('OTRO');

INSERT INTO cat_especialidades (nombre) VALUES
    ('Fisioterapia Musculoesquelética'),
    ('Neurorehabilitación'),
    ('Rehabilitación Cardiopulmonar'),
    ('Fisioterapia Deportiva'),
    ('Fisioterapia Pediátrica');

INSERT INTO cat_tipos_sesion (nombre) VALUES
    ('Individual'),
    ('Grupal'),
    ('Respiratoria');

INSERT INTO cat_metodos_registro (nombre) VALUES
    ('NFC'),
    ('Manual');

INSERT INTO cat_tipos_ejercicio (nombre) VALUES
    ('Estiramiento'),
    ('Fortalecimiento'),
    ('Equilibrio'),
    ('Cardiorrespiratorio'),
    ('Movilidad Articular');

INSERT INTO cat_nivel_dificultad (nombre) VALUES
    ('BAJO'),
    ('MEDIO'),
    ('ALTO');

INSERT INTO cat_estados_dispositivo (nombre) VALUES
    ('ACTIVO'),
    ('INACTIVO'),
    ('MANTENIMIENTO');

INSERT INTO cat_estados_beacon (nombre) VALUES
    ('ACTIVO'),
    ('INACTIVO');

INSERT INTO cat_estados_gps (nombre) VALUES
    ('EN_RUTA'),
    ('LLEGADO'),
    ('FINALIZADO');

INSERT INTO cat_estados_vehiculo (nombre) VALUES
    ('DISPONIBLE'),
    ('EN_USO'),
    ('MANTENIMIENTO');


-- ============================================================
-- 2. ENTIDADES MAESTRAS
-- ============================================================

-- Solo 2 terapeutas
INSERT INTO terapeutas (nombre, apellido_paterno, apellido_materno, id_especialidad, telefono, correo, observaciones) VALUES
    ('Laura',  'Mendoza', 'Cruz',    1, '8190123456', 'l.mendoza@clinica.com', 'Certificada en terapia manual ortopédica'),
    ('Andrés', 'Fuentes', 'Ortega',  2, '8101234567', 'a.fuentes@clinica.com', 'Especialista en ACV y lesiones medulares');

-- 9 Pacientes
INSERT INTO pacientes (nombre, apellido_paterno, apellido_materno, fecha_nacimiento, id_sexo, telefono, correo, direccion, diagnostico_principal, antecedentes_medicos) VALUES
    ('Carlos',   'Ramírez',   'Torres',   '1985-03-15', 1, '8112345678', 'c.ramirez@correo.com',   'Av. Constitución 100, Monterrey',    'Lumbalgia crónica',             'Hernia discal L4-L5 en 2018'),
    ('María',    'González',  'Flores',   '1990-07-22', 2, '8123456789', 'm.gonzalez@correo.com',  'Calle Morelos 250, San Nicolás',     'Rehabilitación post-fractura',  'Fractura de cúbito derecho 2023'),
    ('Roberto',  'Hernández', 'Vega',     '1978-11-30', 1, '8134567890', 'r.hernandez@correo.com', 'Blvd. Díaz Ordaz 500, Monterrey',   'Lesión de ligamento cruzado',   'Diabetes tipo 2, hipertensión'),
    ('Ana',      'López',     'Martínez', '2000-05-10', 2, '8145678901', 'a.lopez@correo.com',     'Av. Insurgentes 300, Guadalupe',     'Escoliosis leve',               NULL),
    ('Miguel',   'Sánchez',   'Reyes',    '1955-09-18', 1, '8156789012', 'm.sanchez@correo.com',   'Calle Juárez 88, Apodaca',           'Artrosis de rodilla bilateral', 'Reemplazo de cadera derecha 2020'),
    ('Patricia', 'Morales',   'Jiménez',  '1995-01-25', 2, '8167890123', 'p.morales@correo.com',   'Av. Lázaro Cárdenas 450, Monterrey', 'Tendinitis rotuliana',          NULL),
    ('Jorge',    'Castillo',  'Núñez',    '1982-06-08', 1, '8178901234', 'j.castillo@correo.com',  'Calle Hidalgo 77, Santa Catarina',   'Parálisis facial periférica',   'Hipertensión arterial'),
    ('Sofía',    'Vargas',    'Espinoza', '2005-12-03', 2, '8189012345', 's.vargas@correo.com',    'Av. Revolución 120, Monterrey',      'Pie plano severo',              NULL),
    ('Sergio',   'Ayala',     'García',   '1998-04-12', 1, '8199012346', 's.ayala@correo.com',     'Av. Morones Prieto 200, Monterrey',  'Rehabilitación post-fractura de tobillo', NULL);

-- Ejercicios
INSERT INTO ejercicios (nombre_ejercicio, descripcion, id_tipo_ejercicio, id_nivel_dificultad) VALUES
    ('Estiramiento de isquiotibiales',       'Estiramiento en decúbito supino con banda elástica, 30 seg por lado.',     1, 1),
    ('Sentadilla asistida',                  'Sentadilla con apoyo en barras paralelas, control excéntrico.',             2, 2),
    ('Equilibrio en una pierna',             'Mantenerse en un pie sobre superficie inestable por 30 segundos.',          3, 2),
    ('Bicicleta estática',                   'Pedaleo continuo a ritmo moderado para trabajo cardiorrespiratorio.',       4, 1),
    ('Movilización cervical activa',         'Movimientos lentos de flexión, extensión y rotación cervical.',             5, 1),
    ('Prensa de pierna',                     'Empuje bilateral en máquina, ángulo de 90° a 160°.',                       2, 3),
    ('Estiramientos de pectoral',            'Estiramiento en marco de puerta, 3 series de 20 segundos.',                1, 1),
    ('Ejercicio respiratorio diafragmático', 'Respiración abdominal controlada en posición supina, 10 repeticiones.',    4, 1),
    ('Puente de glúteo',                     'En decúbito supino, elevar cadera manteniendo core activo.',               2, 2),
    ('Marcha en paralelas',                  'Deambulación con apoyo en barras paralelas, paso controlado.',              3, 1);

-- Vehículos
INSERT INTO vehiculos (tipo, descripcion, id_estado) VALUES
    ('Ambulancia',    'Unidad de traslado médico equipada con camilla y oxígeno.', 2),
    ('Van adaptada',  'Vehículo con rampa hidráulica para silla de ruedas.',        1),
    ('Sedán clínico', 'Automóvil para traslado de terapeutas a domicilio.',         1);

-- Dispositivos NFC
INSERT INTO dispositivos_nfc (tipo_dispositivo, ubicacion, id_estado, descripcion) VALUES
    ('Lector de pulsera', 'Recepción principal',        1, 'Lector NFC para registro de entrada de pacientes'),
    ('Lector de tarjeta', 'Sala de fisioterapia A',     1, 'Dispositivo para confirmar inicio de sesión'),
    ('Lector de pulsera', 'Sala de fisioterapia B',     1, 'Dispositivo para confirmar inicio de sesión'),
    ('Terminal fija',     'Pasillo central',            2, 'Terminal en mantenimiento preventivo'),
    ('Lector de tarjeta', 'Gimnasio de rehabilitación', 1, 'Control de acceso al área de ejercicios');

-- Beacons
INSERT INTO beacons (area, habitacion, id_estado) VALUES
    ('Fisioterapia', 'Sala A',              1),
    ('Fisioterapia', 'Sala B',              1),
    ('Gimnasio',     'Área de máquinas',    1),
    ('Recepción',    'Lobby',               1),
    ('Hidroterapia', 'Piscina terapéutica', 1),
    ('Consultorios', 'Consultorio 1',       1);


-- ============================================================
-- 3. USUARIOS (autenticación)
-- ============================================================

INSERT INTO usuarios (login, password, rol, ref_id) VALUES
    ('admin01',        '1234', 'admin',     NULL),
    ('laura.mendoza',  '1234', 'terapeuta', 1),
    ('andres.fuentes', '1234', 'terapeuta', 2),
    ('fam_pac1',       '1234', 'familiar',  1),
    ('fam_pac2',       '1234', 'familiar',  2),
    ('fam_pac3',       '1234', 'familiar',  3);


-- ============================================================
-- 4. TABLAS MULTIVALUADAS
-- ============================================================

INSERT INTO paciente_alergia (id_paciente, alergia) VALUES
    (1, 'Penicilina'),
    (3, 'Ibuprofeno'),
    (3, 'Látex'),
    (5, 'Aspirina'),
    (7, 'Sulfamidas');

INSERT INTO paciente_lesion (id_paciente, lesion_previa) VALUES
    (1, 'Hernia discal L4-L5'),
    (2, 'Fractura de cúbito derecho'),
    (3, 'Rotura de menisco medial izquierdo'),
    (5, 'Fractura de cadera derecha'),
    (7, 'Parálisis facial 2019');

INSERT INTO paciente_medicamento (id_paciente, medicamento_actual) VALUES
    (1, 'Naproxeno 500mg'),
    (3, 'Metformina 850mg'),
    (3, 'Losartán 50mg'),
    (5, 'Ácido hialurónico intraarticular'),
    (7, 'Prednisolona 5mg');


-- ============================================================
-- 5. RELACIONES N:M
-- ============================================================

-- Paciente ↔ Terapeuta (solo terapeutas 1 y 2)
INSERT INTO paciente_terapeuta (id_paciente, id_terapeuta) VALUES
    (1, 1), (2, 1), (3, 1),
    (4, 1), (5, 1), (6, 1),
    (7, 2), (8, 2), (9, 1);

-- Evaluaciones
INSERT INTO evaluaciones_progreso (fecha, tipo_evaluacion, nivel_movilidad, nivel_dolor, resistencia, progreso_observado, recomendaciones, ajustes_plan) VALUES
    ('2024-10-28', 'Inicial',     5, 7, 4, 'Limitación significativa en flexión lumbar.',         'Iniciar con ejercicios de bajo impacto.',      'Plan de 12 semanas, 3 sesiones semanales.'),
    ('2024-10-28', 'Inicial',     6, 5, 5, 'Buena fuerza residual, movilidad reducida en codo.',  'Priorizar movilidad articular de codo.',       'Incluir ejercicios de movilización activa.'),
    ('2024-10-29', 'Inicial',     4, 8, 3, 'Inestabilidad marcada en rodilla izquierda.',          'Evitar impacto hasta reducir inflamación.',    'Inicio con fortalecimiento isométrico.'),
    ('2024-11-04', 'Seguimiento', 7, 4, 6, 'Mejora del 30% en rango de movimiento lumbar.',        'Incrementar progresivamente la carga.',        'Agregar sentadilla asistida a la rutina.'),
    ('2024-11-05', 'Seguimiento', 7, 3, 7, 'Reducción notable del dolor, mejor funcionalidad.',    'Continuar con plan actual.',                   NULL),
    ('2024-11-06', 'Final',       9, 2, 8, 'Paciente alcanzó objetivos funcionales planteados.',   'Alta clínica con programa de mantenimiento.',  'Reducir a 1 sesión quincenal de seguimiento.');

INSERT INTO paciente_evaluacion (id_paciente, id_evaluacion) VALUES
    (1, 1), (2, 2), (3, 3), (1, 4), (2, 5), (2, 6);

INSERT INTO evaluacion_terapeuta (id_evaluacion, id_terapeuta) VALUES
    (1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1);


-- ============================================================
-- 6. SESIONES DE HOY (tiempo real)
-- Ajusta las horas según la hora actual al momento de insertar
-- ============================================================

INSERT INTO sesiones (fecha, hora_inicio, hora_fin, id_tipo_sesion, observaciones_clinicas, asistencia, id_metodo, estado_sesion) VALUES
    (CURRENT_DATE, '09:00:00', '09:45:00', 1, 'Rehabilitación lumbar - Carlos',           FALSE, 1, 'PROGRAMADA'),
    (CURRENT_DATE, '10:00:00', '10:45:00', 1, 'Movilidad de codo - María',                FALSE, 1, 'PROGRAMADA'),
    (CURRENT_DATE, '11:00:00', '11:45:00', 1, 'Fortalecimiento de rodilla - Roberto',     FALSE, 1, 'PROGRAMADA'),
    (CURRENT_DATE, '12:00:00', '13:00:00', 2, 'Sesión grupal de movilidad',               FALSE, 2, 'PROGRAMADA'),
    (CURRENT_DATE, '14:00:00', '14:45:00', 3, 'Ejercicios respiratorios - Jorge',         FALSE, 1, 'PROGRAMADA'),
    (CURRENT_DATE, '15:00:00', '15:45:00', 1, 'Rehabilitación neurológica - Jorge',       FALSE, 1, 'PROGRAMADA'),
    (CURRENT_DATE, '16:00:00', '16:45:00', 1, 'Tendinitis rotuliana - Patricia',          FALSE, 1, 'PROGRAMADA'),
    (CURRENT_DATE, '17:00:00', '17:45:00', 1, 'Escoliosis - Ana',                        FALSE, 2, 'PROGRAMADA');

-- Paciente ↔ Sesión
INSERT INTO paciente_sesion (id_paciente, id_sesion) VALUES
    (1, 1), (2, 2), (3, 3),
    (4, 4), (5, 4),
    (7, 5), (7, 6),
    (6, 7), (4, 8);

-- Terapeuta ↔ Sesión
INSERT INTO terapeuta_sesion (id_terapeuta, id_sesion) VALUES
    (1, 1), (1, 2), (1, 3),
    (1, 4), (2, 5), (2, 6),
    (1, 7), (1, 8);

-- Ejercicios en sesiones
INSERT INTO ejercicio_sesion_detalle (id_sesion, id_ejercicio, repeticiones, duracion_min, observaciones) VALUES
    (1, 1, 3, 10, 'Buen rango de movimiento'),
    (1, 5, 2,  8, NULL),
    (2, 7, 3, 10, 'Molestia leve en hombro izquierdo'),
    (3, 2, 4, 15, 'Carga aumentada a 30 kg'),
    (3, 9, 3, 10, NULL),
    (4, 3, 3, 12, 'Sesión grupal, buen desempeño'),
    (5, 8, 5,  8, 'Completado sin disnea'),
    (6, 10,3, 10, NULL),
    (7, 4, 1, 20, 'Frecuencia cardíaca en rango'),
    (8, 1, 3, 10, NULL);


-- ============================================================
-- 7. IoT
-- ============================================================

-- GPS registros
INSERT INTO gps_registros (id_paciente, id_terapeuta, latitud, longitud, fecha, hora, id_estado) VALUES
    (1, 1, 25.686614, -100.316116, CURRENT_DATE, '08:30:00', 3),
    (2, 1, 25.726168, -100.318990, CURRENT_DATE, '09:30:00', 3),
    (7, 2, 25.700000, -100.350000, CURRENT_DATE, '13:30:00', 1);

INSERT INTO gps_vehiculo (id_registro, id_vehiculo) VALUES
    (1, 2), (2, 2), (3, 1);


-- ============================================================
-- 8. NFC UIDs — vincula tarjeta con paciente
-- ============================================================

INSERT INTO nfc_uids (id_paciente, uid) VALUES
    (1, 'AA:BB:CC:11'),
    (2, 'AA:BB:CC:22'),
    (3, 'AA:BB:CC:33'),
    (4, 'AA:BB:CC:44'),
    (5, 'AA:BB:CC:55'),
    (6, 'AA:BB:CC:66'),
    (7, 'AA:BB:CC:77'),
    (8, 'AA:BB:CC:88'),
    (9, 'AA:BB:CC:99');
