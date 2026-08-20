-- ==============================================================
-- HOTELVIP SaaS - Update 004: Fix vistas de reportes
-- SistemasVIP - Cusco, Peru
-- ==============================================================
-- Redefine 3 vistas para que coincidan EXACTAMENTE con lo que el
-- codigo Delphi (UReportesService.pas) consume. Arregla los HTTP 500 de:
--   /rep/kpis-hoy y /rep/resumen  (v_KPIsHoy)
--   /rep/ocupacion                (v_OcupacionDiaria)
--   /rep/hsk                      (v_RendimientoHSK)
--
-- CREATE OR REPLACE VIEW es idempotente -> no requiere IF NOT EXISTS.
-- ==============================================================

-- --------------------------------------------------------------
-- VISTA 1: v_KPIsHoy
-- GetKPIsHoy lee 12 columnas POR INDICE POSICIONAL (Fields[0..11]).
-- El ORDEN debe ser exactamente:
--   0 checkinsHoy   1 checkoutsHoy   2 enCasa         3 habsDisponibles
--   4 habsOcupadas  5 habsMantto     6 limpiezasPend  7 serviciosActivos
--   8 ingresosHoy   9 cajaHoy       10 webPendientes 11 channelNuevas
-- --------------------------------------------------------------
CREATE OR REPLACE VIEW v_KPIsHoy AS
SELECT
  -- 0: check-ins de hoy (reservas con check-in efectuado hoy)
  (SELECT COUNT(*) FROM res_Reservas WHERE DATE(FechaCheckin) = CURDATE()) AS CheckinsHoy,
  -- 1: check-outs de hoy
  (SELECT COUNT(*) FROM res_Reservas WHERE DATE(FechaCheckout) = CURDATE()) AS CheckoutsHoy,
  -- 2: huespedes en casa (reservas en estado CheckIn)
  (SELECT COUNT(*) FROM res_Reservas WHERE Estado = 'CheckIn') AS EnCasa,
  -- 3: habitaciones disponibles
  (SELECT COUNT(*) FROM hot_Habitaciones WHERE Estado = 'Disponible' AND Activa = 1) AS HabsDisponibles,
  -- 4: habitaciones ocupadas
  (SELECT COUNT(*) FROM hot_Habitaciones WHERE Estado = 'Ocupada' AND Activa = 1) AS HabsOcupadas,
  -- 5: habitaciones en mantenimiento
  (SELECT COUNT(*) FROM hot_Habitaciones WHERE Estado = 'Mantenimiento' AND Activa = 1) AS HabsMantto,
  -- 6: limpiezas pendientes (no terminadas)
  (SELECT COUNT(*) FROM hsk_TareasLimpieza WHERE Estado IN ('Pendiente','Asignada','EnProceso')) AS LimpiezasPend,
  -- 7: servicios activos (pedidos que no estan entregados ni cancelados)
  (SELECT COUNT(*) FROM svc_Pedidos WHERE Estado NOT IN ('Entregado','Cancelado')) AS ServiciosActivos,
  -- 8: ingresos de hoy (todos los pagos de ingreso no anulados con fecha de hoy)
  (SELECT COALESCE(SUM(MontoBase), 0)
     FROM caj_Pagos
    WHERE DATE(Fecha) = CURDATE() AND Anulado = 0 AND TipoPago = 'Ingreso') AS IngresosHoy,
  -- 9: caja de hoy (ingresos no anulados de turnos abiertos)
  (SELECT COALESCE(SUM(p.MontoBase), 0)
     FROM caj_Pagos p
     INNER JOIN caj_TurnoCaja t ON t.IdTurno = p.IdTurno
    WHERE t.Estado = 'Abierto' AND p.Anulado = 0 AND p.TipoPago = 'Ingreso') AS CajaHoy,
  -- 10: reservas web pendientes de procesar
  (SELECT COUNT(*) FROM web_ReservasOnline WHERE Estado = 'Pendiente') AS WebPendientes,
  -- 11: reservas de canales externos nuevas
  (SELECT COUNT(*) FROM chn_ReservasExternas WHERE Estado = 'NUEVA') AS ChannelNuevas;

-- --------------------------------------------------------------
-- VISTA 2: v_OcupacionDiaria
-- GetOcupacionMes selecciona por NOMBRE:
--   Fecha, Reservas, HabsOcupadas, HabsTotal, PctOcupacion,
--   IngresosAlojamiento, IngresosServicios, IngresoTotal
-- Mantiene el CTE de numeros (ultimos 30 dias + proximos 30).
-- Ingresos por fecha desde caj_Pagos (no hay forma de discriminar
-- alojamiento vs servicios -> Alojamiento = total, Servicios = 0,
-- pero IngresoTotal es la suma real de los pagos de ese dia).
-- --------------------------------------------------------------
CREATE OR REPLACE VIEW v_OcupacionDiaria AS
SELECT
  fecha_ref.Fecha,
  COUNT(DISTINCT r.IdReserva)    AS Reservas,
  COUNT(DISTINCT r.IdHabitacion) AS HabsOcupadas,
  (SELECT COUNT(*) FROM hot_Habitaciones WHERE Activa = 1) AS HabsTotal,
  ROUND(COUNT(DISTINCT r.IdHabitacion) * 100.0 /
    NULLIF((SELECT COUNT(*) FROM hot_Habitaciones WHERE Activa = 1), 0), 1) AS PctOcupacion,
  COALESCE((SELECT SUM(p.MontoBase) FROM caj_Pagos p
            WHERE DATE(p.Fecha) = fecha_ref.Fecha AND p.Anulado = 0 AND p.TipoPago = 'Ingreso'), 0) AS IngresosAlojamiento,
  0 AS IngresosServicios,
  COALESCE((SELECT SUM(p.MontoBase) FROM caj_Pagos p
            WHERE DATE(p.Fecha) = fecha_ref.Fecha AND p.Anulado = 0 AND p.TipoPago = 'Ingreso'), 0) AS IngresoTotal
FROM (
  SELECT CURDATE() - INTERVAL n DAY AS Fecha
  FROM (
    SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
    UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15
    UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19 UNION SELECT 20
    UNION SELECT 21 UNION SELECT 22 UNION SELECT 23 UNION SELECT 24 UNION SELECT 25
    UNION SELECT 26 UNION SELECT 27 UNION SELECT 28 UNION SELECT 29
  ) nums
  UNION ALL
  SELECT CURDATE() + INTERVAL n DAY
  FROM (
    SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
    UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15
    UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19 UNION SELECT 20
    UNION SELECT 21 UNION SELECT 22 UNION SELECT 23 UNION SELECT 24 UNION SELECT 25
    UNION SELECT 26 UNION SELECT 27 UNION SELECT 28 UNION SELECT 29 UNION SELECT 30
  ) nums2
) fecha_ref
LEFT JOIN res_Reservas r
  ON r.Estado NOT IN ('Cancelada','NoShow')
  AND fecha_ref.Fecha >= r.FechaEntrada
  AND fecha_ref.Fecha <  r.FechaSalida
GROUP BY fecha_ref.Fecha
ORDER BY fecha_ref.Fecha;

-- --------------------------------------------------------------
-- VISTA 3: v_RendimientoHSK
-- GetRendimientoHSK selecciona por NOMBRE:
--   Fecha, Camarera, TotalTareas, Completadas, Pendientes, MinutosPromedio
-- Agrupado por fecha (DATE de la tarea) + camarera.
-- --------------------------------------------------------------
CREATE OR REPLACE VIEW v_RendimientoHSK AS
SELECT
  DATE(t.FechaCreacion) AS Fecha,
  u.Nombres             AS Camarera,
  COUNT(t.IdTarea)      AS TotalTareas,
  SUM(CASE WHEN t.Estado IN ('Completada','Verificada') THEN 1 ELSE 0 END) AS Completadas,
  SUM(CASE WHEN t.Estado NOT IN ('Completada','Verificada','Cancelada') THEN 1 ELSE 0 END) AS Pendientes,
  ROUND(AVG(
    CASE WHEN t.FechaFin IS NOT NULL AND t.FechaInicio IS NOT NULL
         THEN TIMESTAMPDIFF(MINUTE, t.FechaInicio, t.FechaFin)
         ELSE NULL END
  ), 0) AS MinutosPromedio
FROM hsk_TareasLimpieza t
INNER JOIN seg_Usuarios u ON u.IdUsuario = t.IdAsignado
WHERE t.FechaCreacion >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(t.FechaCreacion), t.IdAsignado, u.Nombres
ORDER BY Fecha DESC, TotalTareas DESC;
