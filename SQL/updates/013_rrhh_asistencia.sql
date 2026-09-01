-- ============================================================
--  RRHH / ASISTENCIA  —  idempotente
--
--  Portado del modulo que ya funciona en RestaurantVip, adaptado a HotelVip:
--    - Sin Cod_Empresa: aca cada hotel tiene su propia base, no hace falta.
--    - Cod_Usuario -> IdUsuario, contra seg_Usuarios.
--    - Prefijo rrhh_ para seguir la convencion del proyecto (seg_, hot_, res_).
--
--  Que resuelve: a que hora entro y salio cada uno, quien llego tarde, quien
--  falto, quien lo cubrio, y cuanto se le descuenta. Hoy eso vive en un
--  cuaderno y nadie lo puede auditar.
-- ============================================================

-- ── Marcaciones: el registro crudo de entradas y salidas ──
CREATE TABLE IF NOT EXISTS rrhh_Marcacion (
  IdMarcacion    INT AUTO_INCREMENT PRIMARY KEY,
  IdUsuario      INT NOT NULL,
  Fecha          DATE NOT NULL,
  Hora           TIME NOT NULL,
  FechaHora      DATETIME NOT NULL,
  Tipo           ENUM('Entrada','Salida') NOT NULL,
  -- PIN es lo que sirve en un hotel chico; HUELLA queda para cuando haya
  -- lector; MANUAL es cuando un jefe la carga por alguien (queda su nombre).
  Metodo         ENUM('PIN','Huella','Manual') NOT NULL DEFAULT 'PIN',
  IdUsuarioReg   INT NULL,
  Observacion    VARCHAR(200) NULL,
  -- Nunca se borra una marcacion: se anula. Si no, no hay nada que auditar.
  Anulada        TINYINT(1) NOT NULL DEFAULT 0,
  MotivoAnulacion VARCHAR(200) NULL,
  FechaCreacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_marc_dia   (IdUsuario, Fecha),
  KEY ix_marc_fecha (Fecha, Anulada)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── Horario semanal: que le toca a cada uno ──
CREATE TABLE IF NOT EXISTS rrhh_Horario (
  IdHorario      INT AUTO_INCREMENT PRIMARY KEY,
  IdUsuario      INT NOT NULL,
  Dia            ENUM('Lunes','Martes','Miercoles','Jueves','Viernes','Sabado','Domingo') NOT NULL,
  -- Turno 1, 2, 3: un hotel parte el dia (manana y noche) y una mucama puede
  -- entrar dos veces el mismo dia.
  Turno          SMALLINT NOT NULL DEFAULT 1,
  HoraInicio     TIME NOT NULL,
  HoraFin        TIME NOT NULL,
  -- Minutos de gracia antes de contar tardanza
  ToleranciaMin  INT NOT NULL DEFAULT 10,
  Activo         TINYINT(1) NOT NULL DEFAULT 1,
  FechaModificacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY ux_horario (IdUsuario, Dia, Turno),
  KEY ix_horario_user (IdUsuario, Dia)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── Permisos: la falta avisada no es falta ──
CREATE TABLE IF NOT EXISTS rrhh_Permiso (
  IdPermiso      INT AUTO_INCREMENT PRIMARY KEY,
  IdUsuario      INT NOT NULL,
  Fecha          DATE NOT NULL,
  Tipo           ENUM('SalidaAnticipada','InasistenciaJustificada','PermisoHoras','Vacaciones','Descanso') NOT NULL,
  HoraDesde      TIME NULL,
  HoraHasta      TIME NULL,
  Motivo         VARCHAR(200) NULL,
  IdUsuarioAutoriza INT NOT NULL,
  Anulado        TINYINT(1) NOT NULL DEFAULT 0,
  FechaCreacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_permiso_dia  (Fecha, Anulado),
  KEY ix_permiso_user (IdUsuario, Fecha)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── Reemplazos: quien cubrio a quien ──
CREATE TABLE IF NOT EXISTS rrhh_Reemplazo (
  IdReemplazo    INT AUTO_INCREMENT PRIMARY KEY,
  Fecha          DATE NOT NULL,
  IdUsuarioAusente INT NOT NULL,
  IdUsuarioCubre   INT NOT NULL,
  Turno          SMALLINT NOT NULL DEFAULT 1,
  HoraInicio     TIME NULL,
  HoraFin        TIME NULL,
  Motivo         VARCHAR(200) NULL,
  IdUsuarioReg   INT NULL,
  Anulado        TINYINT(1) NOT NULL DEFAULT 0,
  FechaCreacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_reemp_fecha (Fecha, Anulado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── Politica de descuentos y datos de sueldo ──
-- IdUsuario = 0 es la politica general del hotel; una fila por persona la pisa.
CREATE TABLE IF NOT EXISTS rrhh_Politica (
  IdPolitica     INT AUTO_INCREMENT PRIMARY KEY,
  IdUsuario      INT NOT NULL DEFAULT 0,
  FaltaModo      ENUM('Ninguno','MontoFijo','JornalDiario') NOT NULL DEFAULT 'Ninguno',
  FaltaMonto     DECIMAL(10,2) NOT NULL DEFAULT 0,
  TardanzaModo   ENUM('Ninguno','MontoFijo','PorMinuto','Escalonado') NOT NULL DEFAULT 'Ninguno',
  TardanzaMonto  DECIMAL(10,2) NOT NULL DEFAULT 0,
  TardanzaGraciaMin INT NOT NULL DEFAULT 0,
  -- JSON [{"hastaMin":15,"monto":0},{"hastaMin":30,"monto":5}] para Escalonado
  TardanzaEscalones TEXT NULL,
  SueldoMensual  DECIMAL(10,2) NOT NULL DEFAULT 0,
  DiasMes        INT NOT NULL DEFAULT 30,
  HorasJornada   DECIMAL(5,2) NOT NULL DEFAULT 8,
  FechaModificacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY ux_politica (IdUsuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Politica general por defecto, para que el modulo no nazca vacio
INSERT INTO rrhh_Politica (IdUsuario, FaltaModo, TardanzaModo, TardanzaGraciaMin)
SELECT 0, 'Ninguno', 'Ninguno', 10
 WHERE NOT EXISTS (SELECT 1 FROM rrhh_Politica WHERE IdUsuario = 0);

-- ── Datos del trabajador que seg_Usuarios no tiene ──
-- seg_Usuarios guarda usuario, clave y rol. Para RRHH hace falta la ficha.
ALTER TABLE seg_Usuarios
  ADD COLUMN IF NOT EXISTS NumeroDoc     VARCHAR(15)  NULL AFTER Email,
  ADD COLUMN IF NOT EXISTS Telefono      VARCHAR(20)  NULL AFTER NumeroDoc,
  ADD COLUMN IF NOT EXISTS Cargo         VARCHAR(60)  NULL AFTER Telefono,
  ADD COLUMN IF NOT EXISTS FechaIngreso  DATE         NULL AFTER Cargo,
  -- PIN para marcar asistencia sin usar la clave del sistema: la mucama marca
  -- en la tablet de recepcion sin que nadie vea con que entra al sistema.
  ADD COLUMN IF NOT EXISTS PinAsistencia VARCHAR(10)  NULL AFTER FechaIngreso;

CREATE INDEX IF NOT EXISTS ix_usuario_pin ON seg_Usuarios (PinAsistencia);
