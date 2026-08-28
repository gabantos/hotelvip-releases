-- ============================================================
-- 011 - Caja por defecto
--
-- POR QUE: la tabla caj_Cajas quedaba VACIA al instalar, y sin una caja no
-- se puede abrir turno; sin turno no se pueden registrar cobros; y sin
-- cobrar no se puede hacer check-out (el sistema lo bloquea si hay saldo).
-- O sea: el hotel se instalaba y no podia cobrarle a nadie desde el dia 1.
--
-- Se crea la caja de recepcion, que es la que todo hotel necesita para
-- operar. Si el hotel quiere mas cajas (bar, restaurante), las agrega desde
-- Configuracion.
-- ============================================================

INSERT INTO caj_Cajas (IdCaja, Nombre, Activa)
SELECT 1, 'Caja Recepcion', 1
WHERE NOT EXISTS (SELECT 1 FROM caj_Cajas WHERE IdCaja = 1);
