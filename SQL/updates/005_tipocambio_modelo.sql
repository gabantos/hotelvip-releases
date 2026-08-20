-- ============================================================
-- 005: Alinear cfg_TipoCambio / cfg_Monedas al modelo origen->destino
-- ============================================================
-- El codigo (UCajaController.DoGetTipoCambio / DoUpdateTipoCambio y
-- UCajaService.GetTipoCambio) asume un modelo de tipo de cambio
-- "moneda origen -> moneda base destino":
--   * cfg_TipoCambio: IdMonedaOrigen, IdMonedaDestino, Tasa, Fecha, Fuente
--     - DoUpdateTipoCambio hace INSERT ... ON DUPLICATE KEY UPDATE
--       sobre (IdMonedaOrigen, IdMonedaDestino, Fecha)
--       => requiere UNIQUE KEY sobre esas 3 columnas.
--   * cfg_Monedas: EsBase (la moneda base del hotel) + Activo
--     - DoGetTipoCambio filtra: mo.EsBase = 0 AND mo.Activo = 1
--     - DoUpdateTipoCambio toma la moneda destino con mb.EsBase = 1
--
-- El schema original (01_Estructura v1.0.0) tenia el modelo viejo:
--   cfg_TipoCambio(IdMoneda, Tasa, Fecha, PK(IdMoneda,Fecha))
--   cfg_Monedas(IdMoneda, Codigo, Nombre, Simbolo)
-- => GET /api/caja/tipo-cambio devolvia HTTP 500 "Unknown column 'tc.Fuente'".
--
-- Migracion idempotente: ADD COLUMN IF NOT EXISTS + UNIQUE KEY via
-- information_schema (patron estandar de migracion de indices).
-- ============================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- 1. cfg_Monedas: columnas EsBase y Activo
-- ------------------------------------------------------------
ALTER TABLE cfg_Monedas
  ADD COLUMN IF NOT EXISTS EsBase TINYINT(1) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS Activo TINYINT(1) NOT NULL DEFAULT 1;

-- ------------------------------------------------------------
-- 2. cfg_TipoCambio: columnas del modelo origen->destino + Fuente
--    (NULL para poder agregarlas sobre una tabla con datos viejos)
-- ------------------------------------------------------------
ALTER TABLE cfg_TipoCambio
  ADD COLUMN IF NOT EXISTS IdMonedaOrigen  INT          NULL,
  ADD COLUMN IF NOT EXISTS IdMonedaDestino INT          NULL,
  ADD COLUMN IF NOT EXISTS Fuente          VARCHAR(20)  NULL DEFAULT 'MANUAL';

-- ------------------------------------------------------------
-- 3. Marcar la moneda base del hotel (PEN, moneda local).
--    Se hace ANTES del backfill para poder resolver IdMonedaDestino.
-- ------------------------------------------------------------
UPDATE cfg_Monedas SET EsBase = 1 WHERE Codigo = 'PEN';
-- El resto explicitamente NO base (por si EsBase entro con otro default)
UPDATE cfg_Monedas SET EsBase = 0 WHERE Codigo <> 'PEN';

-- ------------------------------------------------------------
-- 4. Backfill de filas viejas (modelo IdMoneda):
--    - IdMonedaOrigen  = IdMoneda (la moneda que se cotiza)
--    - IdMonedaDestino = la moneda base (EsBase = 1, normalmente PEN)
--    Solo aplica si la columna IdMoneda todavia existe en la tabla.
-- ------------------------------------------------------------
SET @dbname = DATABASE();
SET @tieneIdMoneda = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
                      WHERE TABLE_SCHEMA = @dbname
                      AND TABLE_NAME = 'cfg_TipoCambio'
                      AND COLUMN_NAME = 'IdMoneda');

SET @sqlBackfillOrigen = IF(@tieneIdMoneda > 0,
  'UPDATE cfg_TipoCambio SET IdMonedaOrigen = IdMoneda WHERE IdMonedaOrigen IS NULL',
  'SELECT ''cfg_TipoCambio sin columna IdMoneda: nada que backfillear''');
PREPARE stmt FROM @sqlBackfillOrigen;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- IdMonedaDestino = moneda base (vale para filas viejas y para cualquier
-- fila que se haya quedado sin destino). Si no hay moneda base marcada,
-- queda NULL y el UNIQUE KEY igual se crea (se documenta el supuesto).
UPDATE cfg_TipoCambio
SET IdMonedaDestino = (SELECT IdMoneda FROM cfg_Monedas WHERE EsBase = 1 LIMIT 1)
WHERE IdMonedaDestino IS NULL;

-- Fuente por defecto para filas viejas
UPDATE cfg_TipoCambio SET Fuente = 'MANUAL' WHERE Fuente IS NULL;

-- ------------------------------------------------------------
-- 5. UNIQUE KEY para el upsert (IdMonedaOrigen, IdMonedaDestino, Fecha).
--    Idempotente: solo se crea si no existe ya un indice con ese nombre.
-- ------------------------------------------------------------
SET @existeUk = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
                 WHERE TABLE_SCHEMA = @dbname
                 AND TABLE_NAME = 'cfg_TipoCambio'
                 AND INDEX_NAME = 'uk_tc_origen_destino_fecha');
SET @sqlUk = IF(@existeUk = 0,
  'ALTER TABLE cfg_TipoCambio ADD UNIQUE KEY uk_tc_origen_destino_fecha (IdMonedaOrigen, IdMonedaDestino, Fecha)',
  'SELECT ''uk_tc_origen_destino_fecha ya existe''');
PREPARE stmt FROM @sqlUk;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 6. Verificacion
-- ------------------------------------------------------------
SELECT m.Codigo, m.EsBase, m.Activo FROM cfg_Monedas m ORDER BY m.IdMoneda;

SELECT tc.IdMonedaOrigen, tc.IdMonedaDestino, tc.Tasa, tc.Fecha, tc.Fuente
FROM cfg_TipoCambio tc
ORDER BY tc.IdMonedaOrigen, tc.Fecha;
