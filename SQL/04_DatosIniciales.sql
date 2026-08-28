-- ==============================================================
-- HOTELVIP SaaS - Datos Iniciales v1.0.0
-- SistemasVIP - Cusco, Peru
-- ==============================================================

SET NAMES utf8mb4;

-- ============================================================
-- ROLES
-- ============================================================
INSERT IGNORE INTO seg_Roles (IdRol, Nombre, Descripcion) VALUES
(1, 'Administrador', 'Acceso completo al sistema'),
(2, 'Recepcionista',  'Reservas, check-in/out, caja'),
(3, 'Housekeeping',   'Tareas de limpieza'),
(4, 'Supervisor',     'Supervision HSK y reportes'),
(5, 'Caja',           'Solo caja y pagos');

-- ============================================================
-- USUARIO ADMIN INICIAL
-- Clave: Admin123 (SHA2-256 — cambiar al instalar)
-- ============================================================
INSERT IGNORE INTO seg_Usuarios (IdUsuario, Usuario, Contrasena, Nombres, Email, IdRol, Activo)
VALUES (1, 'admin',
  SHA2('Admin123', 256),
  'Administrador', 'admin@hotel.com', 1, 1);

-- ============================================================
-- CONFIGURACION HOTEL
-- ============================================================
INSERT IGNORE INTO cfg_Hotel (IdHotel, NombreComercial, MonedaDefecto, HoraCheckin, HoraCheckout, IGV_General, IGV_Nacional, IGV_Extranjero)
VALUES (1, 'HOTEL VIP', 'PEN', '14:00:00', '12:00:00', 18.00, 18.00, 0.00);

-- ============================================================
-- MONEDAS Y TIPO DE CAMBIO
-- ============================================================
-- EsBase = 1 en PEN (moneda local del hotel). Activo = 1 en todas.
INSERT IGNORE INTO cfg_Monedas (IdMoneda, Codigo, Nombre, Simbolo, EsBase, Activo) VALUES
(1, 'PEN', 'Sol Peruano',    'S/', 1, 1),
(2, 'USD', 'Dolar Americano','$',  0, 1),
(3, 'EUR', 'Euro',           '€',  0, 1);

-- Modelo origen->destino: USD y EUR cotizados contra la moneda base PEN (IdMoneda=1).
-- PEN no se cotiza contra si mismo (el GET filtra EsBase=0).
INSERT INTO cfg_TipoCambio (IdMonedaOrigen, IdMonedaDestino, Tasa, Fecha, Fuente) VALUES
(2, 1, 3.7500, CURDATE(), 'MANUAL'),
(3, 1, 4.1000, CURDATE(), 'MANUAL')
ON DUPLICATE KEY UPDATE Tasa = VALUES(Tasa), Fuente = VALUES(Fuente);

-- ============================================================
-- TIPOS DE DOCUMENTO
-- ============================================================
INSERT IGNORE INTO hsp_TiposDocumento (IdTipoDoc, Codigo, Nombre, CodigoSUNAT) VALUES
(1, 'DNI',      'DNI - Doc. Nacional de Identidad', '1'),
(2, 'CE',       'Carnet de Extranjeria',             '4'),
(3, 'PASAPORTE','Pasaporte',                         '7'),
(4, 'RUC',      'RUC',                               '6');

-- ============================================================
-- TIPOS DE HABITACION
-- ============================================================
INSERT IGNORE INTO cfg_TiposHabitacion (IdTipo, Nombre, PrecioBase, Capacidad, CapacidadMax) VALUES
(1, 'Simple',      150.00, 1, 1),
(2, 'Doble',       220.00, 2, 2),
(3, 'Triple',      290.00, 3, 3),
(4, 'Matrimonial', 230.00, 2, 2),
(5, 'Suite',       450.00, 2, 4);

-- ============================================================
-- AMENIDADES
-- ============================================================
INSERT IGNORE INTO cfg_Amenidades (IdAmenidad, Nombre, Icono) VALUES
(1,  'WiFi',             'wifi'),
(2,  'TV Cable',         'tv'),
(3,  'Aire Acondicionado','air'),
(4,  'Agua Caliente',    'water'),
(5,  'Minibar',          'wine-bottle'),
(6,  'Frigobar',         'fridge'),
(7,  'Caja Fuerte',      'safe'),
(8,  'Balcon',           'balcony'),
(9,  'Vista al Mar',     'sea'),
(10, 'Jacuzzi',          'bath'),
(11, 'Cocina',           'kitchen'),
(12, 'Sala de Estar',    'sofa');

-- ============================================================
-- METODOS DE PAGO
-- ============================================================
-- Caja de recepcion. SIN al menos una caja no se puede abrir turno, sin
-- turno no se puede cobrar, y sin cobrar no se puede hacer check-out: el
-- hotel quedaba sin poder operar desde el dia de la instalacion.
INSERT IGNORE INTO caj_Cajas (IdCaja, Nombre, Activa) VALUES
(1, 'Caja Recepcion', 1);

INSERT IGNORE INTO cfg_MetodosPago (IdMetodo, Nombre) VALUES
(1, 'Efectivo PEN'),
(2, 'Efectivo USD'),
(3, 'Tarjeta Visa'),
(4, 'Tarjeta Mastercard'),
(5, 'Transferencia Bancaria'),
(6, 'Yape'),
(7, 'Plin'),
(8, 'Culqi (Online)');

-- ============================================================
-- PISOS Y HABITACIONES DEMO
-- ============================================================
INSERT IGNORE INTO hot_Pisos (IdPiso, Numero, Nombre, Orden) VALUES
(1, 1, 'Primer Piso',   1),
(2, 2, 'Segundo Piso',  2),
(3, 3, 'Tercer Piso',   3);

INSERT IGNORE INTO hot_Habitaciones (Numero, IdPiso, IdTipo, Estado, EstadoLimpieza, MaxPersonas, PosX, PosY) VALUES
('101', 1, 1, 'Disponible', 'Limpia', 1, 0, 0),
('102', 1, 2, 'Disponible', 'Limpia', 2, 1, 0),
('103', 1, 4, 'Disponible', 'Limpia', 2, 2, 0),
('104', 1, 3, 'Disponible', 'Limpia', 3, 3, 0),
('201', 2, 1, 'Disponible', 'Limpia', 1, 0, 1),
('202', 2, 2, 'Disponible', 'Limpia', 2, 1, 1),
('203', 2, 4, 'Disponible', 'Limpia', 2, 2, 1),
('204', 2, 2, 'Disponible', 'Limpia', 2, 3, 1),
('301', 3, 5, 'Disponible', 'Limpia', 2, 0, 2),
('302', 3, 5, 'Disponible', 'Limpia', 4, 1, 2);

-- ============================================================
-- TARIFAS BASE
-- ============================================================
INSERT IGNORE INTO cfg_Tarifas (IdTarifa, Nombre, IdTipo, PrecioPEN) VALUES
(1, 'Rack Simple',      1, 150.00),
(2, 'Rack Doble',       2, 220.00),
(3, 'Rack Triple',      3, 290.00),
(4, 'Rack Matrimonial', 4, 230.00),
(5, 'Rack Suite',       5, 450.00);

-- ============================================================
-- CANALES OTA
-- ============================================================
INSERT IGNORE INTO chn_Canales (IdCanal, Codigo, Nombre, Activo) VALUES
(1, 'BOOKING',  'Booking.com',   0),
(2, 'AIRBNB',   'Airbnb',        0),
(3, 'EXPEDIA',  'Expedia',       0),
(4, 'WEB',      'Motor Web',     0);

-- ============================================================
-- SERIES DE FACTURACION
-- ============================================================
INSERT IGNORE INTO fac_Series (IdSerie, TipoDoc, Serie, Correlativo) VALUES
(1, '01', 'F001', 1),  -- Facturas
(2, '03', 'B001', 1),  -- Boletas
(3, '07', 'FC01', 1),  -- Notas credito Factura
(4, '07', 'BC01', 1);  -- Notas credito Boleta

-- ============================================================
-- SERVICIOS ADICIONALES
-- ============================================================
INSERT IGNORE INTO cfg_Servicios (IdServicio, Categoria, Nombre, Descripcion, PrecioPEN, PrecioUSD, Unidad, IncluyeIGV, TiempoEstimado, Orden) VALUES
(1,  'Restaurante', 'Desayuno Americano',    'Desayuno completo',         25.00, 7.00,  'por pax', 1, 30, 1),
(2,  'Restaurante', 'Desayuno Buffet',       'Buffet libre',              35.00, 9.50,  'por pax', 1, 30, 2),
(3,  'Restaurante', 'Almuerzo Menu',         'Menu del dia',              30.00, 8.00,  'por pax', 1, 45, 3),
(4,  'Restaurante', 'Cena',                  'Cena a la carta',           45.00, 12.00, 'por pax', 1, 60, 4),
(5,  'Minibar',     'Agua Mineral 500ml',    'Agua mineral',               5.00, 1.50,  'und',     1, NULL,5),
(6,  'Minibar',     'Gaseosa 350ml',         'Gaseosa fria',               7.00, 2.00,  'und',     1, NULL,6),
(7,  'Minibar',     'Cerveza Nacional',      'Cerveza 330ml',             12.00, 3.50,  'und',     1, NULL,7),
(8,  'Lavanderia',  'Lavado y Planchado',    'Por prenda',                15.00, 4.00,  'prenda',  1, 240,8),
(9,  'Lavanderia',  'Lavado Express 3h',     'Servicio express',          25.00, 7.00,  'prenda',  1, 180,9),
(10, 'Transporte',  'Transfer Aeropuerto',   'Servicio privado',         100.00,27.00,  'viaje',   1, 60, 10),
(11, 'Transporte',  'Transfer Terminal Bus', 'Servicio privado',          80.00,21.00,  'viaje',   1, 45, 11),
(12, 'Spa',         'Masaje Relajante 60m',  'Masaje cuerpo completo',   120.00,32.00,  'sesion',  1, 60, 12),
(13, 'Spa',         'Masaje Express 30m',    'Masaje espalda y cuello',   70.00,19.00,  'sesion',  1, 30, 13),
(14, 'Otros',       'Estacionamiento',       'Por dia',                   20.00, 5.50,  'dia',     1, NULL,14),
(15, 'Otros',       'Alquiler Bicicleta',    'Por hora',                  15.00, 4.00,  'hora',    1, NULL,15);

-- ============================================================
-- CHECKLIST TEMPLATE HSK
-- ============================================================
INSERT IGNORE INTO hsk_ChecklistTemplate (Tipo, Descripcion, Orden) VALUES
('Salida',    'Retirar ropa de cama y toallas',        1),
('Salida',    'Limpiar y desinfectar bano completo',   2),
('Salida',    'Limpiar superficies y mobiliario',      3),
('Salida',    'Barrer y trapear pisos',                4),
('Salida',    'Aspirar alfombras',                     5),
('Salida',    'Revisar minibar y registrar consumos',  6),
('Salida',    'Verificar TV, AC, luces y enchufes',    7),
('Salida',    'Reponer amenidades (shampoo, jab)',      8),
('Salida',    'Colocar ropa de cama limpia',           9),
('Salida',    'Colocar toallas limpias',               10),
('Salida',    'Verificar objetos olvidados',           11),
('Estancia',  'Hacer cama',                            1),
('Estancia',  'Recoger basura',                        2),
('Estancia',  'Limpiar bano y reponer papel',          3),
('Estancia',  'Reponer amenidades',                    4),
('Estancia',  'Ordenar mobiliario',                    5),
('Llegada',   'Verificar limpieza general',            1),
('Llegada',   'Verificar ropa de cama',                2),
('Llegada',   'Verificar amenidades completas',        3),
('Llegada',   'Verificar minibar surtido',             4),
('Llegada',   'Verificar funcionamiento TV, AC',       5),
('Llegada',   'Verificar bano limpio y seco',          6);

-- ============================================================
-- PLANTILLAS DE NOTIFICACION
-- ============================================================
INSERT IGNORE INTO ntf_Plantillas (Codigo, Tipo, Contenido) VALUES
('RESERVA_CONFIRMADA', 'WhatsApp',
'Estimado/a {{Nombres}}, su reserva en {{Hotel}} ha sido *CONFIRMADA*.

📋 *Detalle:*
• Reserva: *{{Codigo}}*
• Habitacion: {{Habitacion}} ({{TipoHabitacion}})
• Check-in: *{{FechaEntrada}}* desde las 14:00h
• Check-out: *{{FechaSalida}}* hasta las 12:00h
• Noches: {{Noches}}
• Total: S/ {{Total}}

Para consultas: {{Telefono}}
¡Le esperamos!'),

('CHECKIN_BIENVENIDA', 'WhatsApp',
'¡Bienvenido/a {{Nombres}}! 🏨

Ya tiene acceso a su habitacion *{{Habitacion}}*.

📶 WiFi: {{WifiNombre}} | Clave: {{WifiClave}}
🕐 Check-out: {{FechaSalida}} hasta las 12:00h

Para servicios o asistencia, estamos en recepcion.
¡Disfrute su estancia!'),

('CHECKOUT_GRACIAS', 'WhatsApp',
'Estimado/a {{Nombres}}, gracias por hospedarse en {{Hotel}}.

⭐ Esperamos haber superado sus expectativas.

Su opinion es muy importante para nosotros. Si desea calificarnos:
👉 {{LinkResena}}

¡Hasta pronto! 🙏'),

('PAGO_RECIBIDO', 'WhatsApp',
'{{Hotel}} - Pago registrado ✅

Reserva: {{Codigo}}
Monto: S/ {{Monto}}
Metodo: {{MetodoPago}}
Saldo pendiente: S/ {{Saldo}}

Gracias por su preferencia.');

-- ============================================================
-- MOTOR WEB (desactivado por defecto)
-- ============================================================
INSERT IGNORE INTO web_ConfigMotor (IdConfig, HabilitadoWeb, MinNoches, MaxNoches, AnticipacionMin, PctAdelanto)
VALUES (1, 0, 1, 30, 1, 30.00);

-- ============================================================
-- ESTADO INICIAL SYNC
-- ============================================================
INSERT IGNORE INTO sync_EstadoConexion (IdEstado, TieneInternet) VALUES (1, 0);
