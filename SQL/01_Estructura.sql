-- ==============================================================
-- HOTELVIP SaaS - Estructura de Base de Datos v1.0.0
-- SistemasVIP - Cusco, Peru
-- Ejecutar contra el schema del tenant (ej: hotel_001)
-- ==============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- SEGURIDAD (seg_)
-- ============================================================

CREATE TABLE IF NOT EXISTS seg_Roles (
  IdRol       INT          AUTO_INCREMENT PRIMARY KEY,
  Nombre      VARCHAR(50)  NOT NULL,
  Descripcion VARCHAR(200),
  Activo      TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS seg_Usuarios (
  IdUsuario      INT          AUTO_INCREMENT PRIMARY KEY,
  Usuario        VARCHAR(50)  NOT NULL UNIQUE,
  Contrasena     VARCHAR(255) NOT NULL,
  Nombres        VARCHAR(100) NOT NULL,
  Apellidos      VARCHAR(100) NOT NULL DEFAULT '',
  Email          VARCHAR(100),
  Telefono       VARCHAR(20),
  FotoBase64     LONGTEXT,
  IdRol          INT          NOT NULL,
  Activo         TINYINT(1)   NOT NULL DEFAULT 1,
  FechaCreacion  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UltimoLogin    DATETIME,
  UltimaSesion   DATETIME,
  NombreCompleto VARCHAR(200) AS (CONCAT(Nombres,' ',Apellidos)) VIRTUAL,
  FOREIGN KEY (IdRol) REFERENCES seg_Roles(IdRol)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Sesiones (auth bearer). El codigo (UAuthController) la usa; sin esta tabla
-- y las columnas de arriba un tenant nuevo no puede loguear.
CREATE TABLE IF NOT EXISTS seg_Sesiones (
  IdSesion      INT          AUTO_INCREMENT PRIMARY KEY,
  IdUsuario     INT          NOT NULL,
  Token         TEXT         NOT NULL,
  IP            VARCHAR(45),
  FechaCreacion DATETIME     DEFAULT CURRENT_TIMESTAMP,
  FechaExpira   DATETIME,
  Activo        TINYINT(1)   DEFAULT 1,
  KEY (IdUsuario),
  FOREIGN KEY (IdUsuario) REFERENCES seg_Usuarios(IdUsuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ============================================================
-- CONFIGURACION HOTEL (cfg_)
-- ============================================================

CREATE TABLE IF NOT EXISTS cfg_Hotel (
  IdHotel            INT          AUTO_INCREMENT PRIMARY KEY,
  NombreComercial    VARCHAR(100) NOT NULL DEFAULT 'HOTEL VIP',
  RUC                VARCHAR(11),
  RazonSocial        VARCHAR(200),
  Direccion          VARCHAR(300),
  Telefono           VARCHAR(20),
  Email              VARCHAR(100),
  Website            VARCHAR(200),
  LogoUrl            VARCHAR(300),
  ColorPrimario      VARCHAR(7)   DEFAULT '#1a3a5c',
  MonedaDefecto      VARCHAR(3)   DEFAULT 'PEN',
  HoraCheckin        TIME         DEFAULT '14:00:00',
  HoraCheckout       TIME         DEFAULT '12:00:00',
  IGV_General        DECIMAL(5,2) DEFAULT 18.00,
  IGV_Nacional       DECIMAL(5,2) DEFAULT 18.00,
  IGV_Extranjero     DECIMAL(5,2) DEFAULT 0.00,
  MaxHuespedes       INT          DEFAULT 100,
  DiasMaxReserva     INT          NOT NULL DEFAULT 365,
  -- Pro7 (facturacion electronica)
  Pro7ApiUrl         VARCHAR(200),
  Pro7ApiToken       VARCHAR(500),
  Pro7TenantId       VARCHAR(50),
  -- WhatsApp (Evolution API)
  EvolutionApiUrl    VARCHAR(200),
  EvolutionApiKey    VARCHAR(200),
  -- Telegram
  TelegramChatId     VARCHAR(50),
  -- Culqi (pagos online)
  CulqiPublicKey     VARCHAR(100),
  -- TTLock (cerraduras inteligentes)
  TTLockClientId     VARCHAR(100),
  TTLockClientSecret VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS cfg_TiposHabitacion (
  IdTipo      INT          AUTO_INCREMENT PRIMARY KEY,
  Nombre      VARCHAR(100) NOT NULL,
  Descripcion VARCHAR(300),
  PrecioBase  DECIMAL(10,2) NOT NULL DEFAULT 0,
  Capacidad   INT          NOT NULL DEFAULT 2,
  CapacidadMax INT         NOT NULL DEFAULT 4,
  Amenidades  VARCHAR(300),
  Activo      TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS cfg_Amenidades (
  IdAmenidad  INT          AUTO_INCREMENT PRIMARY KEY,
  Nombre      VARCHAR(100) NOT NULL,
  Icono       VARCHAR(50),
  Activo      TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS cfg_MetodosPago (
  IdMetodo    INT          AUTO_INCREMENT PRIMARY KEY,
  Nombre      VARCHAR(50)  NOT NULL,
  Activo      TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS cfg_Monedas (
  IdMoneda    INT          AUTO_INCREMENT PRIMARY KEY,
  Codigo      VARCHAR(3)   NOT NULL UNIQUE,
  Nombre      VARCHAR(50)  NOT NULL,
  Simbolo     VARCHAR(5),
  EsBase      TINYINT(1)   NOT NULL DEFAULT 0,   -- moneda base del hotel (1 = PEN)
  Activo      TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Modelo origen->destino: cotizacion de IdMonedaOrigen expresada en IdMonedaDestino
-- (destino = moneda base EsBase=1). El upsert del codigo usa (Origen, Destino, Fecha).
CREATE TABLE IF NOT EXISTS cfg_TipoCambio (
  IdMonedaOrigen  INT          NOT NULL,
  IdMonedaDestino INT          NOT NULL,
  Tasa            DECIMAL(10,4) NOT NULL DEFAULT 1,
  Fecha           DATE         NOT NULL DEFAULT (CURDATE()),
  Fuente          VARCHAR(20)  NULL DEFAULT 'MANUAL',
  UNIQUE KEY uk_tc_origen_destino_fecha (IdMonedaOrigen, IdMonedaDestino, Fecha),
  FOREIGN KEY (IdMonedaOrigen)  REFERENCES cfg_Monedas(IdMoneda),
  FOREIGN KEY (IdMonedaDestino) REFERENCES cfg_Monedas(IdMoneda)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS cfg_Tarifas (
  IdTarifa    INT          AUTO_INCREMENT PRIMARY KEY,
  Nombre      VARCHAR(100) NOT NULL,
  IdTipo      INT,
  PrecioPEN   DECIMAL(10,2) NOT NULL DEFAULT 0,
  Activo      TINYINT(1)   NOT NULL DEFAULT 1,
  FOREIGN KEY (IdTipo) REFERENCES cfg_TiposHabitacion(IdTipo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS cfg_Temporadas (
  IdTemporada INT          AUTO_INCREMENT PRIMARY KEY,
  Nombre      VARCHAR(100) NOT NULL,
  FechaInicio DATE         NOT NULL,
  FechaFin    DATE         NOT NULL,
  Multiplicador DECIMAL(4,2) NOT NULL DEFAULT 1.00,
  Activo      TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS cfg_Servicios (
  IdServicio        INT          AUTO_INCREMENT PRIMARY KEY,
  Categoria         VARCHAR(50)  NOT NULL,
  Nombre            VARCHAR(100) NOT NULL,
  Descripcion       VARCHAR(300),
  PrecioPEN         DECIMAL(10,2) NOT NULL DEFAULT 0,
  PrecioUSD         DECIMAL(10,2) NOT NULL DEFAULT 0,
  Unidad            VARCHAR(20)  DEFAULT 'und',
  IncluyeIGV        TINYINT(1)   NOT NULL DEFAULT 1,
  TiempoEstimado    INT,
  DisponibleDesde   TIME,
  DisponibleHasta   TIME,
  Orden             INT          DEFAULT 0,
  Activo            TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ============================================================
-- HOTEL - HABITACIONES (hot_)
-- ============================================================

CREATE TABLE IF NOT EXISTS hot_Pisos (
  IdPiso      INT          AUTO_INCREMENT PRIMARY KEY,
  Numero      INT          NOT NULL,
  Nombre      VARCHAR(50),
  Descripcion VARCHAR(200),
  Orden       INT          DEFAULT 0,
  Activo      TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS hot_Habitaciones (
  IdHabitacion    INT          AUTO_INCREMENT PRIMARY KEY,
  Numero          VARCHAR(10)  NOT NULL UNIQUE,
  IdPiso          INT,
  IdTipo          INT,
  Estado          ENUM('Disponible','Ocupada','Mantenimiento','Bloqueada') NOT NULL DEFAULT 'Disponible',
  EstadoLimpieza  ENUM('Limpia','Sucia','EnLimpieza','Inspeccion') NOT NULL DEFAULT 'Limpia',
  FechaEstado     DATETIME,
  IdUsuarioEstado INT,
  Observaciones   TEXT,
  PosX            INT          DEFAULT 0,
  PosY            INT          DEFAULT 0,
  MaxPersonas     INT          DEFAULT 2,
  Activa          TINYINT(1)   NOT NULL DEFAULT 1,
  FOREIGN KEY (IdPiso) REFERENCES hot_Pisos(IdPiso),
  FOREIGN KEY (IdTipo) REFERENCES cfg_TiposHabitacion(IdTipo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS hot_HabitacionAmenidades (
  IdHabitacion  INT NOT NULL,
  IdAmenidad    INT NOT NULL,
  PRIMARY KEY (IdHabitacion, IdAmenidad),
  FOREIGN KEY (IdHabitacion) REFERENCES hot_Habitaciones(IdHabitacion) ON DELETE CASCADE,
  FOREIGN KEY (IdAmenidad)   REFERENCES cfg_Amenidades(IdAmenidad)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS hot_HistorialEstados (
  IdHistorial     INT          AUTO_INCREMENT PRIMARY KEY,
  IdHabitacion    INT          NOT NULL,
  EstadoAnterior  VARCHAR(30),
  EstadoNuevo     VARCHAR(30),
  IdUsuario       INT,
  Observaciones   TEXT,
  Fecha           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (IdHabitacion) REFERENCES hot_Habitaciones(IdHabitacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ============================================================
-- HUESPEDES (hsp_)
-- ============================================================

CREATE TABLE IF NOT EXISTS hsp_TiposDocumento (
  IdTipoDoc   INT          AUTO_INCREMENT PRIMARY KEY,
  Codigo      VARCHAR(10)  NOT NULL,
  Nombre      VARCHAR(50)  NOT NULL,
  CodigoSUNAT VARCHAR(2),
  Activo      TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS hsp_Huespedes (
  IdHuesped         INT          AUTO_INCREMENT PRIMARY KEY,
  IdTipoDoc         INT,
  NumeroDoc         VARCHAR(20),
  Nombres           VARCHAR(100) NOT NULL,
  Apellidos         VARCHAR(100),
  Email             VARCHAR(100),
  Telefono          VARCHAR(20),
  WhatsApp          VARCHAR(20),
  Pais              VARCHAR(50)  DEFAULT 'PE',
  Direccion         VARCHAR(300),
  RazonSocial       VARCHAR(200),
  TipoIGV           ENUM('General','Nacional','Extranjero','Exonerado') DEFAULT 'General',
  CategoriaFidelidad ENUM('Bronce','Plata','Oro','Platino') DEFAULT 'Bronce',
  PuntosAcumulados  INT          DEFAULT 0,
  Activo            TINYINT(1)   NOT NULL DEFAULT 1,
  FechaCreacion     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (IdTipoDoc) REFERENCES hsp_TiposDocumento(IdTipoDoc)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE INDEX idx_hsp_doc ON hsp_Huespedes(IdTipoDoc, NumeroDoc);
CREATE INDEX idx_hsp_email ON hsp_Huespedes(Email);

CREATE TABLE IF NOT EXISTS crm_HistorialEstancias (
  IdHistorial   INT          AUTO_INCREMENT PRIMARY KEY,
  IdHuesped     INT          NOT NULL,
  IdReserva     INT,
  FechaEntrada  DATE         NOT NULL,
  FechaSalida   DATE,
  Noches        INT          DEFAULT 0,
  TotalPagado   DECIMAL(10,2) DEFAULT 0,
  FOREIGN KEY (IdHuesped) REFERENCES hsp_Huespedes(IdHuesped)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS crm_Preferencias (
  IdPreferencia INT          AUTO_INCREMENT PRIMARY KEY,
  IdHuesped     INT          NOT NULL,
  Categoria     VARCHAR(50)  NOT NULL,
  Descripcion   VARCHAR(200) NOT NULL,
  Activo        TINYINT(1)   NOT NULL DEFAULT 1,
  FechaCreacion DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (IdHuesped) REFERENCES hsp_Huespedes(IdHuesped)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ============================================================
-- RESERVAS (res_)
-- ============================================================

CREATE TABLE IF NOT EXISTS res_Reservas (
  IdReserva         INT          AUTO_INCREMENT PRIMARY KEY,
  Codigo            VARCHAR(20)  NOT NULL UNIQUE,
  IdHabitacion      INT          NOT NULL,
  IdHuespedPrincipal INT         NOT NULL,
  FechaEntrada      DATE         NOT NULL,
  FechaSalida       DATE         NOT NULL,
  Noches            INT          NOT NULL DEFAULT 1,
  NumAdultos        INT          NOT NULL DEFAULT 1,
  NumNinos          INT          NOT NULL DEFAULT 0,
  Estado            ENUM('Pendiente','Confirmada','CheckIn','CheckOut','Cancelada','NoShow') NOT NULL DEFAULT 'Pendiente',
  Canal             ENUM('Directo','Booking','Airbnb','Expedia','Web','Telefono','Walk-in','Agencia') NOT NULL DEFAULT 'Directo',
  IdAgencia             INT NULL,
  TarifaAgenciaAplicada DECIMAL(10,2) NULL,
  IdLiquidacionAgencia  INT NULL,
  IdTarifa          INT,
  PrecioNoche       DECIMAL(10,2) NOT NULL DEFAULT 0,
  Subtotal          DECIMAL(10,2) NOT NULL DEFAULT 0,
  DescuentoPct      DECIMAL(5,2) DEFAULT 0,
  DescuentoMonto    DECIMAL(10,2) DEFAULT 0,
  TotalServicios    DECIMAL(10,2) DEFAULT 0,
  Total             DECIMAL(10,2) NOT NULL DEFAULT 0,
  TotalPagado       DECIMAL(10,2) DEFAULT 0,
  Saldo             DECIMAL(10,2) DEFAULT 0,
  TipoIGV           ENUM('General','Nacional','Extranjero','Exonerado') DEFAULT 'General',
  MotivoViaje       VARCHAR(100),
  NotasCliente      TEXT,
  NotasInternas     TEXT,
  AdelantoOnline    DECIMAL(10,2) DEFAULT 0,
  CodigoCerradura   VARCHAR(50),
  IdUsuarioCreacion INT,
  FechaReserva      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FechaCheckin      DATETIME,
  IdUsuarioCheckin  INT,
  FechaCheckout     DATETIME,
  IdUsuarioCheckout INT,
  FOREIGN KEY (IdHabitacion)      REFERENCES hot_Habitaciones(IdHabitacion),
  FOREIGN KEY (IdHuespedPrincipal) REFERENCES hsp_Huespedes(IdHuesped),
  FOREIGN KEY (IdTarifa)          REFERENCES cfg_Tarifas(IdTarifa)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE INDEX idx_res_fechas ON res_Reservas(FechaEntrada, FechaSalida);
CREATE INDEX idx_res_estado ON res_Reservas(Estado);

CREATE TABLE IF NOT EXISTS res_HuespedesReserva (
  IdReserva   INT          NOT NULL,
  IdHuesped   INT          NOT NULL,
  EsPrincipal TINYINT(1)   NOT NULL DEFAULT 0,
  PRIMARY KEY (IdReserva, IdHuesped),
  FOREIGN KEY (IdReserva) REFERENCES res_Reservas(IdReserva) ON DELETE CASCADE,
  FOREIGN KEY (IdHuesped) REFERENCES hsp_Huespedes(IdHuesped)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS res_ServiciosReserva (
  IdDetalle     INT          AUTO_INCREMENT PRIMARY KEY,
  IdReserva     INT          NOT NULL,
  IdServicio    INT          NOT NULL,
  Cantidad      INT          NOT NULL DEFAULT 1,
  PrecioUnitario DECIMAL(10,2) NOT NULL DEFAULT 0,
  Subtotal      DECIMAL(10,2) NOT NULL DEFAULT 0,
  Estado        ENUM('Pendiente','Entregado','Cancelado') NOT NULL DEFAULT 'Pendiente',
  Fecha         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (IdReserva)  REFERENCES res_Reservas(IdReserva) ON DELETE CASCADE,
  FOREIGN KEY (IdServicio) REFERENCES cfg_Servicios(IdServicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ============================================================
-- CAJA (caj_)
-- ============================================================

CREATE TABLE IF NOT EXISTS caj_Cajas (
  IdCaja      INT          AUTO_INCREMENT PRIMARY KEY,
  Nombre      VARCHAR(50)  NOT NULL,
  Activa      TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS caj_TurnoCaja (
  IdTurno        INT          AUTO_INCREMENT PRIMARY KEY,
  IdCaja         INT          NOT NULL,
  IdUsuario      INT          NOT NULL,
  SaldoInicial   DECIMAL(10,2) NOT NULL DEFAULT 0,
  Estado         ENUM('Abierto','Cerrado') NOT NULL DEFAULT 'Abierto',
  FechaApertura  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FechaCierre    DATETIME,
  SaldoFinalReal DECIMAL(10,2),
  SaldoFinalSist DECIMAL(10,2),
  Diferencia     DECIMAL(10,2),
  Observaciones  TEXT,
  FOREIGN KEY (IdCaja) REFERENCES caj_Cajas(IdCaja)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS caj_Pagos (
  IdPago          INT          AUTO_INCREMENT PRIMARY KEY,
  IdTurno         INT          NOT NULL,
  IdReserva       INT,
  IdMetodoPago    INT          NOT NULL,
  TipoPago        ENUM('Ingreso','Egreso','Devolucion') NOT NULL DEFAULT 'Ingreso',
  MonedaPago      VARCHAR(3)   NOT NULL DEFAULT 'PEN',
  MontoPago       DECIMAL(10,2) NOT NULL DEFAULT 0,
  TipoCambio      DECIMAL(10,4) DEFAULT 1,
  MontoBase       DECIMAL(10,2),
  Referencia      VARCHAR(100),
  Anulado         TINYINT(1)   NOT NULL DEFAULT 0,
  MotivoAnulacion TEXT,
  IdUsuario       INT,
  Fecha           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (IdTurno)      REFERENCES caj_TurnoCaja(IdTurno),
  FOREIGN KEY (IdReserva)    REFERENCES res_Reservas(IdReserva),
  FOREIGN KEY (IdMetodoPago) REFERENCES cfg_MetodosPago(IdMetodo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS caj_MovimientosCaja (
  IdMovimiento  INT          AUTO_INCREMENT PRIMARY KEY,
  IdTurno       INT          NOT NULL,
  Tipo          ENUM('Ingreso','Egreso') NOT NULL,
  Concepto      VARCHAR(200) NOT NULL,
  Monto         DECIMAL(10,2) NOT NULL DEFAULT 0,
  Moneda        VARCHAR(3)   DEFAULT 'PEN',
  IdUsuario     INT,
  Fecha         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (IdTurno) REFERENCES caj_TurnoCaja(IdTurno)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ============================================================
-- HOUSEKEEPING (hsk_)
-- ============================================================

CREATE TABLE IF NOT EXISTS hsk_TareasLimpieza (
  IdTarea         INT          AUTO_INCREMENT PRIMARY KEY,
  IdHabitacion    INT          NOT NULL,
  IdReserva       INT,
  Tipo            ENUM('Salida','Estancia','Llegada','Mantenimiento','Inspeccion') NOT NULL DEFAULT 'Estancia',
  Prioridad       ENUM('Normal','Alta','Urgente') NOT NULL DEFAULT 'Normal',
  Estado          ENUM('Pendiente','Asignada','EnProceso','Completada','Verificada','Cancelada') NOT NULL DEFAULT 'Pendiente',
  Observaciones   TEXT,
  IdAsignado      INT,
  IdSupervisor    INT,
  NotasSupervisor TEXT,
  FechaCreacion   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FechaAsignacion DATETIME,
  FechaInicio     DATETIME,
  FechaFin        DATETIME,
  FechaVerif      DATETIME,
  FOREIGN KEY (IdHabitacion) REFERENCES hot_Habitaciones(IdHabitacion),
  FOREIGN KEY (IdReserva)    REFERENCES res_Reservas(IdReserva)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS hsk_ChecklistTemplate (
  IdTemplate    INT          AUTO_INCREMENT PRIMARY KEY,
  Tipo          VARCHAR(30)  NOT NULL,
  Descripcion   VARCHAR(200) NOT NULL,
  Orden         INT          DEFAULT 0,
  Activo        TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS hsk_ChecklistTarea (
  IdCheckItem   INT          AUTO_INCREMENT PRIMARY KEY,
  IdTarea       INT          NOT NULL,
  Descripcion   VARCHAR(200) NOT NULL,
  Completado    TINYINT(1)   NOT NULL DEFAULT 0,
  FechaCheck    DATETIME,
  FOREIGN KEY (IdTarea) REFERENCES hsk_TareasLimpieza(IdTarea) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS hsk_Insumos (
  IdInsumo      INT          AUTO_INCREMENT PRIMARY KEY,
  Nombre        VARCHAR(100) NOT NULL,
  Unidad        VARCHAR(20)  DEFAULT 'und',
  StockActual   DECIMAL(10,2) DEFAULT 0,
  StockMinimo   DECIMAL(10,2) DEFAULT 0,
  Activo        TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS hsk_ObjetosEncontrados (
  IdObjeto      INT          AUTO_INCREMENT PRIMARY KEY,
  IdTarea       INT,
  IdHabitacion  INT,
  Descripcion   VARCHAR(300) NOT NULL,
  Ubicacion     VARCHAR(200),
  Estado        ENUM('Encontrado','Reclamado','Donado','Descartado') NOT NULL DEFAULT 'Encontrado',
  Notas         TEXT,
  FechaHallazgo DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (IdTarea)      REFERENCES hsk_TareasLimpieza(IdTarea),
  FOREIGN KEY (IdHabitacion) REFERENCES hot_Habitaciones(IdHabitacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ============================================================
-- SERVICIOS ADICIONALES (svc_)
-- ============================================================

CREATE TABLE IF NOT EXISTS svc_Pedidos (
  IdPedido           INT          AUTO_INCREMENT PRIMARY KEY,
  IdReserva          INT,
  IdHabitacion       INT,
  Canal              ENUM('Recepcion','App','QR','Telefono') NOT NULL DEFAULT 'Recepcion',
  Estado             ENUM('Pendiente','Confirmado','EnPreparacion','EnCamino','Entregado','Cancelado') NOT NULL DEFAULT 'Pendiente',
  Observaciones      TEXT,
  TotalPedido        DECIMAL(10,2) DEFAULT 0,
  Cobrado            TINYINT(1)   NOT NULL DEFAULT 0,
  FechaEstimada      DATETIME,
  FechaPedido        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FechaEntrega       DATETIME,
  IdUsuarioCreacion  INT,
  IdUsuarioEntrega   INT,
  FOREIGN KEY (IdReserva)    REFERENCES res_Reservas(IdReserva),
  FOREIGN KEY (IdHabitacion) REFERENCES hot_Habitaciones(IdHabitacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS svc_DetallePedido (
  IdDetalle      INT          AUTO_INCREMENT PRIMARY KEY,
  IdPedido       INT          NOT NULL,
  IdServicio     INT          NOT NULL,
  Cantidad       INT          NOT NULL DEFAULT 1,
  PrecioUnitario DECIMAL(10,2) NOT NULL DEFAULT 0,
  Notas          TEXT,
  FOREIGN KEY (IdPedido)   REFERENCES svc_Pedidos(IdPedido) ON DELETE CASCADE,
  FOREIGN KEY (IdServicio) REFERENCES cfg_Servicios(IdServicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS svc_MinibarStock (
  IdHabitacion  INT          NOT NULL,
  IdServicio    INT          NOT NULL,
  Cantidad      INT          NOT NULL DEFAULT 0,
  CantidadMin   INT          NOT NULL DEFAULT 0,
  UltimaRevision DATETIME,
  PRIMARY KEY (IdHabitacion, IdServicio),
  FOREIGN KEY (IdHabitacion) REFERENCES hot_Habitaciones(IdHabitacion),
  FOREIGN KEY (IdServicio)   REFERENCES cfg_Servicios(IdServicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS svc_MinibarConsumo (
  IdConsumo     INT          AUTO_INCREMENT PRIMARY KEY,
  IdReserva     INT,
  IdHabitacion  INT,
  IdServicio    INT          NOT NULL,
  Cantidad      INT          NOT NULL DEFAULT 1,
  PrecioUnit    DECIMAL(10,2) NOT NULL DEFAULT 0,
  Subtotal      DECIMAL(10,2) NOT NULL DEFAULT 0,
  Cobrado       TINYINT(1)   NOT NULL DEFAULT 0,
  IdUsuario     INT,
  Fecha         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (IdReserva)    REFERENCES res_Reservas(IdReserva),
  FOREIGN KEY (IdHabitacion) REFERENCES hot_Habitaciones(IdHabitacion),
  FOREIGN KEY (IdServicio)   REFERENCES cfg_Servicios(IdServicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ============================================================
-- FACTURACION ELECTRONICA (fac_)
-- ============================================================

CREATE TABLE IF NOT EXISTS fac_Series (
  IdSerie     INT          AUTO_INCREMENT PRIMARY KEY,
  TipoDoc     ENUM('01','03','07') NOT NULL,
  Serie       VARCHAR(4)   NOT NULL,
  Correlativo INT          NOT NULL DEFAULT 1,
  Activo      TINYINT(1)   NOT NULL DEFAULT 1,
  UNIQUE KEY uk_serie (TipoDoc, Serie)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS fac_Comprobantes (
  IdComprobante    INT          AUTO_INCREMENT PRIMARY KEY,
  IdReserva        INT,
  IdSerie          INT          NOT NULL,
  TipoDoc          ENUM('01','03','07') NOT NULL,
  Serie            VARCHAR(4)   NOT NULL,
  Correlativo      INT          NOT NULL,
  NumeroCompleto   VARCHAR(20)  NOT NULL,
  FechaEmision     DATE         NOT NULL,
  -- Datos cliente
  IdCliente        INT,
  TipoDocCliente   VARCHAR(2),
  NumDocCliente    VARCHAR(15),
  RazonSocial      VARCHAR(200),
  -- Importes
  SubtotalGravado  DECIMAL(10,2) DEFAULT 0,
  SubtotalExonerado DECIMAL(10,2) DEFAULT 0,
  IGV              DECIMAL(10,2) DEFAULT 0,
  Total            DECIMAL(10,2) NOT NULL DEFAULT 0,
  -- Estado SUNAT
  Estado           ENUM('Borrador','Enviado','Aceptado','Rechazado','Anulado') NOT NULL DEFAULT 'Borrador',
  Pro7Id           VARCHAR(50),
  FechaEnvio       DATETIME,
  CDREstado        VARCHAR(10),
  CDRDesc          TEXT,
  -- Nota de credito
  EsNotaCredito    TINYINT(1)   NOT NULL DEFAULT 0,
  ComprobRef       VARCHAR(20),
  MotivoNota       TEXT,
  IdUsuario        INT,
  FechaCreacion    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (IdReserva) REFERENCES res_Reservas(IdReserva),
  FOREIGN KEY (IdSerie)   REFERENCES fac_Series(IdSerie)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS fac_DetalleComprobante (
  IdDetalle      INT          AUTO_INCREMENT PRIMARY KEY,
  IdComprobante  INT          NOT NULL,
  Descripcion    VARCHAR(300) NOT NULL,
  Unidad         VARCHAR(10)  DEFAULT 'ZZ',
  Cantidad       DECIMAL(10,3) NOT NULL DEFAULT 1,
  PrecioUnitario DECIMAL(10,2) NOT NULL DEFAULT 0,
  TipoIGV        VARCHAR(2)   DEFAULT '10',
  PorcentajeIGV  DECIMAL(5,2) DEFAULT 18,
  IGVMonto       DECIMAL(10,2) DEFAULT 0,
  Subtotal       DECIMAL(10,2) NOT NULL DEFAULT 0,
  FOREIGN KEY (IdComprobante) REFERENCES fac_Comprobantes(IdComprobante) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ============================================================
-- SINCRONIZACION VPS (sync_)
-- ============================================================

CREATE TABLE IF NOT EXISTS sync_EstadoConexion (
  IdEstado      INT          AUTO_INCREMENT PRIMARY KEY,
  TieneInternet TINYINT(1)   NOT NULL DEFAULT 0,
  UltimaSync    DATETIME,
  FechaUpdate   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS sync_ColaSyncSalida (
  IdSync        INT          AUTO_INCREMENT PRIMARY KEY,
  Entidad       VARCHAR(50)  NOT NULL,
  IdEntidad     INT          NOT NULL,
  Accion        ENUM('INSERT','UPDATE','DELETE') NOT NULL,
  Payload       JSON,
  Estado        ENUM('Pendiente','Enviado','Error') NOT NULL DEFAULT 'Pendiente',
  Intentos      INT          DEFAULT 0,
  ErrorMsg      TEXT,
  FechaCreacion DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FechaEnvio    DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS sync_ColaSyncEntrada (
  IdSync        INT          AUTO_INCREMENT PRIMARY KEY,
  Origen        VARCHAR(100),
  Payload       JSON,
  Estado        ENUM('Pendiente','Procesado','Error') NOT NULL DEFAULT 'Pendiente',
  ErrorMsg      TEXT,
  FechaCreacion DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FechaProcesado DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ============================================================
-- CANALES OTA (chn_)
-- ============================================================

CREATE TABLE IF NOT EXISTS chn_Canales (
  IdCanal     INT          AUTO_INCREMENT PRIMARY KEY,
  Codigo      VARCHAR(20)  NOT NULL UNIQUE,
  Nombre      VARCHAR(100) NOT NULL,
  Activo      TINYINT(1)   NOT NULL DEFAULT 1,
  UltimaSync  DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS chn_Tarifas (
  IdCanal       INT          NOT NULL,
  IdTipoHab     INT          NOT NULL,
  Fecha         DATE         NOT NULL,
  Precio        DECIMAL(10,2) NOT NULL DEFAULT 0,
  UltimaActualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (IdCanal, IdTipoHab, Fecha),
  FOREIGN KEY (IdCanal)   REFERENCES chn_Canales(IdCanal),
  FOREIGN KEY (IdTipoHab) REFERENCES cfg_TiposHabitacion(IdTipo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS chn_ReservasExternas (
  IdResExt       INT          AUTO_INCREMENT PRIMARY KEY,
  IdCanal        INT          NOT NULL,
  ExternalId     VARCHAR(100) NOT NULL,
  Estado         ENUM('NUEVA','PROCESADA','CANCELADA','ERROR') NOT NULL DEFAULT 'NUEVA',
  FechaEntrada   DATE,
  FechaSalida    DATE,
  Noches         INT          DEFAULT 0,
  NumAdultos     INT          DEFAULT 1,
  NumNinos       INT          DEFAULT 0,
  NombreHuesped  VARCHAR(200),
  EmailHuesped   VARCHAR(100),
  TelefonoHuesped VARCHAR(20),
  PaisHuesped    VARCHAR(50),
  MontoTotal     DECIMAL(10,2) DEFAULT 0,
  Comision       DECIMAL(10,2) DEFAULT 0,
  MonedaCanal    VARCHAR(3)   DEFAULT 'USD',
  TipoHabitacion VARCHAR(100),
  IdHabitacion   INT,
  IdReservaLocal INT,
  RawJSON        JSON,
  ErrorMsg       TEXT,
  FechaRecibido  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FechaProcesado DATETIME,
  FOREIGN KEY (IdCanal)        REFERENCES chn_Canales(IdCanal),
  FOREIGN KEY (IdHabitacion)   REFERENCES hot_Habitaciones(IdHabitacion),
  FOREIGN KEY (IdReservaLocal) REFERENCES res_Reservas(IdReserva)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ============================================================
-- NOTIFICACIONES (ntf_)
-- ============================================================

CREATE TABLE IF NOT EXISTS ntf_Cola (
  IdNot         INT          AUTO_INCREMENT PRIMARY KEY,
  Tipo          ENUM('WhatsApp','Telegram','Email') NOT NULL DEFAULT 'WhatsApp',
  Destinatario  VARCHAR(100) NOT NULL,
  Mensaje       TEXT         NOT NULL,
  IdReserva     INT,
  Estado        ENUM('Pendiente','Enviado','Error','Cancelado') NOT NULL DEFAULT 'Pendiente',
  Intentos      INT          NOT NULL DEFAULT 0,
  ErrorMsg      TEXT,
  FechaCreacion DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FechaEnvio    DATETIME,
  FOREIGN KEY (IdReserva) REFERENCES res_Reservas(IdReserva)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS ntf_Plantillas (
  Codigo      VARCHAR(30)  NOT NULL PRIMARY KEY,
  Tipo        ENUM('WhatsApp','Telegram','Email') NOT NULL DEFAULT 'WhatsApp',
  Contenido   TEXT         NOT NULL,
  Activo      TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ============================================================
-- MOTOR DE RESERVAS WEB (web_)
-- ============================================================

CREATE TABLE IF NOT EXISTS web_ConfigMotor (
  IdConfig        INT          AUTO_INCREMENT PRIMARY KEY,
  HabilitadoWeb   TINYINT(1)   NOT NULL DEFAULT 0,
  MinNoches       INT          DEFAULT 1,
  MaxNoches       INT          DEFAULT 30,
  AnticipacionMin INT          DEFAULT 1,
  PctAdelanto     DECIMAL(5,2) DEFAULT 30,
  RequierePago    TINYINT(1)   DEFAULT 0,
  ColorPrimario   VARCHAR(7)   DEFAULT '#1a3a5c'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS web_ReservasOnline (
  IdWebReserva    INT          AUTO_INCREMENT PRIMARY KEY,
  NombresCliente  VARCHAR(100) NOT NULL,
  ApellidosCliente VARCHAR(100),
  EmailCliente    VARCHAR(100) NOT NULL,
  TelefonoCliente VARCHAR(30),
  DocumentoCliente VARCHAR(20),
  PaisCliente     VARCHAR(50),
  FechaEntrada    DATE         NOT NULL,
  FechaSalida     DATE         NOT NULL,
  Noches          INT          NOT NULL DEFAULT 1,
  NumAdultos      INT          NOT NULL DEFAULT 1,
  NumNinos        INT          NOT NULL DEFAULT 0,
  IdHabitacion    INT,
  MontoTotal      DECIMAL(10,2) NOT NULL DEFAULT 0,
  AdelantoOnline  DECIMAL(10,2) DEFAULT 0,
  MetodoPagoOnline VARCHAR(30),
  ReferenciaOnline VARCHAR(100),
  NotasCliente    TEXT,
  Estado          ENUM('Pendiente','Procesada','Error','Cancelada') NOT NULL DEFAULT 'Pendiente',
  IdReservaLocal  INT,
  ExternalId      VARCHAR(100),
  ErrorMsg        TEXT,
  FechaCreacion   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FechaProcesado  DATETIME,
  FOREIGN KEY (IdHabitacion)  REFERENCES hot_Habitaciones(IdHabitacion),
  FOREIGN KEY (IdReservaLocal) REFERENCES res_Reservas(IdReserva)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ============================================================
-- CERRADURAS INTELIGENTES (lock_)
-- ============================================================

CREATE TABLE IF NOT EXISTS lock_Codigos (
  IdCodigo      INT          AUTO_INCREMENT PRIMARY KEY,
  IdReserva     INT,
  IdHabitacion  INT          NOT NULL,
  LockId        VARCHAR(100),
  Codigo        VARCHAR(20)  NOT NULL,
  FechaInicio   DATETIME     NOT NULL,
  FechaFin      DATETIME     NOT NULL,
  Estado        ENUM('Activo','Expirado','Revocado') NOT NULL DEFAULT 'Activo',
  Revocado      TINYINT(1)   NOT NULL DEFAULT 0,
  FechaCreacion DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (IdReserva)    REFERENCES res_Reservas(IdReserva),
  FOREIGN KEY (IdHabitacion) REFERENCES hot_Habitaciones(IdHabitacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- AGENCIAS (agt_) - modulo agencias asociadas (updates/009)
-- Mismas definiciones que SQL/updates/009_modulo_agencias.sql
-- ============================================================
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


