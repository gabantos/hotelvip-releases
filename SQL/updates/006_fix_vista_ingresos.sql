-- =============================================================================
-- 006_fix_vista_ingresos.sql
-- v_IngresosMensuales no coincidia con lo que GetIngresosMeses (UReportesService)
-- consume: el codigo lee Anio, Mes, TotalReservas, IngresoTotal, IngresoServicios,
-- IngresoAlojamiento, TotalDescuentos, PrecioPromedio, NochesPromedio,
-- ReservasWeb/Booking/Airbnb, Canceladas. La vista solo exponia Periodo/etc.
-- Rompe /rep/resumen y /rep/ingresos. Se reescribe desde res_Reservas.
-- Idempotente (CREATE OR REPLACE VIEW).
-- =============================================================================
CREATE OR REPLACE VIEW v_IngresosMensuales AS
SELECT
  YEAR(FechaReserva)  AS Anio,
  MONTH(FechaReserva) AS Mes,
  COUNT(*)            AS TotalReservas,
  COALESCE(SUM(CASE WHEN Estado <> 'Cancelada' THEN Total          ELSE 0 END), 0) AS IngresoTotal,
  COALESCE(SUM(CASE WHEN Estado <> 'Cancelada' THEN TotalServicios ELSE 0 END), 0) AS IngresoServicios,
  COALESCE(SUM(CASE WHEN Estado <> 'Cancelada' THEN Subtotal       ELSE 0 END), 0) AS IngresoAlojamiento,
  COALESCE(SUM(DescuentoMonto), 0)                                                 AS TotalDescuentos,
  COALESCE(ROUND(AVG(CASE WHEN Estado <> 'Cancelada' THEN PrecioNoche END), 2), 0) AS PrecioPromedio,
  COALESCE(ROUND(AVG(Noches), 1), 0)                                               AS NochesPromedio,
  SUM(CASE WHEN Canal = 'Web'     THEN 1 ELSE 0 END) AS ReservasWeb,
  SUM(CASE WHEN Canal = 'Booking' THEN 1 ELSE 0 END) AS ReservasBooking,
  SUM(CASE WHEN Canal = 'Airbnb'  THEN 1 ELSE 0 END) AS ReservasAirbnb,
  SUM(CASE WHEN Estado = 'Cancelada' THEN 1 ELSE 0 END) AS Canceladas
FROM res_Reservas
WHERE FechaReserva >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY YEAR(FechaReserva), MONTH(FechaReserva)
ORDER BY Anio DESC, Mes DESC;

-- v_TopServicios: GetTopServicios (UReportesService) lee Nombre, Categoria,
-- VecesVendido, TotalVendido, PrecioPromedio. La vista vieja exponia
-- Servicio/UnidadesVendidas/TotalVentas/NumPedidos -> rompia /rep/resumen.
CREATE OR REPLACE VIEW v_TopServicios AS
SELECT
  s.Nombre    AS Nombre,
  s.Categoria AS Categoria,
  COALESCE(SUM(d.Cantidad), 0)                     AS VecesVendido,
  COALESCE(SUM(d.Cantidad * d.PrecioUnitario), 0)  AS TotalVendido,
  COALESCE(ROUND(AVG(d.PrecioUnitario), 2), 0)     AS PrecioPromedio
FROM svc_DetallePedido d
INNER JOIN cfg_Servicios s ON s.IdServicio = d.IdServicio
INNER JOIN svc_Pedidos   p ON p.IdPedido   = d.IdPedido
WHERE p.Estado NOT IN ('Cancelado')
  AND p.FechaPedido >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY s.IdServicio, s.Nombre, s.Categoria
ORDER BY TotalVendido DESC;
