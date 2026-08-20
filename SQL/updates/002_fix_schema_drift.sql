-- =============================================================================
-- 002_fix_schema_drift.sql
-- Corrige el DRIFT entre 01_Estructura.sql y el codigo Delphi.
--
-- PROBLEMA detectado en auditoria: un tenant NUEVO creado con 01_Estructura.sql
-- NO podia hacer login -> "Unknown column 'Apellidos' in 'SELECT'". El codigo
-- (UAuthController y otros) usa columnas de seg_Usuarios y la tabla seg_Sesiones
-- que el 01_Estructura no creaba. La BD de desarrollo hotel_001 las tenia por
-- ALTERs manuales viejos que nunca se reflejaron en el script base.
--
-- Esta migracion alinea cualquier BD existente (hotel_001, tenants ya creados)
-- al schema que el codigo espera. El 01_Estructura.sql ya quedo corregido para
-- los tenants futuros; esta migracion es para los que ya nacieron incompletos.
--
-- Idempotente: ADD COLUMN IF NOT EXISTS / CREATE TABLE IF NOT EXISTS.
-- =============================================================================

-- Columnas faltantes en seg_Usuarios (orden: Apellidos antes de NombreCompleto,
-- porque la columna generada depende de Apellidos).
ALTER TABLE seg_Usuarios ADD COLUMN IF NOT EXISTS Apellidos    VARCHAR(100) NOT NULL DEFAULT '' AFTER Nombres;
ALTER TABLE seg_Usuarios ADD COLUMN IF NOT EXISTS Telefono     VARCHAR(20)  NULL AFTER Email;
ALTER TABLE seg_Usuarios ADD COLUMN IF NOT EXISTS FotoBase64   LONGTEXT     NULL AFTER Telefono;
ALTER TABLE seg_Usuarios ADD COLUMN IF NOT EXISTS UltimaSesion DATETIME     NULL AFTER UltimoLogin;
ALTER TABLE seg_Usuarios ADD COLUMN IF NOT EXISTS NombreCompleto VARCHAR(200)
  AS (CONCAT(Nombres,' ',Apellidos)) VIRTUAL;

-- Tabla de sesiones (auth bearer)
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
