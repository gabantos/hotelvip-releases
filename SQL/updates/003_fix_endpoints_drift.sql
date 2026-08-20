-- =============================================================================
-- 003_fix_endpoints_drift.sql
-- Saneamiento del drift codigo<->schema detectado en auditoria de endpoints.
-- El codigo Delphi hace SELECT de columnas que el schema base nunca tuvo.
-- Esta migracion (FASE A) agrega las columnas FALTANTES. Las vistas y el
-- modelo de tipo de cambio se corrigen en migraciones aparte (004, 005).
--
-- Idempotente: ADD COLUMN IF NOT EXISTS. El 01_Estructura.sql ya quedo
-- alineado para tenants futuros.
-- =============================================================================

-- /api/caja/metodos-pago : el SELECT pide CodigoSUNAT, EsDigital, AceptaMonedaExtranjera
ALTER TABLE cfg_MetodosPago ADD COLUMN IF NOT EXISTS CodigoSUNAT            VARCHAR(2)  NULL                  AFTER Nombre;
ALTER TABLE cfg_MetodosPago ADD COLUMN IF NOT EXISTS EsDigital             TINYINT(1)  NOT NULL DEFAULT 0     AFTER CodigoSUNAT;
ALTER TABLE cfg_MetodosPago ADD COLUMN IF NOT EXISTS AceptaMonedaExtranjera TINYINT(1) NOT NULL DEFAULT 0     AFTER EsDigital;

-- /api/caja/cajas : el SELECT pide Descripcion, MonedaBase (el WHERE c.Activo->c.Activa se corrigio en codigo)
ALTER TABLE caj_Cajas ADD COLUMN IF NOT EXISTS Descripcion VARCHAR(200) NULL              AFTER Nombre;
ALTER TABLE caj_Cajas ADD COLUMN IF NOT EXISTS MonedaBase  VARCHAR(3)   NOT NULL DEFAULT 'PEN' AFTER Descripcion;

-- /api/huespedes : el SELECT pide BlackList (FechaRegistro->FechaCreacion se corrigio en codigo).
-- Las demas las usa /api/huespedes/:id (mismo origen de drift).
ALTER TABLE hsp_Huespedes ADD COLUMN IF NOT EXISTS BlackList       TINYINT(1)  NOT NULL DEFAULT 0 AFTER PuntosAcumulados;
ALTER TABLE hsp_Huespedes ADD COLUMN IF NOT EXISTS MotivoBlack     TEXT        NULL;
ALTER TABLE hsp_Huespedes ADD COLUMN IF NOT EXISTS Nacionalidad    VARCHAR(50) NULL;
ALTER TABLE hsp_Huespedes ADD COLUMN IF NOT EXISTS Idioma          VARCHAR(10) NULL;
ALTER TABLE hsp_Huespedes ADD COLUMN IF NOT EXISTS Genero          VARCHAR(20) NULL;
ALTER TABLE hsp_Huespedes ADD COLUMN IF NOT EXISTS FechaNacimiento DATE        NULL;
ALTER TABLE hsp_Huespedes ADD COLUMN IF NOT EXISTS EsEmpresa       TINYINT(1)  NOT NULL DEFAULT 0;
ALTER TABLE hsp_Huespedes ADD COLUMN IF NOT EXISTS Notas           TEXT        NULL;

-- /api/huespedes/tipos-documento : el SELECT pide TipoIGV (mismo dominio que hsp_Huespedes.TipoIGV)
ALTER TABLE hsp_TiposDocumento ADD COLUMN IF NOT EXISTS TipoIGV
  ENUM('General','Nacional','Extranjero','Exonerado') NOT NULL DEFAULT 'General' AFTER CodigoSUNAT;

-- /api/servicios/resumen-hoy : el SELECT SUM(d.Subtotal) de svc_DetallePedido
ALTER TABLE svc_DetallePedido ADD COLUMN IF NOT EXISTS Subtotal DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER PrecioUnitario;
