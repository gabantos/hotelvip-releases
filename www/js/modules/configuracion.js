// configuracion.js — HotelVIP SaaS
// SistemasVIP Cusco 2026
// Modulo: Configuracion del Sistema

// ── Estado global ─────────────────────────────────────────────
let _pisos   = [];
let _tipos   = [];
let _habs    = [];

// ── Amenidades disponibles ────────────────────────────────────
const AMENIDADES = [
  { key: 'wifi',       label: 'WiFi',        icon: 'fa-wifi' },
  { key: 'tv',         label: 'TV',          icon: 'fa-tv' },
  { key: 'ac',         label: 'Aire Acond.', icon: 'fa-wind' },
  { key: 'frigobar',   label: 'Frigobar',    icon: 'fa-temperature-low' },
  { key: 'jacuzzi',    label: 'Jacuzzi',     icon: 'fa-hot-tub-person' },
  { key: 'balcon',     label: 'Balcon',      icon: 'fa-archway' },
  { key: 'vista_mar',  label: 'Vista al mar',icon: 'fa-water' },
  { key: 'cuna',       label: 'Cuna',        icon: 'fa-baby' },
];

// ── Modulos configurables ─────────────────────────────────────
const MODULOS_DEF = [
  { key: 'reservas',        label: 'Reservas',              icon: 'fa-calendar-days',    desc: 'Gestion de reservas y disponibilidad.' },
  { key: 'housekeeping',    label: 'Housekeeping',          icon: 'fa-broom',            desc: 'Control de limpieza y estado de habitaciones.' },
  { key: 'facturacion',     label: 'Facturacion',           icon: 'fa-file-invoice',     desc: 'Emision de facturas y boletas electronicas SUNAT.' },
  { key: 'canales',         label: 'Canales',               icon: 'fa-satellite-dish',   desc: 'Integracion con Booking.com, Airbnb y otros canales.' },
  { key: 'servicios',       label: 'Servicios',             icon: 'fa-concierge-bell',   desc: 'Servicios adicionales cargados a la cuenta del huesped.' },
  { key: 'reportes',        label: 'Reportes',              icon: 'fa-chart-bar',        desc: 'Reportes de ocupacion, ingresos y estadisticas.' },
  { key: 'notificaciones',  label: 'Notificaciones',        icon: 'fa-comment-dots',     desc: 'Envio de notificaciones por WhatsApp a huespedes.' },
  { key: 'sincronizacion',  label: 'Sincronizacion VPS',   icon: 'fa-rotate',           desc: 'Sincronizacion de datos con servidor en la nube.' },
];

// ═════════════════════════════════════════════════════════════
//  INIT
// ═════════════════════════════════════════════════════════════
function configInit() {
  initTabs();
  buildAmenidadesGrid();
  buildModulosList();
  cargarEstructuraHotel();
}

// ═════════════════════════════════════════════════════════════
//  TABS
// ═════════════════════════════════════════════════════════════
function initTabs() {
  const tabs    = document.querySelectorAll('#configTabs .tab-btn');
  const panels  = document.querySelectorAll('.tab-panel');

  tabs.forEach(btn => {
    btn.addEventListener('click', () => {
      const target = btn.dataset.tab;
      tabs.forEach(b => b.classList.remove('active'));
      panels.forEach(p => p.classList.remove('active'));
      btn.classList.add('active');
      document.getElementById('tab-' + target).classList.add('active');
      onTabActivado(target);
    });
  });
}

function onTabActivado(tab) {
  switch (tab) {
    case 'estructura':  cargarEstructuraHotel(); break;
    case 'general':     cargarConfigGeneral();   break;
    case 'facturacion': cargarConfigFac();        break;
    case 'impresion':   cargarConfigImpresion();  break;
    case 'documentos':  cargarConfigDocs();       break;
    case 'modulos':     cargarConfigModulos();    break;
  }
}

// ═════════════════════════════════════════════════════════════
//  HELPERS MODALES
// ═════════════════════════════════════════════════════════════
function abrirModal(id) {
  document.getElementById(id).classList.add('open');
}
function cerrarModal(id) {
  document.getElementById(id).classList.remove('open');
}
function cerrarModalSiOverlay(e, id) {
  if (e.target === document.getElementById(id)) cerrarModal(id);
}

function confirmar(mensaje, callback) {
  document.getElementById('confirmMensaje').textContent = mensaje;
  const btn = document.getElementById('btnConfirmOk');
  const nuevo = btn.cloneNode(true);
  btn.parentNode.replaceChild(nuevo, btn);
  nuevo.addEventListener('click', () => {
    cerrarModal('modalConfirmOverlay');
    callback();
  });
  abrirModal('modalConfirmOverlay');
}

// ═════════════════════════════════════════════════════════════
//  ESTRUCTURA DEL HOTEL
// ═════════════════════════════════════════════════════════════
async function cargarEstructuraHotel() {
  await Promise.all([cargarPisos(), cargarTipos(), cargarHabitaciones()]);
}

// ── PISOS ─────────────────────────────────────────────────────
async function cargarPisos() {
  setTablaLoading('bodyPisos', 6, 'fa-layer-group', 'Cargando pisos...');
  try {
    const res = await api.get('/habitaciones/pisos');
    _pisos = res.data || res.pisos || [];
    renderPisos(_pisos);
  } catch (e) {
    setTablaError('bodyPisos', 6, 'fa-layer-group', 'Error al cargar pisos', e.message);
  }
}

function renderPisos(pisos) {
  const tbody = document.getElementById('bodyPisos');
  if (!pisos.length) {
    tbody.innerHTML = `<tr><td colspan="6"><div class="empty-state">
      <i class="fa-solid fa-layer-group"></i><p>Sin pisos registrados. Agrega el primer piso.</p>
    </div></td></tr>`;
    return;
  }
  tbody.innerHTML = pisos.map(p => `
    <tr>
      <td class="muted text-xs">${p.IdPiso || p.id || '-'}</td>
      <td><strong>${esc(p.Nombre || p.nombre || '')}</strong></td>
      <td class="muted">${esc(p.Descripcion || p.descripcion || '—')}</td>
      <td class="muted">${p.Orden || p.orden || '—'}</td>
      <td>${badgeActivo(p.Activo ?? p.activo ?? 1)}</td>
      <td>
        <div class="flex gap-8">
          <button class="btn btn-ghost btn-sm" onclick="abrirModalPiso(${p.IdPiso || p.id})">
            <i class="fa-solid fa-pen"></i>
          </button>
          <button class="btn btn-danger btn-sm" onclick="eliminarPiso(${p.IdPiso || p.id}, '${esc(p.Nombre||p.nombre)}')">
            <i class="fa-solid fa-trash"></i>
          </button>
        </div>
      </td>
    </tr>`).join('');
}

function abrirModalPiso(id = null) {
  document.getElementById('pisoId').value        = '';
  document.getElementById('pisoNombre').value    = '';
  document.getElementById('pisoDescripcion').value = '';
  document.getElementById('pisoOrden').value     = _pisos.length + 1;
  document.getElementById('pisoActivo').checked  = true;
  document.getElementById('modalPisoTitulo').innerHTML =
    '<i class="fa-solid fa-layer-group" style="color:var(--accent);margin-right:8px"></i> ' +
    (id ? 'Editar Piso' : 'Nuevo Piso');

  if (id) {
    const piso = _pisos.find(p => (p.IdPiso || p.id) == id);
    if (piso) {
      document.getElementById('pisoId').value           = id;
      document.getElementById('pisoNombre').value       = piso.Nombre || piso.nombre || '';
      document.getElementById('pisoDescripcion').value  = piso.Descripcion || piso.descripcion || '';
      document.getElementById('pisoOrden').value        = piso.Orden || piso.orden || 1;
      document.getElementById('pisoActivo').checked     = !!(piso.Activo ?? piso.activo ?? 1);
    }
  }
  abrirModal('modalPisoOverlay');
  document.getElementById('pisoNombre').focus();
}

async function guardarPiso() {
  const id     = document.getElementById('pisoId').value;
  const nombre = document.getElementById('pisoNombre').value.trim();
  if (!nombre) { toast('El nombre del piso es obligatorio', 'warning'); return; }

  const payload = {
    nombre:      nombre,
    descripcion: document.getElementById('pisoDescripcion').value.trim(),
    orden:       parseInt(document.getElementById('pisoOrden').value) || 1,
    activo:      document.getElementById('pisoActivo').checked ? 1 : 0,
  };

  try {
    if (id) {
      await api.put('/habitaciones/pisos/' + id, payload);
      toast('Piso actualizado correctamente', 'success');
    } else {
      await api.post('/habitaciones/pisos', payload);
      toast('Piso creado correctamente', 'success');
    }
    cerrarModal('modalPisoOverlay');
    await cargarPisos();
    sincronizarSelectPisos();
  } catch (e) {
    toast('Error al guardar piso: ' + e.message, 'error');
  }
}

async function eliminarPiso(id, nombre) {
  confirmar(`¿Eliminar el piso "${nombre}"? Esta accion es irreversible.`, async () => {
    try {
      await api.delete('/habitaciones/pisos/' + id);
      toast('Piso eliminado', 'success');
      await cargarPisos();
      sincronizarSelectPisos();
    } catch (e) {
      toast('Error al eliminar piso: ' + e.message, 'error');
    }
  });
}

// ── TIPOS DE HABITACION ───────────────────────────────────────
async function cargarTipos() {
  setTablaLoading('bodyTipos', 6, 'fa-tags', 'Cargando tipos...');
  try {
    const res = await api.get('/habitaciones/tipos');
    _tipos = res.data || res.tipos || [];
    renderTipos(_tipos);
  } catch (e) {
    setTablaError('bodyTipos', 6, 'fa-tags', 'Error al cargar tipos', e.message);
  }
}

function renderTipos(tipos) {
  const tbody = document.getElementById('bodyTipos');
  if (!tipos.length) {
    tbody.innerHTML = `<tr><td colspan="6"><div class="empty-state">
      <i class="fa-solid fa-tags"></i><p>Sin tipos de habitacion registrados.</p>
    </div></td></tr>`;
    return;
  }
  tbody.innerHTML = tipos.map(t => `
    <tr>
      <td><strong>${esc(t.Nombre || t.nombre || '')}</strong></td>
      <td class="muted">${t.Capacidad || t.capacidad || '—'} pers.</td>
      <td>${fMoneda(t.PrecioBase || t.precio_base || 0)}</td>
      <td class="muted">${esc(t.Descripcion || t.descripcion || '—')}</td>
      <td>${badgeActivo(t.Activo ?? t.activo ?? 1)}</td>
      <td>
        <button class="btn btn-ghost btn-sm" onclick="abrirModalTipo(${t.IdTipo || t.id})">
          <i class="fa-solid fa-pen"></i>
        </button>
      </td>
    </tr>`).join('');
}

function buildAmenidadesGrid() {
  const grid = document.getElementById('amenidadesGrid');
  grid.innerHTML = AMENIDADES.map(a => `
    <label style="display:flex;align-items:center;gap:6px;cursor:pointer;font-size:12px;color:var(--text-muted);padding:6px 8px;border:1px solid var(--border);border-radius:var(--radius-sm)">
      <input type="checkbox" id="amen_${a.key}" style="accent-color:var(--accent)">
      <i class="fa-solid ${a.icon}" style="font-size:11px;width:14px;text-align:center"></i>
      ${a.label}
    </label>`).join('');
}

function abrirModalTipo(id = null) {
  document.getElementById('tipoId').value          = '';
  document.getElementById('tipoNombre').value      = '';
  document.getElementById('tipoCapacidad').value   = 2;
  document.getElementById('tipoPrecio').value      = '0.00';
  document.getElementById('tipoDescripcion').value = '';
  document.getElementById('tipoActivo').checked    = true;
  AMENIDADES.forEach(a => { document.getElementById('amen_' + a.key).checked = false; });
  document.getElementById('modalTipoTitulo').innerHTML =
    '<i class="fa-solid fa-tag" style="color:var(--accent);margin-right:8px"></i> ' +
    (id ? 'Editar Tipo de Habitacion' : 'Nuevo Tipo de Habitacion');

  if (id) {
    const tipo = _tipos.find(t => (t.IdTipo || t.id) == id);
    if (tipo) {
      document.getElementById('tipoId').value          = id;
      document.getElementById('tipoNombre').value      = tipo.Nombre || tipo.nombre || '';
      document.getElementById('tipoCapacidad').value   = tipo.Capacidad || tipo.capacidad || 2;
      document.getElementById('tipoPrecio').value      = tipo.PrecioBase || tipo.precio_base || 0;
      document.getElementById('tipoDescripcion').value = tipo.Descripcion || tipo.descripcion || '';
      document.getElementById('tipoActivo').checked    = !!(tipo.Activo ?? tipo.activo ?? 1);
      const amens = tipo.Amenidades || tipo.amenidades || [];
      const lista = typeof amens === 'string' ? amens.split(',') : (Array.isArray(amens) ? amens : []);
      lista.forEach(k => {
        const el = document.getElementById('amen_' + k.trim());
        if (el) el.checked = true;
      });
    }
  }
  abrirModal('modalTipoOverlay');
  document.getElementById('tipoNombre').focus();
}

async function guardarTipo() {
  const id     = document.getElementById('tipoId').value;
  const nombre = document.getElementById('tipoNombre').value.trim();
  if (!nombre) { toast('El nombre del tipo es obligatorio', 'warning'); return; }

  const amenidades = AMENIDADES.filter(a => document.getElementById('amen_' + a.key).checked).map(a => a.key);

  const payload = {
    nombre:      nombre,
    descripcion: document.getElementById('tipoDescripcion').value.trim(),
    capacidad:   parseInt(document.getElementById('tipoCapacidad').value) || 2,
    precio_base: parseFloat(document.getElementById('tipoPrecio').value) || 0,
    amenidades:  amenidades.join(','),
    activo:      document.getElementById('tipoActivo').checked ? 1 : 0,
  };

  try {
    if (id) {
      await api.put('/habitaciones/tipos/' + id, payload);
      toast('Tipo actualizado correctamente', 'success');
    } else {
      await api.post('/habitaciones/tipos', payload);
      toast('Tipo creado correctamente', 'success');
    }
    cerrarModal('modalTipoOverlay');
    await cargarTipos();
    sincronizarSelectTipos();
  } catch (e) {
    toast('Error al guardar tipo: ' + e.message, 'error');
  }
}

// ── HABITACIONES ──────────────────────────────────────────────
async function cargarHabitaciones() {
  setTablaLoading('bodyHabitaciones', 7, 'fa-door-open', 'Cargando habitaciones...');
  try {
    const res = await api.get('/habitaciones');
    _habs = res.data || res.habitaciones || [];
    renderHabitaciones(_habs);
  } catch (e) {
    setTablaError('bodyHabitaciones', 7, 'fa-door-open', 'Error al cargar habitaciones', e.message);
  }
}

function renderHabitaciones(habs) {
  const tbody = document.getElementById('bodyHabitaciones');
  if (!habs.length) {
    tbody.innerHTML = `<tr><td colspan="7"><div class="empty-state">
      <i class="fa-solid fa-door-open"></i><p>Sin habitaciones registradas.</p>
    </div></td></tr>`;
    return;
  }
  tbody.innerHTML = habs.map(h => `
    <tr>
      <td><strong>${esc(h.Numero || h.numero || '')}</strong></td>
      <td class="muted">${esc(h.NombrePiso || h.nombre_piso || h.piso || '—')}</td>
      <td class="muted">${esc(h.NombreTipo || h.nombre_tipo || h.tipo || '—')}</td>
      <td>${badgeEstado(h.Estado || h.estado || 'DISPONIBLE')}</td>
      <td class="muted">${h.Capacidad || h.capacidad || '—'} pers.</td>
      <td>${fMoneda(h.Precio || h.precio || 0)}</td>
      <td>
        <button class="btn btn-ghost btn-sm" onclick="abrirModalHabitacion(${h.IdHabitacion || h.id})">
          <i class="fa-solid fa-pen"></i>
        </button>
      </td>
    </tr>`).join('');
}

function sincronizarSelectPisos() {
  const sel = document.getElementById('habPiso');
  const val = sel.value;
  sel.innerHTML = '<option value="">-- Seleccionar piso --</option>' +
    _pisos.filter(p => (p.Activo ?? p.activo ?? 1)).map(p =>
      `<option value="${p.IdPiso || p.id}">${esc(p.Nombre || p.nombre)}</option>`
    ).join('');
  if (val) sel.value = val;
}

function sincronizarSelectTipos() {
  const sel = document.getElementById('habTipo');
  const val = sel.value;
  sel.innerHTML = '<option value="">-- Seleccionar tipo --</option>' +
    _tipos.filter(t => (t.Activo ?? t.activo ?? 1)).map(t =>
      `<option value="${t.IdTipo || t.id}">${esc(t.Nombre || t.nombre)}</option>`
    ).join('');
  if (val) sel.value = val;
}

function abrirModalHabitacion(id = null) {
  sincronizarSelectPisos();
  sincronizarSelectTipos();

  document.getElementById('habId').value          = '';
  document.getElementById('habNumero').value      = '';
  document.getElementById('habPiso').value        = '';
  document.getElementById('habTipo').value        = '';
  document.getElementById('habEstado').value      = 'DISPONIBLE';
  document.getElementById('habDescripcion').value = '';
  document.getElementById('modalHabTitulo').innerHTML =
    '<i class="fa-solid fa-door-open" style="color:var(--accent);margin-right:8px"></i> ' +
    (id ? 'Editar Habitacion' : 'Nueva Habitacion');

  if (id) {
    const hab = _habs.find(h => (h.IdHabitacion || h.id) == id);
    if (hab) {
      document.getElementById('habId').value          = id;
      document.getElementById('habNumero').value      = hab.Numero || hab.numero || '';
      document.getElementById('habPiso').value        = hab.IdPiso || hab.id_piso || '';
      document.getElementById('habTipo').value        = hab.IdTipo || hab.id_tipo || '';
      document.getElementById('habEstado').value      = hab.Estado || hab.estado || 'DISPONIBLE';
      document.getElementById('habDescripcion').value = hab.Descripcion || hab.descripcion || '';
    }
  }
  abrirModal('modalHabitacionOverlay');
  document.getElementById('habNumero').focus();
}

async function guardarHabitacion() {
  const id     = document.getElementById('habId').value;
  const numero = document.getElementById('habNumero').value.trim();
  const piso   = document.getElementById('habPiso').value;
  const tipo   = document.getElementById('habTipo').value;

  if (!numero) { toast('El numero de habitacion es obligatorio', 'warning'); return; }
  if (!piso)   { toast('Selecciona un piso', 'warning'); return; }
  if (!tipo)   { toast('Selecciona un tipo de habitacion', 'warning'); return; }

  const payload = {
    numero:      numero,
    id_piso:     parseInt(piso),
    id_tipo:     parseInt(tipo),
    estado:      document.getElementById('habEstado').value,
    descripcion: document.getElementById('habDescripcion').value.trim(),
  };

  try {
    if (id) {
      await api.put('/habitaciones/' + id, payload);
      toast('Habitacion actualizada correctamente', 'success');
    } else {
      await api.post('/habitaciones', payload);
      toast('Habitacion creada correctamente', 'success');
    }
    cerrarModal('modalHabitacionOverlay');
    await cargarHabitaciones();
  } catch (e) {
    toast('Error al guardar habitacion: ' + e.message, 'error');
  }
}

// ═════════════════════════════════════════════════════════════
//  TAB GENERAL
// ═════════════════════════════════════════════════════════════
async function cargarConfigGeneral() {
  try {
    const res = await api.get('/rep/config-empresa');
    const d   = res.data || res;

    // Datos del hotel
    setVal('gNombreComercial', d.nombre_comercial || d.NombreComercial || '');
    setVal('gRuc',             d.ruc              || d.Ruc              || '');
    setVal('gRazonSocial',     d.razon_social     || d.RazonSocial     || '');
    setVal('gDireccion',       d.direccion        || d.Direccion       || '');
    setVal('gDepartamento',    d.departamento     || d.Departamento    || '');
    setVal('gProvincia',       d.provincia        || d.Provincia       || '');
    setVal('gDistrito',        d.distrito         || d.Distrito        || '');
    setVal('gTelefono',        d.telefono         || d.Telefono        || '');
    setVal('gEmail',           d.email            || d.Email           || '');

    // Parametros operativos
    setVal('pCheckin',    d.checkin_default   || d.CheckinDefault   || '14:00');
    setVal('pCheckout',   d.checkout_default  || d.CheckoutDefault  || '12:00');
    setVal('pDiasMax',    d.dias_max_reserva  || d.DiasMaxReserva   || 365);
    setVal('pMoneda',     d.moneda            || d.Moneda           || 'PEN');
    setVal('pTipoCambio', d.tipo_cambio       || d.TipoCambio       || '3.70');
  } catch (e) {
    toast('Error al cargar configuracion general: ' + e.message, 'error');
  }
}

async function guardarConfigGeneral(seccion) {
  try {
    let payload = {};

    if (seccion === 'hotel') {
      payload = {
        nombre_comercial: getVal('gNombreComercial'),
        ruc:              getVal('gRuc'),
        razon_social:     getVal('gRazonSocial'),
        direccion:        getVal('gDireccion'),
        departamento:     getVal('gDepartamento'),
        provincia:        getVal('gProvincia'),
        distrito:         getVal('gDistrito'),
        telefono:         getVal('gTelefono'),
        email:            getVal('gEmail'),
      };
      if (!payload.nombre_comercial) { toast('El nombre comercial es obligatorio', 'warning'); return; }
    }

    if (seccion === 'parametros') {
      payload = {
        checkin_default:  getVal('pCheckin'),
        checkout_default: getVal('pCheckout'),
        dias_max_reserva: parseInt(getVal('pDiasMax')) || 365,
        moneda:           getVal('pMoneda'),
        tipo_cambio:      parseFloat(getVal('pTipoCambio')) || 3.70,
      };
    }

    await api.put('/rep/config-empresa', payload);
    toast('Configuracion guardada correctamente', 'success');
  } catch (e) {
    toast('Error al guardar: ' + e.message, 'error');
  }
}

// ═════════════════════════════════════════════════════════════
//  TAB FACTURACION
// ═════════════════════════════════════════════════════════════
async function cargarConfigFac() {
  try {
    const res = await api.get('/fac/config');
    const d   = res.data || res;

    setVal('fRuc',          d.ruc          || d.Ruc          || '');
    setVal('fRazonSocial',  d.razon_social || d.RazonSocial || '');
    setVal('fUrlPro7',      d.url_pro7     || d.UrlPro7     || '');
    setVal('fEmailPro7',    d.email_pro7   || d.EmailPro7   || '');
    setVal('fPasswordPro7', d.password_pro7|| d.PasswordPro7|| '');

    const modoProduccion = !!(d.modo_produccion || d.ModoProduccion);
    document.getElementById('fModoProduccion').checked = modoProduccion;
    actualizarWarningProduccion(modoProduccion);
    actualizarLabelModo(modoProduccion);

    setVal('fSerieFactura',   d.serie_factura    || d.SerieFactura   || 'F001');
    setVal('fSerieBoleta',    d.serie_boleta     || d.SerieBoleta    || 'B001');
    setVal('fSerieNcFactura', d.serie_nc_factura || d.SerieNcFactura || 'FC01');
    setVal('fSerieNcBoleta',  d.serie_nc_boleta  || d.SerieNcBoleta  || 'BC01');
  } catch (e) {
    toast('Error al cargar configuracion de facturacion: ' + e.message, 'error');
  }
}

async function guardarConfigFac() {
  const payload = {
    ruc:             getVal('fRuc'),
    razon_social:    getVal('fRazonSocial'),
    url_pro7:        getVal('fUrlPro7'),
    email_pro7:      getVal('fEmailPro7'),
    password_pro7:   getVal('fPasswordPro7'),
    modo_produccion: document.getElementById('fModoProduccion').checked ? 1 : 0,
    serie_factura:   getVal('fSerieFactura'),
    serie_boleta:    getVal('fSerieBoleta'),
    serie_nc_factura:getVal('fSerieNcFactura'),
    serie_nc_boleta: getVal('fSerieNcBoleta'),
  };
  try {
    await api.put('/fac/config', payload);
    toast('Configuracion de facturacion guardada', 'success');
  } catch (e) {
    toast('Error al guardar: ' + e.message, 'error');
  }
}

async function probarConexionPro7() {
  const btn = event.currentTarget;
  const orig = btn.innerHTML;
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner"></span> Probando...';
  try {
    const res = await api.post('/fac/test-conexion', {
      url_pro7:   getVal('fUrlPro7'),
      email_pro7: getVal('fEmailPro7'),
    });
    toast(res.mensaje || 'Conexion exitosa con Pro7', 'success');
  } catch (e) {
    toast('Error de conexion: ' + e.message, 'error');
  } finally {
    btn.disabled = false;
    btn.innerHTML = orig;
  }
}

function togglePassPro7() {
  const input = document.getElementById('fPasswordPro7');
  const icon  = document.getElementById('iconPassPro7');
  if (input.type === 'password') {
    input.type = 'text';
    icon.className = 'fa-solid fa-eye-slash';
  } else {
    input.type = 'password';
    icon.className = 'fa-solid fa-eye';
  }
}

function onChangeModoProduccion(chk) {
  actualizarWarningProduccion(chk.checked);
  actualizarLabelModo(chk.checked);
}

function actualizarWarningProduccion(activo) {
  document.getElementById('warningProduccion').style.display = activo ? 'block' : 'none';
}

function actualizarLabelModo(activo) {
  document.getElementById('labelModoProduccion').textContent =
    activo ? 'Produccion (REAL — comprobantes validos)' : 'Pruebas (Beta)';
  document.getElementById('labelModoProduccion').style.color =
    activo ? 'var(--red)' : 'var(--text-muted)';
}

// ═════════════════════════════════════════════════════════════
//  TAB IMPRESION
// ═════════════════════════════════════════════════════════════
async function cargarConfigImpresion() {
  try {
    const res = await api.get('/rep/config-impresion');
    const d   = res.data || res;

    setVal('iAnchoTicket',  d.ancho_ticket   || d.AnchoTicket   || 40);
    setVal('iImpTicket',    d.imp_ticket      || d.ImpTicket      || '');
    setVal('iImpReportes',  d.imp_reportes    || d.ImpReportes    || '');
    setVal('iPuertoAgente', d.puerto_agente   || d.PuertoAgente   || 3001);
    document.getElementById('iAgenteActivo').checked = !!(d.agente_activo || d.AgenteActivo);
  } catch (e) {
    toast('Error al cargar configuracion de impresion: ' + e.message, 'error');
  }
}

async function guardarConfigImpresion() {
  const payload = {
    ancho_ticket:  parseInt(getVal('iAnchoTicket')) || 40,
    imp_ticket:    getVal('iImpTicket'),
    imp_reportes:  getVal('iImpReportes'),
    puerto_agente: parseInt(getVal('iPuertoAgente')) || 3001,
    agente_activo: document.getElementById('iAgenteActivo').checked ? 1 : 0,
  };
  try {
    await api.put('/rep/config-impresion', payload);
    toast('Configuracion de impresion guardada', 'success');
  } catch (e) {
    toast('Error al guardar: ' + e.message, 'error');
  }
}

async function imprimirPrueba() {
  try {
    await api.post('/rep/config-impresion', { accion: 'test' });
    toast('Impresion de prueba enviada', 'success');
  } catch (e) {
    toast('Error al imprimir prueba: ' + e.message, 'error');
  }
}

// ═════════════════════════════════════════════════════════════
//  TAB DOCUMENTOS (consulta DNI/RUC)
//  Un solo lugar para el proveedor: si el hotel cambia de
//  servicio, se cambia aca y el resto del sistema sigue igual.
// ═════════════════════════════════════════════════════════════
async function cargarConfigDocs() {
  try {
    const res = await api.get('/rep/config-documentos');
    const d   = res.data || res;
    setVal('docProveedor', d.proveedor || '');
    setVal('docToken',     d.token     || '');
    document.getElementById('docActivo').checked = !!(d.activo);
  } catch (e) {
    toast('Error al cargar la configuracion de documentos: ' + e.message, 'error');
  }
}

async function guardarConfigDocs() {
  const activo = document.getElementById('docActivo').checked ? 1 : 0;
  const prov   = getVal('docProveedor');
  const token  = getVal('docToken');
  if (activo && !prov)  { toast('Selecciona un proveedor', 'warning'); return; }
  if (activo && !token) { toast('Ingresa el token del proveedor', 'warning'); return; }
  try {
    await api.put('/rep/config-documentos', { proveedor: prov, token: token, activo: activo });
    toast('Configuracion de documentos guardada', 'success');
  } catch (e) {
    toast('Error al guardar: ' + e.message, 'error');
  }
}

async function probarConexionDocs() {
  const btn  = event.currentTarget;
  const orig = btn.innerHTML;
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner"></span> Probando...';
  try {
    // Guarda antes de probar, asi se prueba lo que esta en pantalla
    await api.put('/rep/config-documentos', {
      proveedor: getVal('docProveedor'),
      token:     getVal('docToken'),
      activo:    document.getElementById('docActivo').checked ? 1 : 0,
    });
    const res = await api.post('/rep/config-documentos', {});
    toast(res.mensaje || 'Conexion correcta', 'success');
  } catch (e) {
    toast(e.message, 'error');
  } finally {
    btn.disabled = false;
    btn.innerHTML = orig;
  }
}

function toggleDocToken() {
  const input = document.getElementById('docToken');
  const icon  = document.getElementById('iconDocToken');
  if (input.type === 'password') { input.type = 'text';     icon.className = 'fa-solid fa-eye-slash'; }
  else                           { input.type = 'password'; icon.className = 'fa-solid fa-eye'; }
}

// ═════════════════════════════════════════════════════════════
//  TAB MODULOS
// ═════════════════════════════════════════════════════════════
function buildModulosList() {
  const cont = document.getElementById('listaModulos');
  cont.innerHTML = MODULOS_DEF.map((m, i) => `
    <div style="display:flex;align-items:center;gap:16px;padding:14px 18px;
      background:${i % 2 === 0 ? 'transparent' : 'rgba(255,255,255,.02)'};
      border-bottom:1px solid var(--border)">
      <div style="width:34px;height:34px;border-radius:8px;background:var(--accent-light);
        display:flex;align-items:center;justify-content:center;flex-shrink:0">
        <i class="fa-solid ${m.icon}" style="color:var(--accent);font-size:14px"></i>
      </div>
      <div style="flex:1">
        <div style="font-size:13px;font-weight:600;color:var(--text)">${m.label}</div>
        <div style="font-size:12px;color:var(--text-muted);margin-top:2px">${m.desc}</div>
      </div>
      <label class="toggle-wrap" style="margin:0">
        <span class="toggle">
          <input type="checkbox" id="mod_${m.key}" checked>
          <span class="toggle-slider"></span>
        </span>
      </label>
    </div>`).join('');
}

async function cargarConfigModulos() {
  try {
    const res = await api.get('/rep/config-modulos');
    const d   = res.data || res;
    MODULOS_DEF.forEach(m => {
      const el = document.getElementById('mod_' + m.key);
      if (el) el.checked = !!(d[m.key] ?? d[m.key.charAt(0).toUpperCase() + m.key.slice(1)] ?? 1);
    });
  } catch (e) {
    toast('Error al cargar configuracion de modulos: ' + e.message, 'error');
  }
}

async function guardarConfigModulos() {
  const payload = {};
  MODULOS_DEF.forEach(m => {
    const el = document.getElementById('mod_' + m.key);
    payload[m.key] = el ? (el.checked ? 1 : 0) : 1;
  });
  try {
    await api.put('/rep/config-modulos', payload);
    toast('Configuracion de modulos guardada', 'success');
  } catch (e) {
    toast('Error al guardar: ' + e.message, 'error');
  }
}

// ═════════════════════════════════════════════════════════════
//  HELPERS RENDER
// ═════════════════════════════════════════════════════════════
function badgeActivo(val) {
  return parseInt(val) === 1
    ? '<span class="badge badge-green"><i class="fa-solid fa-circle" style="font-size:6px"></i> Activo</span>'
    : '<span class="badge badge-gray"><i class="fa-solid fa-circle" style="font-size:6px"></i> Inactivo</span>';
}

function badgeEstado(estado) {
  const mapa = {
    'DISPONIBLE':   'badge-green',
    'OCUPADA':      'badge-blue',
    'LIMPIEZA':     'badge-yellow',
    'MANTENIMIENTO':'badge-red',
    'BLOQUEADA':    'badge-gray',
  };
  return `<span class="badge ${mapa[estado] || 'badge-gray'}">${estado}</span>`;
}

function esc(str) {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function setVal(id, val) {
  const el = document.getElementById(id);
  if (el) el.value = val;
}

function getVal(id) {
  const el = document.getElementById(id);
  return el ? el.value.trim() : '';
}

function setTablaLoading(tbodyId, cols, icon, msg) {
  document.getElementById(tbodyId).innerHTML =
    `<tr><td colspan="${cols}">
      <div class="empty-state" style="padding:30px 20px">
        <div class="spinner" style="margin:0 auto 10px"></div>
        <p>${msg}</p>
      </div>
    </td></tr>`;
}

function setTablaError(tbodyId, cols, icon, titulo, detalle) {
  document.getElementById(tbodyId).innerHTML =
    `<tr><td colspan="${cols}">
      <div class="empty-state">
        <i class="fa-solid ${icon}" style="color:var(--red)"></i>
        <p style="color:var(--red)">${titulo}</p>
        <p class="text-xs text-muted" style="margin-top:4px">${esc(detalle)}</p>
      </div>
    </td></tr>`;
}
