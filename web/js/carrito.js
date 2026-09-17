const CARRITO_KEY = 'carrito';
const CUENTAS_KEY = 'cuentas';
const BACKEND_VENTA_URL = 'https://6uxm3jz7xwth5cliak6zk6dudi0iseih.lambda-url.us-east-1.on.aws/api/sale';

const listaCarrito = document.getElementById('lista-carrito');
const mensajeCarrito = document.getElementById('mensaje-carrito');
const totalCarrito = document.getElementById('total-carrito');

// LOG 1: Verificar que los contenedores principales existen en el HTML
console.log('DOM - Contenedor listaCarrito:', listaCarrito);
console.log('DOM - Contenedor mensajeCarrito:', mensajeCarrito);

const metodoPago = document.getElementById('metodo-pago');
const seccionEfectivo = document.getElementById('seccion-efectivo');
const seccionTarjeta = document.getElementById('seccion-tarjeta');

const inputEfectivo = document.getElementById('dinero-recibido');
const cambioResultado = document.getElementById('cambio');

const tipoTarjeta = document.getElementById('tipo-tarjeta');

const btnFinalizar = document.getElementById('btn-finalizar');

cargarCarrito();

function renderizarCarrito() {
    const rawData = localStorage.getItem(CARRITO_KEY);
    // LOG 2: Ver qué hay exactamente en localStorage antes de procesarlo
    console.log('LocalStorage (Datos crudos):', rawData);

    const parsedData = JSON.parse(rawData) || [];
    // LOG 3: Ver los datos ya convertidos en un arreglo de JavaScript
    console.log('LocalStorage (Datos parseados):', parsedData);

    return parsedData;
}

function guardarCarrito(carrito) {
    console.log('Guardando carrito en localStorage:', carrito);
    localStorage.setItem(CARRITO_KEY, JSON.stringify(carrito));
}

function calcularTotal(carrito) {
    return carrito.reduce((total, producto) => {
        const precio = Number(producto.price) || 0;
        // Si un producto no trae cantidad, se asume 1 (no 0), para que
        // sí sume al total aunque todavía no se haya persistido el default.
        const cantidad = Number(producto.cantidad) || 1;
        return total + precio * cantidad;
    }, 0);
}

function actualizarTotal() {
    const carrito = renderizarCarrito();
    const total = calcularTotal(carrito);
    totalCarrito.textContent = `Total: $${total.toFixed(2)}`;
}

function cargarCarrito() {
    console.log('--- Iniciando cargarCarrito() ---');
    const carrito = renderizarCarrito();

    if (!listaCarrito) {
        console.error('ERROR CRÍTICO: listaCarrito es null. Verifica que el ID "lista-carrito" exista en tu HTML.');
        return;
    }

    listaCarrito.innerHTML = '';

    if (carrito.length === 0) {
        console.log('El carrito detectó 0 elementos. Mostrando mensaje de vacío.');
        mensajeCarrito.textContent = 'El carrito está vacío.';
        totalCarrito.textContent = '';
        if (btnFinalizar) btnFinalizar.disabled = true; // antes se quedaba habilitado con carrito vacío
        return;
    }

    console.log(`Se encontraron ${carrito.length} productos listos para renderizar.`);
    mensajeCarrito.textContent = '';

    let seActualizaronDefaults = false;

    carrito.forEach((producto, index) => {
        // LOG 4: Ver la información individual de cada producto que se va a pintar
        console.log(`Renderizando producto #${index + 1}:`, producto);

        // si un producto no tiene cantidad (como es el caso en esta base de datos de prueba), se le asigna 1 por defecto
        if (!producto.cantidad) {
            producto.cantidad = 1;
            seActualizaronDefaults = true; // hay que persistir este default en localStorage
        }

        const articulo = document.createElement('div');
        articulo.classList.add('articulo-carrito');

        const precioUnitario = Number(producto.price) || 0;
        const cantidad = Number(producto.cantidad) || 0;
        const subtotal = precioUnitario * cantidad;

        // LOG 5: Verificar si hay datos indefinidos en los atributos clave
        if (!producto.name || !producto.price) {
            console.warn(`Advertencia: El producto en el índice ${index} no tiene nombre o precio válido.`, producto);
        }

        articulo.innerHTML = `
        <div class="info-articulo">
            <h3>${producto.name}</h3>
            <p>SKU: ${producto.sku}</p>
            <p>Tipo: ${producto.typeid}</p>
            <p>Precio: $${producto.price}</p>
        </div>

        <div class="cantidad-articulo">
            <button class="boton-disminuir" data-index="${index}" data-accion="disminuir">-</button>
            <span>${producto.cantidad}</span>
            <button class="boton-aumentar" data-index="${index}" data-accion="aumentar">+</button>
        </div>

        <div class="precio-articulo">
            $${subtotal.toFixed(2)}
        </div>

        <button class="boton-eliminar" data-index="${index}" data-accion="eliminar" title="Eliminar producto">
            🗑 Eliminar
        </button>
        `;

        listaCarrito.appendChild(articulo);
    });

    // Si se asignaron cantidades por defecto, se guardan para que
    // actualizarTotal() (que vuelve a leer de localStorage) las vea reflejadas.
    if (seActualizaronDefaults) {
        guardarCarrito(carrito);
    }

    console.log('--- Finalizó cargarCarrito() con éxito ---');
    actualizarTotal();
    validarBotonFinalizar();
}

function actualizarCantidad(index, accion) {
    const carrito = renderizarCarrito();
    const producto = carrito[index];

    if (accion === 'aumentar') {
        producto.cantidad = (Number(producto.cantidad) || 0) + 1;
    } else if (accion === 'disminuir') {
        producto.cantidad = (Number(producto.cantidad) || 0) - 1;
        // El botón "-" ya NO elimina el producto: se detiene en 1.
        // Para quitar un producto del carrito se debe usar el botón "Eliminar".
        if (producto.cantidad <= 0) {
            producto.cantidad = 1;
        }
    }
    guardarCarrito(carrito);
    cargarCarrito();
}

// Revisa que el carrito y el formulario de pago estén completos y
// válidos antes de permitir hacer clic en "Finalizar".
function validarBotonFinalizar() {
    if (!btnFinalizar) return;

    const carrito = renderizarCarrito();

    if (carrito.length === 0) {
        btnFinalizar.disabled = true;
        return;
    }

    const metodo = metodoPago ? metodoPago.value : '';

    if (!metodo) {
        btnFinalizar.disabled = true;
        return;
    }

    if (metodo === 'tarjeta' && (!tipoTarjeta || !tipoTarjeta.value)) {
        btnFinalizar.disabled = true;
        return;
    }

    if (metodo === 'efectivo') {
        const dineroRecibido = parseFloat(inputEfectivo ? inputEfectivo.value : NaN);
        const total = calcularTotal(carrito);
        if (isNaN(dineroRecibido) || dineroRecibido < total) {
            btnFinalizar.disabled = true;
            return;
        }
    }

    btnFinalizar.disabled = false;
}

// Elimina un producto del carrito sin importar su cantidad
function eliminarProducto(index) {
    const carrito = renderizarCarrito();

    if (index < 0 || index >= carrito.length) {
        console.error('Índice de producto inválido al eliminar:', index);
        return;
    }

    console.log('Eliminando producto del carrito:', carrito[index]);
    carrito.splice(index, 1);

    guardarCarrito(carrito);
    cargarCarrito();
}

function limpiarCarrito() {
    localStorage.removeItem(CARRITO_KEY);
    cargarCarrito();
}

// eventos de los botones de aumentar, disminuir y eliminar
if (listaCarrito) {
    listaCarrito.addEventListener('click', (event) => {
        const boton = event.target.closest('button');
        if (!boton) return;

        const index = Number(boton.dataset.index);
        const accion = boton.dataset.accion;

        if (boton.classList.contains('boton-aumentar')) {
            actualizarCantidad(index, 'aumentar');
        }
        else if (boton.classList.contains('boton-disminuir')) {
            actualizarCantidad(index, 'disminuir');
        }
        else if (boton.classList.contains('boton-eliminar')) {
            eliminarProducto(index);
        }
    });
}

// cambiar metodo de pago
if (metodoPago) {
    metodoPago.addEventListener('change', () => {
        const metodo = metodoPago.value;
        if (metodo === 'efectivo') {
            seccionEfectivo.style.display = 'block';
            seccionTarjeta.style.display = 'none';
        }
        else if (metodo === 'tarjeta') {
            seccionEfectivo.style.display = 'none';
            seccionTarjeta.style.display = 'block';
        }
        else {
            seccionEfectivo.style.display = 'none';
            seccionTarjeta.style.display = 'none';
        }
        calcularCambio();
        validarBotonFinalizar();
    });
}

// cambiar tipo de tarjeta (antes no tenía listener propio)
if (tipoTarjeta) {
    tipoTarjeta.addEventListener('change', validarBotonFinalizar);
}

function calcularCambio() {
    if (!inputEfectivo) return;

    const dineroRecibido = parseFloat(inputEfectivo.value);
    const total = calcularTotal(renderizarCarrito());

    if (isNaN(dineroRecibido) || dineroRecibido < total) {
        cambioResultado.textContent = 'Dinero insuficiente';
    }
    else {
        const cambio = dineroRecibido - total;
        cambioResultado.textContent = `Cambio: $${cambio.toFixed(2)}`;
    }
}

if (inputEfectivo) {
    inputEfectivo.addEventListener('input', () => {
        calcularCambio();
        validarBotonFinalizar();
    });
}

// obtener el usuario de localStorage
function obtenerUsuario() {
    const usuario = JSON.parse(localStorage.getItem('usuario'));

    if (usuario) {
        return {
            id: usuario.id || null,
            nombre: usuario.nombre || '',
            correo: usuario.correo || '',
            rol: usuario.rol || ''
        };
    }

    return null;
}

function generarIdCuenta() {
    const carrito = renderizarCarrito();

    if (carrito.length === 0) {
        console.error('No se puede generar una cuenta con un carrito vacío.');
        return null;
    }

    const metodo = metodoPago.value;
    if (!metodo) {
        console.error('No se ha seleccionado un método de pago.');
        return null;
    }

    const total = calcularTotal(carrito);
    let informacionPago = {};

    if (metodo === 'efectivo') {
        const dineroRecibido = parseFloat(inputEfectivo.value) || 0;

        if (dineroRecibido < total) {
            console.error('Dinero insuficiente para cubrir el total.');
            return null;
        }

        informacionPago = {
            metodo: 'efectivo',
            dineroRecibido: dineroRecibido,
            cambio: dineroRecibido - total
        };
    } else if (metodo === 'tarjeta') {
        if (!tipoTarjeta.value) {
            console.error('No se ha seleccionado un tipo de tarjeta.');
            return null;
        }

        informacionPago = {
            metodo: 'tarjeta',
            tipo: tipoTarjeta.value
        };
    }

    const usuario = obtenerUsuario();
    if (!usuario) {
        console.error('No se encontró un usuario activo.');
        return null;
    }

    const cuenta = {
        id: Date.now().toString(),
        fecha: new Date().toISOString(),
        usuario: {
            nombre: usuario.nombre
        },
        productos: carrito.map(producto => ({
            sku: producto.sku,
            nombre: producto.name,
            tipo: producto.typeid,
            precioUnitario: Number(producto.price) || 0,
            cantidad: Number(producto.cantidad) || 1,
            subtotal: Number(((Number(producto.price) || 0) * (Number(producto.cantidad) || 1)).toFixed(2))
        })),
        total: Number(total.toFixed(2)),
        pago: {
            metodo: metodo,
            ...informacionPago
        }
    };

    const cuentas = JSON.parse(localStorage.getItem(CUENTAS_KEY)) || [];
    cuentas.push(cuenta);
    localStorage.setItem(CUENTAS_KEY, JSON.stringify(cuentas));

    console.log('cuenta guardada:', cuenta);

    localStorage.removeItem(CARRITO_KEY);

    alert(`Cuenta finalizada correctamente.\n\nVenta: ${cuenta.id}\nTotal: $${cuenta.total.toFixed(2)}`);

    cargarCarrito();

    metodoPago.value = '';
    metodoPago.style.display = 'none';
    inputEfectivo.value = '';
    cambioResultado.textContent = '$0.00';
    tipoTarjeta.value = '';

    return cuenta.id;

}

// --- Helpers para datos que todavia no llamo ---

function obtenerShiftId() {
    // Sugerencia: guardar el turno activo en localStorage (p.ej. al abrir caja),
    // igual que se hace con 'usuario', y leerlo aquí.
    const turno = JSON.parse(localStorage.getItem('turnoActivo') || 'null');
    if (turno && turno.shiftId) {
        return turno.shiftId;
    }
    console.warn('No se encontró un shiftId activo en localStorage ("turnoActivo"). Usando valor temporal.');
    return null; // TODO: reemplazar por el id real del turno una vez implementado
}

function generarReferenciaTransaccion() {
    // Referencia única generada en el cliente. Si el backend/terminal de
    // tarjeta ya entrega un folio de autorización, usar ese valor en su lugar.
    if (crypto && crypto.randomUUID) {
        return crypto.randomUUID();
    }
    return `ref-${Date.now()}`;
}

function normalizarPaymentMethod(metodo, tipoTarjetaValue) {
    if (metodo === 'efectivo') {
        return 'EFECTIVO';
    }
    if (metodo === 'tarjeta') {
        const tipo = (tipoTarjetaValue || '')
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .trim()
            .toLowerCase();

        if (tipo.includes('cred')) {
            return 'TARJETA_CREDITO';
        }
        if (tipo.includes('deb')) {
            return 'TARJETA_DEBITO'; 
        }
        console.error('Tipo de tarjeta no reconocido:', tipoTarjetaValue);
        return null;
    }
    console.error('Método de pago no reconocido:', metodo);
    return null;
}

function resetFormularioPago() {
    if (metodoPago) metodoPago.value = '';
    if (seccionEfectivo) seccionEfectivo.style.display = 'none';
    if (seccionTarjeta) seccionTarjeta.style.display = 'none';
    if (inputEfectivo) inputEfectivo.value = '';
    if (cambioResultado) cambioResultado.textContent = '';
    if (tipoTarjeta) tipoTarjeta.value = '';
    validarBotonFinalizar();
}

// Arma el payload exacto que exige el backend y envía la venta.
async function procesarVentaBackend() {
    const carrito = renderizarCarrito();

    if (carrito.length === 0) {
        console.error('No se puede procesar una venta con el carrito vacío.');
        return null;
    }

    const metodo = metodoPago.value;
    if (!metodo) {
        console.error('No se ha seleccionado un método de pago.');
        return null;
    }

    const total = calcularTotal(carrito);
    let payment_method = '';
    let amount_given = 0;
    let change_given = 0;

    if (metodo === 'efectivo') {
        amount_given = parseFloat(inputEfectivo.value) || 0;
        if (amount_given < total) {
            console.error('Dinero insuficiente para cubrir el total.');
            return null;
        }
        change_given = amount_given - total;
    } else if (metodo === 'tarjeta') {
        if (!tipoTarjeta.value) {
            console.error('No se ha seleccionado un tipo de tarjeta.');
            return null;
        }
        amount_given = total;
        change_given = 0;
    } else {
        console.error('Método de pago no reconocido:', metodo);
        return null;
    }

    payment_method = normalizarPaymentMethod(metodo, tipoTarjeta.value);

    if (!payment_method) {
        alert('No se pudo determinar el método de pago. Verifica la selección.');
        return null;
    }

    const token = localStorage.getItem('authToken');

    if (!token) {
        console.error('No se encontró el JWT en localStorage.');
        alert('No hay una sesión válida. Inicia sesión nuevamente.');
        return null;
    }

const usuario = obtenerUsuario();
    // Obtener cashierId desde localStorage o desde el usuario activo
    const cashierId = localStorage.getItem('cashierId') || (usuario ? usuario.id : null);
    // Obtener shiftId desde localStorage o función auxiliar
    const shiftId = localStorage.getItem('shiftId') || obtenerShiftId();

    if (!shiftId) {
        console.error('No se encontró un shiftId activo. No se puede procesar la venta.');
        alert('No se encontró un turno activo (shiftId). Inicia turno antes de vender.');
        return null;
    }

    if (!cashierId) {
        console.error('No se encontró un cashierId activo. No se puede procesar la venta.');
        alert('No se encontró un cajero activo (cashierId).');
        return null;
    }

const payload = {
        shiftId: Number(shiftId), 
        cashierId: cashierId,
        total: Number(total.toFixed(2)),
        payment_method: payment_method,
        amount_given: Number(amount_given.toFixed(2)),
        change_given: Number(change_given.toFixed(2)),
        transaction_reference: generarReferenciaTransaccion(),
        products: carrito.map(producto => ({
            productId: Number(producto.id ?? producto.productId),
            unit_price: Number(producto.price) || 0,
            quantity: Number(producto.cantidad) || 1,
            subtotal: Number(((Number(producto.price) || 0) * (Number(producto.cantidad) || 1)).toFixed(2))
        }))
    };

    console.log('Enviando venta al backend:', payload);


    // ========================================================================================================================
    try {
        const token = localStorage.getItem('authToken');
        const response = await fetch(BACKEND_VENTA_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            const textoError = await response.text().catch(() => '');
            throw new Error(`Error ${response.status} del servidor: ${textoError}`);
        }

        const data = await response.json();
        console.log('Venta guardada correctamente en el backend:', data);

        alert(`Venta procesada correctamente.\n\nTotal: $${total.toFixed(2)}`);

        // Reiniciar la cuenta: vaciar carrito y resetear formulario de pago
        limpiarCarrito();
        resetFormularioPago();

        return data;
    } catch (error) {
        console.error('Error al procesar la venta en el backend:', error);
        alert('Ocurrió un error al procesar la venta. Intenta de nuevo.');
        return null;
    }
    // ========================================================================================================================
}

// Click en "Finalizar": pide confirmación y, si es afirmativa, procesa la venta.
if (btnFinalizar) {
    btnFinalizar.addEventListener('click', async () => {
        const carrito = renderizarCarrito();
        if (carrito.length === 0) return;

        const total = calcularTotal(carrito);
        const confirmar = confirm(`¿Confirmas finalizar la venta por $${total.toFixed(2)}?`);
        if (!confirmar) return;

        btnFinalizar.disabled = true; // evita doble clic mientras se procesa
        await procesarVentaBackend();
        validarBotonFinalizar(); // vuelve a evaluar el estado (carrito ya vacío)
    });
}
