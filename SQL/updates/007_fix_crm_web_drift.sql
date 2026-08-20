-- =============================================================================
-- 007_fix_crm_web_drift.sql
-- Dos residuos de drift detectados en auditoria 13-ago-2026:
-- 1) crm_Preferencias: UHuespedController (GET /huespedes/:id) la consulta
--    (SELECT Categoria, Descripcion FROM crm_Preferencias WHERE IdHuesped=:id
--    AND Activo=1) pero ningun .sql la creaba -> HTTP 500 en tenant nuevo.
-- 2) web_ReservasOnline: DoRecibirReservaVPS (POST /sync/webhook/reserva)
--    inserta Noches, TelefonoCliente, MontoTotal, MetodoPagoOnline,
--    ReferenciaOnline y NotasCliente, columnas que el CREATE TABLE original
--    no tenia -> "Unknown column" al recibir reservas del VPS.
-- Idempotente. Reflejado tambien en 01_Estructura.sql.
-- =============================================================================

CREATE TABLE IF NOT EXISTS crm_Preferencias (
  IdPreferencia INT          AUTO_INCREMENT PRIMARY KEY,
  IdHuesped     INT          NOT NULL,
  Categoria     VARCHAR(50)  NOT NULL,
  Descripcion   VARCHAR(200) NOT NULL,
  Activo        TINYINT(1)   NOT NULL DEFAULT 1,
  FechaCreacion DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (IdHuesped) REFERENCES hsp_Huespedes(IdHuesped)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

ALTER TABLE web_ReservasOnline
  ADD COLUMN IF NOT EXISTS Noches           INT           NOT NULL DEFAULT 1 AFTER FechaSalida,
  ADD COLUMN IF NOT EXISTS TelefonoCliente  VARCHAR(30)   NULL AFTER EmailCliente,
  ADD COLUMN IF NOT EXISTS MontoTotal       DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER IdHabitacion,
  ADD COLUMN IF NOT EXISTS MetodoPagoOnline VARCHAR(30)   NULL AFTER AdelantoOnline,
  ADD COLUMN IF NOT EXISTS ReferenciaOnline VARCHAR(100)  NULL AFTER MetodoPagoOnline,
  ADD COLUMN IF NOT EXISTS NotasCliente     TEXT          NULL AFTER ReferenciaOnline;
