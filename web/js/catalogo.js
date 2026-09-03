const API_URL =
    'https://4upkj2tafvod2ubwcsbnagviyu0feljy.lambda-url.us-east-1.on.aws/api/products';

const productosContainer = document.getElementById('productos');
const mensaje = document.getElementById('mensaje');

async function cargarProductos() {

    const token = localStorage.getItem('authToken');

    // Verificar que exista el JWT
    if (!token) {
        window.location.href = 'index.html';
        return;
    }

    try {

        mensaje.textContent = 'Cargando productos...';

        const response = await fetch(API_URL, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });

        // Si el token no es válido o no tiene permisos
        if (response.status === 401) {
            localStorage.removeItem('authToken');
            window.location.href = 'index.html';
            return;
        }

        if (response.status === 403) {
            mensaje.textContent = 'No tienes permisos para consultar los productos.';
            return;
        }

        if (!response.ok) {
            throw new Error(`Error HTTP: ${response.status}`);
        }

        const productos = await response.json();

        console.log('Productos recibidos:', productos);

        mostrarProductos(productos);

    } catch (error) {

        console.error('Error al cargar productos:', error);

        mensaje.textContent =
            'No fue posible cargar el catálogo. Intenta nuevamente.';
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