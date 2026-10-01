
const API_URL ='https://4upkj2tafvod2ubwcsbnagviyu0feljy.lambda-url.us-east-1.on.aws';
const productosContainer = document.getElementById('productos');
const mensaje = document.getElementById('mensaje');

const buscador = document.getElementById('buscador');
let terminoBusqueda = '';
// Nota: Actualmente se guarda el carrito en localStorage, pero se recomienda cambiarlo a backend para persistencia y seguridad
// Guardamos temporalmente los productos recibidos de la API 
let productosActuales = []; 
// Nombre que utilizaremos en localStorage 
const CARRITO_KEY = 'carrito';

// Utilidades de mensajes

function mostrarMensajeGeneral(texto, tipo = 'info') {
    if (!mensaje) return;
    mensaje.textContent = texto;
    mensaje.style.color = tipo === 'error' ? '#d9534f' : (tipo === 'exito' ? '#2e7d32' : '#333');
}

// buscador 


function normalizar(texto) {
    return String(texto ?? '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
}

function aplicarFiltro() {
    const termino = normalizar(terminoBusqueda);
    const filtrados = termino
        ? productosActuales.filter(p =>
            normalizar(p.name).includes(termino) || normalizar(p.sku).includes(termino))
        : productosActuales;

    if (termino && filtrados.length === 0) {
        productosContainer.innerHTML = '';
        mostrarMensajeGeneral(`No se encontraron productos para "${terminoBusqueda.trim()}".`);
        return;
    }
    mostrarProductos(filtrados);
}

if (buscador) {
    buscador.addEventListener('input', () => {
        terminoBusqueda = buscador.value;
        aplicarFiltro();
    });
    buscador.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            buscador.value = '';
            terminoBusqueda = '';
            aplicarFiltro();
        }
    });
}


// Productos (GET)
async function cargarProductos() {
    const token = localStorage.getItem('authToken');

    console.log("Token actual en localStorage:", token);

    if (!token) {
        mensaje.textContent = "Error: No hay token guardado en localStorage.";
        // window.location.href = 'index.html'; // COMENTA ESTO TEMPORALMENTE
        return;
    }

    try {
        mensaje.textContent = 'Cargando productos...';
        const response = await fetch(API_URL + "/api/products/product/get", {
        // const response = await fetch(API_URL + "/api/products/product/get", {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });

        console.log("Status del backend:", response.status);

        if (response.status === 401) {
            mensaje.textContent = "Error 401: El backend rechazó el token (Unauthorized).";
            return;
        }

        if (response.status === 403) {
            mensaje.textContent = "Error 403: Token válido pero sin permisos requeridos (Forbidden).";
            return;
        }

        if (!response.ok) {
            const data = await response.json().catch(() => ({}));
            const detalle = data.message || data.Message || data.error || `HTTP ${response.status}`;
            mostrarMensajeGeneral("No se pudieron cargar los productos: " + detalle, 'error');
            return;
        }

        const data = await response.json();
        console.log("Productos recibidos:", data);

        // Limpiar el mensaje de carga
        mensaje.textContent = '';

        // El backend devuelve la lista dentro de data.product
        const lista = data.product || data.products || (Array.isArray(data) ? data : []);
        
        productosActuales = lista; // Guardar los productos cargados
        console.log("Se guardo con exito la siguiente lista:", productosActuales);

        // mostrarProductos(lista);    
        aplicarFiltro();   // respeta el texto del buscador al recargar la lista

    } catch (err) {
        console.error("Error en fetch:", err);
        mensaje.textContent = "Error al conectar: " + err.message;
    }
}


function mostrarProductos(productos) {

    productosContainer.innerHTML = '';
    mensaje.textContent = '';

    if (!productos || productos.length === 0) {

        mensaje.textContent = 'No hay productos disponibles.';
        return;
    }

    productos.forEach(producto => {
        console.log('producto individual:', producto);

        const article = document.createElement('article');

        article.classList.add('producto');

        article.innerHTML = `
            <img 
                src="${producto.imageURL || '/img/product.jpg'}" 
                alt="${producto.name}"
                class="producto-imagen"
                onerror="this.src='/img/product.jpg'"
            >

            <div class="producto-info">
                <h3>${producto.name}</h3>
                <p class="producto-precio"> $${Number(producto.price).toFixed(2)} </p>
                <p> SKU: ${producto.sku} </p>
                <p> Tipo: ${producto.type?.typeName ?? 'Sin tipo'} </p>

                <button class="boton-agregar" data-id="${producto.productid}" > 
                    Agregar al carrito 
                </button>

            </div>
        `;

        productosContainer.appendChild(article);
    });

    agregarEventosBotones();
}


function agregarEventosBotones() {
    const botones = document.querySelectorAll('.boton-agregar');

    botones.forEach(boton => {
        boton.addEventListener('click', () => {
            const productId = boton.dataset.id;
            console.log('Producto agregado:', productId);
            const producto = productosActuales.find(
                p => String(p.productid) === String(productId)
            );
            if (!producto) {
                console.error("No se encontró el producto:", productId);
                return;
            }
            agregarAlCarrito(producto);
        });
    });
}

const MAX_CANTIDAD = 10; // misma regla que en carrito.js

function agregarAlCarrito(producto) {
    const carrito = JSON.parse(localStorage.getItem(CARRITO_KEY)) || [];

    // Buscar si el producto ya está en el carrito (por id del PRODUCTO)
    const existente = carrito.find(
        item => String(item.productId) === String(producto.productid)
    );

    if (existente) {
        if ((Number(existente.cantidad) || 0) >= MAX_CANTIDAD) {
            mostrarMensajeGeneral(
                `No puedes agregar más de ${MAX_CANTIDAD} unidades de "${producto.name}".`,
                'error'
            );
            return;
        }
        existente.cantidad = (Number(existente.cantidad) || 0) + 1;
    } else {
        carrito.push({
            productId: producto.productid,          // id del producto
            typeid: producto.type?.typeid ?? null,  // id del tipo
            typeName: producto.type?.typeName ?? 'Sin tipo',
            name: producto.name,
            sku: producto.sku,
            price: producto.price,
            cantidad: 1
        });
    }

    localStorage.setItem(CARRITO_KEY, JSON.stringify(carrito));

    console.log("Carrito actual:", carrito);
    mostrarMensajeGeneral(`Producto "${producto.name}" agregado al carrito.`, 'exito');
}
// Ejecutar cuando cargue la página
cargarProductos();

