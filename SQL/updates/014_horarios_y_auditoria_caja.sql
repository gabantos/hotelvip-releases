-- ============================================================
-- 014 - Horarios de salida/limpieza + auditoria de cierres de caja
-- Idempotente. Aplicar con: mysql -u root -p <base> < 014_...sql
-- ============================================================

-- ------------------------------------------------------------
-- 1) Cuanto tarda una limpieza
-- ------------------------------------------------------------
-- El hotel ya guardaba HoraCheckin y HoraCheckout, pero nadie las usaba y no
-- habia forma de saber DESDE QUE HORA una habitacion vuelve a estar vendible.
-- Recepcion lo necesita para dos cosas: decirle al huesped que se va a que hora
-- debe dejar el cuarto, y poder vender esa misma habitacion para la tarde.
ALTER TABLE cfg_Hotel
  ADD COLUMN IF NOT EXISTS MinutosLimpieza INT NOT NULL DEFAULT 45
  COMMENT 'Minutos que tarda dejar una habitacion lista despues de una salida';

-- Una suite no se limpia en el mismo tiempo que una simple: si el tipo tiene
-- su propio valor manda ese, si esta en NULL se usa el del hotel.
ALTER TABLE cfg_TiposHabitacion
  ADD COLUMN IF NOT EXISTS MinutosLimpieza INT NULL
  COMMENT 'Minutos de limpieza propios de este tipo. NULL = usa el del hotel';

-- El caso de todos los dias: recepcion le pregunta al huesped si sigue una
-- noche mas y dice que no. La habitacion todavia figura ocupada, pero ya se
-- sabe a que hora queda libre y se puede vender para esa misma tarde. Sin este
-- campo esa venta se pierde hasta que el huesped efectivamente se va.
ALTER TABLE hot_Habitaciones
  ADD COLUMN IF NOT EXISTS LibreDesde DATETIME NULL
  COMMENT 'Salida confirmada: hora desde la que recepcion la da por vendible';

-- ------------------------------------------------------------
-- 2) Auditoria de cierres de caja
-- ------------------------------------------------------------
-- caj_TurnoCaja ya calculaba la Diferencia entre lo contado y lo que decia el
-- sistema, pero nadie podia REVISAR ese cierre despues: no quedaba constancia
-- de que el administrador lo hubiera mirado ni de que explicacion se le dio a
-- un descuadre.
ALTER TABLE caj_TurnoCaja
  ADD COLUMN IF NOT EXISTS RevisadoPor   INT      NULL COMMENT 'Usuario que audito el cierre',
  ADD COLUMN IF NOT EXISTS FechaRevision DATETIME NULL,
  ADD COLUMN IF NOT EXISTS NotaRevision  TEXT     NULL COMMENT 'Explicacion del descuadre o visto bueno';

-- El listado de auditoria filtra por fecha de cierre y por estado.
CREATE INDEX IF NOT EXISTS ix_turno_cierre ON caj_TurnoCaja (FechaCierre);

-- ------------------------------------------------------------
-- 3) Valores por defecto sensatos donde falten
-- ------------------------------------------------------------
UPDATE cfg_Hotel
   SET MinutosLimpieza = 45
 WHERE MinutosLimpieza IS NULL OR MinutosLimpieza <= 0;

UPDATE cfg_Hotel SET HoraCheckin  = '14:00:00' WHERE HoraCheckin  IS NULL;
UPDATE cfg_Hotel SET HoraCheckout = '12:00:00' WHERE HoraCheckout IS NULL;
