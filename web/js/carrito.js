'use strict';
const CARRITO_KEY = 'carrito';
const REF_KEY = 'ventaRef';
const MAX_CANTIDAD = 20;
const API_PRODUCTOS_URL = 'https://4upkj2tafvod2ubwcsbnagviyu0feljy.lambda-url.us-east-1.on.aws/api/products/product/get';
const CATALOGO_CACHE_KEY = 'catalogoCache';
const IMG_FALLBACK = '/img/product.jpg';
const BACKEND_VENTA_URL = 'https://6uxm3jz7xwth5cliak6zk6dudi0iseih.lambda-url.us-east-1.on.aws/api/sale';

const $ = id => document.getElementById(id);
const listaCarrito = $('lista-carrito');
const mensajeCarrito = $('mensaje-carrito');
const totalCarrito = $('total-carrito');
const metodoPago = $('metodo-pago');
const seccionEfectivo = $('seccion-efectivo');
const seccionTarjeta = $('seccion-tarjeta');
const inputEfectivo = $('dinero-recibido');
const cambioResultado = $('cambio');
const tipoTarjeta = $('tipo-tarjeta');
const btnFinalizar = $('btn-finalizar');
const btnVaciarCarrito = $('btn-vaciar-carrito');
const segmentos = document.querySelectorAll('.segmento[data-metodo]');

// ---------- Estado en memoria (localStorage solo se escribe al cambiar) ----------
let carrito = leerCarrito();
let enviando = false;
let stockVerificado = false; // true cuando las existencias se confirmaron con el servidor

// ---------- Stock ----------
const stockDe = p => (p.stock == null || p.stock === '' || !Number.isFinite(Number(p.stock))) ? null : Number(p.stock);
const limiteDe = p => { const s = stockDe(p); return s === null ? MAX_CANTIDAD : Math.min(MAX_CANTIDAD, s); };

function problemaStock(p) {
    const s = stockDe(p);
    if (s === null) return null;
    if (s <= 0) return 'Producto agotado. Elimínalo del carrito.';
    if (p.cantidad > s) return `Stock insuficiente: solo hay ${s} disponible(s). Reduce la cantidad.`;
    return null;
}
const hayProblemasStock = () => carrito.some(p => problemaStock(p));

// Dinero en centavos enteros para evitar errores de punto flotante
const aCentavos = n => Math.round((Number(n) || 0) * 100);
const dinero = c => `$${(c / 100).toFixed(2)}`;

function leerCarrito() {
    try {
        const d = JSON.parse(localStorage.getItem(CARRITO_KEY) || '[]');
        if (!Array.isArray(d)) return [];
        return d.filter(p => p && p.productId != null).map(p => ({
            ...p,
            cantidad: Math.min(Math.max(parseInt(p.cantidad, 10) || 1, 1), MAX_CANTIDAD)
        }));
    } catch { return []; }
}

function guardarCarrito() {
    localStorage.setItem(CARRITO_KEY, JSON.stringify(carrito));
}

function totalCentavos() {
    return carrito.reduce((t, p) => t + aCentavos(p.price) * p.cantidad, 0);
}

function obtenerUsuario() {
    try { return JSON.parse(localStorage.getItem('user') || 'null'); } catch { return null; }
}

// ---------- Render (sin innerHTML para datos: nombres/SKU se muestran como texto) ----------
function el(tag, clase, texto) {
    const e = document.createElement(tag);
    if (clase) e.className = clase;
    if (texto != null) e.textContent = texto;
    return e;
}

// Íconos circulares (SVG constante, sin datos del usuario)
const ICONO_MENOS = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="9.5"/><path d="M7.5 12h9"/></svg>';
const ICONO_MAS = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="9.5"/><path d="M7.5 12h9M12 7.5v9"/></svg>';

function botonIcono(clase, svg, index, accion, label) {
    const b = el('button', `btn-icono ${clase}`);
    b.type = 'button';
    b.innerHTML = svg;
    b.dataset.index = index;
    b.dataset.accion = accion;
    b.setAttribute('aria-label', label);
    return b;
}

// Miniatura: misma lógica que el catálogo (imageURL validada + imagen por defecto)
function crearMiniatura(p) {
    const img = el('img', 'miniatura');
    img.loading = 'lazy';
    img.decoding = 'async';
    img.alt = p.name ?? '';
    img.src = Api.urlSegura(p.imageURL) || IMG_FALLBACK;
    img.addEventListener('error', () => { img.src = IMG_FALLBACK; }, { once: true });
    return img;
}

function crearArticulo(p, i) {
    const art = el('div', 'articulo-carrito');
    const problema = problemaStock(p);
    const stock = stockDe(p);

    const info = el('div', 'info-articulo');
    info.append(
        el('h3', null, p.name),
        el('p', null, `${p.cantidad} x ${dinero(aCentavos(p.price))}`)
    );
    if (stock !== null && problema === null && stock <= 5) info.append(el('p', null, `Disponibles: ${stock}`));
    if (problema) info.append(el('p', 'aviso-stock', problema));

    const menos = botonIcono('boton-disminuir', ICONO_MENOS, i, 'disminuir',
        p.cantidad <= 1 ? `Quitar ${p.name} del carrito` : `Disminuir cantidad de ${p.name}`);
    const mas = botonIcono('boton-aumentar', ICONO_MAS, i, 'aumentar', `Aumentar cantidad de ${p.name}`);
    if (p.cantidad >= limiteDe(p)) {
        mas.disabled = true;
        mas.title = stock !== null && stock < MAX_CANTIDAD
            ? `Solo hay ${stock} disponible(s)` : `Máximo ${MAX_CANTIDAD} por producto`;
    }

    const controles = el('div', 'controles');
    controles.append(menos, mas);

    art.append(
        crearMiniatura(p),
        info,
        el('div', 'precio-articulo', dinero(aCentavos(p.price) * p.cantidad)),
        controles
    );
    return art;
}

function render() {
    if (!listaCarrito) return;
    if (carrito.length === 0) {
        listaCarrito.replaceChildren();
        mensajeCarrito.textContent = 'El carrito está vacío.';
        totalCarrito.textContent = dinero(0);
    } else {
        mensajeCarrito.textContent = '';
        const frag = document.createDocumentFragment();
        carrito.forEach((p, i) => frag.appendChild(crearArticulo(p, i)));
        listaCarrito.replaceChildren(frag);
        totalCarrito.textContent = dinero(totalCentavos());
    }
    calcularCambio();
    validarBotonFinalizar();
}

// ---------- Acciones ----------
function actualizarCantidad(index, accion) {
    const p = carrito[index];
    if (!p) return;
    if (accion === 'aumentar') {
        const limite = limiteDe(p);
        if (p.cantidad >= limite) {
            const s = stockDe(p);
            alert(s !== null && s < MAX_CANTIDAD
                ? `Solo hay ${s} unidad(es) disponibles de "${p.name}".`
                : `No puedes agregar más de ${MAX_CANTIDAD} unidades del mismo producto.`);
            return;
        }
        p.cantidad += 1;
    } else if (accion === 'disminuir') {
        // Con 1 unidad, el botón "−" quita el producto (ya no hay botón "Eliminar" aparte)
        if (p.cantidad <= 1) { eliminarProducto(index); return; }
        p.cantidad -= 1;
    }
    guardarCarrito();
    render();
}

function eliminarProducto(index) {
    if (index < 0 || index >= carrito.length) return;
    carrito.splice(index, 1);
    guardarCarrito();
    render();
}

function limpiarCarrito() {
    carrito = [];
    localStorage.removeItem(CARRITO_KEY);
    render();
}

// Selecciona el método de pago (sincroniza select oculto, segmentos y secciones)
function aplicarMetodo(m) {
    if (metodoPago) metodoPago.value = m;
    segmentos.forEach(s => s.setAttribute('aria-pressed', String(s.dataset.metodo === m)));
    if (seccionEfectivo) seccionEfectivo.style.display = m === 'efectivo' ? 'flex' : 'none';
    if (seccionTarjeta) seccionTarjeta.style.display = m === 'tarjeta' ? 'flex' : 'none';
    calcularCambio();
    validarBotonFinalizar();
}

function resetFormularioPago() {
    if (inputEfectivo) inputEfectivo.value = '';
    if (tipoTarjeta) tipoTarjeta.value = '';
    aplicarMetodo('efectivo'); // como en la app: efectivo por defecto
}

if (listaCarrito) {
    listaCarrito.addEventListener('click', (e) => {
        const b = e.target.closest('button');
        if (!b) return;
        const index = Number(b.dataset.index);
        if (b.classList.contains('boton-aumentar')) actualizarCantidad(index, 'aumentar');
        else if (b.classList.contains('boton-disminuir')) actualizarCantidad(index, 'disminuir');
    });
}

if (btnVaciarCarrito) {
    btnVaciarCarrito.addEventListener('click', () => {
        if (carrito.length === 0) { alert('El carrito ya está vacío.'); return; }
        if (confirm('¿Estás seguro de que deseas eliminar todos los productos del carrito?')) {
            limpiarCarrito();
            resetFormularioPago();
        }
    });
}

// ---------- Pago ----------
function dineroRecibidoCentavos() {
    return inputEfectivo ? aCentavos(parseFloat(inputEfectivo.value)) : 0;
}

function calcularCambio() {
    if (!inputEfectivo || !cambioResultado) return;
    const recibido = parseFloat(inputEfectivo.value);
    if (isNaN(recibido)) {
        cambioResultado.textContent = dinero(0);
        cambioResultado.classList.remove('insuficiente');
    } else if (aCentavos(recibido) < totalCentavos()) {
        cambioResultado.textContent = 'Dinero insuficiente';
        cambioResultado.classList.add('insuficiente');
    } else {
        cambioResultado.textContent = dinero(aCentavos(recibido) - totalCentavos());
        cambioResultado.classList.remove('insuficiente');
    }
}

function validarBotonFinalizar() {
    if (!btnFinalizar) return;
    const metodo = metodoPago ? metodoPago.value : '';
    // No se puede vender si el stock no está verificado o alguna línea excede las existencias
    let ok = carrito.length > 0 && !!metodo && !enviando && stockVerificado && !hayProblemasStock();
    if (ok && metodo === 'tarjeta') ok = !!(tipoTarjeta && tipoTarjeta.value);
    if (ok && metodo === 'efectivo') {
        const r = parseFloat(inputEfectivo ? inputEfectivo.value : NaN);
        ok = !isNaN(r) && aCentavos(r) >= totalCentavos();
    }
    btnFinalizar.disabled = !ok;
}

segmentos.forEach(s => s.addEventListener('click', () => aplicarMetodo(s.dataset.metodo)));
if (tipoTarjeta) tipoTarjeta.addEventListener('change', validarBotonFinalizar);
if (inputEfectivo) inputEfectivo.addEventListener('input', () => { calcularCambio(); validarBotonFinalizar(); });

function obtenerMetodoPagoBD() {
    const m = metodoPago.value;
    if (m === 'efectivo') return 'EFECTIVO';
    if (m === 'tarjeta') return ['TARJETA_CREDITO', 'TARJETA_DEBITO'].includes(tipoTarjeta.value) ? tipoTarjeta.value : null;
    return null;
}

// La MISMA referencia se reutiliza mientras la cuenta no cambie. Si la respuesta se pierde
// por mala conexión y el usuario reintenta, el backend recibe la misma clave y puede
// rechazar el duplicado (requiere restricción UNIQUE en transaction_reference).
function referenciaTransaccion(firma) {
    try {
        const g = JSON.parse(sessionStorage.getItem(REF_KEY) || 'null');
        if (g && g.firma === firma) return g.ref;
    } catch { /* se genera una nueva */ }
    const ref = (window.crypto && crypto.randomUUID)
        ? crypto.randomUUID()
        : `ref-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    sessionStorage.setItem(REF_KEY, JSON.stringify({ firma, ref }));
    return ref;
}

async function procesarVentaBackend() {
    if (carrito.length === 0) return null;
    if (!stockVerificado || hayProblemasStock()) { alert('Hay productos sin stock suficiente. Ajusta las cantidades.'); return null; }

    const paymentMethod = obtenerMetodoPagoBD();
    if (!paymentMethod) { alert('Verifica el método de pago seleccionado.'); return null; }

    const total = totalCentavos();
    let given = total;
    if (metodoPago.value === 'efectivo') {
        given = dineroRecibidoCentavos();
        if (given < total) { alert('Dinero insuficiente para cubrir el total.'); return null; }
    }

    const shiftId = localStorage.getItem('shiftId');
    const cashierId = localStorage.getItem('cashierId');
    if (!shiftId || !cashierId) { alert('No hay un turno activo. Abre turno en Ventas antes de vender.'); return null; }

    const user = obtenerUsuario();
    if (user && user.id && String(user.id) !== String(cashierId)) {
        alert('El turno abierto pertenece a otro cajero. Debe cerrarlo ese usuario.');
        return null;
    }

    const firma = JSON.stringify([carrito.map(p => [p.productId, p.cantidad]), paymentMethod, given]);
    // NOTA: el backend debe recalcular precios/totales y tomar el cajero del JWT;
    // estos campos se envían solo por compatibilidad con el contrato actual.
    const payload = {
        shiftId: Number(shiftId),
        cashierId,
        total: total / 100,
        payment_method: paymentMethod,
        amount_given: given / 100,
        change_given: (given - total) / 100,
        transaction_reference: referenciaTransaccion(firma),
        products: carrito.map(p => ({
            productId: Number(p.productId),
            unit_price: aCentavos(p.price) / 100,
            quantity: p.cantidad,
            subtotal: (aCentavos(p.price) * p.cantidad) / 100
        }))
    };

    try {
        const res = await Api.request(BACKEND_VENTA_URL, { method: 'POST', body: JSON.stringify(payload), timeout: 20000 });
        if (!res.ok) throw new Error(await Api.errorDe(res));
        const data = await res.json().catch(() => ({}));
        sessionStorage.removeItem(REF_KEY);
        sessionStorage.removeItem(CATALOGO_CACHE_KEY); // el stock cambió: el catálogo debe recargarse
        alert(`Venta procesada correctamente.\n\nTotal: ${dinero(total)}`);
        limpiarCarrito();
        resetFormularioPago();
        return data;
    } catch (error) {
        alert(`No se pudo confirmar la venta: ${error.message}\n\nSi el problema fue de conexión, vuelve a pulsar "Confirmar y cobrar": se reutiliza la misma referencia para evitar cobros duplicados. Revisa también la lista de ventas del turno.`);
        refrescarStock(); // por si el error fue de existencias
        return null;
    }
}

// ---------- Verificación de existencias con el servidor ----------
const avisoStock = el('div', 'aviso-stock-global');
avisoStock.setAttribute('role', 'status');
if (mensajeCarrito) mensajeCarrito.after(avisoStock);

function setAvisoStock(texto, onReintentar) {
    avisoStock.replaceChildren();
    if (!texto) return;
    avisoStock.append(el('span', null, texto));
    if (onReintentar) {
        const b = el('button', null, 'Reintentar');
        b.type = 'button';
        b.style.marginLeft = '8px';
        b.addEventListener('click', onReintentar);
        avisoStock.append(b);
    }
}

async function refrescarStock() {
    if (carrito.length === 0) { stockVerificado = true; setAvisoStock(''); return true; }
    setAvisoStock('Verificando existencias...');
    try {
        const res = await Api.request(API_PRODUCTOS_URL, { method: 'GET', retries: 2, timeout: 15000 });
        if (!res.ok) throw new Error(await Api.errorDe(res));
        const data = await res.json();
        const lista = data.product || data.products || (Array.isArray(data) ? data : []);
        const mapa = new Map(lista.map(p => [String(p.productid ?? p.productId), { stock: Number(p.stock), imageURL: p.imageURL }]));

        // Producto ausente o sin stock numérico = sin existencias
        carrito.forEach(p => {
            const info = mapa.get(String(p.productId));
            p.stock = info && Number.isFinite(info.stock) ? info.stock : 0;
            if (info && info.imageURL) p.imageURL = info.imageURL; // completa la foto de productos ya guardados
        });
        guardarCarrito();
        stockVerificado = true;
        setAvisoStock('');
        render();
        return true;
    } catch (err) {
        stockVerificado = false;
        setAvisoStock(`No se pudo verificar el stock: ${err.message}`, refrescarStock);
        validarBotonFinalizar();
        return false;
    }
}

if (btnFinalizar) {
    btnFinalizar.addEventListener('click', async () => {
        if (enviando || carrito.length === 0) return;
        enviando = true;
        btnFinalizar.disabled = true;
        try {
            // Se vuelve a consultar el stock justo antes de cobrar
            if (!(await refrescarStock())) {
                alert('No se pudo verificar el stock. Revisa tu conexión e intenta de nuevo.');
                return;
            }
            if (hayProblemasStock()) {
                alert('Hay productos sin stock suficiente. Ajusta las cantidades o elimina los agotados.');
                return;
            }
            if (!confirm(`¿Confirmas finalizar la venta por ${dinero(totalCentavos())}?`)) return;
            await procesarVentaBackend();
        } finally {
            enviando = false;
            validarBotonFinalizar();
        }
    });
}

aplicarMetodo('efectivo'); // efectivo seleccionado por defecto, como en la app
render();
refrescarStock();