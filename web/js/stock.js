// MACHAPOINT POS - Edición de stock de productos
'use strict';

const API_PRODUCTS_URL = 'https://4upkj2tafvod2ubwcsbnagviyu0feljy.lambda-url.us-east-1.on.aws/api/products/product';
const URL_LISTAR = `${API_PRODUCTS_URL}/get`;
const URL_STOCK = `${API_PRODUCTS_URL}/stock`;
const STOCK_METHOD = 'PATCH';          // AJUSTAR si el endpoint /stock espera POST o PUT
const CATALOGO_CACHE_KEY = 'catalogoCache';
const IMG_FALLBACK = '/img/product.jpg';

// ---------- Reglas ----------
const MAX_STOCK = 500;   
const STOCK_BAJO = 5;      // a partir de este valor se marca "Bajo"

// ---------- DOM ----------
const $ = id => document.getElementById(id);
const buscador = $('buscador');
const msgLista = $('mensaje');
const tbody = $('tabla-stock');
const dialogo = $('dialogo-editar');
const formEditar = $('form-editar');
const btnGuardar = $('btn-guardar-edicion');
const btnCancelar = $('btn-cancelar-edicion');
const msgEdicion = $('mensaje-edicion');
const selModo = $('ed-modo');
const inpCantidad = $('ed-cantidad');
const lblCantidad = $('lbl-cantidad');
const txtResultado = $('ed-resultado');
const txtAviso = $('ed-aviso');

let productos = [];
let productoEnEdicion = null;

// ---------- Utilidades ----------
function setMsg(el, texto, tipo = 'info') {
    if (!el) return;
    el.textContent = texto;
    el.classList.remove('mp-inline-msg--success', 'mp-inline-msg--error');
    if (tipo === 'error') el.classList.add('mp-inline-msg--error');
    else if (tipo === 'exito') el.classList.add('mp-inline-msg--success');
}

const esAdmin = () => !!(window.Auth && Auth.isAdmin());

function normalizarTexto(t) {
    return String(t ?? '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
}

// GET /product/get devuelve { productid, name, sku, price, imageURL, stock, type: { typeid, typeName } }
function normalizarProducto(p) {
    const s = p.stock == null || p.stock === '' ? null : Number(p.stock);
    const o = {
        id: p.productid ?? p.productId,
        name: p.name ?? '',
        sku: p.sku ?? '',
        typeName: p.type?.typeName ?? 'Sin tipo',
        stock: Number.isFinite(s) ? s : null,
        imageURL: p.imageURL ?? ''
    };
    o._q = normalizarTexto(`${o.name} ${o.sku}`);
    return o;
}

function interpretarError(status, crudo) {
    const t = String(crudo || '').toLowerCase();
    if (status === 405) return 'El servidor no acepta este método para actualizar el stock (405). Revisa STOCK_METHOD en stock.js.';
    if (status === 403) return 'No tienes permisos para modificar el stock.';
    if (t.includes('not found') || t.includes('no existe') || t.includes('no encontrado') || status === 404) return 'No se encontró el producto.';
    if (t.includes('check constraint') || t.includes('negative') || t.includes('negativo')) return 'El stock no puede quedar en negativo.';
    if (t.includes('out of range') || t.includes('overflow')) return 'La cantidad es demasiado grande.';
    if (crudo && String(crudo).length < 200) return String(crudo);
    return Api.mensajePorCodigo(status);
}

// Petición de escritura: lanza Error con mensaje apto para el usuario
async function enviar(url, method, body) {
    const res = await Api.request(url, { method, body: JSON.stringify(body), timeout: 20000 });
    const raw = await res.text();
    let data = null;
    try { data = raw ? JSON.parse(raw) : null; } catch { /* respuesta no JSON */ }

    const crudo = (data && typeof data === 'object') ? (data.message || data.Message || data.error || '') : '';
    if (!res.ok) {
        throw new Error(res.status >= 500 && !/not found|no existe|negative|out of range/i.test(crudo)
            ? Api.mensajePorCodigo(res.status)
            : interpretarError(res.status, crudo));
    }
    // El SP devuelve un booleano: false = no se actualizó nada (p. ej. el producto no existe)
    const rechazado = data === false || (data && typeof data === 'object' &&
        (data.success === false || data.updated === false || data.result === false));
    if (rechazado) throw new Error(crudo || 'No se pudo actualizar el stock (el producto no existe o no hubo cambios).');
    return data || {};
}

// Marca el campo con error y le da el foco; la marca se quita al escribir
function marcarInvalido(id) {
    formEditar.querySelectorAll('[aria-invalid]').forEach(el => { el.removeAttribute('aria-invalid'); el.style.borderColor = ''; });
    const campo = id && $(id);
    if (!campo) return;
    campo.setAttribute('aria-invalid', 'true');
    campo.style.borderColor = '#d9534f';
    campo.focus();
}
formEditar.addEventListener('input', e => { e.target.removeAttribute('aria-invalid'); e.target.style.borderColor = ''; });

// ---------- Bloqueo de input: solo dígitos ----------
const sanitizarCantidad = v => v.replace(/\D/g, '').slice(0, String(MAX_STOCK).length);

inpCantidad.addEventListener('beforeinput', (e) => {
    if (e.data == null || e.inputType.startsWith('delete')) return;
    const ini = inpCantidad.selectionStart ?? inpCantidad.value.length;
    const fin = inpCantidad.selectionEnd ?? inpCantidad.value.length;
    const resultado = inpCantidad.value.slice(0, ini) + e.data + inpCantidad.value.slice(fin);
    if (sanitizarCantidad(resultado) !== resultado) e.preventDefault();
});
inpCantidad.addEventListener('input', () => {
    const limpio = sanitizarCantidad(inpCantidad.value);
    if (limpio !== inpCantidad.value) inpCantidad.value = limpio;
});

// ---------- Validación ----------
function validar(modo, texto, original) {
    const t = texto.trim();
    if (!['sumar', 'establecer'].includes(modo)) return { error: 'Selecciona un tipo de ajuste válido.', campo: 'ed-modo' };
    if (!t) return { error: 'Ingresa la cantidad.', campo: 'ed-cantidad' };
    if (!/^\d+$/.test(t)) return { error: 'La cantidad debe ser un número entero, sin signos ni decimales.', campo: 'ed-cantidad' };

    const n = Number(t);
    if (!Number.isSafeInteger(n) || n > MAX_STOCK) {
        return { error: `La cantidad no puede ser mayor a ${MAX_STOCK}.`, campo: 'ed-cantidad' };
    }

    if (modo === 'sumar') {
        if (n < 1) return { error: 'La cantidad a sumar debe ser mayor a 0.', campo: 'ed-cantidad' };
        const total = (original.stock ?? 0) + n;
        if (total > MAX_STOCK) {
            return { error: `El stock resultante (${total}) superaría el máximo permitido (${MAX_STOCK}).`, campo: 'ed-cantidad' };
        }
    } else if (original.stock !== null && n === original.stock) {
        return { error: 'El stock ya tiene ese valor. No hay cambios que guardar.', campo: 'ed-cantidad' };
    }
    return { valores: { modo, cantidad: n } };
}

// ---------- Vista previa dentro del diálogo ----------
function actualizarVista() {
    const modo = selModo.value;
    lblCantidad.textContent = modo === 'sumar'
        ? 'Cantidad a sumar (entero, mayor a 0)'
        : `Nuevo stock (entero, de 0 a ${MAX_STOCK})`;
    txtAviso.textContent = modo === 'establecer'
        ? 'Reemplaza el stock actual, incluidas las ventas que se hayan hecho mientras editabas.'
        : '';

    const t = inpCantidad.value.trim();
    if (!productoEnEdicion || !/^\d+$/.test(t)) { txtResultado.textContent = ''; return; }
    const n = Number(t);
    const resultado = modo === 'sumar' ? (productoEnEdicion.stock ?? 0) + n : n;
    txtResultado.textContent = `Stock resultante: ${resultado}`;
}
selModo.addEventListener('change', actualizarVista);
inpCantidad.addEventListener('input', actualizarVista);

// ---------- Listado ----------
async function cargarProductos() {
    setMsg(msgLista, 'Cargando productos...');
    try {
        const res = await Api.request(URL_LISTAR, { method: 'GET', retries: 2 });
        if (res.status === 403) { setMsg(msgLista, 'Tu usuario no tiene permisos para ver los productos.', 'error'); return; }
        if (!res.ok) throw new Error(await Api.errorDe(res));

        const data = await res.json();
        const lista = data.product || data.products || (Array.isArray(data) ? data : []);
        productos = lista.map(normalizarProducto);
        renderTabla();
    } catch (err) {
        setMsg(msgLista, 'No se pudieron cargar los productos: ' + err.message, 'error');
    }
}

function celda(texto, clase) {
    const td = document.createElement('td');
    td.textContent = texto;
    if (clase) td.className = clase;
    return td;
}

function celdaStock(stock) {
    const td = document.createElement('td');
    td.className = 'num';
    td.append(stock === null ? '-' : String(stock));
    if (stock !== null && stock <= STOCK_BAJO) {
        const b = document.createElement('span');
        b.className = 'mp-badge';
        b.textContent = stock === 0 ? 'Agotado' : 'Bajo';
        b.style.marginLeft = '8px';
        td.append(b);
    }
    return td;
}

function crearFila(p) {
    const tr = document.createElement('tr');

    const tdImg = document.createElement('td');
    const img = document.createElement('img');
    img.src = Api.urlSegura(p.imageURL) || IMG_FALLBACK;
    img.alt = p.name;
    img.className = 'pp-miniatura';
    img.loading = 'lazy';
    img.addEventListener('error', () => { img.src = IMG_FALLBACK; }, { once: true });
    tdImg.appendChild(img);

    const tdAcc = document.createElement('td');
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'mp-btn mp-btn--dark pp-btn-sm';
    btn.textContent = 'Editar';
    btn.setAttribute('aria-label', `Editar stock de ${p.name}`);
    btn.addEventListener('click', () => abrirEdicion(p));
    tdAcc.appendChild(btn);

    tr.append(tdImg, celda(p.name), celda(p.sku), celda(p.typeName), celdaStock(p.stock), tdAcc);
    return tr;
}

function renderTabla() {
    const termino = normalizarTexto(buscador.value);
    const lista = termino ? productos.filter(p => p._q.includes(termino)) : productos;
    tbody.replaceChildren();

    if (lista.length === 0) {
        setMsg(msgLista, productos.length
            ? `No se encontraron productos para "${buscador.value.trim()}".`
            : 'No hay productos registrados.');
        return;
    }
    setMsg(msgLista, '');
    const frag = document.createDocumentFragment();
    lista.forEach(p => frag.appendChild(crearFila(p)));
    tbody.appendChild(frag);
}

buscador.addEventListener('input', Api.debounce(renderTabla, 200));
buscador.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') { buscador.value = ''; renderTabla(); }
});

// ---------- Edición ----------
function abrirEdicion(p) {
    productoEnEdicion = p;
    $('ed-actual').value = p.stock === null ? 'Sin dato' : String(p.stock);
    selModo.value = 'sumar';
    inpCantidad.value = '';
    marcarInvalido(null);
    $('titulo-edicion').textContent = `Editar stock: ${p.name}`;
    setMsg(msgEdicion, '');
    actualizarVista();
    dialogo.showModal();
    inpCantidad.focus();
}

function cerrarEdicion() {
    dialogo.close();
    productoEnEdicion = null;
}

btnCancelar.addEventListener('click', cerrarEdicion);
dialogo.addEventListener('click', (e) => { if (e.target === dialogo) cerrarEdicion(); });

formEditar.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (btnGuardar.disabled) return;
    if (!esAdmin()) { setMsg(msgEdicion, 'No tienes permisos para modificar el stock.', 'error'); return; }
    if (!productoEnEdicion) return;
    const original = productoEnEdicion;

    const v = validar(selModo.value, inpCantidad.value, original);
    if (v.error) { setMsg(msgEdicion, v.error, 'error'); marcarInvalido(v.campo); return; }
    const { modo, cantidad } = v.valores;

    // Dejar un producto en 0 lo oculta del catálogo: se pide confirmación
    if (modo === 'establecer' && cantidad === 0
        && !confirm(`"${original.name}" quedará sin stock y dejará de mostrarse en el catálogo. ¿Continuar?`)) return;

    // Sin isAdjustment el SP SUMA; con isAdjustment: false REEMPLAZA el valor
    const payload = { productId: Number(original.id), stock: cantidad,
        isAdjustment: modo === 'sumar' // Enviará true si es sumar si o si, false si es establecer
    };  

    btnGuardar.disabled = true;
    setMsg(msgEdicion, 'Guardando cambios...');
    try {
        await enviar(URL_STOCK, STOCK_METHOD, payload);
        sessionStorage.removeItem(CATALOGO_CACHE_KEY); // el catálogo debe recargar el stock
        cerrarEdicion();
        await cargarProductos();
        const nuevo = productos.find(p => String(p.id) === String(original.id));
        setMsg(msgLista, `Stock de "${original.name}" actualizado${nuevo && nuevo.stock !== null ? `. Stock actual: ${nuevo.stock}` : '.'}`, 'exito');
    } catch (err) {
        setMsg(msgEdicion, 'Error al guardar: ' + err.message, 'error');
        if (/no se encontr/i.test(err.message)) { // el producto ya no existe: se refresca la lista
            cerrarEdicion();
            await cargarProductos();
            setMsg(msgLista, 'El producto ya no existe. Se actualizó la lista.', 'error');
        }
    } finally {
        btnGuardar.disabled = false;
    }
});

// ---------- Inicio ----------
cargarProductos();