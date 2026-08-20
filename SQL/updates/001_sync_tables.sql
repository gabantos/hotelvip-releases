-- =============================================================================
-- 001_sync_tables.sql
-- Patron sync cloud->local (estilo RestaurantVip / Agencia). Tablas LOCALES que
-- usa el worker TSyncWorker de USync.pas para bajar las reservas web del VPS.
--
-- Spec: erp.sistemasvip.com/manuales/skills-ia/sync-cloud-local
-- Idempotente: se puede correr varias veces sin romper nada.
-- =============================================================================

-- Cursor: ultimo Id de eventos_out (cloud) que el local ya proceso
CREATE TABLE IF NOT EXISTS sync_cursor (
  Nombre VARCHAR(50) NOT NULL PRIMARY KEY,
  Valor  BIGINT      NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

INSERT IGNORE INTO sync_cursor (Nombre, Valor) VALUES ('eventos_out_last_id', 0);

-- Estado del sync para mostrar en el tray (color + mensaje + timestamps)
CREATE TABLE IF NOT EXISTS sync_estado (
  Id                INT          NOT NULL PRIMARY KEY DEFAULT 1,
  Color             VARCHAR(10)  DEFAULT 'GRIS',
  Mensaje           VARCHAR(255) DEFAULT 'Sin sincronizar',
  UltimoSyncIntento DATETIME     NULL,
  UltimoSyncOK      DATETIME     NULL,
  UltimoError       VARCHAR(500) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

INSERT IGNORE INTO sync_estado (Id) VALUES (1);

-- Idempotencia: que reservas externas del cloud ya se bajaron al local.
-- Evita duplicar filas en chn_ReservasExternas si el cursor se reinicia o un
-- evento llega dos veces. IdResExtCloud = IdResExt en la BD del VPS.
CREATE TABLE IF NOT EXISTS sync_reservas_aplicadas (
  IdResExtCloud INT      NOT NULL PRIMARY KEY,
  IdResExtLocal INT      NOT NULL,
  FechaAplicado DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- -----------------------------------------------------------------------------
-- FIX: el ENUM de chn_ReservasExternas.Estado en 01_Estructura.sql quedo como
-- ('Recibida','Procesada','Error','Cancelada') pero TODO el codigo (UChannel*,
-- channel.html, el badge del sidebar) usa NUEVA/PROCESADA/CANCELADA/ERROR.
-- Se alinea el ENUM al codigo.
--
-- NO se puede usar un ENUM superset (viejos+nuevos): con collation
-- case-insensitive MariaDB ve 'PROCESADA' y 'Procesada' como duplicados y
-- falla (ERROR 1291). Por eso la transicion pasa por VARCHAR:
--   1) Estado -> VARCHAR  2) remapear valores viejos->nuevos  3) ENUM final
-- Idempotente: re-correrlo deja todo en el ENUM final sin perder filas.
-- -----------------------------------------------------------------------------
ALTER TABLE chn_ReservasExternas
  MODIFY COLUMN Estado VARCHAR(20) NOT NULL DEFAULT 'NUEVA';

UPDATE chn_ReservasExternas SET Estado='NUEVA'     WHERE Estado IN ('Recibida','recibida');
UPDATE chn_ReservasExternas SET Estado='PROCESADA' WHERE Estado IN ('Procesada','procesada');
UPDATE chn_ReservasExternas SET Estado='CANCELADA' WHERE Estado IN ('Cancelada','cancelada');
UPDATE chn_ReservasExternas SET Estado='ERROR'     WHERE Estado IN ('Error','error','');

ALTER TABLE chn_ReservasExternas
  MODIFY COLUMN Estado
  ENUM('NUEVA','PROCESADA','CANCELADA','ERROR')
  NOT NULL DEFAULT 'NUEVA';
