// layout.js - HotelVIP Frontend Layout Core
// SistemasVIP Cusco 2026
// Incluir en TODAS las paginas (excepto login.html)

const MODULES = {
  modulos:        { title: 'Modulos del sistema', icon: 'fa-grip' },
  recepcion:      { title: 'Recepcion',       icon: 'fa-door-open' },
  reservas:       { title: 'Reservas',        icon: 'fa-calendar-days' },
  huespedes:      { title: 'Huespedes',       icon: 'fa-users' },
  caja:           { title: 'Caja',            icon: 'fa-cash-register' },
  housekeeping:   { title: 'Housekeeping',    icon: 'fa-broom' },
  servicios:      { title: 'Servicios',       icon: 'fa-concierge-bell' },
  channel:        { title: 'Canales',         icon: 'fa-satellite-dish' },
  facturacion:    { title: 'Facturacion',     icon: 'fa-file-invoice' },
  sincronizacion: { title: 'Sincronizacion',  icon: 'fa-rotate' },
  admin:          { title: 'Administracion',  icon: 'fa-chart-line' },
  configuracion:  { title: 'Configuracion',   icon: 'fa-gear' },
};

function buildSidebar() {
  return `
<nav class="sidebar">
  <div class="sidebar-brand">
    <div class="brand-icon">&#x1F3E8;</div>
    <div>
      <div class="brand-name">Hotel<span style="color:var(--accent)">VIP</span></div>
      <div class="brand-sub">SistemasVIP</div>
    </div>
  </div>

  <div class="nav-section">
    <a href="modulos.html"        class="nav-item" data-module="modulos"><i class="fa-solid fa-grip"></i>Todos los m&#xF3;dulos</a>
  </div>

  <div class="nav-section">
    <div class="nav-section-label">Operaciones</div>
    <a href="recepcion.html"      class="nav-item" data-module="recepcion"><i class="fa-solid fa-door-open"></i>Recepci&#xF3;n</a>
    <a href="reservas.html"       class="nav-item" data-module="reservas"><i class="fa-solid fa-calendar-days"></i>Reservas</a>
    <a href="huespedes.html"      class="nav-item" data-module="huespedes"><i class="fa-solid fa-users"></i>Hu&#xE9;spedes</a>
    <a href="caja.html"           class="nav-item" data-module="caja"><i class="fa-solid fa-cash-register"></i>Caja</a>
    <a href="housekeeping.html"   class="nav-item" data-module="housekeeping"><i class="fa-solid fa-broom"></i>Housekeeping</a>
    <a href="servicios.html"      class="nav-item" data-module="servicios"><i class="fa-solid fa-concierge-bell"></i>Servicios</a>
  </div>

  <div class="nav-section">
    <div class="nav-section-label">Comercial</div>
    <a href="agencias.html"       class="nav-item" data-module="agencias"><i class="fa-solid fa-handshake"></i>Agencias</a>
    <a href="channel.html"        class="nav-item" data-module="channel"><i class="fa-solid fa-satellite-dish"></i>Canales</a>
    <a href="facturacion.html"    class="nav-item" data-module="facturacion"><i class="fa-solid fa-file-invoice"></i>Facturaci&#xF3;n</a>
    <a href="sincronizacion.html" class="nav-item" data-module="sincronizacion"><i class="fa-solid fa-rotate"></i>Sincronizaci&#xF3;n</a>
  </div>

  <div class="nav-section">
    <div class="nav-section-label">Sistema</div>
    <a href="admin.html"          class="nav-item" data-module="admin"><i class="fa-solid fa-chart-line"></i>Administraci&#xF3;n</a>
    <a href="configuracion.html"  class="nav-item" data-module="configuracion"><i class="fa-solid fa-gear"></i>Configuraci&#xF3;n</a>
  </div>
</nav>`;
}

function buildHeader(activeModule) {
  const mod = MODULES[activeModule] || { title: activeModule, icon: 'fa-circle' };
  return `
<header class="app-header">
  <div class="header-title">
    <i class="fa-solid ${mod.icon}"></i>
    <span id="headerTitle">${mod.title}</span>
    <span class="header-hotel" id="headerHotel"></span>
  </div>
  <div class="header-right">
    <div class="user-info">
      <div class="user-avatar" id="userAvatar">?</div>
      <span class="user-name" id="userName">...</span>
      <span class="user-role" id="userRole">...</span>
    </div>
    <button class="btn-logout" id="btnLogout"><i class="fa-solid fa-right-from-bracket"></i>Salir</button>
  </div>
</header>`;
}

// Pagina del menu (data-module) -> permiso que exige el backend.
// Ojo que no siempre coinciden: 'sincronizacion' y 'channel' son la misma
// familia, y 'admin' agrupa reportes + usuarios.
const PERMISO_DE_PAGINA = {
  // El hub lo ve cualquiera: adentro solo aparecen los modulos de su cargo
  modulos:        null,
  recepcion:      'recepcion',
  reservas:       'reservas',
  huespedes:      'huespedes',
  caja:           'caja',
  housekeeping:   'housekeeping',
  servicios:      'servicios',
  agencias:       'agencias',
  channel:        'channel',
  sincronizacion: 'channel',
  facturacion:    'facturacion',
  admin:          'reportes',
  configuracion:  'configuracion',
};

// Pagina a la que mandar a cada rol cuando no puede ver la que pidio
const PAGINA_DE_PERMISO = {
  recepcion: 'recepcion', reservas: 'reservas', huespedes: 'huespedes',
  caja: 'caja', housekeeping: 'housekeeping', servicios: 'servicios',
  agencias: 'agencias', channel: 'channel', facturacion: 'facturacion',
  reportes: 'admin', usuarios: 'admin', configuracion: 'configuracion',
};

// Modulos permitidos del usuario logueado (los manda el backend al login).
// Si por lo que sea no estan, no se esconde nada: el backend igual bloquea.
function modulosPermitidos() {
  const user = JSON.parse(localStorage.getItem('hv_usuario') || '{}');
  return Array.isArray(user.modulos) ? user.modulos : null;
}

function puedeVerPagina(pagina) {
  const mods = modulosPermitidos();
  if (!mods) return true;
  // 'admin' agrupa reportes y usuarios: alcanza con tener uno de los dos
  if (pagina === 'admin') return mods.includes('reportes') || mods.includes('usuarios');
  const permiso = PERMISO_DE_PAGINA[pagina];
  return permiso ? mods.includes(permiso) : true;
}

// Saca del menu lo que el rol no puede abrir y borra las secciones
// que quedaron sin ningun item.
function filtrarSidebarPorRol() {
  const mods = modulosPermitidos();
  if (!mods) return;
  document.querySelectorAll('.sidebar .nav-item').forEach(a => {
    if (!puedeVerPagina(a.dataset.module)) a.remove();
  });
  document.querySelectorAll('.sidebar .nav-section').forEach(sec => {
    if (!sec.querySelector('.nav-item')) sec.remove();
  });
}

function initLayout(activeModule) {
  // 1. Verificar auth
  if (!api._token) {
    window.location.href = 'login.html';
    return;
  }

  // 1b. Guardia de pagina: si escribio la URL a mano de un modulo que no le
  //     toca, se lo manda a la primera pagina que si puede ver.
  if (activeModule && !puedeVerPagina(activeModule)) {
    const mods = modulosPermitidos() || [];
    const destino = mods.length ? (PAGINA_DE_PERMISO[mods[0]] || 'recepcion') : 'recepcion';
    alert('Tu usuario no tiene acceso a ese modulo.');
    window.location.href = destino + '.html';
    return;
  }

  // 2. Leer usuario
  const user = JSON.parse(localStorage.getItem('hv_usuario') || '{}');

  // 3. Inyectar sidebar en #app-layout como primer hijo
  const appLayout = document.getElementById('app-layout');
  if (appLayout) {
    appLayout.insertAdjacentHTML('afterbegin', buildSidebar());
    filtrarSidebarPorRol();
  }

  // 4. Inyectar header como primer hijo de .page-wrapper
  const pageWrapper = document.querySelector('.page-wrapper');
  if (pageWrapper) {
    pageWrapper.insertAdjacentHTML('afterbegin', buildHeader(activeModule));
  }

  // 5. Marcar nav-item activo
  if (activeModule) {
    const activeLink = document.querySelector(`.nav-item[data-module="${activeModule}"]`);
    if (activeLink) activeLink.classList.add('active');
  }

  // 6. Poblar datos de usuario
  const nombre = ((user.nombres || '') + ' ' + (user.apellidos || '')).trim();
  const inicial = nombre ? nombre.charAt(0).toUpperCase() : '?';

  const elAvatar = document.getElementById('userAvatar');
  const elNombre = document.getElementById('userName');
  const elRol    = document.getElementById('userRole');

  if (elAvatar) elAvatar.textContent = inicial;
  if (elNombre) elNombre.textContent = nombre || 'Usuario';
  if (elRol)    elRol.textContent    = user.rolNombre || user.rol || '';

  // Nombre del hotel/sucursal en la barra y en la pestana del navegador.
  // Con varios locales abiertos a la vez todas las pestanas decian igual y
  // no se sabia en cual se estaba trabajando.
  const tituloMod = (MODULES[activeModule] || {}).title || activeModule || '';

  function pintarHotel(nombre, direccion) {
    const el = document.getElementById('headerHotel');
    if (el && nombre) {
      el.textContent = nombre;
      if (direccion) el.title = direccion;
    }
    document.title = nombre ? `${nombre} — ${tituloMod}` : `HotelVIP — ${tituloMod}`;
  }

  if ((user.hotelNombre || '').trim()) {
    pintarHotel(user.hotelNombre.trim(), user.hotelDireccion);
  } else {
    // Sesion abierta ANTES de que existiera este dato: no esta guardado.
    // Se pide a /auth/me y se deja guardado para las siguientes pantallas,
    // asi no hace falta cerrar sesion y volver a entrar.
    pintarHotel('', '');
    api.get('/auth/me')
      .then(r => {
        const d = (r && r.data) ? r.data : r;
        if (!d || !d.hotelNombre) return;
        user.hotelNombre    = d.hotelNombre;
        user.hotelDireccion = d.hotelDireccion || '';
        localStorage.setItem('hv_usuario', JSON.stringify(user));
        pintarHotel(d.hotelNombre, d.hotelDireccion);
      })
      .catch(() => {});   // si falla, la barra queda oculta y no molesta
  }

  // 7. Conectar boton logout
  const btnLogout = document.getElementById('btnLogout');
  if (btnLogout) {
    btnLogout.addEventListener('click', () => {
      api.clearAuth();
      window.location.href = 'login.html';
    });
  }

  // 8. Badge de reservas nuevas en Canales
  setTimeout(_checkChannelBadge, 800);
  setInterval(_checkChannelBadge, 30000);
}

// Verifica cuantas reservas externas NUEVA hay y muestra badge en sidebar
async function _checkChannelBadge() {
  try {
    const res = await api.get('/channel/canales');
    const total = (res.data || []).reduce((s, c) => s + Number(c.nuevas || 0), 0);
    const el = document.querySelector('.nav-item[data-module="channel"]');
    if (!el) return;
    let badge = el.querySelector('.nav-badge');
    if (total > 0) {
      if (!badge) {
        badge = document.createElement('span');
        badge.className = 'nav-badge';
        el.appendChild(badge);
      }
      badge.textContent = total > 99 ? '99+' : String(total);
    } else if (badge) {
      badge.remove();
    }
    // Disparar evento para que recepcion.html lo use
    window.dispatchEvent(new CustomEvent('channelBadgeUpdate', { detail: { total } }));
  } catch(e) { /* offline, no importa */ }
}
