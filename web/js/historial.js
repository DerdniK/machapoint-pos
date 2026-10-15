// ==========================================
// MACHAPOINT POS - Historial de ventas por rango de fechas
// ==========================================
'use strict';

const API_SALES_RANGE_URL = 'https://6uxm3jz7xwth5cliak6zk6dudi0iseih.lambda-url.us-east-1.on.aws/api/sale/by-date-range';
const PAGE_SIZE = 100;

const $ = id => document.getElementById(id);
const form = $('form-filtros');
const inpInicio = $('fecha-inicio');
const inpFin = $('fecha-fin');
const btnBuscar = $('btn-buscar');
const btnMas = $('btn-mas');
const msgFechas = $('mensaje-fechas');
const estado = $('estado');
const tabla = $('tabla-ventas');
const tbody = $('tabla-ventas-body');
const atajos = document.querySelectorAll('[data-rango]');

let ventas = [];      // resultado de la última consulta
let mostradas = 0;    // filas ya pintadas
let peticionId = 0;   // para ignorar respuestas viejas (red lenta)

// ---------- Fechas (siempre en hora LOCAL; toISOString() usaría UTC y cambiaría el día) ----------
const pad = n => String(n).padStart(2, '0');
const fmt = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const hoy = () => fmt(new Date());
const parseFecha = s => { const [y, m, d] = s.split('-').map(Number); return new Date(y, m - 1, d); };
const esFechaValida = s => /^\d{4}-\d{2}-\d{2}$/.test(s) && fmt(parseFecha(s)) === s;

const sumarDia = s => { const d = parseFecha(s); d.setDate(d.getDate() + 1); return fmt(d); };

function haceUnMes(base) {
    const d = new Date(base.getFullYear(), base.getMonth() - 1, base.getDate());
    if (d.getDate() !== base.getDate()) d.setDate(0); // ej. 31-mar -> último día de febrero
    d.setDate(d.getDate() + 1);                       // rango inclusivo
    return d;
}

function rangoAtajo(tipo) {
    const fin = new Date();
    const inicio = new Date();
    if (tipo === 'semana') inicio.setDate(fin.getDate() - 6);        // hoy + 6 días previos
    else if (tipo === 'mes') return { inicio: fmt(haceUnMes(fin)), fin: fmt(fin) };
    return { inicio: fmt(inicio), fin: fmt(fin) };                    // 1 día = hoy
}

function marcarAtajo(tipo) {
    atajos.forEach(b => {
        const activo = b.dataset.rango === tipo;
        b.classList.toggle('activo', activo);
        b.setAttribute('aria-pressed', activo);
    });
}

// Límites dinámicos de los inputs: max = hoy; fin >= inicio; inicio <= fin
function actualizarLimites() {
    const h = hoy();
    inpFin.max = h;
    inpFin.min = inpInicio.value || '';
    inpInicio.max = inpFin.value && inpFin.value < h ? inpFin.value : h;
}

function validarRango() {
    const ini = inpInicio.value, fin = inpFin.value, h = hoy();
    inpInicio.removeAttribute('aria-invalid');
    inpFin.removeAttribute('aria-invalid');

    const fallo = (campo, texto) => { campo.setAttribute('aria-invalid', 'true'); return texto; };

    if (!ini) return fallo(inpInicio, 'Selecciona la fecha de inicio.');
    if (!fin) return fallo(inpFin, 'Selecciona la fecha de fin.');
    if (!esFechaValida(ini)) return fallo(inpInicio, 'La fecha de inicio no es válida.');
    if (!esFechaValida(fin)) return fallo(inpFin, 'La fecha de fin no es válida.');
    if (ini > h) return fallo(inpInicio, 'La fecha de inicio no puede ser posterior a hoy.');
    if (fin > h) return fallo(inpFin, 'La fecha de fin no puede ser posterior a hoy.');
    if (ini > fin) return fallo(inpInicio, 'La fecha de inicio no puede ser mayor a la fecha de fin.');
    return null;
}

function mostrarErrorFechas(texto) {
    msgFechas.textContent = texto || '';
    msgFechas.classList.toggle('mp-inline-msg--error', !!texto);
}

// ---------- Formato ----------
const dinero = n => (Number(n) || 0).toLocaleString('es-MX', { style: 'currency', currency: 'MXN' });

function formatoFechaHora(f) {
    if (!f) return '-';
    const d = new Date(f);
    return isNaN(d.getTime()) ? String(f) : d.toLocaleString('es-MX', { dateStyle: 'short', timeStyle: 'short' });
}

// El endpoint devuelve las columnas de sp_sales_by_date_range (saleid, shiftid, cashierid, total, created_at)
function normalizarVenta(s) {
    return {
        id: s.saleId ?? s.saleid ?? s.id,
        shiftId: s.shiftId ?? s.shiftid ?? '-',
        cashierId: String(s.cashierId ?? s.cashierid ?? ''),
        cashier: s.cashierUsername ?? s.cashierName ?? null,
        total: Number(s.total) || 0,
        createdAt: s.createdAt ?? s.created_at ?? s.createAt ?? null
    };
}

// Día (YYYY-MM-DD) al que pertenece la venta, en el mismo criterio con que se muestra la hora
function diaDeVenta(v) {
    const s = String(v.createdAt ?? '');
    const conZona = /(Z|[+-]\d{2}:?\d{2})$/.test(s);
    if (!conZona && /^\d{4}-\d{2}-\d{2}/.test(s)) return s.slice(0, 10); // sin zona: tal cual la guardó la BD
    const d = new Date(v.createdAt);
    return isNaN(d.getTime()) ? null : fmt(d);                              // con zona: día local
}

// ---------- Estados de la UI ----------
function setEstado(tipo, texto, onReintentar) {
    estado.className = 'hv-estado' + (tipo === 'error' ? ' hv-error' : tipo === 'vacio' ? ' hv-vacio' : '');
    estado.replaceChildren();
    if (!tipo) return;

    if (tipo === 'cargando') {
        const sp = document.createElement('span');
        sp.className = 'hv-spinner';
        sp.setAttribute('aria-hidden', 'true');
        estado.appendChild(sp);
    }
    estado.appendChild(document.createTextNode(texto));

    if (onReintentar) {
        const b = document.createElement('button');
        b.type = 'button';
        b.className = 'mp-btn pp-btn-secondary pp-btn-sm';
        b.textContent = 'Reintentar';
        b.addEventListener('click', onReintentar);
        estado.appendChild(b);
    }
}

function setCargando(cargando) {
    tabla.setAttribute('aria-busy', cargando);
    btnBuscar.disabled = cargando;
    btnBuscar.textContent = cargando ? 'Consultando...' : 'Consultar';
}

// ---------- Render ----------
function crearFila(v) {
    const tr = document.createElement('tr');
    const td = (texto, clase) => {
        const c = document.createElement('td');
        c.textContent = texto;
        if (clase) c.className = clase;
        return c;
    };

    const tdVenta = td(`#${v.id}`);
    tdVenta.style.fontWeight = '600';

    const tdCajero = td(v.cashier || (v.cashierId ? v.cashierId.slice(0, 8) : '-'));
    if (!v.cashier && v.cashierId) tdCajero.title = v.cashierId;

    tr.append(tdVenta, td(formatoFechaHora(v.createdAt)), td(`#${v.shiftId}`), tdCajero,
              td(dinero(v.total), 'num'));
    return tr;
}

function pintarMas() {
    const frag = document.createDocumentFragment();
    ventas.slice(mostradas, mostradas + PAGE_SIZE).forEach(v => frag.appendChild(crearFila(v)));
    tbody.appendChild(frag);
    mostradas = Math.min(mostradas + PAGE_SIZE, ventas.length);
    btnMas.classList.toggle('oculto', mostradas >= ventas.length);
    btnMas.textContent = `Mostrar más (${ventas.length - mostradas} restantes)`;
}

function pintarResumen() {
    $('resumen').classList.toggle('oculto', ventas.length === 0);
    $('resumen-cantidad').textContent = String(ventas.length);
    $('resumen-total').textContent = dinero(ventas.reduce((t, v) => t + v.total, 0));
}

function limpiarResultados() {
    ventas = [];
    mostradas = 0;
    tbody.replaceChildren();
    btnMas.classList.add('oculto');
    $('resumen').classList.add('oculto');
}

// ---------- Consulta ----------
async function consultar() {
    const error = validarRango();
    if (error) { mostrarErrorFechas(error); return; }
    mostrarErrorFechas('');

    const id = ++peticionId;
    const inicio = inpInicio.value, fin = inpFin.value;
    limpiarResultados();
    setCargando(true);
    setEstado('cargando', 'Consultando ventas...');

    try {
        // El SP compara timestamps contra fechas (00:00). Con endDate = fin, las ventas del último día
        // quedan fuera; por eso se pide hasta el día SIGUIENTE y luego se recorta aquí al rango elegido.
        const url = `${API_SALES_RANGE_URL}?startDate=${encodeURIComponent(inicio)}&endDate=${encodeURIComponent(sumarDia(fin))}`;
        const res = await Api.request(url, { method: 'GET', retries: 2, timeout: 20000 });
        if (id !== peticionId) return; // llegó una respuesta vieja: se descarta

        if (!res.ok) throw new Error(await Api.errorDe(res));
        const data = await res.json().catch(() => { throw new Error('El servidor devolvió una respuesta no válida.'); });
        if (id !== peticionId) return;

        const lista = Array.isArray(data) ? data : (data.data || data.sales || data.ventas || []);
        if (!Array.isArray(lista)) throw new Error('El servidor devolvió un formato inesperado.');

        ventas = lista.map(normalizarVenta)
            .filter(v => { const d = diaDeVenta(v); return !d || (d >= inicio && d <= fin); })
            .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

        if (ventas.length === 0) {
            setEstado('vacio', 'No hay ventas registradas en el rango seleccionado.');
        } else {
            setEstado(null);
            pintarResumen();
            pintarMas();
        }
    } catch (err) {
        if (id !== peticionId) return;
        setEstado('error', `No se pudieron cargar las ventas: ${err.message}`, consultar);
    } finally {
        if (id === peticionId) setCargando(false);
    }
}

// ---------- Eventos ----------
atajos.forEach(b => b.addEventListener('click', () => {
    const r = rangoAtajo(b.dataset.rango);
    inpInicio.value = r.inicio;
    inpFin.value = r.fin;
    actualizarLimites();
    marcarAtajo(b.dataset.rango);
    consultar();
}));

const consultarConRetraso = Api.debounce(() => { if (!validarRango()) consultar(); }, 400);

[inpInicio, inpFin].forEach(inp => inp.addEventListener('change', () => {
    marcarAtajo(null);
    actualizarLimites();
    const error = validarRango();
    mostrarErrorFechas(error);
    if (!error) consultarConRetraso(); // consulta automática al cambiar un rango válido
}));

form.addEventListener('submit', (e) => { e.preventDefault(); consultar(); });
btnMas.addEventListener('click', pintarMas);

// ---------- Inicio: hoy ----------
(function iniciar() {
    const r = rangoAtajo('dia');
    inpInicio.value = r.inicio;
    inpFin.value = r.fin;
    actualizarLimites();
    marcarAtajo('dia');
    consultar();
})();