// NOTAS DE PUSH: 
// SE AGREGO LA FUNCIONALIDAD SELECCIONAR PRODUCTOS
// SE AGREGO SELECCIONAR PRODUCTOS Y AGREGARLOS AL CARRITO
// SE AGREGO UN BOTON QUE LLEVA A CARRITO.HTML


const API_URL ='https://4upkj2tafvod2ubwcsbnagviyu0feljy.lambda-url.us-east-1.on.aws';
// const API_URL ='http://localhost:8081';

const productosContainer = document.getElementById('productos');
const mensaje = document.getElementById('mensaje');

// Nota: Actualmente se guarda el carrito en localStorage, pero se recomienda cambiarlo a backend para persistencia y seguridad
// Guardamos temporalmente los productos recibidos de la API 
let productosActuales = []; 
// Nombre que utilizaremos en localStorage 
const CARRITO_KEY = 'carrito';

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
            // localStorage.removeItem('authToken'); // COMENTA ESTO TEMPORALMENTE
            // window.location.href = 'index.html';
            return;
        }

        if (response.status === 403) {
            mensaje.textContent = "Error 403: Token válido pero sin permisos requeridos (Forbidden).";
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

                <p class="producto-precio">
                    $${Number(producto.price).toFixed(2)}
                </p>

                <p>
                    SKU: ${producto.sku}
                </p>

                <p>
                    Tipo: ${producto.typeid}
                </p>

                <button class="boton-agregar" data-id="${producto.id}" > 
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

            // Posteriormente aquí conectaremos el carrito
            // Buscar el producto completo en la lista 
            const producto = productosActuales.find( 
                p => String(p.id) === String(productId) ); 
            
            if (!producto) { 
                console.error("No se encontró el producto:", productId); return; 
                } 
            agregarAlCarrito(producto);

            // productosActuales es un arreglo que contiene todos los productos cargados actualmente, se debe definir en el ámbito global para que esté disponible aquí.
            // se necesita modificar la API para que conserve el estado del carrito en el backend y no en localStorage


        });

    });
}

function agregarAlCarrito(producto) {
    // Obtener el carrito actual desde localStorage
    let carrito = JSON.parse(localStorage.getItem(CARRITO_KEY)) || [];

    // agregar unicamente la infomación necesaria del producto al carrito
    const productoCarrito = {
        id: producto.id,
        name: producto.name,
        sku: producto.sku,
        price: producto.price,
        typeid: producto.typeid,
        quantity: 1 // cantidad inicial
        // para quantity se puede implementar un input en el modal de carrito.html para que el usuario pueda modificar la cantidad de cada producto
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
const msgCreacion = document.getElementById('mensaje-creacion');

if (formCrear) {
    formCrear.addEventListener('submit', async (e) => {
        e.preventDefault();
        const token = localStorage.getItem('authToken');

        const nameVal = document.getElementById('prod-name').value.trim();
        const skuVal = document.getElementById('prod-sku').value.trim();
        const priceVal = parseFloat(document.getElementById('prod-price').value) || 0;
        const typeIdVal = parseInt(document.getElementById('prod-type').value, 10) || 1;
        const imgVal = document.getElementById('prod-img').value.trim();

        // Enviamos nombres en PascalCase y camelCase para cubrir cualquier mapeo de EF/DTO
        const payload = {
            Name: nameVal,
            name: nameVal,
            SKU: skuVal,
            Sku: skuVal,
            sku: skuVal,
            Price: priceVal,
            price: priceVal,
            TypeId: typeIdVal,
            typeId: typeIdVal,
            ImageUrl: imgVal,
            ImageURL: imgVal,
            imageUrl: imgVal
        };


        //

        try {
            if (msgCreacion) msgCreacion.textContent = "Creando producto...";

            const res = await fetch(`${API_URL}/api/products/product/create`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(payload)
            });

            // Extraer respuesta del backend antes de validar el status
            const data = await res.json().catch(() => null);

            if (!res.ok) {
                console.error("Detalle completo del error 500:", data);
                const serverMsg = data?.message || data?.Message || data?.error || data?.title || JSON.stringify(data);
                throw new Error(`HTTP ${res.status}: ${serverMsg}`);
            }

            console.log("Respuesta creación exitosa:", data);
            if (msgCreacion) msgCreacion.textContent = "¡Producto creado con éxito!";
            formCrear.reset();
            
            if (typeof cargarProductos === 'function') {
                cargarProductos();
            }
        } catch (err) {
            console.error("Error al registrar producto:", err);
            if (msgCreacion) msgCreacion.textContent = "Error al crear: " + err.message;
        }
    });
}