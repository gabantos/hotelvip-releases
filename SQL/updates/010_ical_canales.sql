-- ============================================================
-- 010 - Sincronizacion con Booking / Airbnb / Expedia por iCal
--
-- POR QUE iCal Y NO LA API DE BOOKING:
-- La Connectivity API de Booking.com (y la de Airbnb) solo se entrega a
-- partners certificados: hay que postular, cumplir requisitos tecnicos y
-- pasar una certificacion que toma meses. Por eso existen los channel
-- managers comerciales (SiteMinder, Cloudbeds), que ya estan certificados
-- y revenden esa conexion.
--
-- Booking, Airbnb, Expedia y VRBO SI publican un calendario iCal por
-- alojamiento, que se puede leer sin permisos especiales y es lo que usa
-- de verdad un hotel boutique. Es bidireccional:
--   IMPORTAR: se lee su .ics y entran las reservas al sistema
--   EXPORTAR: se les entrega nuestro .ics y ellos bloquean esas fechas
-- Con eso se evita la sobreventa entre canales, que es el objetivo real.
--
-- Limitacion honesta del iCal: trae fechas y (segun el canal) el nombre del
-- huesped, pero no siempre email/telefono. Los datos completos se ven en la
-- extranet del canal. Para datos completos hace falta un channel manager.
-- ============================================================

-- URL del calendario de cada canal (la copia el hotel desde su extranet)
ALTER TABLE chn_Canales
  ADD COLUMN IF NOT EXISTS IcalImportUrl  VARCHAR(500) NULL
    COMMENT 'URL .ics del canal, desde su extranet',
  ADD COLUMN IF NOT EXISTS IcalExportTok  VARCHAR(64)  NULL
    COMMENT 'Token del .ics que publicamos para ese canal',
  ADD COLUMN IF NOT EXISTS SyncCadaMin    INT          NOT NULL DEFAULT 15
    COMMENT 'Cada cuantos minutos se lee el iCal',
  ADD COLUMN IF NOT EXISTS UltimoSyncMsg  VARCHAR(300) NULL
    COMMENT 'Resultado del ultimo intento (para mostrar en pantalla)',
  ADD COLUMN IF NOT EXISTS UltimoSyncOk   TINYINT(1)   NOT NULL DEFAULT 1;

-- El UID del evento iCal identifica la reserva en el canal. Se usa para no
-- volver a crear la misma reserva en cada lectura del calendario.
ALTER TABLE chn_ReservasExternas
  ADD COLUMN IF NOT EXISTS IcalUID VARCHAR(200) NULL,
  ADD COLUMN IF NOT EXISTS Origen  ENUM('WEBHOOK','ICAL','MANUAL') NOT NULL DEFAULT 'WEBHOOK';

-- Clave para que la misma reserva del canal no entre dos veces
CREATE UNIQUE INDEX IF NOT EXISTS uq_resext_canal_uid
  ON chn_ReservasExternas (IdCanal, ExternalId);

-- NOTA: el token de los webhooks NO va en la BD, va en el .ini seccion
-- [Channel] TokenWebhook (igual que SecretKey y el token de Sync). Booking y
-- Airbnb no pueden mandar nuestro JWT, asi que esas rutas se autentican con
-- ese token propio; hoy quedaban detras del middleware de auth y por eso
-- jamas habrian podido entregar una reserva.

-- Habitacion por defecto de cada canal: el iCal no dice que habitacion es,
-- solo el alojamiento. Si el canal publica una sola habitacion, se mapea aca.
CREATE TABLE IF NOT EXISTS chn_MapeoHabitacion (
  IdCanal       INT          NOT NULL,
  ClaveExterna  VARCHAR(150) NOT NULL COMMENT 'Nombre del alojamiento/tipo en el canal',
  IdHabitacion  INT          NULL,
  IdTipoHab     INT          NULL,
  PRIMARY KEY (IdCanal, ClaveExterna),
  FOREIGN KEY (IdCanal)      REFERENCES chn_Canales(IdCanal),
  FOREIGN KEY (IdHabitacion) REFERENCES hot_Habitaciones(IdHabitacion),
  FOREIGN KEY (IdTipoHab)    REFERENCES cfg_TiposHabitacion(IdTipo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
