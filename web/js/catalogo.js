
const API_URL ='https://4upkj2tafvod2ubwcsbnagviyu0feljy.lambda-url.us-east-1.on.aws';
// const API_URL ='http://localhost:8081';

const productosContainer = document.getElementById('productos');
const mensaje = document.getElementById('mensaje');

// Nota: Actualmente se guarda el carrito en localStorage, pero se recomienda cambiarlo a backend para persistencia y seguridad
// Guardamos temporalmente los productos recibidos de la API 
let productosActuales = []; 
// Nombre que utilizaremos en localStorage 
const CARRITO_KEY = 'carrito';

// Utilidades de mensajes
function mostrarMensajeCreacion(texto, tipo = 'info') {
    const el = document.getElementById('mensaje-creacion');
    if (!el) return;
    el.textContent = texto;
    el.style.color = tipo === 'error' ? '#d9534f' : (tipo === 'exito' ? '#2e7d32' : '#333');
}

function mostrarMensajeGeneral(texto, tipo = 'info') {
    if (!mensaje) return;
    mensaje.textContent = texto;
    mensaje.style.color = tipo === 'error' ? '#d9534f' : (tipo === 'exito' ? '#2e7d32' : '#333');
}

// Validaciones de producto
function esTextoNoVacio(valor) {
    return typeof valor === 'string' && valor.trim().length > 0;
}
 
function esSkuValido(valor) {
    if (!esTextoNoVacio(valor)) return false;
    return valor.trim().length <= 20;
}
 
function esPrecioValido(valor) {
    // valor debe venir ya como number (resultado de parseFloat)
    if (typeof valor !== 'number' || Number.isNaN(valor)) return false;
    return valor > 0 && valor <= 500;
}
 
function esTypeIdValido(valor) {
    // valor debe venir ya como number (resultado de parseInt)
    if (typeof valor !== 'number' || Number.isNaN(valor)) return false;
    return Number.isInteger(valor) && valor > 0;
}
 
function esUrlValida(valor) {
    if (!esTextoNoVacio(valor)) return false;
    try {
        new URL(valor.trim());
        return true;
    } catch {
        return false;
    }
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

        mostrarProductos(lista);

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
                src="/img/product.jpg" 
                alt="${producto.name}"
                class="producto-imagen"
            >

            <div class="producto-info">
                <h3>${producto.name}</h3>
                <p class="producto-precio"> $${Number(producto.price).toFixed(2)} </p>
                <p> SKU: ${producto.sku} </p>
                <p> Tipo: ${producto.typeid} </p>

                <button class="boton-agregar" data-id="${producto.productId}" > 
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
            // console.log('Producto agregado:', productId);
            const producto = productosActuales.find( 
                p => String(p.productId) === String(productId)
            );
            if (!producto) { 
                console.error("No se encontró el producto:", productId); return; 
                } 
            agregarAlCarrito(producto);
        });
    });
}

function agregarAlCarrito(producto) {
    // Obtener el carrito actual desde localStorage
    let carrito = JSON.parse(localStorage.getItem(CARRITO_KEY)) || [];

    // agregar unicamente la infomación necesaria del producto al carrito
    const productoCarrito = {
        id: producto.productId,
        name: producto.name,
        sku: producto.sku,
        price: producto.price,
        typeid: producto.typeid,
        quantity: 1 
    };

    carrito.push(productoCarrito);
    // guardar de nuevo en localStorage
    localStorage.setItem(CARRITO_KEY, JSON.stringify(carrito));

    console.log("Producto agregado al carrito:", productoCarrito);
    console.log("Carrito actual:", carrito);

    mensaje.textContent = `Producto "${producto.name}" agregado al carrito.`;
}

// Ejecutar cuando cargue la página
cargarProductos();

const formCrear = document.getElementById('form-crear-producto');
// const msgCreacion = document.getElementById('mensaje-creacion');

if (formCrear) {
    formCrear.addEventListener('submit', async (e) => {
        e.preventDefault();
        const token = localStorage.getItem('authToken');
        
        if (!token) {
            mostrarMensajeCreacion("No hay sesión activa. Inicia sesión de nuevo.", 'error');
            return;
        }

        const nameVal = document.getElementById('prod-name').value.trim();
        const skuVal = document.getElementById('prod-sku').value.trim();
        const priceInput = document.getElementById('prod-price').value.trim();
        const typeInput = document.getElementById('prod-type').value.trim();
        const imgVal = document.getElementById('prod-img').value.trim();

        // --- Validaciones ---
        if (!esTextoNoVacio(nameVal)) {
            mostrarMensajeCreacion("El nombre del producto es obligatorio.", 'error');
            return;
        }
 
        if (!esTextoNoVacio(skuVal)) {
            mostrarMensajeCreacion("El SKU es obligatorio.", 'error');
            return;
        }
        if (!esSkuValido(skuVal)) {
            mostrarMensajeCreacion(`El SKU no puede tener más de 20 caracteres (tiene ${skuVal.length}).`, 'error');
            return;
        }
 
        if (!esTextoNoVacio(priceInput)) {
            mostrarMensajeCreacion("El precio es obligatorio.", 'error');
            return;
        }
        const priceVal = parseFloat(priceInput);
        if (Number.isNaN(priceVal)) {
            mostrarMensajeCreacion("El precio debe ser un número válido.", 'error');
            return;
        }
        if (!esPrecioValido(priceVal)) {
            mostrarMensajeCreacion("El precio debe ser mayor a 0 y no puede exceder 500.", 'error');
            return;
        }
 
        if (!esTextoNoVacio(typeInput)) {
            mostrarMensajeCreacion("El TypeId es obligatorio.", 'error');
            return;
        }
        const typeIdVal = parseInt(typeInput, 10);
        if (Number.isNaN(typeIdVal)) {
            mostrarMensajeCreacion("El TypeId debe ser un número entero válido.", 'error');
            return;
        }
        if (!esTypeIdValido(typeIdVal)) {
            mostrarMensajeCreacion("El TypeId debe ser un número entero mayor a 0.", 'error');
            return;
        }
 
        if (!esTextoNoVacio(imgVal)) {
            mostrarMensajeCreacion("La URL de imagen es obligatoria.", 'error');
            return;
        }
        if (!esUrlValida(imgVal)) {
            mostrarMensajeCreacion("La URL de imagen no tiene un formato válido (debe incluir http:// o https://).", 'error');
            return;
        }

        const payload = {
            Name: nameVal,
            SKU: skuVal,
            Price: priceVal,
            TypeId: typeIdVal,
            ImageUrl: imgVal
        };

        try {
            // Usamos tu helper en lugar de la variable comentada
            mostrarMensajeCreacion("Creando producto...", 'info');

            const res = await fetch(`${API_URL}/api/products/product/create`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(payload)
            });

            const data = await res.json().catch(() => null);

            if (!res.ok) {
                // Simplificamos el manejo del error para evitar referencias rotas
                const serverMsg = data?.message || data?.Message || data?.error || `Error HTTP ${res.status}`;
                throw new Error(serverMsg);
            }

            console.log("Respuesta creación exitosa:", data);
            mostrarMensajeCreacion("¡Producto creado con éxito!", 'exito');
            
            formCrear.reset();
            cargarProductos(); 
            
        } catch (err) {
            console.error("Error al registrar producto:", err);
            // Mostrar error usando la función segura
            mostrarMensajeCreacion("Error al crear: " + err.message, 'error');
        }
    });
}
