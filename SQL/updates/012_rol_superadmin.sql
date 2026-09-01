-- ============================================================
--  ROL SUPERADMIN (SistemasVIP)  —  idempotente
--
--  Hasta ahora el ADMIN del hotel entraba a TODO, incluidas las claves de
--  facturacion electronica, los datos de la empresa y la estructura de pisos
--  y habitaciones. Si el hotel movia eso, dejaba de facturar o de vender, y
--  la llamada nos llegaba a nosotros.
--
--  A partir de aca:
--    SUPERADMIN (nosotros) : configura el sistema y lo entrega
--    ADMIN      (el hotel) : manda en su operacion y en su gente
-- ============================================================

INSERT INTO seg_Roles (IdRol, Nombre, Descripcion, Activo)
SELECT 6, 'Super Administrador',
          'SistemasVIP. Configura el sistema: estructura del hotel, datos de la empresa y facturacion electronica.',
          1
 WHERE NOT EXISTS (SELECT 1 FROM seg_Roles WHERE IdRol = 6);

-- El usuario de soporte se crea en la instalacion, no aca: cada hotel lleva
-- su propia clave y no queremos una clave igual en todas las instalaciones.
