// ==========================================
// MACHAPOINT POS - Historial (ventas y cortes Z) por rango de fechas
// ==========================================
'use strict';

const API_SALES_RANGE_URL = 'https://6uxm3jz7xwth5cliak6zk6dudi0iseih.lambda-url.us-east-1.on.aws/api/sale/by-date-range';
const API_CUTS_RANGE_URL = 'https://2v34s2xxn4rxq6utaxaaoawpb40soivi.lambda-url.us-east-1.on.aws/api/cut/by-date-range';
const API_USERS_URL = 'https://tmvksz56enigo6ojk25lfvg6x40vigzo.lambda-url.us-east-1.on.aws/api/users';

// Se llama con ?userid=<uuid> cuando se quiere un solo usuario (p_userid opcional).
const URL_LISTAR = `${API_USERS_URL}/auth/view`;

const PAGE_SIZE = 100;
const COLUMNAS_CORTES = 9;

const $ = id => document.getElementById(id);
const form = $('form-filtros');
const inpInicio = $('fecha-inicio');
const inpFin = $('fecha-fin');
const btnBuscar = $('btn-buscar');
const msgFechas = $('mensaje-fechas');
const atajos = document.querySelectorAll('[data-rango]');

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

// Día (YYYY-MM-DD) al que pertenece un timestamp, con el mismo criterio con que se muestra la hora
function diaDe(valor) {
    const s = String(valor ?? '');
    if (!s) return null;
    const conZona = /(Z|[+-]\d{2}:?\d{2})$/.test(s);
    if (!conZona && /^\d{4}-\d{2}-\d{2}/.test(s)) return s.slice(0, 10); // sin zona: tal cual la guardó la BD
    const d = new Date(valor);
    return isNaN(d.getTime()) ? null : fmt(d);                           // con zona: día local
}

// ---------- Formato ----------
const dinero = n => (Number(n) || 0).toLocaleString('es-MX', { style: 'currency', currency: 'MXN' });

function formatoFechaHora(f) {
    if (!f) return '-';
    const d = new Date(f);
    return isNaN(d.getTime()) ? String(f) : d.toLocaleString('es-MX', { dateStyle: 'short', timeStyle: 'short' });
}

// ---------- Usuarios (UUID -> firstName). Se pide UNA vez y se comparte entre secciones ----------
let usuariosPromesa = null;

function usuariosPorId() {
    if (usuariosPromesa) return usuariosPromesa;
    usuariosPromesa = (async () => {
        try {
            const res = await Api.request(URL_LISTAR, { method: 'GET', retries: 2, timeout: 20000 });
            if (!res.ok) {
                if (res.status !== 403) usuariosPromesa = null; // 403: no insistir; otros errores: reintentar luego
                return new Map();
            }
            const data = await res.json();
            const lista = Array.isArray(data) ? data : (data.data || data.users || data.user || data.usuarios || []);
            const mapa = new Map();
            lista.forEach(u => {
                const id = String(u.userId ?? u.userid ?? u.id ?? u.user_id ?? '').toLowerCase();
                const nombre = u.firstName ?? u.firstname ?? u.first_name ?? '';
                if (id && nombre) mapa.set(id, nombre);
            });
            return mapa;
        } catch {
            usuariosPromesa = null; // falla de red: se reintenta en la próxima consulta
            return new Map();       // el historial se muestra igual, solo sin nombres
        }
    })();
    return usuariosPromesa;
}

// ---------- Normalización ----------
const pick = (o, ...claves) => { for (const k of claves) if (o[k] != null) return o[k]; return null; };
const num = v => Number(v) || 0;

// sp_sales_by_date_range: saleid, shiftid, cashierid, total, created_at
function normalizarVenta(s, usuarios) {
    const cashierId = String(pick(s, 'cashierId', 'cashierid') ?? '');
    return {
        id: pick(s, 'saleId', 'saleid', 'id'),
        shiftId: pick(s, 'shiftId', 'shiftid') ?? '-',
        cashierId,
        cashier: pick(s, 'cashierUsername', 'cashierName') ?? usuarios.get(cashierId.toLowerCase()) ?? null,
        total: num(s.total),
        createdAt: pick(s, 'createdAt', 'created_at', 'createAt')
    };
}

// sp_zcuts_by_date_range: zcutid, shiftid, cashierid, opened_at, closed_at, firstsaleid, lastsaleid,
// opening_cash, total_sales, total_sales_count, expected_cash, expected_card, expected_transfer,
// actual_cash, cash_difference, notes
function normalizarCorte(c, usuarios) {
    const cashierId = String(pick(c, 'cashierId', 'cashierid', 'cashier_id') ?? '');
    return {
        id: pick(c, 'zcutId', 'zcutid', 'zCutId', 'zcut_id', 'id'),
        shiftId: pick(c, 'shiftId', 'shiftid', 'shift_id') ?? '-',
        cashierId,
        cashier: pick(c, 'cashierUsername', 'cashierName') ?? usuarios.get(cashierId.toLowerCase()) ?? null,
        openedAt: pick(c, 'openedAt', 'opened_at'),
        closedAt: pick(c, 'closedAt', 'closed_at'),
        firstSaleId: pick(c, 'firstSaleId', 'firstsaleid', 'first_sale_id'),
        lastSaleId: pick(c, 'lastSaleId', 'lastsaleid', 'last_sale_id'),
        openingCash: num(pick(c, 'openingCash', 'opening_cash')),
        totalSales: num(pick(c, 'totalSales', 'total_sales')),
        totalSalesCount: num(pick(c, 'totalSalesCount', 'total_sales_count')),
        expectedCash: num(pick(c, 'expectedCash', 'expected_cash')),
        expectedCard: num(pick(c, 'expectedCard', 'expected_card')),
        expectedTransfer: num(pick(c, 'expectedTransfer', 'expected_transfer')),
        actualCash: num(pick(c, 'actualCash', 'actual_cash')),
        cashDifference: num(pick(c, 'cashDifference', 'cash_difference')),
        notes: String(pick(c, 'notes') ?? '')
    };
}

// ---------- Render: celdas y filas ----------
function td(texto, clase) {
    const c = document.createElement('td');
    c.textContent = texto;
    if (clase) c.className = clase;
    return c;
}

function dato(etiqueta, valor, clase) {
    const d = document.createElement('div');
    d.className = 'hv-dato' + (clase ? ` ${clase}` : '');
    const s = document.createElement('span'); s.textContent = etiqueta;
    const st = document.createElement('strong'); st.textContent = valor;
    d.append(s, st);
    return d;
}

function crearFilaVenta(v) {
    const tr = document.createElement('tr');
    const tdVenta = td(`#${v.id}`);
    tdVenta.style.fontWeight = '600';

    const tdCajero = td(v.cashier || '-');
    if (!v.cashier && v.cashierId) tdCajero.title = 'No se encontró el nombre del usuario';

    tr.append(tdVenta, td(formatoFechaHora(v.createdAt)), td(`#${v.shiftId}`), tdCajero, td(dinero(v.total), 'num'));
    return [tr];
}

// Diferencia de efectivo. La etiqueta (Faltante/Sobrante) se calcula con contado - esperado,
// así no depende del signo con que el backend guarde cash_difference.
function celdaDiferencia(c) {
    const cell = document.createElement('td');
    cell.className = 'num hv-dif';
    const monto = document.createElement('span');
    monto.textContent = dinero(c.cashDifference);

    const calc = c.actualCash - c.expectedCash;
    let etiqueta = null, clase = '';
    if (Math.abs(c.cashDifference) < 0.005) { etiqueta = 'Cuadrado'; clase = 'hv-ok'; }
    else if (Math.abs(Math.abs(calc) - Math.abs(c.cashDifference)) < 0.005) {
        if (calc < 0) { etiqueta = 'Faltante'; clase = 'hv-neg'; }
        else { etiqueta = 'Sobrante'; clase = 'hv-pos'; }
    }
    if (clase) monto.className = clase;
    cell.appendChild(monto);
    if (etiqueta) {
        const small = document.createElement('small');
        small.textContent = etiqueta;
        small.className = clase;
        cell.appendChild(small);
    }
    return cell;
}

function crearFilaCorte(c) {
    const tr = document.createElement('tr');
    const tdCorte = td(`#${c.id}`);
    tdCorte.style.fontWeight = '600';
    const tdCajero = td(c.cashier || '-');
    if (!c.cashier && c.cashierId) tdCajero.title = 'No se encontró el nombre del usuario';

    // fila de detalle (oculta) con el resto de datos del corte
    const detalle = document.createElement('tr');
    detalle.className = 'hv-detalle-fila';
    detalle.hidden = true;
    const celdaDetalle = document.createElement('td');
    celdaDetalle.colSpan = COLUMNAS_CORTES;
    const grid = document.createElement('div');
    grid.className = 'hv-detalle';
    grid.append(
        dato('Total ventas', dinero(c.totalSales)),
        dato('Efectivo esperado', dinero(c.expectedCash)),
        dato('Fondo inicial', dinero(c.openingCash)),
        dato('Tarjeta esperada', dinero(c.expectedCard)),
        dato('Transferencia esperada', dinero(c.expectedTransfer)),
        dato('Ventas incluidas', c.firstSaleId != null && c.lastSaleId != null ? `#${c.firstSaleId} a #${c.lastSaleId}` : '-'),
        dato('Observaciones', c.notes.trim() || 'Sin observaciones', 'hv-notas')
    );
    celdaDetalle.appendChild(grid);
    detalle.appendChild(celdaDetalle);

    const tdAcc = document.createElement('td');
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'mp-btn mp-btn--dark pp-btn-sm';
    btn.textContent = 'Detalle';
    btn.setAttribute('aria-expanded', 'false');
    btn.setAttribute('aria-label', `Ver detalle del corte ${c.id}`);
    btn.addEventListener('click', () => {
        const abrir = detalle.hidden;
        detalle.hidden = !abrir;
        btn.setAttribute('aria-expanded', String(abrir));
        btn.textContent = abrir ? 'Ocultar' : 'Detalle';
    });
    tdAcc.appendChild(btn);

    tr.append(tdCorte, td(`#${c.shiftId}`), tdCajero,
              td(formatoFechaHora(c.openedAt)), td(formatoFechaHora(c.closedAt)),
              td(String(c.totalSalesCount), 'num'), td(dinero(c.actualCash), 'num'),
              celdaDiferencia(c), tdAcc);
    return [tr, detalle];
}

const sumar = (items, campo) => items.reduce((t, x) => t + x[campo], 0);

// ---------- Definición de las secciones ----------
const vistas = {
    ventas: {
        url: API_SALES_RANGE_URL,
        claves: ['data', 'sales', 'ventas'],
        normalizar: normalizarVenta,
        fechas: v => [v.createdAt],
        orden: v => v.createdAt,
        fila: crearFilaVenta,
        resumen: items => [['Ventas', String(items.length)], ['Total vendido', dinero(sumar(items, 'total'))]],
        textoCarga: 'Consultando ventas...',
        textoVacio: 'No hay ventas registradas en el rango seleccionado.',
        textoError: 'No se pudieron cargar las ventas',
        tab: $('tab-ventas'), panel: $('panel-ventas'), resumenEl: $('resumen'),
        estadoEl: $('estado'), tabla: $('tabla-ventas'), tbody: $('tabla-ventas-body'), mas: $('btn-mas')
    },
    cortes: {
        url: API_CUTS_RANGE_URL,
        claves: ['cuts', 'zcuts', 'zCuts', 'data'],
        normalizar: normalizarCorte,
        fechas: c => [c.openedAt, c.closedAt],
        orden: c => c.closedAt || c.openedAt,
        fila: crearFilaCorte,
        resumen: items => [
            ['Cortes', String(items.length)],
            ['Total ventas', dinero(sumar(items, 'totalSales'))],
            ['Efectivo esperado', dinero(sumar(items, 'expectedCash'))],
            ['Efectivo contado', dinero(sumar(items, 'actualCash'))]
        ],
        textoCarga: 'Consultando cortes...',
        textoVacio: 'No hay cortes registrados en el rango seleccionado.',
        textoError: 'No se pudieron cargar los cortes',
        tab: $('tab-cortes'), panel: $('panel-cortes'), resumenEl: $('resumen-cortes'),
        estadoEl: $('estado-cortes'), tabla: $('tabla-cortes'), tbody: $('tabla-cortes-body'), mas: $('btn-mas-cortes')
    }
};
Object.values(vistas).forEach(v => Object.assign(v, { items: [], mostradas: 0, clave: null, id: 0, cargando: false }));
let vistaActiva = 'ventas';

// ---------- Estados de la UI ----------
function setEstado(vista, tipo, texto, onReintentar) {
    const e = vista.estadoEl;
    e.className = 'hv-estado' + (tipo === 'error' ? ' hv-error' : tipo === 'vacio' ? ' hv-vacio' : '');
    e.replaceChildren();
    if (!tipo) return;

    if (tipo === 'cargando') {
        const sp = document.createElement('span');
        sp.className = 'hv-spinner';
        sp.setAttribute('aria-hidden', 'true');
        e.appendChild(sp);
    }
    e.appendChild(document.createTextNode(texto));

    if (onReintentar) {
        const b = document.createElement('button');
        b.type = 'button';
        b.className = 'mp-btn pp-btn-secondary pp-btn-sm';
        b.textContent = 'Reintentar';
        b.addEventListener('click', onReintentar);
        e.appendChild(b);
    }
}

function actualizarBoton() {
    const cargando = vistas[vistaActiva].cargando;
    btnBuscar.disabled = cargando;
    btnBuscar.textContent = cargando ? 'Consultando...' : 'Consultar';
}

function limpiarVista(vista) {
    vista.items = [];
    vista.mostradas = 0;
    vista.tbody.replaceChildren();
    vista.mas.classList.add('oculto');
    vista.resumenEl.classList.add('oculto');
    vista.resumenEl.replaceChildren();
}

function pintarMas(vista) {
    const frag = document.createDocumentFragment();
    vista.items.slice(vista.mostradas, vista.mostradas + PAGE_SIZE)
        .forEach(it => vista.fila(it).forEach(tr => frag.appendChild(tr)));
    vista.tbody.appendChild(frag);
    vista.mostradas = Math.min(vista.mostradas + PAGE_SIZE, vista.items.length);
    vista.mas.classList.toggle('oculto', vista.mostradas >= vista.items.length);
    vista.mas.textContent = `Mostrar más (${vista.items.length - vista.mostradas} restantes)`;
}

function pintarResumen(vista) {
    vista.resumenEl.replaceChildren(...vista.resumen(vista.items).map(([e, v]) => dato(e, v)));
    vista.resumenEl.classList.toggle('oculto', vista.items.length === 0);
}

// ---------- Consulta ----------
function extraerLista(data, claves) {
    if (Array.isArray(data)) return data;
    const lista = claves.map(k => data && data[k]).find(Array.isArray);
    if (!lista) throw new Error('El servidor devolvió un formato inesperado.');
    return lista;
}

// forzar = true: vuelve a consultar aunque ya se haya cargado ese mismo rango en la sección
async function consultar(forzar = false) {
    const error = validarRango();
    if (error) { mostrarErrorFechas(error); return; }
    mostrarErrorFechas('');

    const vista = vistas[vistaActiva];
    const inicio = inpInicio.value, fin = inpFin.value;
    const clave = `${inicio}|${fin}`;
    if (!forzar && vista.clave === clave) return; // esta sección ya muestra ese rango

    const id = ++vista.id;
    limpiarVista(vista);
    vista.clave = null;
    vista.cargando = true;
    actualizarBoton();
    vista.tabla.setAttribute('aria-busy', 'true');
    setEstado(vista, 'cargando', vista.textoCarga);

    try {
        // El SP compara timestamps contra fechas (00:00). Con endDate = fin, lo del último día
        // queda fuera; por eso se pide hasta el día SIGUIENTE y luego se recorta aquí al rango elegido.
        const url = `${vista.url}?startDate=${encodeURIComponent(inicio)}&endDate=${encodeURIComponent(sumarDia(fin))}`;
        const res = await Api.request(url, { method: 'GET', retries: 2, timeout: 20000 });
        if (id !== vista.id) return; // llegó una respuesta vieja: se descarta

        if (!res.ok) throw new Error(await Api.errorDe(res));
        const data = await res.json().catch(() => { throw new Error('El servidor devolvió una respuesta no válida.'); });
        if (id !== vista.id) return;

        const lista = extraerLista(data, vista.claves);
        const usuarios = await usuariosPorId(); // si falla, solo se omiten los nombres
        if (id !== vista.id) return;

        vista.items = lista.map(x => vista.normalizar(x, usuarios))
            .filter(it => {
                const dias = vista.fechas(it).map(diaDe).filter(Boolean);
                return dias.length === 0 || dias.some(d => d >= inicio && d <= fin);
            })
            .sort((a, b) => new Date(vista.orden(b)) - new Date(vista.orden(a)));
        vista.clave = clave;

        if (vista.items.length === 0) {
            setEstado(vista, 'vacio', vista.textoVacio);
        } else {
            setEstado(vista, null);
            pintarResumen(vista);
            pintarMas(vista);
        }
    } catch (err) {
        if (id !== vista.id) return;
        setEstado(vista, 'error', `${vista.textoError}: ${err.message}`, () => consultar(true));
    } finally {
        if (id === vista.id) {
            vista.cargando = false;
            vista.tabla.setAttribute('aria-busy', 'false');
            actualizarBoton();
        }
    }
}

// ---------- Secciones (pestañas) ----------
function activarVista(nombre, { foco = false } = {}) {
    if (!vistas[nombre]) nombre = 'ventas';
    vistaActiva = nombre;
    Object.entries(vistas).forEach(([n, v]) => {
        const activa = n === nombre;
        v.tab.setAttribute('aria-selected', String(activa));
        v.tab.tabIndex = activa ? 0 : -1;
        v.tab.classList.toggle('activo', activa);
        v.panel.hidden = !activa;
    });
    if (foco) vistas[nombre].tab.focus();
    try { history.replaceState(null, '', `#${nombre}`); } catch { /* sin historial */ }
    actualizarBoton();
    consultar(false);
}

Object.entries(vistas).forEach(([nombre, v]) => {
    v.tab.addEventListener('click', () => activarVista(nombre));
    v.mas.addEventListener('click', () => pintarMas(v));
});

// Flechas izquierda/derecha entre pestañas
document.querySelector('.hv-tabs').addEventListener('keydown', (e) => {
    if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft') return;
    const nombres = Object.keys(vistas);
    const i = nombres.indexOf(vistaActiva);
    const sig = nombres[(i + (e.key === 'ArrowRight' ? 1 : nombres.length - 1)) % nombres.length];
    activarVista(sig, { foco: true });
});

// ---------- Eventos de filtros ----------
atajos.forEach(b => b.addEventListener('click', () => {
    const r = rangoAtajo(b.dataset.rango);
    inpInicio.value = r.inicio;
    inpFin.value = r.fin;
    actualizarLimites();
    marcarAtajo(b.dataset.rango);
    consultar(true);
}));

const consultarConRetraso = Api.debounce(() => { if (!validarRango()) consultar(false); }, 400);

[inpInicio, inpFin].forEach(inp => inp.addEventListener('change', () => {
    marcarAtajo(null);
    actualizarLimites();
    const error = validarRango();
    mostrarErrorFechas(error);
    if (!error) consultarConRetraso(); // consulta automática al cambiar un rango válido
}));

form.addEventListener('submit', (e) => { e.preventDefault(); consultar(true); });

// ---------- Inicio: hoy (y la sección indicada en el #hash, si la hay) ----------
(function iniciar() {
    const r = rangoAtajo('dia');
    inpInicio.value = r.inicio;
    inpFin.value = r.fin;
    actualizarLimites();
    marcarAtajo('dia');
    activarVista(location.hash.replace('#', '') || 'ventas');
})();