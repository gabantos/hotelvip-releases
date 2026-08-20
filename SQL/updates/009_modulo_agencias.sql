-- =============================================================================
-- 009_modulo_agencias.sql
-- Modulo Agencias/Agentes portado de AgenciaViajesVip (esquema agt_ limpio),
-- adaptado a hotel: tarifa por NOCHE y tipo de habitacion, y soporte de DOS
-- modelos comerciales por agencia:
--   NETO     = la agencia le debe al hotel la tarifa neta negociada x noche
--   COMISION = el hotel le devuelve a la agencia un % del total de la reserva
-- Liquidacion con guardas del original: correlativo POR agencia, anti-doble
-- liquidacion (res_Reservas.IdLiquidacionAgencia), arrastre de saldo, abonos.
-- La tarifa se CONGELA en la reserva al asignar la agencia
-- (TarifaAgenciaAplicada) para que cambios de tarifario no alteren
-- liquidaciones retroactivamente (bug conocido del sistema origen).
-- Idempotente. Reflejado en 01_Estructura.sql.
-- =============================================================================

CREATE TABLE IF NOT EXISTS agt_Agencias (
  IdAgencia       INT          AUTO_INCREMENT PRIMARY KEY,
  Nombre          VARCHAR(150) NOT NULL UNIQUE,
  RUC             VARCHAR(11),
  Contacto        VARCHAR(100),
  Telefono        VARCHAR(30),
  Email           VARCHAR(120),
  Direccion       VARCHAR(250),
  TipoLiquidacion ENUM('NETO','COMISION') NOT NULL DEFAULT 'NETO',
  ComisionPct     DECIMAL(5,2) NOT NULL DEFAULT 0,
  CreditoMaximo   DECIMAL(12,2) NOT NULL DEFAULT 0,
  Notas           TEXT,
  Activo          TINYINT(1)   NOT NULL DEFAULT 1,
  FechaCreacion   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FechaModificacion DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Tarifa neta por noche negociada por agencia x tipo de habitacion
CREATE TABLE IF NOT EXISTS agt_Tarifas (
  IdTarifa      INT          AUTO_INCREMENT PRIMARY KEY,
  IdAgencia     INT          NOT NULL,
  IdTipo        INT          NOT NULL,
  TarifaNoche   DECIMAL(10,2) NOT NULL DEFAULT 0,
  Activo        TINYINT(1)   NOT NULL DEFAULT 1,
  FechaCreacion DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_agencia_tipo (IdAgencia, IdTipo),
  FOREIGN KEY (IdAgencia) REFERENCES agt_Agencias(IdAgencia),
  FOREIGN KEY (IdTipo)    REFERENCES cfg_TiposHabitacion(IdTipo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Pagos a cuenta ANTES del cierre de liquidacion
CREATE TABLE IF NOT EXISTS agt_Adelantos (
  IdAdelanto      INT          AUTO_INCREMENT PRIMARY KEY,
  IdAgencia       INT          NOT NULL,
  Fecha           DATE         NOT NULL,
  Monto           DECIMAL(12,2) NOT NULL DEFAULT 0,
  Moneda          VARCHAR(3)   NOT NULL DEFAULT 'PEN',
  TipoCambio      DECIMAL(6,3) NOT NULL DEFAULT 1,
  MetodoPago      VARCHAR(50),
  NumeroOperacion VARCHAR(50),
  Banco           VARCHAR(50),
  Observaciones   VARCHAR(300),
  Liquidado       TINYINT(1)   NOT NULL DEFAULT 0,
  IdLiquidacion   INT          NULL,
  Anulado         TINYINT(1)   NOT NULL DEFAULT 0,
  IdUsuario       INT,
  FechaCreacion   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX ix_agencia_fecha (IdAgencia, Fecha, Liquidado, Anulado),
  FOREIGN KEY (IdAgencia) REFERENCES agt_Agencias(IdAgencia)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Cargos/abonos manuales fuera de tarifario (equivalente a ServicioLibre)
CREATE TABLE IF NOT EXISTS agt_Ajustes (
  IdAjuste      INT          AUTO_INCREMENT PRIMARY KEY,
  IdAgencia     INT          NOT NULL,
  Fecha         DATE         NOT NULL,
  Descripcion   VARCHAR(200) NOT NULL,
  Tipo          ENUM('CARGO','ABONO') NOT NULL DEFAULT 'CARGO',
  Monto         DECIMAL(12,2) NOT NULL DEFAULT 0,
  Liquidado     TINYINT(1)   NOT NULL DEFAULT 0,
  IdLiquidacion INT          NULL,
  Anulado       TINYINT(1)   NOT NULL DEFAULT 0,
  IdUsuario     INT,
  FechaCreacion DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX ix_agencia (IdAgencia, Liquidado, Anulado),
  FOREIGN KEY (IdAgencia) REFERENCES agt_Agencias(IdAgencia)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Cabecera de liquidacion (cierre de periodo)
CREATE TABLE IF NOT EXISTS agt_Liquidaciones (
  IdLiquidacion  INT          AUTO_INCREMENT PRIMARY KEY,
  IdAgencia      INT          NOT NULL,
  Numero         INT          NOT NULL,                -- correlativo POR agencia
  FechaDesde     DATE         NOT NULL,
  FechaHasta     DATE         NOT NULL,
  SaldoAnterior  DECIMAL(12,2) NOT NULL DEFAULT 0,
  TotalReservas  DECIMAL(12,2) NOT NULL DEFAULT 0,
  TotalAjustes   DECIMAL(12,2) NOT NULL DEFAULT 0,
  MontoBruto     DECIMAL(12,2) NOT NULL DEFAULT 0,
  TotalAdelantos DECIMAL(12,2) NOT NULL DEFAULT 0,
  MontoPagado    DECIMAL(12,2) NOT NULL DEFAULT 0,     -- pagado en el mismo cierre
  SaldoFinal     DECIMAL(12,2) NOT NULL DEFAULT 0,
  EstadoPago     ENUM('PENDIENTE','PARCIAL','PAGADO') NOT NULL DEFAULT 'PENDIENTE',
  Anulada        TINYINT(1)   NOT NULL DEFAULT 0,
  Observaciones  VARCHAR(500),
  IdUsuario      INT,
  FechaCreacion  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX ix_agencia_num (IdAgencia, Numero),
  FOREIGN KEY (IdAgencia) REFERENCES agt_Agencias(IdAgencia)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS agt_LiquidacionDetalle (
  IdDetalle     INT          AUTO_INCREMENT PRIMARY KEY,
  IdLiquidacion INT          NOT NULL,
  IdReserva     INT          NULL,
  Fecha         DATE,
  Concepto      VARCHAR(255),
  Noches        INT          NOT NULL DEFAULT 0,
  Importe       DECIMAL(12,2) NOT NULL DEFAULT 0,
  FOREIGN KEY (IdLiquidacion) REFERENCES agt_Liquidaciones(IdLiquidacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Pagos DESPUES del cierre, contra una liquidacion emitida
CREATE TABLE IF NOT EXISTS agt_Abonos (
  IdAbono         INT          AUTO_INCREMENT PRIMARY KEY,
  IdLiquidacion   INT          NOT NULL,
  IdAgencia       INT          NOT NULL,
  Fecha           DATE         NOT NULL,
  Monto           DECIMAL(12,2) NOT NULL DEFAULT 0,
  MetodoPago      VARCHAR(50),
  NumeroOperacion VARCHAR(50),
  Observaciones   VARCHAR(300),
  Anulado         TINYINT(1)   NOT NULL DEFAULT 0,
  IdUsuario       INT,
  FechaCreacion   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX ix_liquidacion (IdLiquidacion, Anulado),
  FOREIGN KEY (IdLiquidacion) REFERENCES agt_Liquidaciones(IdLiquidacion),
  FOREIGN KEY (IdAgencia)     REFERENCES agt_Agencias(IdAgencia)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Enlace reserva <-> agencia (tarifa congelada + sellado de liquidacion)
ALTER TABLE res_Reservas
  ADD COLUMN IF NOT EXISTS IdAgencia             INT NULL AFTER Canal,
  ADD COLUMN IF NOT EXISTS TarifaAgenciaAplicada DECIMAL(10,2) NULL AFTER IdAgencia,
  ADD COLUMN IF NOT EXISTS IdLiquidacionAgencia  INT NULL AFTER TarifaAgenciaAplicada;

ALTER TABLE res_Reservas
  ADD INDEX IF NOT EXISTS ix_res_agencia (IdAgencia, IdLiquidacionAgencia, FechaSalida);

-- Canal 'Agencia' en el ENUM (MODIFY es idempotente: define la lista final)
ALTER TABLE res_Reservas
  MODIFY COLUMN Canal ENUM('Directo','Booking','Airbnb','Expedia','Web','Telefono','Walk-in','Agencia') NOT NULL DEFAULT 'Directo';
