// ==========================================
// MACHAPOINT POS
// Administración de productos (alta y edición)
// ==========================================

const API_URL = 'https://4upkj2tafvod2ubwcsbnagviyu0feljy.lambda-url.us-east-1.on.aws';

const UPDATE_METHOD = 'PATCH';

const IMG_FALLBACK = '/img/product.jpg';

// Mismos tipos que catalogo.html
const TIPOS = [
    { id: 1, nombre: 'Poster' },
    { id: 2, nombre: 'Pines' },
    { id: 3, nombre: 'Stickers' },
    { id: 4, nombre: 'Postales' }
];

// ---------- DOM ----------
const formCrear = document.getElementById('form-crear-producto');
const btnCrear = document.getElementById('btn-crear');
const msgCreacion = document.getElementById('mensaje-creacion');

const buscador = document.getElementById('buscador');
const msgLista = document.getElementById('mensaje');
const tbody = document.getElementById('tabla-productos');

const dialogo = document.getElementById('dialogo-editar');
const formEditar = document.getElementById('form-editar');
const btnGuardarEdicion = document.getElementById('btn-guardar-edicion');
const btnCancelarEdicion = document.getElementById('btn-cancelar-edicion');
const msgEdicion = document.getElementById('mensaje-edicion');

let productos = [];          // lista normalizada
let productoEnEdicion = null;

// ---------- Utilidades ----------

function setMsg(el, texto, tipo = 'info') {
    if (!el) return;
    el.textContent = texto;
    el.classList.remove('mp-inline-msg--success', 'mp-inline-msg--error');
    if (tipo === 'error') el.classList.add('mp-inline-msg--error');
    else if (tipo === 'exito') el.classList.add('mp-inline-msg--success');
}

function esAdmin() {
    return !!(window.Auth && Auth.isAdmin());
}

// Minúsculas y sin acentos, para que "camion" encuentre "Camión"
function normalizarTexto(texto) {
    return String(texto ?? '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
}

function nombreTipo(id) {
    const tipo = TIPOS.find(t => t.id === Number(id));
    return tipo ? tipo.nombre : (id ? `Tipo ${id}` : 'Sin tipo');
}

async function authFetch(url, options = {}) {
    const token = localStorage.getItem('authToken');
    const res = await fetch(url, {
        ...options,
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`,
            ...(options.headers || {})
        }
    });
    if (res.status === 401 && window.Auth) {
        Auth.forceLogout('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    return res;
}

async function errorDelServidor(res) {
    const data = await res.json().catch(() => ({}));
    return data.message || data.Message || data.error || `Error HTTP ${res.status}`;
}

// El GET devuelve { productid, type: { typeid, typeName }, ... }
function normalizarProducto(p) {
    const typeId = Number(p.type?.typeid ?? p.typeId ?? p.typeid);
    return {
        id: p.productid ?? p.productId,
        name: p.name ?? '',
        sku: p.sku ?? '',
        typeId,
        typeName: p.type?.typeName ?? nombreTipo(typeId),
        price: Number(p.price),
        imageURL: p.imageURL ?? ''
    };
}

// ---------- Validación (mismas reglas que catalogo.js) ----------
// Recibe los textos crudos del formulario y devuelve { error } o { valores }

function validarCampos({ name, sku, price, typeId, img }) {
    name = name.trim();
    sku = sku.trim();
    price = price.trim();
    img = img.trim();

    if (!name) return { error: 'El nombre del producto es obligatorio.' };

    if (!sku) return { error: 'El SKU es obligatorio.' };
    if (sku.length > 20) return { error: `El SKU no puede tener más de 20 caracteres (tiene ${sku.length}).` };

    if (!price) return { error: 'El precio es obligatorio.' };
    const precio = Number(price);
    if (Number.isNaN(precio)) return { error: 'El precio debe ser un número válido.' };
    if (precio <= 0 || precio > 500) return { error: 'El precio debe ser mayor a 0 y no puede exceder 500.' };

    const tipo = parseInt(typeId, 10);
    if (Number.isNaN(tipo) || tipo <= 0) return { error: 'Selecciona un tipo de producto.' };

    if (!img) return { error: 'La URL de imagen es obligatoria.' };
    try {
        const url = new URL(img);
        if (!['http:', 'https:'].includes(url.protocol)) throw new Error('protocolo');
    } catch {
        return { error: 'La URL de imagen no es válida (debe incluir http:// o https://).' };
    }

    return { valores: { name, sku, price: precio, typeId: tipo, img } };
}

// ---------- Listado ----------

async function cargarProductos() {
    setMsg(msgLista, 'Cargando productos...');
    try {
        const res = await authFetch(`${API_URL}/api/products/product/get`);
        if (res.status === 403) {
            setMsg(msgLista, 'Tu usuario no tiene permisos para ver los productos.', 'error');
            return;
        }
        if (!res.ok) throw new Error(await errorDelServidor(res));

        const data = await res.json();
        const lista = data.product || data.products || (Array.isArray(data) ? data : []);
        productos = lista.map(normalizarProducto);
        renderTabla();
    } catch (err) {
        console.error('Error al cargar productos:', err);
        setMsg(msgLista, 'No se pudieron cargar los productos: ' + err.message, 'error');
    }
}

function celda(texto, clase) {
    const td = document.createElement('td');
    td.textContent = texto;
    if (clase) td.className = clase;
    return td;
}

function celdaBadge(texto) {
    const td = document.createElement('td');
    const badge = document.createElement('span');
    badge.className = 'mp-badge';
    badge.textContent = texto;
    td.appendChild(badge);
    return td;
}

function crearFila(p) {
    const tr = document.createElement('tr');

    const tdImg = document.createElement('td');
    const img = document.createElement('img');
    img.src = p.imageURL || IMG_FALLBACK;
    img.alt = p.name;
    img.className = 'pp-miniatura';
    img.addEventListener('error', () => { img.src = IMG_FALLBACK; }, { once: true });
    tdImg.appendChild(img);

    const tdAcc = document.createElement('td');
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'mp-btn mp-btn--dark pp-btn-sm';
    btn.textContent = 'Editar';
    btn.setAttribute('aria-label', `Editar ${p.name}`);
    btn.addEventListener('click', () => abrirEdicion(p));
    tdAcc.appendChild(btn);

    tr.append(tdImg, celda(p.name), celda(p.sku), celdaBadge(p.typeName),
              celda(`$${p.price.toFixed(2)}`, 'num'), tdAcc);
    return tr;
}

function renderTabla() {
    const termino = normalizarTexto(buscador.value);
    const lista = termino
        ? productos.filter(p => normalizarTexto(p.name).includes(termino) || normalizarTexto(p.sku).includes(termino))
        : productos;

    tbody.replaceChildren();

    if (lista.length === 0) {
        setMsg(msgLista, productos.length
            ? `No se encontraron productos para "${buscador.value.trim()}".`
            : 'No hay productos registrados.');
        return;
    }

    setMsg(msgLista, '');
    lista.forEach(p => tbody.appendChild(crearFila(p)));
}

buscador.addEventListener('input', renderTabla);
buscador.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        buscador.value = '';
        renderTabla();
    }
});

// ---------- Alta ----------

formCrear.addEventListener('submit', async (e) => {
    e.preventDefault();

    if (!esAdmin()) {
        setMsg(msgCreacion, 'No tienes permisos para crear productos.', 'error');
<<<<<<< HEAD
        await new Promise(resolve => setTimeout(resolve, 3000));        
=======
>>>>>>> origin/main
        return;
    }

    const v = validarCampos({
        name: document.getElementById('prod-name').value,
        sku: document.getElementById('prod-sku').value,
        price: document.getElementById('prod-price').value,
        typeId: document.getElementById('prod-type').value,
        img: document.getElementById('prod-img').value
    });
    if (v.error) {
        setMsg(msgCreacion, v.error, 'error');
        return;
    }

    const { name, sku, price, typeId, img } = v.valores;
    const payload = { Name: name, SKU: sku, Price: price, TypeId: typeId, ImageURL: img };

    btnCrear.disabled = true;
    setMsg(msgCreacion, 'Creando producto...');

    try {
        const res = await authFetch(`${API_URL}/api/products/product/create`, {
            method: 'POST',
            body: JSON.stringify(payload)
        });
        if (!res.ok) throw new Error(await errorDelServidor(res));

        setMsg(msgCreacion, '¡Producto creado con éxito!', 'exito');
        formCrear.reset();
        await cargarProductos();
    } catch (err) {
        console.error('Error al registrar producto:', err);
        setMsg(msgCreacion, 'Error al crear: ' + err.message, 'error');
    } finally {
        btnCrear.disabled = false;
    }
});

// ---------- Edición ----------

function abrirEdicion(p) {
    productoEnEdicion = p;
    document.getElementById('ed-name').value = p.name;
    document.getElementById('ed-sku').value = p.sku;
    document.getElementById('ed-price').value = p.price;
    document.getElementById('ed-type').value = String(p.typeId);
    document.getElementById('ed-img').value = p.imageURL;
    document.getElementById('titulo-edicion').textContent = `Editar producto #${p.id}`;
    setMsg(msgEdicion, '');
    dialogo.showModal();
}

function cerrarEdicion() {
    dialogo.close();
    productoEnEdicion = null;
}

btnCancelarEdicion.addEventListener('click', cerrarEdicion);

// Clic en el fondo oscuro cierra el diálogo
dialogo.addEventListener('click', (e) => {
    if (e.target === dialogo) cerrarEdicion();
});

formEditar.addEventListener('submit', async (e) => {
    e.preventDefault();

    if (!esAdmin()) {
        setMsg(msgEdicion, 'No tienes permisos para editar productos.', 'error');
<<<<<<< HEAD
        await new Promise(resolve => setTimeout(resolve, 3000));        
=======
>>>>>>> origin/main
        return;
    }
    if (!productoEnEdicion) return;
    const original = productoEnEdicion;

    const v = validarCampos({
        name: document.getElementById('ed-name').value,
        sku: document.getElementById('ed-sku').value,
        price: document.getElementById('ed-price').value,
        typeId: document.getElementById('ed-type').value,
        img: document.getElementById('ed-img').value
    });
    if (v.error) {
        setMsg(msgEdicion, v.error, 'error');
        return;
    }

    // Solo se envía lo que realmente cambió
    const { name, sku, price, typeId, img } = v.valores;
    const cambios = {};
    if (name !== original.name) cambios.name = name;
    if (sku !== original.sku) cambios.sku = sku;
    if (price !== original.price) cambios.price = price;
    if (typeId !== original.typeId) cambios.typeId = typeId;
    if (img !== original.imageURL) cambios.imageURL = img;

    if (Object.keys(cambios).length === 0) {
        setMsg(msgEdicion, 'No hay cambios que guardar.');
        return;
    }

    btnGuardarEdicion.disabled = true;
    setMsg(msgEdicion, 'Guardando cambios...');

    try {
        const res = await authFetch(`${API_URL}/api/products/product/update/${encodeURIComponent(original.id)}`, {
            method: UPDATE_METHOD,
            body: JSON.stringify(cambios)
        });

        const data = await res.json().catch(() => ({}));
        if (!res.ok || data.success === false) {
            throw new Error(data.message || data.Message || data.error || `Error HTTP ${res.status}`);
        }

        cerrarEdicion();
        await cargarProductos();
        setMsg(msgLista, data.message || 'Producto actualizado con éxito.', 'exito');
    } catch (err) {
        console.error('Error al actualizar producto:', err);
        setMsg(msgEdicion, 'Error al guardar: ' + err.message, 'error');
    } finally {
        btnGuardarEdicion.disabled = false;
    }
});

// ---------- Inicio ----------

// Opciones de tipo para ambos formularios
['prod-type', 'ed-type'].forEach(id => {
    const select = document.getElementById(id);
    TIPOS.forEach(t => {
        const option = document.createElement('option');
        option.value = String(t.id);
        option.textContent = `Tipo ${t.id} (${t.nombre})`;
        select.appendChild(option);
    });
});

cargarProductos();