const API_URL ='https://4upkj2tafvod2ubwcsbnagviyu0feljy.lambda-url.us-east-1.on.aws';
// const API_URL ='http://localhost:8081';

const productosContainer = document.getElementById('productos');
const mensaje = document.getElementById('mensaje');

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
                src="${producto.imageURL}" 
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


            </div>
        `;

        productosContainer.appendChild(article);
    });

    agregarEventosBotones();
}


function agregarEventosBotones() {

    const botones = document.querySelectorAll('.btn-agregar');

    botones.forEach(boton => {

        boton.addEventListener('click', () => {

            const productId = boton.dataset.id;

            console.log('Producto agregado:', productId);

            // Posteriormente aquí conectaremos el carrito
        });

    });
}


// Ejecutar cuando cargue la página
cargarProductos();

const formCrear = document.getElementById('form-crear-producto');
const msgCreacion = document.getElementById('mensaje-creacion');

if (formCrear) {
    formCrear.addEventListener('submit', async (e) => {
        e.preventDefault();
        const token = localStorage.getItem('authToken');

        const payload = {
            Name: document.getElementById('prod-name').value,
            SKU: document.getElementById('prod-sku').value,
            Price: parseFloat(document.getElementById('prod-price').value),
            TypeId: parseInt(document.getElementById('prod-type').value, 10),
            ImageURL: document.getElementById('prod-img').value
        };

        try {
            msgCreacion.textContent = "Creando producto...";
            const res = await fetch(`${API_URL}/api/products/product/create`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(payload)
            });

            if (!res.ok) throw new Error(`HTTP ${res.status}`);

            msgCreacion.textContent = "¡Producto creado con éxito!";
            formCrear.reset();
            cargarProductos(); // Recarga la lista automáticamente
        } catch (err) {
            msgCreacion.textContent = "Error al crear: " + err.message;
        }
    });
}