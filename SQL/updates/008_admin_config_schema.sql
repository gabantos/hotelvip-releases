-- =============================================================================
-- 008_admin_config_schema.sql
-- Soporte de schema para el backend de admin.html / configuracion.html
-- (endpoints implementados 13-ago-2026):
-- 1) hot_Pisos: configuracion.js gestiona Descripcion y Activo (soft delete)
-- 2) cfg_TiposHabitacion: el modal de tipos envia descripcion y amenidades (CSV)
-- 3) cfg_Hotel: parametro operativo DiasMaxReserva (tab General)
-- 4) seg_Roles: el alta de usuarios ofrece rol CAJA que el seed no tenia
-- Idempotente. Reflejado en 01_Estructura.sql y 04_DatosIniciales.sql.
-- =============================================================================

ALTER TABLE hot_Pisos
  ADD COLUMN IF NOT EXISTS Descripcion VARCHAR(200) NULL AFTER Nombre,
  ADD COLUMN IF NOT EXISTS Activo      TINYINT(1)   NOT NULL DEFAULT 1 AFTER Orden;

ALTER TABLE cfg_TiposHabitacion
  ADD COLUMN IF NOT EXISTS Descripcion VARCHAR(300) NULL AFTER Nombre,
  ADD COLUMN IF NOT EXISTS Amenidades  VARCHAR(300) NULL AFTER CapacidadMax;

ALTER TABLE cfg_Hotel
  ADD COLUMN IF NOT EXISTS DiasMaxReserva INT NOT NULL DEFAULT 365 AFTER MaxHuespedes;

INSERT IGNORE INTO seg_Roles (IdRol, Nombre, Descripcion) VALUES
(5, 'Caja', 'Solo caja y pagos');
