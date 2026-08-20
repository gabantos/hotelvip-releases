-- ==============================================================
-- HOTELVIP SaaS - Stored Procedures v1.0.0
-- SistemasVIP - Cusco, Peru
-- ==============================================================

DELIMITER //

-- Genera codigo de reserva unico (formato: HV-YYYYMMDD-XXXX)
CREATE PROCEDURE IF NOT EXISTS sp_GenerarCodigoReserva(OUT p_Codigo VARCHAR(20))
BEGIN
  DECLARE v_fecha VARCHAR(8);
  DECLARE v_seq   INT;
  SET v_fecha = DATE_FORMAT(CURDATE(), '%Y%m%d');
  SELECT COALESCE(MAX(CAST(SUBSTRING(Codigo, 13) AS UNSIGNED)), 0) + 1
    INTO v_seq
    FROM res_Reservas
   WHERE Codigo LIKE CONCAT('HV-', v_fecha, '-%');
  SET p_Codigo = CONCAT('HV-', v_fecha, '-', LPAD(v_seq, 4, '0'));
END //

-- Actualiza el saldo de una reserva (Total - TotalPagado)
CREATE PROCEDURE IF NOT EXISTS sp_ActualizarSaldoReserva(IN p_IdReserva INT)
BEGIN
  DECLARE v_pagado DECIMAL(10,2);
  SELECT COALESCE(SUM(MontoBase), 0)
    INTO v_pagado
    FROM caj_Pagos
   WHERE IdReserva = p_IdReserva AND Anulado = 0 AND TipoPago = 'Ingreso';
  UPDATE res_Reservas
     SET TotalPagado = v_pagado,
         Saldo       = Total - v_pagado
   WHERE IdReserva = p_IdReserva;
END //

-- CheckIn: cambia estado reserva y habitacion
CREATE PROCEDURE IF NOT EXISTS sp_CheckIn(
  IN p_IdReserva INT,
  IN p_IdUsuario INT
)
BEGIN
  DECLARE v_IdHabitacion INT;
  SELECT IdHabitacion INTO v_IdHabitacion FROM res_Reservas WHERE IdReserva = p_IdReserva;

  UPDATE res_Reservas
     SET Estado = 'CheckIn', FechaCheckin = NOW(), IdUsuarioCheckin = p_IdUsuario
   WHERE IdReserva = p_IdReserva;

  UPDATE hot_Habitaciones
     SET Estado = 'Ocupada', FechaEstado = NOW(), IdUsuarioEstado = p_IdUsuario
   WHERE IdHabitacion = v_IdHabitacion;

  INSERT INTO hot_HistorialEstados (IdHabitacion, EstadoAnterior, EstadoNuevo, IdUsuario)
  VALUES (v_IdHabitacion, 'Disponible', 'Ocupada', p_IdUsuario);
END //

-- CheckOut: cambia estado reserva y genera tarea HSK
CREATE PROCEDURE IF NOT EXISTS sp_CheckOut(
  IN p_IdReserva INT,
  IN p_IdUsuario INT
)
BEGIN
  DECLARE v_IdHabitacion INT;
  SELECT IdHabitacion INTO v_IdHabitacion FROM res_Reservas WHERE IdReserva = p_IdReserva;

  UPDATE res_Reservas
     SET Estado = 'CheckOut', FechaCheckout = NOW(), IdUsuarioCheckout = p_IdUsuario
   WHERE IdReserva = p_IdReserva;

  UPDATE hot_Habitaciones
     SET Estado = 'Disponible', EstadoLimpieza = 'Sucia',
         FechaEstado = NOW(), IdUsuarioEstado = p_IdUsuario
   WHERE IdHabitacion = v_IdHabitacion;

  INSERT INTO hot_HistorialEstados (IdHabitacion, EstadoAnterior, EstadoNuevo, IdUsuario)
  VALUES (v_IdHabitacion, 'Ocupada', 'Disponible', p_IdUsuario);

  -- Generar tarea de limpieza automatica
  INSERT INTO hsk_TareasLimpieza (IdHabitacion, IdReserva, Tipo, Prioridad, Estado)
  VALUES (v_IdHabitacion, p_IdReserva, 'Salida', 'Alta', 'Pendiente');
END //

-- Siguiente correlativo para facturacion (con lock)
CREATE PROCEDURE IF NOT EXISTS sp_SiguienteCorrelativo(
  IN  p_IdSerie    INT,
  OUT p_Correlativo INT
)
BEGIN
  START TRANSACTION;
  SELECT Correlativo INTO p_Correlativo
    FROM fac_Series
   WHERE IdSerie = p_IdSerie FOR UPDATE;
  UPDATE fac_Series SET Correlativo = Correlativo + 1 WHERE IdSerie = p_IdSerie;
  COMMIT;
END //

-- Reporte de disponibilidad para un rango de fechas
CREATE PROCEDURE IF NOT EXISTS sp_DisponibilidadRango(
  IN p_FechaInicio DATE,
  IN p_FechaFin    DATE
)
BEGIN
  SELECT
    h.IdHabitacion,
    h.Numero,
    h.Estado,
    h.EstadoLimpieza,
    t.Nombre AS TipoHabitacion,
    t.PrecioBase,
    t.Capacidad,
    CASE
      WHEN EXISTS (
        SELECT 1 FROM res_Reservas r
         WHERE r.IdHabitacion = h.IdHabitacion
           AND r.Estado NOT IN ('Cancelada','NoShow')
           AND r.FechaEntrada < p_FechaFin
           AND r.FechaSalida  > p_FechaInicio
      ) THEN 0
      ELSE 1
    END AS Disponible
  FROM hot_Habitaciones h
  LEFT JOIN cfg_TiposHabitacion t ON t.IdTipo = h.IdTipo
  WHERE h.Activa = 1
  ORDER BY h.Numero;
END //

DELIMITER ;
