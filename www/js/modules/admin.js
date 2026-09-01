// admin.js — Modulo Administracion HotelVIP
// SistemasVIP Cusco 2026

'use strict';

/* ================================================================
   ESTADO INTERNO
================================================================ */
let _tabActiva   = 'dashboard';
let _rptSubtab   = 'ocupacion';
let _usrEditId   = null;
let _hspPage     = 1;
let _hspTimer    = null;
let _dashData    = null;

/* ================================================================
   INIT PRINCIPAL
================================================================ */
function adminInit() {
  _initTabs();
  _initRptSubtabs();
  _initFechasPorDefecto();
  cargarDashboard();
}

/* ----------------------------------------------------------------
   Tabs principales
---------------------------------------------------------------- */
function _initTabs() {
  const tabs = document.querySelectorAll('#adminTabs .tab-btn');
  tabs.forEach(btn => {
    btn.addEventListener('click', () => {
      const tab = btn.dataset.tab;
      _tabActiva = tab;

      // Activar boton
      tabs.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      // Mostrar panel
      document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
      const panel = document.getElementById('panel-' + tab);
      if (panel) panel.classList.add('active');

      // Acciones contextuales en page-header
      _updatePageActions(tab);

      // Cargar datos segun tab
      if (tab === 'dashboard' && !_dashData) cargarDashboard();
      if (tab === 'usuarios')  cargarUsuarios();
      if (tab === 'huespedes') cargarHuespedes();
    });
  });
}

/* ----------------------------------------------------------------
   Sub-tabs reportes
---------------------------------------------------------------- */
function _initRptSubtabs() {
  const btns = document.querySelectorAll('#rptSubtabs .subtab-btn');
  btns.forEach(btn => {
    btn.addEventListener('click', () => {
      _rptSubtab = btn.dataset.rpt;
      btns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      // Si ya hay fechas y ya se genero, re-generar con nuevo subtab
      const inicio = document.getElementById('rptInicio').value;
      const fin    = document.getElementById('rptFin').value;
      if (inicio && fin) adminGenerarReporte();
    });
  });
}

/* ----------------------------------------------------------------
   Fechas por defecto: primer dia del mes — hoy
---------------------------------------------------------------- */
function _initFechasPorDefecto() {
  const hoy   = new Date();
  const finStr = hoy.toISOString().split('T')[0];
  const inicio = new Date(hoy.getFullYear(), hoy.getMonth(), 1);
  const iniStr = inicio.toISOString().split('T')[0];

  const elIni = document.getElementById('rptInicio');
  const elFin = document.getElementById('rptFin');
  if (elIni) elIni.value = iniStr;
  if (elFin) elFin.value = finStr;
}

/* ----------------------------------------------------------------
   Acciones dinamicas en page-header segun tab
---------------------------------------------------------------- */
function _updatePageActions(tab) {
  const cont = document.getElementById('adminPageActions');
  if (!cont) return;
  if (tab === 'usuarios') {
    cont.innerHTML = `<button class="btn btn-primary" onclick="abrirModalUsuario()">
      <i class="fa-solid fa-user-plus"></i> Nuevo Usuario</button>`;
  } else {
    cont.innerHTML = '';
  }
}

/* ================================================================
   TAB 1 — DASHBOARD
================================================================ */
async function cargarDashboard() {
  try {
    const res = await api.get('/rep/dashboard');
    _dashData = res;
    _renderKPIs(res);
    _renderOcupacionSemanal(res.ocupacion_semanal || []);
    _renderTopHabitaciones(res.top_habitaciones || []);
  } catch (e) {
    _renderKPIsError(e.message);
  }
}

function _renderKPIs(d) {
  const ocup     = d.ocupacion   || 0;
  const ingresos = d.ingresos_mes || 0;
  const reservas = d.reservas_activas || 0;
  const huespedes= d.total_huespedes || 0;

  // Color segun ocupacion
  let colOcup = 'kpi-rojo';
  let txtOcup = 'Ocupacion baja';
  if (ocup >= 80) { colOcup = 'kpi-verde'; txtOcup = 'Excelente ocupacion'; }
  else if (ocup >= 50) { colOcup = 'kpi-amarillo'; txtOcup = 'Ocupacion moderada'; }

  const clsOcup = ocup >= 80 ? 'text-green' : ocup >= 50 ? 'text-yellow' : 'text-red';

  document.getElementById('kpiGrid').innerHTML = `
    <div class="kpi-card-admin ${colOcup}">
      <div class="kpi-label">Ocupacion actual</div>
      <div class="kpi-value-big ${clsOcup}">${ocup.toFixed(1)}%</div>
      <div class="kpi-sub">${txtOcup}</div>
      <div class="kpi-icon-bg" style="background:var(--accent-light);color:var(--accent)">
        <i class="fa-solid fa-bed"></i>
      </div>
    </div>
    <div class="kpi-card-admin kpi-verde">
      <div class="kpi-label">Ingresos del mes</div>
      <div class="kpi-value-big text-green">${fMoneda(ingresos)}</div>
      <div class="kpi-sub">Mes en curso</div>
      <div class="kpi-icon-bg" style="background:var(--green-light);color:var(--green)">
        <i class="fa-solid fa-sack-dollar"></i>
      </div>
    </div>
    <div class="kpi-card-admin kpi-amarillo">
      <div class="kpi-label">Reservas activas</div>
      <div class="kpi-value-big text-yellow">${reservas}</div>
      <div class="kpi-sub">En este momento</div>
      <div class="kpi-icon-bg" style="background:var(--yellow-light);color:var(--yellow)">
        <i class="fa-solid fa-calendar-check"></i>
      </div>
    </div>
    <div class="kpi-card-admin kpi-azul">
      <div class="kpi-label">Total huespedes</div>
      <div class="kpi-value-big text-accent">${huespedes.toLocaleString()}</div>
      <div class="kpi-sub">Registrados en el sistema</div>
      <div class="kpi-icon-bg" style="background:var(--accent-light);color:var(--accent)">
        <i class="fa-solid fa-users"></i>
      </div>
    </div>
  `;
}

function _renderKPIsError(msg) {
  document.getElementById('kpiGrid').innerHTML = `
    <div class="kpi-card-admin kpi-azul" style="grid-column:1/-1">
      <div class="empty-state" style="padding:20px">
        <i class="fa-solid fa-triangle-exclamation"></i>
        <p>No se pudieron cargar los KPIs: ${_esc(msg)}</p>
      </div>
    </div>`;
}

function _renderOcupacionSemanal(rows) {
  const cont = document.getElementById('tablaOcupacionSemanal');
  if (!rows.length) {
    cont.innerHTML = `<div class="empty-state"><i class="fa-solid fa-calendar-xmark"></i>
      <p>Sin datos de ocupacion</p></div>`;
    return;
  }
  const filas = rows.map(r => {
    const pct = r.porcentaje || 0;
    const cls = pct >= 80 ? 'text-green' : pct >= 50 ? 'text-yellow' : 'text-red';
    return `<tr>
      <td>${fFecha(r.fecha)}</td>
      <td class="muted">${r.disponibles ?? '—'}</td>
      <td>${r.ocupadas ?? '—'}</td>
      <td class="${cls} font-bold">${pct.toFixed(1)}%</td>
    </tr>`;
  }).join('');
  cont.innerHTML = `<table>
    <thead><tr>
      <th>Fecha</th><th>Disponibles</th><th>Ocupadas</th><th>% Ocup.</th>
    </tr></thead>
    <tbody>${filas}</tbody>
  </table>`;
}

function _renderTopHabitaciones(rows) {
  const cont = document.getElementById('tablaTopHabitaciones');
  if (!rows.length) {
    cont.innerHTML = `<div class="empty-state"><i class="fa-solid fa-bed"></i>
      <p>Sin datos de habitaciones</p></div>`;
    return;
  }
  const filas = rows.map((r, i) => `<tr>
    <td>
      <span style="font-size:11px;color:var(--text-faint);margin-right:6px">#${i+1}</span>
      <strong>${_esc(r.habitacion)}</strong>
    </td>
    <td class="muted">${_esc(r.tipo || '—')}</td>
    <td><span class="badge badge-blue">${r.reservas}</span></td>
    <td class="text-green">${fMoneda(r.ingresos || 0)}</td>
  </tr>`).join('');
  cont.innerHTML = `<table>
    <thead><tr>
      <th>Habitacion</th><th>Tipo</th><th>Reservas</th><th>Ingresos</th>
    </tr></thead>
    <tbody>${filas}</tbody>
  </table>`;
}

/* ================================================================
   TAB 2 — REPORTES
================================================================ */
async function adminGenerarReporte() {
  const inicio = document.getElementById('rptInicio').value;
  const fin    = document.getElementById('rptFin').value;
  const cont   = document.getElementById('rptContenido');

  if (!inicio || !fin) { toast('Seleccione rango de fechas', 'warning'); return; }
  if (inicio > fin)    { toast('La fecha inicio debe ser menor al fin', 'warning'); return; }

  cont.innerHTML = `<div class="tbl-loading"><div class="spinner"></div>Generando reporte...</div>`;

  const btn = document.getElementById('btnGenerar');
  btn.disabled = true;

  try {
    const params = `?inicio=${inicio}&fin=${fin}`;
    let data;

    switch (_rptSubtab) {
      case 'ocupacion':
        data = await api.get('/rep/ocupacion' + params);
        _renderRptOcupacion(data.data || []);
        break;
      case 'ingresos':
        data = await api.get('/rep/ingresos' + params);
        _renderRptIngresos(data.data || []);
        break;
      case 'caja':
        data = await api.get('/rep/caja' + params);
        _renderRptCaja(data.data || []);
        break;
      case 'huespedes':
        data = await api.get('/rep/huespedes' + params);
        _renderRptHuespedes(data.data || []);
        break;
    }
  } catch (e) {
    cont.innerHTML = `<div class="empty-state">
      <i class="fa-solid fa-triangle-exclamation"></i>
      <p>Error al generar reporte: ${_esc(e.message)}</p>
    </div>`;
  } finally {
    btn.disabled = false;
  }
}

function _renderRptOcupacion(rows) {
  const cont = document.getElementById('rptContenido');
  if (!rows.length) { cont.innerHTML = _emptyState('Sin datos para el periodo'); return; }

  const filas = rows.map(r => {
    const pct = r.porcentaje || 0;
    const cls = pct >= 80 ? 'text-green' : pct >= 50 ? 'text-yellow' : 'text-red';
    return `<tr>
      <td>${fFecha(r.fecha)}</td>
      <td class="muted">${r.total ?? '—'}</td>
      <td>${r.ocupadas ?? '—'}</td>
      <td class="${cls} font-bold">${pct.toFixed(1)}%</td>
      <td class="text-green">${fMoneda(r.ingresos_dia || 0)}</td>
    </tr>`;
  }).join('');

  // Totales
  const totIngresos = rows.reduce((s, r) => s + (r.ingresos_dia || 0), 0);
  const promOcup    = rows.reduce((s, r) => s + (r.porcentaje || 0), 0) / rows.length;

  cont.innerHTML = `<div class="table-wrapper"><table>
    <thead><tr>
      <th>Fecha</th><th>Hab. Totales</th><th>Ocupadas</th><th>% Ocup.</th><th>Ingresos</th>
    </tr></thead>
    <tbody>
      ${filas}
      <tr class="fila-total">
        <td>PROMEDIO / TOTAL</td>
        <td>—</td><td>—</td>
        <td>${promOcup.toFixed(1)}%</td>
        <td>${fMoneda(totIngresos)}</td>
      </tr>
    </tbody>
  </table></div>`;
}

function _renderRptIngresos(rows) {
  const cont = document.getElementById('rptContenido');
  if (!rows.length) { cont.innerHTML = _emptyState('Sin datos para el periodo'); return; }

  const filas = rows.map(r => `<tr>
    <td>${fFecha(r.fecha)}</td>
    <td>${r.reservas ?? '—'}</td>
    <td class="text-accent">${fMoneda(r.servicios || 0)}</td>
    <td class="text-yellow">${fMoneda(r.caja || 0)}</td>
    <td class="text-green font-bold">${fMoneda(r.total || 0)}</td>
  </tr>`).join('');

  const totRes  = rows.reduce((s, r) => s + (r.reservas || 0), 0);
  const totSrv  = rows.reduce((s, r) => s + (r.servicios || 0), 0);
  const totCaja = rows.reduce((s, r) => s + (r.caja || 0), 0);
  const totTot  = rows.reduce((s, r) => s + (r.total || 0), 0);

  cont.innerHTML = `<div class="table-wrapper"><table>
    <thead><tr>
      <th>Fecha</th><th>Reservas</th><th>Servicios</th><th>Caja</th><th>Total</th>
    </tr></thead>
    <tbody>
      ${filas}
      <tr class="fila-total">
        <td>TOTALES</td>
        <td>${totRes}</td>
        <td>${fMoneda(totSrv)}</td>
        <td>${fMoneda(totCaja)}</td>
        <td>${fMoneda(totTot)}</td>
      </tr>
    </tbody>
  </table></div>`;
}

function _renderRptCaja(rows) {
  const cont = document.getElementById('rptContenido');
  if (!rows.length) { cont.innerHTML = _emptyState('Sin movimientos en el periodo'); return; }

  const filas = rows.map(r => `<tr>
    <td>${fFecha(r.fecha)}</td>
    <td class="muted">${_esc(r.tipo || '—')}</td>
    <td>${_esc(r.descripcion || '—')}</td>
    <td>${r.cantidad ?? 1}</td>
    <td class="text-green font-bold">${fMoneda(r.monto || 0)}</td>
  </tr>`).join('');

  const totMonto = rows.reduce((s, r) => s + (r.monto || 0), 0);

  cont.innerHTML = `<div class="table-wrapper"><table>
    <thead><tr>
      <th>Fecha</th><th>Tipo</th><th>Descripcion</th><th>Cant.</th><th>Monto</th>
    </tr></thead>
    <tbody>
      ${filas}
      <tr class="fila-total">
        <td colspan="4">TOTAL</td>
        <td>${fMoneda(totMonto)}</td>
      </tr>
    </tbody>
  </table></div>`;
}

function _renderRptHuespedes(rows) {
  const cont = document.getElementById('rptContenido');
  if (!rows.length) { cont.innerHTML = _emptyState('Sin huespedes en el periodo'); return; }

  const filas = rows.map((r, i) => `<tr>
    <td>
      <span style="font-size:11px;color:var(--text-faint);margin-right:6px">#${i+1}</span>
      ${_esc(r.nombre || '—')}
    </td>
    <td class="muted">${_esc(r.documento || '—')}</td>
    <td class="muted">${_esc(r.pais || '—')}</td>
    <td><span class="badge badge-blue">${r.visitas || 0}</span></td>
    <td class="text-green">${fMoneda(r.total_gastado || 0)}</td>
    <td class="muted">${r.noches_total || 0}</td>
  </tr>`).join('');

  cont.innerHTML = `<div class="table-wrapper"><table>
    <thead><tr>
      <th>Huesped</th><th>Documento</th><th>Pais</th>
      <th>Visitas</th><th>Total gastado</th><th>Noches</th>
    </tr></thead>
    <tbody>${filas}</tbody>
  </table></div>`;
}

/* ================================================================
   TAB 3 — USUARIOS
================================================================ */
async function cargarUsuarios() {
  const tbody = document.getElementById('tbodyUsuarios');
  tbody.innerHTML = `<tr><td colspan="8"><div class="tbl-loading"><div class="spinner"></div>Cargando...</div></td></tr>`;

  try {
    const res = await api.get('/rep/usuarios');
    const lista = res.data || res.usuarios || [];
    document.getElementById('lblUsuariosTotal').textContent = lista.length + ' usuario(s)';
    _renderTablaUsuarios(lista);
  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="8"><div class="empty-state">
      <i class="fa-solid fa-triangle-exclamation"></i>
      <p>Error: ${_esc(e.message)}</p>
    </div></td></tr>`;
  }
}

function _renderTablaUsuarios(lista) {
  const tbody = document.getElementById('tbodyUsuarios');
  if (!lista.length) {
    tbody.innerHTML = `<tr><td colspan="8"><div class="empty-state">
      <i class="fa-solid fa-user-slash"></i>
      <p>No hay usuarios registrados</p>
    </div></td></tr>`;
    return;
  }

  const ROL_BADGE = {
    ADMIN:        'badge-purple',
    RECEPCION:    'badge-blue',
    CAJA:         'badge-yellow',
    HOUSEKEEPING: 'badge-green',
  };

  tbody.innerHTML = lista.map(u => {
    const nombre  = `${_esc(u.nombres || '')} ${_esc(u.apellidos || '')}`.trim();
    const inicial = nombre.charAt(0).toUpperCase() || '?';
    const badgeCls = ROL_BADGE[u.rol] || 'badge-gray';
    const activo   = u.activo !== false && u.activo !== 0;
    const loginAt  = u.ultimoLogin ? fFecha(u.ultimoLogin) : '—';

    return `<tr>
      <td><div class="usr-avatar">${inicial}</div></td>
      <td>
        <div style="font-weight:600">${nombre || _esc(u.usuario)}</div>
        <div style="font-size:11px;color:var(--text-muted)">${_esc(u.nombres || '')} ${_esc(u.apellidos || '')}</div>
      </td>
      <td class="muted">${_esc(u.usuario || '—')}</td>
      <td><span class="badge ${badgeCls}">${_esc(u.rol)}</span></td>
      <td class="muted">${_esc(u.email || '—')}</td>
      <td>${activo
        ? `<span class="usr-status-on">Activo</span>`
        : `<span class="usr-status-off">Inactivo</span>`}</td>
      <td class="muted">${loginAt}</td>
      <td>
        <div style="display:flex;gap:6px">
          <button class="btn btn-ghost btn-sm" onclick="abrirModalUsuario(${u.idUsuario})">
            <i class="fa-solid fa-pencil"></i>
          </button>
          <button class="btn btn-sm ${activo ? 'btn-warning' : 'btn-success'}"
                  onclick="toggleUsuario(${u.idUsuario}, ${activo})"
                  title="${activo ? 'Desactivar' : 'Activar'}">
            <i class="fa-solid ${activo ? 'fa-ban' : 'fa-check'}"></i>
          </button>
        </div>
      </td>
    </tr>`;
  }).join('');
}

/* ----------------------------------------------------------------
   Modal usuarios
---------------------------------------------------------------- */
function abrirModalUsuario(id = null) {
  _usrEditId = id;

  // SUPERADMIN solo aparece si quien esta logueado lo es. Al admin del hotel
  // ni se le muestra: ese rol es de SistemasVIP. (El servidor lo rechaza
  // igual si alguien manda el rol a mano.)
  const yo = JSON.parse(localStorage.getItem('hv_usuario') || '{}');
  const combo = document.getElementById('usrRol');
  const yaEsta = [...combo.options].some(o => o.value === 'SUPERADMIN');
  if ((yo.rol || '').toUpperCase() === 'SUPERADMIN' && !yaEsta) {
    const op = document.createElement('option');
    op.value = 'SUPERADMIN';
    op.textContent = 'SUPERADMIN — SistemasVIP, configura el sistema';
    combo.insertBefore(op, combo.firstChild);
  }

  const titulo     = document.getElementById('modalUsrTitulo');
  const passSection = document.getElementById('usrPassSection');

  // Limpiar campos
  ['usrNombres','usrApellidos','usrLogin','usrEmail','usrPass','usrPass2'].forEach(fld => {
    const el = document.getElementById(fld);
    if (el) el.value = '';
  });
  document.getElementById('usrRol').value    = 'RECEPCION';
  document.getElementById('usrActivo').checked = true;

  if (id) {
    titulo.textContent = 'Editar Usuario';
    // La contrasena es opcional al editar — cambiar label
    passSection.querySelector('label') && (passSection.querySelector('label').textContent = 'Nueva contrasena (dejar en blanco para no cambiar)');
    _cargarDatosUsuario(id);
  } else {
    titulo.textContent = 'Nuevo Usuario';
    if (passSection.querySelector('label'))
      passSection.querySelector('label').textContent = 'Contrasena';
  }

  document.getElementById('modalUsuario').classList.add('open');
}

async function _cargarDatosUsuario(id) {
  try {
    const res = await api.get('/rep/usuarios/' + id);
    const u   = res.data || res.usuario || {};
    document.getElementById('usrNombres').value   = u.nombres   || '';
    document.getElementById('usrApellidos').value = u.apellidos || '';
    document.getElementById('usrLogin').value     = u.usuario   || '';
    document.getElementById('usrEmail').value     = u.email     || '';
    document.getElementById('usrRol').value       = u.rol       || 'RECEPCION';
    document.getElementById('usrActivo').checked  = u.activo !== false && u.activo !== 0;
  } catch (e) {
    toast('No se pudo cargar el usuario: ' + e.message, 'error');
  }
}

function cerrarModalUsuario() {
  document.getElementById('modalUsuario').classList.remove('open');
  _usrEditId = null;
}

async function guardarUsuario() {
  const nombres   = document.getElementById('usrNombres').value.trim();
  const apellidos = document.getElementById('usrApellidos').value.trim();
  const usuario   = document.getElementById('usrLogin').value.trim();
  const email     = document.getElementById('usrEmail').value.trim();
  const rol       = document.getElementById('usrRol').value;
  const activo    = document.getElementById('usrActivo').checked ? 1 : 0;
  const pass      = document.getElementById('usrPass').value;
  const pass2     = document.getElementById('usrPass2').value;

  // Validaciones
  if (!nombres)  { toast('Ingrese los nombres', 'warning'); return; }
  if (!usuario)  { toast('Ingrese el nombre de usuario', 'warning'); return; }
  if (!_usrEditId) {
    if (!pass)   { toast('Ingrese una contrasena', 'warning'); return; }
  }
  if (pass && pass !== pass2) { toast('Las contrasenas no coinciden', 'warning'); return; }
  if (pass && pass.length < 6) { toast('La contrasena debe tener al menos 6 caracteres', 'warning'); return; }

  const payload = { nombres, apellidos, usuario, email, rol, activo };
  if (pass) payload.password = pass;

  const btn = document.getElementById('btnGuardarUsr');
  btn.disabled = true;

  try {
    if (_usrEditId) {
      await api.put('/rep/usuarios/' + _usrEditId, payload);
      toast('Usuario actualizado', 'success');
    } else {
      await api.post('/rep/usuarios', payload);
      toast('Usuario creado', 'success');
    }
    cerrarModalUsuario();
    cargarUsuarios();
  } catch (e) {
    toast('Error: ' + e.message, 'error');
  } finally {
    btn.disabled = false;
  }
}

async function toggleUsuario(id, estaActivo) {
  const nuevoEstado = estaActivo ? 0 : 1;
  const accion      = estaActivo ? 'desactivar' : 'activar';
  try {
    await api.patch('/rep/usuarios/' + id, { activo: nuevoEstado });
    toast(`Usuario ${accion === 'activar' ? 'activado' : 'desactivado'}`, 'success');
    cargarUsuarios();
  } catch (e) {
    toast('Error al ' + accion + ': ' + e.message, 'error');
  }
}

/* ================================================================
   TAB 4 — HUESPEDES
================================================================ */
async function cargarHuespedes(page = 1) {
  _hspPage = page;
  const q     = document.getElementById('hspSearch').value.trim();
  const tbody = document.getElementById('tbodyHuespedes');
  tbody.innerHTML = `<tr><td colspan="8"><div class="tbl-loading"><div class="spinner"></div>Cargando...</div></td></tr>`;

  try {
    const params = `?q=${encodeURIComponent(q)}&page=${page}&limit=20`;
    const res    = await api.get('/huespedes' + params);
    const lista  = res.data || [];
    const total  = res.total || lista.length;
    const pages  = res.pages || Math.ceil(total / 20);

    document.getElementById('lblHspTotal').textContent = `${total} huesped(es) encontrado(s)`;
    _renderTablaHuespedes(lista);
    _renderPaginacion(page, pages);
  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="8"><div class="empty-state">
      <i class="fa-solid fa-triangle-exclamation"></i>
      <p>Error: ${_esc(e.message)}</p>
    </div></td></tr>`;
  }
}

function adminBuscarHuespedes() {
  clearTimeout(_hspTimer);
  _hspTimer = setTimeout(() => cargarHuespedes(1), 320);
}

function _renderTablaHuespedes(lista) {
  const tbody = document.getElementById('tbodyHuespedes');
  if (!lista.length) {
    tbody.innerHTML = `<tr><td colspan="8"><div class="empty-state">
      <i class="fa-solid fa-user-slash"></i>
      <p>No se encontraron huespedes</p>
    </div></td></tr>`;
    return;
  }

  tbody.innerHTML = lista.map(h => {
    const nombre   = `${_esc(h.nombres || '')} ${_esc(h.apellidos || '')}`.trim() ||
                     _esc(h.razonSocial || h.nombre || '—');
    const lastIn   = h.ultimoCheckin ? fFecha(h.ultimoCheckin) : '—';
    return `<tr>
      <td><strong>${nombre}</strong></td>
      <td class="muted">${_esc(h.tipoDoc || '')} ${_esc(h.numeroDoc || h.documento || '—')}</td>
      <td class="muted">${_esc(h.email || '—')}</td>
      <td class="muted">${_esc(h.telefono || h.whatsapp || '—')}</td>
      <td class="muted">${_esc(h.pais || '—')}</td>
      <td><span class="badge badge-blue">${h.estancias || h.visitas || 0}</span></td>
      <td class="muted">${lastIn}</td>
      <td>
        <a href="huespedes.html" class="btn btn-ghost btn-sm">
          <i class="fa-solid fa-arrow-up-right-from-square"></i> Ver
        </a>
      </td>
    </tr>`;
  }).join('');
}

function _renderPaginacion(pagActual, totalPages) {
  const cont = document.getElementById('hspPag');
  if (totalPages <= 1) { cont.innerHTML = ''; return; }

  let html = '';
  if (pagActual > 1) {
    html += `<button class="btn btn-ghost btn-sm" onclick="cargarHuespedes(${pagActual - 1})">
      <i class="fa-solid fa-chevron-left"></i> Anterior</button>`;
  }
  html += `<span style="padding:4px 12px;font-size:12px;color:var(--text-muted)">
    Pag. ${pagActual} / ${totalPages}</span>`;
  if (pagActual < totalPages) {
    html += `<button class="btn btn-ghost btn-sm" onclick="cargarHuespedes(${pagActual + 1})">
      Siguiente <i class="fa-solid fa-chevron-right"></i></button>`;
  }
  cont.innerHTML = html;
}

/* ================================================================
   HELPERS
================================================================ */
function _emptyState(msg) {
  return `<div class="empty-state">
    <i class="fa-solid fa-inbox"></i>
    <p>${_esc(msg)}</p>
  </div>`;
}

function _esc(str) {
  if (str == null) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
