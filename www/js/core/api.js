// api.js - HotelVIP Frontend Core
// SistemasVIP Cusco 2026

// Mismo origen que sirvio la pagina: funciona en cualquier puerto (central
// 9006, tenants 9007/9008) y desde cualquier PC de la red del hotel.
// ANTES estaba fijo a localhost:9006: desde otra PC de la LAN las llamadas
// iban a la maquina del que miraba (nada funcionaba), y un tenant en otro
// puerto hablaba en silencio con el central. Cazado pre-despliegue 20-ago.
const API_BASE = location.origin + '/api';

const api = {
  _token: null,
  _schema: null,

  init() {
    this._token  = localStorage.getItem('hv_token');
    this._schema = localStorage.getItem('hv_schema');
  },

  setAuth(token, schema) {
    this._token  = token;
    this._schema = schema;
    localStorage.setItem('hv_token',  token);
    localStorage.setItem('hv_schema', schema);
  },

  clearAuth() {
    this._token  = null;
    this._schema = null;
    localStorage.removeItem('hv_token');
    localStorage.removeItem('hv_schema');
    localStorage.removeItem('hv_usuario');
  },

  _headers() {
    const h = { 'Content-Type': 'application/json' };
    if (this._token)  h['Authorization']    = 'Bearer ' + this._token;
    if (this._schema) h['X-Hotel-Schema']   = this._schema;
    return h;
  },

  async _fetch(method, endpoint, body = null) {
    const opts = { method, headers: this._headers() };
    if (body) opts.body = JSON.stringify(body);

    try {
      const res = await fetch(API_BASE + endpoint, opts);
      const data = await res.json();

      if (res.status === 401) {
        this.clearAuth();
        window.location.href = '/index.html';
        return null;
      }
      if (!data.success) {
        throw new Error(data.error || 'Error en servidor');
      }
      return data;
    } catch (e) {
      if (e.name === 'TypeError' && e.message.includes('fetch')) {
        throw new Error('Sin conexion con el servidor local');
      }
      throw e;
    }
  },

  get:    (ep)         => api._fetch('GET',    ep),
  post:   (ep, body)   => api._fetch('POST',   ep, body),
  put:    (ep, body)   => api._fetch('PUT',    ep, body),
  delete: (ep)         => api._fetch('DELETE', ep),
  patch:  (ep, body)   => api._fetch('PATCH',  ep, body),

  getUser() {
    return JSON.parse(localStorage.getItem('hv_usuario') || 'null');
  },

  logout() {
    this.post('/auth/logout').catch(() => {});
    this.clearAuth();
    window.location.href = 'login.html';
  },
};

// Toast global
function toast(msg, tipo = 'info', duracion = 3500) {
  let cont = document.getElementById('toast-container');
  if (!cont) {
    cont = document.createElement('div');
    cont.id = 'toast-container';
    cont.style.cssText = 'position:fixed;top:16px;right:16px;z-index:9999;display:flex;flex-direction:column;gap:8px';
    document.body.appendChild(cont);
  }
  const t = document.createElement('div');
  const colores = { info:'#2980B9', success:'#27AE60', warning:'#F39C12', error:'#E74C3C' };
  t.style.cssText = `background:${colores[tipo]||colores.info};color:#fff;padding:12px 20px;
    border-radius:8px;font-size:14px;max-width:320px;box-shadow:0 4px 12px rgba(0,0,0,.2);
    animation:fadeIn .2s ease;`;
  t.textContent = msg;
  cont.appendChild(t);
  setTimeout(() => { t.style.opacity='0'; t.style.transition='opacity .3s';
    setTimeout(() => t.remove(), 300); }, duracion);
}

// Formateo
function fMoneda(v, simbolo = 'S/') {
  return simbolo + ' ' + Number(v || 0).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}
function fFecha(s) {
  if (!s) return '';
  // Fecha-solo (YYYY-MM-DD): parsear como LOCAL, no UTC (evita el corrimiento
  // de un dia en zonas UTC-5 como Peru)
  const d = new Date(/^\d{4}-\d{2}-\d{2}$/.test(s) ? s + 'T00:00:00' : s);
  return d.toLocaleDateString('es-PE', { day:'2-digit', month:'2-digit', year:'numeric' });
}
function fFechaHora(s) {
  if (!s) return '';
  const d = new Date(s);
  return d.toLocaleDateString('es-PE', { day:'2-digit', month:'2-digit', year:'numeric' }) +
         ' ' + d.toLocaleTimeString('es-PE', { hour:'2-digit', minute:'2-digit' });
}

api.init();
