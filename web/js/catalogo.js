'use strict';
const API_URL = 'https://4upkj2tafvod2ubwcsbnagviyu0feljy.lambda-url.us-east-1.on.aws';
const CARRITO_KEY = 'carrito';
const CACHE_KEY = 'catalogoCache';
const CACHE_MS = 60 * 1000;
const MAX_CANTIDAD = 20; // misma regla que en carrito.js
const IMG_FALLBACK = '/img/product.jpg';

const productosContainer = document.getElementById('productos');
const mensaje = document.getElementById('mensaje');
const buscador = document.getElementById('buscador');

let productosActuales = [];
let terminoBusqueda = '';

function mostrarMensajeGeneral(texto, tipo = 'info') {
    if (!mensaje) return;
    mensaje.textContent = texto;
    mensaje.style.color = tipo === 'error' ? '#d9534f' : (tipo === 'exito' ? '#2e7d32' : '#333');
}

function normalizar(texto) {
    return String(texto ?? '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
}

// null si el dato no viene o no es numérico
function stockDe(p) {
    if (p == null || p.stock == null || p.stock === '') return null;
    const n = Number(p.stock);
    return Number.isFinite(n) ? n : null;
}

function aplicarFiltro() {
    const termino = normalizar(terminoBusqueda);
    const filtrados = termino ? productosActuales.filter(p => p._q.includes(termino)) : productosActuales;
    if (termino && filtrados.length === 0) {
        productosContainer.replaceChildren();
        mostrarMensajeGeneral(`No se encontraron productos para "${terminoBusqueda.trim()}".`);
        return;
    }
    mostrarProductos(filtrados);
}

if (buscador) {
    buscador.addEventListener('input', Api.debounce(() => {
        terminoBusqueda = buscador.value;
        aplicarFiltro();
    }, 200));
    buscador.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') { buscador.value = ''; terminoBusqueda = ''; aplicarFiltro(); }
    });
}

function leerCache(aunVencida = false) {
    try {
        const c = JSON.parse(sessionStorage.getItem(CACHE_KEY) || 'null');
        if (c && Array.isArray(c.lista) && (aunVencida || Date.now() - c.t < CACHE_MS)) return c.lista;
    } catch { /* cache corrupta: se ignora */ }
    return null;
}

function usarLista(lista) {
    // Los productos con stock = 0 no se muestran en el catálogo
    productosActuales = lista
        .filter(p => { const s = stockDe(p); return s === null || s > 0; })
        .map(p => ({ ...p, _q: normalizar(`${p.name} ${p.sku}`) }));
    aplicarFiltro();
}

async function cargarProductos() {
    const fresca = leerCache();
    if (fresca) { usarLista(fresca); return; }

    try {
        mostrarMensajeGeneral('Cargando productos...');
        const res = await Api.request(`${API_URL}/api/products/product/get`, { method: 'GET', retries: 2 });
        if (!res.ok) throw new Error(await Api.errorDe(res));

        const data = await res.json();
        const lista = data.product || data.products || (Array.isArray(data) ? data : []);
        try { sessionStorage.setItem(CACHE_KEY, JSON.stringify({ t: Date.now(), lista })); } catch { /* sin espacio */ }
        mensaje.textContent = '';
        usarLista(lista);
    } catch (err) {
        const vieja = leerCache(true);
        if (vieja) {
            usarLista(vieja);
            mostrarMensajeGeneral('Sin conexión estable: mostrando el último catálogo guardado.', 'error');
        } else {
            mostrarMensajeGeneral('No se pudieron cargar los productos: ' + err.message, 'error');
        }
    }
}

function crearTarjeta(p) {
    const article = document.createElement('article');
    article.className = 'producto';

    const img = document.createElement('img');
    img.className = 'producto-imagen';
    img.loading = 'lazy';
    img.decoding = 'async';
    img.alt = p.name ?? '';
    img.src = Api.urlSegura(p.imageURL) || IMG_FALLBACK;
    img.addEventListener('error', () => { img.src = IMG_FALLBACK; }, { once: true });

    const info = document.createElement('div');
    info.className = 'producto-info';
    const h3 = document.createElement('h3'); h3.textContent = p.name;
    const precio = document.createElement('p'); precio.className = 'producto-precio';
    precio.textContent = `$${Number(p.price).toFixed(2)}`;
    const sku = document.createElement('p'); sku.textContent = `SKU: ${p.sku}`;
    const tipo = document.createElement('p'); tipo.textContent = `Tipo: ${p.type?.typeName ?? 'Sin tipo'}`;
    const stockActual = stockDe(p);
    const stock = document.createElement('p');
    stock.className = 'producto-stock';
    stock.textContent = stockActual === null ? 'Disponibilidad no informada' : `Disponibles: ${stockActual}`;
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'boton-agregar';
    btn.dataset.id = p.productid;
    btn.textContent = 'Agregar al carrito';

    info.append(h3, precio, sku, tipo, stock, btn);
    article.append(img, info);
    return article;
}

function mostrarProductos(productos) {
    mensaje.textContent = '';
    if (!productos || productos.length === 0) {
        productosContainer.replaceChildren();
        mensaje.textContent = 'No hay productos disponibles.';
        return;
    }
    const frag = document.createDocumentFragment();
    productos.forEach(p => frag.appendChild(crearTarjeta(p)));
    productosContainer.replaceChildren(frag);
}

// Un solo listener delegado
productosContainer.addEventListener('click', (e) => {
    const boton = e.target.closest('.boton-agregar');
    if (!boton) return;
    const producto = productosActuales.find(p => String(p.productid) === String(boton.dataset.id));
    if (producto) agregarAlCarrito(producto);
});

function leerCarrito() {
    try {
        const d = JSON.parse(localStorage.getItem(CARRITO_KEY) || '[]');
        return Array.isArray(d) ? d : [];
    } catch { return []; }
}

function agregarAlCarrito(producto) {
    const carrito = leerCarrito();
    const stock = stockDe(producto);
    const limite = stock === null ? MAX_CANTIDAD : Math.min(MAX_CANTIDAD, stock);
    const existente = carrito.find(i => String(i.productId) === String(producto.productid));
    const actual = existente ? (Number(existente.cantidad) || 0) : 0;

    if (actual >= limite) {
        mostrarMensajeGeneral(
            stock !== null && stock < MAX_CANTIDAD
                ? `Solo hay ${stock} unidad(es) disponibles de "${producto.name}".`
                : `No puedes agregar más de ${MAX_CANTIDAD} unidades de "${producto.name}".`,
            'error'
        );
        return;
    }

    if (existente) {
        existente.cantidad = actual + 1;
        existente.stock = stock; // referencia; el carrito vuelve a verificarlo con el servidor
    } else {
        carrito.push({
            productId: producto.productid,
            typeid: producto.type?.typeid ?? null,
            typeName: producto.type?.typeName ?? 'Sin tipo',
            name: producto.name,
            sku: producto.sku,
            price: producto.price,
            stock,
            cantidad: 1
        });
    }
    localStorage.setItem(CARRITO_KEY, JSON.stringify(carrito));
    mostrarMensajeGeneral(`Producto "${producto.name}" agregado al carrito.`, 'exito');
}

cargarProductos();