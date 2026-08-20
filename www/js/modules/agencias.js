// agencias.js — Modulo Agencias HotelVIP
// SistemasVIP Cusco 2026
// Agencias asociadas: CRUD + tarifario, cuenta corriente
// (reservas/adelantos/ajustes) y liquidaciones con abonos.

'use strict';

let _agencias   = [];
let _agEditId   = null;
let _tiposTar   = [];     // tarifario en edicion
let _ctaId      = null;   // agencia activa en tab cuenta
let _liqAgId    = null;   // agencia activa en tab liquidaciones
let _liqPreview = null;
let _detLiqId   = null;
let _detLiqData = null;

/* ================================================================
   INIT
================================================================ */
function agenciasInit() {
  _initTabs();
  cargarAgencias();
}

function _initTabs() {
  const tabs = document.querySelectorAll('#agTabs .tab-btn');
  tabs.forEach(btn => {
    btn.addEventListener('click', () => {
      const tab = btn.dataset.tab;
      tabs.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
      document.getElementById('panel-' + tab).classList.add('active');
      _updateActions(tab);
      if (tab === 'cuenta')        { _fillSelect('selAgenciaCuenta', _ctaId); cargarCuenta(); }
      if (tab === 'liquidaciones') { _fillSelect('selAgenciaLiq', _liqAgId);  cargarLiquidaciones(); }
    });
  });
  _updateActions('agencias');
}

function _updateActions(tab) {
  const cont = document.getElementById('agPageActions');
  cont.innerHTML = (tab === 'agencias')
    ? `<button class="btn btn-primary" onclick="abrirModalAgencia()">
         <i class="fa-solid fa-plus"></i> Nueva Agencia</button>`
    : '';
}

function abrirModal(id)  { document.getElementById(id).classList.add('open'); }
function cerrarModal(id) { document.getElementById(id).classList.remove('open'); }

function _fillSelect(selId, keep) {
  const sel = document.getElementById(selId);
  sel.innerHTML = '<option value="">-- Seleccionar agencia --</option>' +
    _agencias.filter(a => a.activo === 1).map(a =>
      `<option value="${a.idAgencia}">${esc(a.nombre)}</option>`).join('');
  if (keep) sel.value = keep;
}

/* ================================================================
   TAB 1 — AGENCIAS (CRUD + tarifario)
================================================================ */
async function cargarAgencias() {
  const tbody = document.getElementById('tbodyAgencias');
  tbody.innerHTML = `<tr><td colspan="8"><div class="tbl-loading"><div class="spinner"></div>Cargando...</div></td></tr>`;
  try {
    const res = await api.get('/agencias');
    _agencias = res.data || [];
    if (!_agencias.length) {
      tbody.innerHTML = `<tr><td colspan="8"><div class="empty-state">
        <i class="fa-solid fa-handshake"></i><p>Sin agencias registradas. Crea la primera.</p></div></td></tr>`;
      return;
    }
    tbody.innerHTML = _agencias.map(a => `
      <tr>
        <td><strong>${esc(a.nombre)}</strong></td>
        <td class="muted">${esc(a.ruc || '—')}</td>
        <td class="muted">${esc(a.contacto || '—')}</td>
        <td class="muted">${esc(a.telefono || '—')}</td>
        <td>${a.tipoLiquidacion === 'COMISION'
            ? `<span class="badge badge-purple">Comision ${a.comisionPct}%</span>`
            : `<span class="badge badge-blue">Tarifa neta</span>`}</td>
        <td><span class="badge ${a.reservasPend > 0 ? 'badge-yellow' : 'badge-gray'}">${a.reservasPend}</span></td>
        <td>${a.activo === 1
            ? '<span class="badge badge-green">Activa</span>'
            : '<span class="badge badge-gray">Inactiva</span>'}</td>
        <td>
          <div style="display:flex;gap:6px">
            <button class="btn btn-ghost btn-sm" onclick="abrirModalAgencia(${a.idAgencia})" title="Editar">
              <i class="fa-solid fa-pencil"></i></button>
            <button class="btn btn-ghost btn-sm" onclick="irACuenta(${a.idAgencia})" title="Cuenta corriente">
              <i class="fa-solid fa-file-invoice-dollar"></i></button>
          </div>
        </td>
      </tr>`).join('');
  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="8"><div class="empty-state">
      <i class="fa-solid fa-triangle-exclamation"></i><p>Error: ${esc(e.message)}</p></div></td></tr>`;
  }
}

function irACuenta(id) {
  _ctaId = id;
  document.querySelector('#agTabs .tab-btn[data-tab="cuenta"]').click();
}

function onTipoLiqChange() {
  const esCom = document.getElementById('agTipoLiq').value === 'COMISION';
  document.getElementById('grpComision').style.display = esCom ? '' : 'none';
  document.getElementById('agTarifarioWrap').style.display = esCom ? 'none' : '';
}

async function abrirModalAgencia(id = null) {
  _agEditId = id;
  document.getElementById('modalAgTitulo').textContent = id ? 'Editar Agencia' : 'Nueva Agencia';
  ['agNombre','agRuc','agContacto','agTelefono','agEmail','agDireccion','agNotas'].forEach(f => {
    document.getElementById(f).value = '';
  });
  document.getElementById('agTipoLiq').value = 'NETO';
  document.getElementById('agComisionPct').value = 10;
  document.getElementById('agCredito').value = 0;
  document.getElementById('agActivo').checked = true;

  try {
    if (id) {
      const res = await api.get('/agencias/' + id);
      const a = res.data;
      document.getElementById('agNombre').value      = a.nombre || '';
      document.getElementById('agRuc').value         = a.ruc || '';
      document.getElementById('agContacto').value    = a.contacto || '';
      document.getElementById('agTelefono').value    = a.telefono || '';
      document.getElementById('agEmail').value       = a.email || '';
      document.getElementById('agDireccion').value   = a.direccion || '';
      document.getElementById('agTipoLiq').value     = a.tipoLiquidacion || 'NETO';
      document.getElementById('agComisionPct').value = a.comisionPct || 0;
      document.getElementById('agCredito').value     = a.creditoMaximo || 0;
      document.getElementById('agNotas').value       = a.notas || '';
      document.getElementById('agActivo').checked    = a.activo === 1;
      const tar = await api.get('/agencias/' + id + '/tarifas');
      _tiposTar = tar.data || [];
    } else {
      // Tarifario base con tipos activos (usa el endpoint sobre id 0 = solo tipos)
      const tar = await api.get('/agencias/0/tarifas');
      _tiposTar = (tar.data || []).map(t => ({ ...t, tarifaNoche: null }));
    }
    _renderTarifas();
    onTipoLiqChange();
    abrirModal('modalAgencia');
    document.getElementById('agNombre').focus();
  } catch (e) {
    toast('Error al abrir la agencia: ' + e.message, 'error');
  }
}

function _renderTarifas() {
  document.getElementById('tbodyTarifas').innerHTML = _tiposTar.map(t => `
    <tr>
      <td>${esc(t.nombre)}</td>
      <td class="muted">${fMoneda(t.precioBase)}</td>
      <td><input type="number" step="0.01" min="0" class="form-control tarifa-input"
                 id="tar_${t.idTipo}" value="${t.tarifaNoche ?? ''}" placeholder="—"></td>
    </tr>`).join('');
}

async function guardarAgencia() {
  const nombre = document.getElementById('agNombre').value.trim();
  if (!nombre) { toast('El nombre es obligatorio', 'warning'); return; }

  const payload = {
    nombre,
    ruc:             document.getElementById('agRuc').value.trim(),
    contacto:        document.getElementById('agContacto').value.trim(),
    telefono:        document.getElementById('agTelefono').value.trim(),
    email:           document.getElementById('agEmail').value.trim(),
    direccion:       document.getElementById('agDireccion').value.trim(),
    tipoLiquidacion: document.getElementById('agTipoLiq').value,
    comisionPct:     parseFloat(document.getElementById('agComisionPct').value) || 0,
    creditoMaximo:   parseFloat(document.getElementById('agCredito').value) || 0,
    notas:           document.getElementById('agNotas').value.trim(),
    activo:          document.getElementById('agActivo').checked ? 1 : 0,
  };

  const btn = document.getElementById('btnGuardarAg');
  btn.disabled = true;
  try {
    if (_agEditId) {
      await api.put('/agencias/' + _agEditId, payload);
    } else {
      await api.post('/agencias', payload);
      // Recuperar el id recien creado para poder guardar el tarifario
      const lista = await api.get('/agencias');
      const nueva = (lista.data || []).find(a => a.nombre === nombre);
      _agEditId = nueva ? nueva.idAgencia : null;
    }

    // Tarifario (solo modelo NETO)
    if (_agEditId && payload.tipoLiquidacion === 'NETO') {
      const tarifas = _tiposTar.map(t => {
        const v = document.getElementById('tar_' + t.idTipo).value;
        return { idTipo: t.idTipo, tarifaNoche: v === '' ? -1 : parseFloat(v) };
      });
      await api.post('/agencias/' + _agEditId + '/tarifas', { tarifas });
    }

    toast('Agencia guardada', 'success');
    cerrarModal('modalAgencia');
    cargarAgencias();
  } catch (e) {
    toast('Error: ' + e.message, 'error');
  } finally {
    btn.disabled = false;
  }
}

/* ================================================================
   TAB 2 — CUENTA CORRIENTE
================================================================ */
function _agSel() {
  const v = document.getElementById('selAgenciaCuenta').value;
  return v ? parseInt(v) : null;
}

async function cargarCuenta() {
  _ctaId = _agSel();
  const res  = document.getElementById('ctaResumen');
  const tb1  = document.getElementById('tbodyPendientes');
  const tb2  = document.getElementById('tbodyAdelantos');
  const tb3  = document.getElementById('tbodyAjustes');
  if (!_ctaId) {
    res.innerHTML = '';
    [tb1, tb2, tb3].forEach(t => t.innerHTML =
      `<tr><td colspan="6"><div class="empty-state"><p>Selecciona una agencia</p></div></td></tr>`);
    return;
  }
  try {
    const r = await api.get('/agencias/' + _ctaId + '/estado-cuenta');
    const d = r.data;
    const s = d.resumen;
    res.innerHTML = `
      <div class="resumen-card"><div class="lbl">Saldo anterior</div><div class="val">${fMoneda(s.saldoAnterior)}</div></div>
      <div class="resumen-card"><div class="lbl">Reservas por liquidar</div><div class="val">${fMoneda(s.totalReservas)}</div></div>
      <div class="resumen-card"><div class="lbl">Ajustes</div><div class="val">${fMoneda(s.totalAjustes)}</div></div>
      <div class="resumen-card"><div class="lbl">Adelantos</div><div class="val text-green">${fMoneda(s.totalAdelantos)}</div></div>
      <div class="resumen-card"><div class="lbl">Saldo estimado</div>
        <div class="val ${s.saldoEstimado > 0 ? 'text-yellow' : 'text-green'}">${fMoneda(s.saldoEstimado)}</div></div>`;

    const pend = (d.pendientes || []);
    tb1.innerHTML = pend.length ? pend.map(p => `
      <tr><td>${fFecha(p.fecha)}</td><td>${esc(p.concepto)}</td>
      <td>${p.noches || '—'}</td><td class="font-bold">${fMoneda(p.importe)}</td></tr>`).join('')
      : `<tr><td colspan="4"><div class="empty-state"><p>Sin movimientos pendientes</p></div></td></tr>`;

    const ade = (d.adelantos || []);
    tb2.innerHTML = ade.length ? ade.map(a => `
      <tr><td>${fFecha(a.fecha)}</td>
      <td class="text-green font-bold">${a.moneda === 'USD' ? '$' : 'S/'} ${Number(a.monto).toFixed(2)}</td>
      <td class="muted">${esc(a.metodoPago || '—')}</td>
      <td class="muted">${esc(a.numeroOperacion || '—')}</td>
      <td class="muted">${esc(a.observaciones || '—')}</td>
      <td><button class="btn btn-ghost btn-sm" onclick="anularAdelanto(${a.idAdelanto})" title="Anular">
        <i class="fa-solid fa-ban"></i></button></td></tr>`).join('')
      : `<tr><td colspan="6"><div class="empty-state"><p>Sin adelantos pendientes</p></div></td></tr>`;

    const aju = (d.ajustes || []);
    tb3.innerHTML = aju.length ? aju.map(a => `
      <tr><td>${fFecha(a.fecha)}</td><td>${esc(a.descripcion)}</td>
      <td>${a.tipo === 'ABONO'
          ? '<span class="badge badge-green">Abono</span>'
          : '<span class="badge badge-yellow">Cargo</span>'}</td>
      <td class="font-bold">${fMoneda(a.monto)}</td>
      <td><button class="btn btn-ghost btn-sm" onclick="anularAjuste(${a.idAjuste})" title="Anular">
        <i class="fa-solid fa-ban"></i></button></td></tr>`).join('')
      : `<tr><td colspan="5"><div class="empty-state"><p>Sin ajustes pendientes</p></div></td></tr>`;
  } catch (e) {
    toast('Error al cargar la cuenta: ' + e.message, 'error');
  }
}

/* ── Asignar reserva ── */
async function abrirModalAsignar() {
  if (!_ctaId) { toast('Selecciona una agencia primero', 'warning'); return; }
  const tbody = document.getElementById('tbodyReservasSin');
  tbody.innerHTML = `<tr><td colspan="7"><div class="tbl-loading"><div class="spinner"></div>Cargando...</div></td></tr>`;
  abrirModal('modalAsignar');
  try {
    const r = await api.get('/agencias/reservas-sin-agencia');
    const lista = r.data || [];
    tbody.innerHTML = lista.length ? lista.map(x => `
      <tr>
        <td><strong>${esc(x.codigo)}</strong></td>
        <td>${esc(x.huesped || '—')}</td>
        <td class="muted">${esc(x.habitacion)} (${esc(x.tipo)})</td>
        <td class="muted">${fFecha(x.fechaEntrada)}</td>
        <td>${x.noches}</td>
        <td>${fMoneda(x.total)}</td>
        <td><button class="btn btn-primary btn-sm" onclick="asignarReserva(${x.idReserva})">Asignar</button></td>
      </tr>`).join('')
      : `<tr><td colspan="7"><div class="empty-state"><p>No hay reservas sin agencia en los ultimos 90 dias</p></div></td></tr>`;
  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="7"><div class="empty-state"><p>Error: ${esc(e.message)}</p></div></td></tr>`;
  }
}

async function asignarReserva(idReserva) {
  try {
    await api.put('/agencias/reserva/' + idReserva + '/asignar', { idAgencia: _ctaId });
    toast('Reserva asignada a la agencia', 'success');
    cerrarModal('modalAsignar');
    cargarCuenta();
  } catch (e) {
    toast('Error: ' + e.message, 'error');
  }
}

/* ── Adelantos ── */
function abrirModalAdelanto() {
  if (!_ctaId) { toast('Selecciona una agencia primero', 'warning'); return; }
  document.getElementById('adFecha').value = _hoy();
  document.getElementById('adMonto').value = '';
  document.getElementById('adOperacion').value = '';
  document.getElementById('adObs').value = '';
  abrirModal('modalAdelanto');
}

async function guardarAdelanto() {
  const monto = parseFloat(document.getElementById('adMonto').value);
  if (!monto || monto <= 0) { toast('Ingresa un monto valido', 'warning'); return; }
  try {
    await api.post('/agencias/' + _ctaId + '/adelantos', {
      fecha:           document.getElementById('adFecha').value,
      monto,
      moneda:          document.getElementById('adMoneda').value,
      tipoCambio:      parseFloat(document.getElementById('adTC').value) || 1,
      metodoPago:      document.getElementById('adMetodo').value,
      numeroOperacion: document.getElementById('adOperacion').value.trim(),
      observaciones:   document.getElementById('adObs').value.trim(),
    });
    toast('Adelanto registrado', 'success');
    cerrarModal('modalAdelanto');
    cargarCuenta();
  } catch (e) {
    toast('Error: ' + e.message, 'error');
  }
}

async function anularAdelanto(id) {
  if (!confirm('¿Anular este adelanto?')) return;
  try {
    await api.put('/agencias/adelanto/' + id + '/anular', {});
    toast('Adelanto anulado', 'success');
    cargarCuenta();
  } catch (e) { toast('Error: ' + e.message, 'error'); }
}

/* ── Ajustes ── */
function abrirModalAjuste() {
  if (!_ctaId) { toast('Selecciona una agencia primero', 'warning'); return; }
  document.getElementById('ajFecha').value = _hoy();
  document.getElementById('ajDesc').value = '';
  document.getElementById('ajMonto').value = '';
  abrirModal('modalAjuste');
}

async function guardarAjuste() {
  const desc  = document.getElementById('ajDesc').value.trim();
  const monto = parseFloat(document.getElementById('ajMonto').value);
  if (!desc)  { toast('Ingresa la descripcion', 'warning'); return; }
  if (!monto || monto <= 0) { toast('Ingresa un monto valido', 'warning'); return; }
  try {
    await api.post('/agencias/' + _ctaId + '/ajustes', {
      fecha: document.getElementById('ajFecha').value,
      tipo:  document.getElementById('ajTipo').value,
      descripcion: desc,
      monto,
    });
    toast('Ajuste registrado', 'success');
    cerrarModal('modalAjuste');
    cargarCuenta();
  } catch (e) { toast('Error: ' + e.message, 'error'); }
}

async function anularAjuste(id) {
  if (!confirm('¿Anular este ajuste?')) return;
  try {
    await api.put('/agencias/ajuste/' + id + '/anular', {});
    toast('Ajuste anulado', 'success');
    cargarCuenta();
  } catch (e) { toast('Error: ' + e.message, 'error'); }
}

/* ── Cierre de liquidacion ── */
function abrirModalCerrar() {
  if (!_ctaId) { toast('Selecciona una agencia primero', 'warning'); return; }
  const hoy = new Date();
  document.getElementById('liqDesde').value = `${hoy.getFullYear()}-${String(hoy.getMonth()+1).padStart(2,'0')}-01`;
  document.getElementById('liqHasta').value = _hoy();
  document.getElementById('liqPagado').value = 0;
  document.getElementById('liqObs').value = '';
  abrirModal('modalCerrar');
  previewLiq();
}

async function previewLiq() {
  const desde = document.getElementById('liqDesde').value;
  const hasta = document.getElementById('liqHasta').value;
  if (!desde || !hasta) return;
  const tbody = document.getElementById('tbodyLiqPreview');
  tbody.innerHTML = `<tr><td colspan="4"><div class="tbl-loading"><div class="spinner"></div>Calculando...</div></td></tr>`;
  try {
    const r = await api.get(`/agencias/${_ctaId}/liquidacion/preview?desde=${desde}&hasta=${hasta}`);
    _liqPreview = r.data;
    const det = _liqPreview.detalle || [];
    tbody.innerHTML = det.length ? det.map(p => `
      <tr><td>${fFecha(p.fecha)}</td><td>${esc(p.concepto)}</td>
      <td>${p.noches || '—'}</td><td>${fMoneda(p.importe)}</td></tr>`).join('')
      : `<tr><td colspan="4"><div class="empty-state"><p>Sin movimientos en el periodo</p></div></td></tr>`;
    previewTotales();
  } catch (e) {
    _liqPreview = null;
    tbody.innerHTML = `<tr><td colspan="4"><div class="empty-state"><p>${esc(e.message)}</p></div></td></tr>`;
    document.getElementById('liqTotales').innerHTML = '';
  }
}

function previewTotales() {
  if (!_liqPreview) return;
  const p = _liqPreview;
  const pagado = parseFloat(document.getElementById('liqPagado').value) || 0;
  const saldo  = p.montoBruto - p.totalAdelantos - pagado;
  document.getElementById('liqTotales').innerHTML = `
    <div class="fila-tot"><span>Saldo anterior</span><span>${fMoneda(p.saldoAnterior)}</span></div>
    <div class="fila-tot"><span>Reservas del periodo</span><span>${fMoneda(p.totalReservas)}</span></div>
    <div class="fila-tot"><span>Ajustes</span><span>${fMoneda(p.totalAjustes)}</span></div>
    <div class="fila-tot"><span><strong>Monto bruto</strong></span><span><strong>${fMoneda(p.montoBruto)}</strong></span></div>
    <div class="fila-tot"><span>(-) Adelantos</span><span>${fMoneda(p.totalAdelantos)}</span></div>
    <div class="fila-tot"><span>(-) Pago al cierre</span><span>${fMoneda(pagado)}</span></div>
    <div class="fila-tot grande"><span>SALDO FINAL</span>
      <span class="${saldo > 0 ? 'text-yellow' : 'text-green'}">${fMoneda(saldo)}</span></div>`;
}

async function confirmarCierre() {
  if (!_liqPreview) { toast('No hay nada para liquidar', 'warning'); return; }
  if (!confirm('¿Cerrar la liquidacion del periodo? Las reservas incluidas quedan selladas.')) return;
  const btn = document.getElementById('btnCerrarLiq');
  btn.disabled = true;
  try {
    const r = await api.post('/agencias/' + _ctaId + '/liquidacion/cerrar', {
      desde:        document.getElementById('liqDesde').value,
      hasta:        document.getElementById('liqHasta').value,
      montoPagado:  parseFloat(document.getElementById('liqPagado').value) || 0,
      observaciones: document.getElementById('liqObs').value.trim(),
    });
    toast(`Liquidacion #${r.data.numero} cerrada (${r.data.estadoPago})`, 'success');
    cerrarModal('modalCerrar');
    cargarCuenta();
  } catch (e) {
    toast('Error: ' + e.message, 'error');
  } finally {
    btn.disabled = false;
  }
}

/* ================================================================
   TAB 3 — LIQUIDACIONES
================================================================ */
async function cargarLiquidaciones() {
  _liqAgId = document.getElementById('selAgenciaLiq').value || null;
  const tbody = document.getElementById('tbodyLiquidaciones');
  if (!_liqAgId) {
    tbody.innerHTML = `<tr><td colspan="9"><div class="empty-state"><p>Selecciona una agencia</p></div></td></tr>`;
    return;
  }
  tbody.innerHTML = `<tr><td colspan="9"><div class="tbl-loading"><div class="spinner"></div>Cargando...</div></td></tr>`;
  try {
    const r = await api.get('/agencias/' + _liqAgId + '/liquidaciones');
    const lista = r.data || [];
    const ESTADO = { PAGADO: 'badge-green', PARCIAL: 'badge-yellow', PENDIENTE: 'badge-red' };
    tbody.innerHTML = lista.length ? lista.map(l => `
      <tr style="${l.anulada ? 'opacity:.45' : ''}">
        <td><strong>#${l.numero}</strong></td>
        <td class="muted">${fFecha(l.fechaDesde)} → ${fFecha(l.fechaHasta)}</td>
        <td>${fMoneda(l.montoBruto)}</td>
        <td>${fMoneda(l.totalAdelantos)}</td>
        <td>${fMoneda(l.montoPagado)}</td>
        <td>${fMoneda(l.totalAbonos)}</td>
        <td class="font-bold">${fMoneda(l.saldoActual)}</td>
        <td>${l.anulada
            ? '<span class="badge badge-gray">ANULADA</span>'
            : `<span class="badge ${ESTADO[l.estadoPago] || 'badge-gray'}">${l.estadoPago}</span>`}</td>
        <td><button class="btn btn-ghost btn-sm" onclick="verLiquidacion(${l.idLiquidacion})">
          <i class="fa-solid fa-eye"></i></button></td>
      </tr>`).join('')
      : `<tr><td colspan="9"><div class="empty-state"><p>Sin liquidaciones</p></div></td></tr>`;
  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="9"><div class="empty-state"><p>Error: ${esc(e.message)}</p></div></td></tr>`;
  }
}

async function verLiquidacion(id) {
  _detLiqId = id;
  try {
    const r = await api.get('/agencias/liquidacion/' + id);
    const d = r.data;
    _detLiqData = d;
    document.getElementById('detLiqTitulo').textContent =
      `Liquidacion #${d.numero} — ${d.agencia}`;
    document.getElementById('btnAnularLiq').style.display = d.anulada ? 'none' : '';

    const det = (d.detalle || []).map(x => `
      <tr><td>${fFecha(x.fecha)}</td><td>${esc(x.concepto)}</td>
      <td>${x.noches || '—'}</td><td>${fMoneda(x.importe)}</td></tr>`).join('');
    const abo = (d.abonos || []).map(b => `
      <tr><td>${fFecha(b.fecha)}</td><td class="text-green font-bold">${fMoneda(b.monto)}</td>
      <td class="muted">${esc(b.metodoPago || '—')}</td>
      <td class="muted">${esc(b.numeroOperacion || '—')}</td></tr>`).join('');

    document.getElementById('detLiqBody').innerHTML = `
      <p style="font-size:12px;color:var(--text-muted);margin-bottom:10px">
        Periodo ${fFecha(d.fechaDesde)} → ${fFecha(d.fechaHasta)} ·
        Modelo: ${d.tipoLiquidacion === 'COMISION' ? 'Comision %' : 'Tarifa neta'} ·
        Estado: <strong>${d.anulada ? 'ANULADA' : d.estadoPago}</strong></p>
      <div class="table-wrapper" style="max-height:220px;overflow-y:auto"><table class="tbl-mini">
        <thead><tr><th>Fecha</th><th>Concepto</th><th>Noches</th><th>Importe</th></tr></thead>
        <tbody>${det || '<tr><td colspan="4">—</td></tr>'}</tbody></table></div>
      <div class="modal-liq-tot">
        <div class="fila-tot"><span>Saldo anterior</span><span>${fMoneda(d.saldoAnterior)}</span></div>
        <div class="fila-tot"><span>Reservas</span><span>${fMoneda(d.totalReservas)}</span></div>
        <div class="fila-tot"><span>Ajustes</span><span>${fMoneda(d.totalAjustes)}</span></div>
        <div class="fila-tot"><span><strong>Monto bruto</strong></span><span><strong>${fMoneda(d.montoBruto)}</strong></span></div>
        <div class="fila-tot"><span>(-) Adelantos</span><span>${fMoneda(d.totalAdelantos)}</span></div>
        <div class="fila-tot"><span>(-) Pagado al cierre</span><span>${fMoneda(d.montoPagado)}</span></div>
        <div class="fila-tot grande"><span>SALDO FINAL</span><span>${fMoneda(d.saldoFinal)}</span></div>
      </div>
      <h3 style="font-size:13px;margin:14px 0 8px">Abonos posteriores</h3>
      <div class="table-wrapper"><table class="tbl-mini">
        <thead><tr><th>Fecha</th><th>Monto</th><th>Metodo</th><th>Operacion</th></tr></thead>
        <tbody>${abo || '<tr><td colspan="4"><div class="empty-state" style="padding:8px"><p>Sin abonos</p></div></td></tr>'}</tbody>
      </table></div>`;
    abrirModal('modalDetalleLiq');
  } catch (e) {
    toast('Error: ' + e.message, 'error');
  }
}

async function registrarAbono() {
  const monto = parseFloat(prompt('Monto del abono:'));
  if (!monto || monto <= 0) return;
  const metodo = prompt('Metodo de pago (Efectivo/Transferencia/Yape...):', 'Efectivo') || '';
  try {
    await api.post('/agencias/liquidacion/' + _detLiqId + '/abono', {
      monto, metodoPago: metodo, fecha: _hoy(),
    });
    toast('Abono registrado', 'success');
    verLiquidacion(_detLiqId);
    cargarLiquidaciones();
  } catch (e) { toast('Error: ' + e.message, 'error'); }
}

async function anularLiquidacion() {
  if (!confirm('¿Anular la liquidacion? Las reservas, adelantos y ajustes vuelven a quedar pendientes.')) return;
  try {
    await api.put('/agencias/liquidacion/' + _detLiqId + '/anular', {});
    toast('Liquidacion anulada', 'success');
    cerrarModal('modalDetalleLiq');
    cargarLiquidaciones();
    cargarCuenta();
  } catch (e) { toast('Error: ' + e.message, 'error'); }
}

/* ================================================================
   HELPERS
================================================================ */
function _hoy() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
}

function esc(str) {
  if (str == null) return '';
  return String(str)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}
