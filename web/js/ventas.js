// ==========================================
// MACHAPOINT POS
// Gestión de turnos y cortes
// ==========================================

// ==========================================
// URLs DE LOS SERVICIOS
// ==========================================

const API_SHIFT_URL =
    "https://hdkp6ejncitdyw5yfwyxc4sj4i0srjxb.lambda-url.us-east-1.on.aws";

const API_CUT_URL =
    "https://2v34s2xxn4rxq6utaxaaoawpb40soivi.lambda-url.us-east-1.on.aws";

const API_SALES_BY_SHIFT_URL = "https://6uxm3jz7xwth5cliak6zk6dudi0iseih.lambda-url.us-east-1.on.aws/api/sale/by-shift";
// ==========================================
// ELEMENTOS DEL DOM
// ==========================================

const seccionApertura = document.getElementById("seccion-apertura");
const seccionTurno = document.getElementById("seccion-turno");
const seccionCorte = document.getElementById("seccion-corte");
const estadoTurno = document.getElementById("estado-turno");

const mensaje = document.getElementById("mensaje");
const cashierSelect = document.getElementById("cashier-select");
const openingAmount = document.getElementById("opening-amount");

const actualCash = document.getElementById("actual-cash");
const closeNotes = document.getElementById("close-notes");

const btnAbrir = document.getElementById("btn-abrir-turno");
const btnCerrar = document.getElementById("btn-cerrar-turno");
let salesPollingInterval = null;

function obtenerToken() {
    return localStorage.getItem("authToken");
}

// Validacion de fondo

const MONTO_MIN = 0.99;
const MONTO_MAX = 20000;
const MONTO_MAX_CARACTERES = 7;

// Filtra lo que el usuario escribe: solo dígitos, un punto, máx. 2 decimales, máx. 5 caracteres
function filtrarMonto(input) {
    let valor = input.value;

    // Permitir coma como punto decimal
    valor = valor.replace(",", ".");

    // Quitar todo excepto dígitos y puntos
    valor = valor.replace(/[^\d.]/g, "");

    // Permitir solo un punto
    const partes = valor.split(".");
    if (partes.length > 2) {
        valor = partes[0] + "." + partes.slice(1).join("");
    }

    // Limitar a 2 decimales
    if (valor.includes(".")) {
        const [entero, decimales] = valor.split(".");
        valor = entero + "." + decimales.slice(0, 2);
    }

    // Limitar a 5 caracteres en total
    valor = valor.slice(0, MONTO_MAX_CARACTERES);

    input.value = valor;
}

if (openingAmount) {
    openingAmount.addEventListener("input", () => filtrarMonto(openingAmount));

    // Controla también el pegado de texto
    openingAmount.addEventListener("paste", () => {
        setTimeout(() => filtrarMonto(openingAmount), 0);
    });
}

if (actualCash) {
    actualCash.addEventListener("input", () => filtrarMonto(actualCash));

    // Controla también el pegado de texto
    actualCash.addEventListener("paste", () => {
        setTimeout(() => filtrarMonto(actualCash), 0);
    });
}

// Validación final (se usa al hacer clic en "Abrir día de venta")
function validarFondoInicial(texto) {
    const valor = texto.trim();

    if (valor === "") {
        return "Ingresa un fondo inicial.";
    }

    if (!/^\d+(\.\d{1,2})?$/.test(valor)) {
        return "Formato inválido. Usa solo números y máximo 2 decimales.";
    }

    if (valor.length > MONTO_MAX_CARACTERES) {
        return `El fondo inicial no puede tener más de ${MONTO_MAX_CARACTERES} caracteres.`;
    }

    const numero = Number(valor);

    if (numero <= MONTO_MIN) {
        return `El fondo inicial debe ser mayor a $${MONTO_MIN}.`;
    }

    if (numero > MONTO_MAX) {
        return `El fondo inicial no puede ser mayor a $${MONTO_MAX.toLocaleString("es-MX")}.`;
    }

    return null; // Sin errores
}

function validarDineroContado(texto) {
    const valor = texto.trim();

    if (valor === "") {
        return "Ingresa el dinero contado en caja.";
    }

    if (!/^\d+(\.\d{1,2})?$/.test(valor)) {
        return "Formato inválido. Usa solo números y máximo 2 decimales.";
    }

    if (valor.length > MONTO_MAX_CARACTERES) {
        return `El monto no puede tener más de ${MONTO_MAX_CARACTERES} caracteres.`;
    }

    const numero = Number(valor);

    if (numero < 0) {
        return "El dinero contado no puede ser negativo.";
    }

    if (numero > MONTO_MAX) {
        return `El dinero contado no puede ser mayor a $${MONTO_MAX.toLocaleString("es-MX")}.`;
    }

    return null; // Sin errores
}

//Ventas del turno
async function cargarVentasTurno(shiftId) {
    if (!shiftId) return;

    try {
        const token = obtenerToken();
        const headers = {"Content-Type":"application/json"};
        if (token) headers["Authorization"] = `Bearer ${token}`;

        const response = await fetch(`${API_SALES_BY_SHIFT_URL}?shiftId=${shiftId}`, {
            method: "GET",
            headers: headers
        });

        if (!response.ok) return;
        const data = await response.json();

        if (data.success && Array.isArray(data.data)) {
            renderizarTablaVentas(data.data);
        }
    }catch (error) {
        console.error("Error al cargar ventas del turno:", error);
    }
}

function renderizarTablaVentas(ventas,totalSales) {
    const tbody = document.getElementById("tabla-ventas-body");

    if (!tbody) return;

    tbody.innerHTML = "";

    if (ventas.length === 0) {
        tbody.innerHTML = `<tr><td colspan="5" class="texto-vacio">No hay ventas registradas en este turno.</td></tr>`;
        return;
    }

    ventas.forEach(sale => {
        //Formato de hora
        const hora = sale.createdAt 
            ? new Date(sale.createdAt).toLocaleTimeString("es-MX", { hour: '2-digit', minute: '2-digit' }) 
            : "-";

        // Obtener resumen de items en texto
        const itemsSummary = Array.isArray(sale.items) && sale.items.length > 0
            ? sale.items.map(item => {
        const nombreProducto = item.product_name || item.productName || item.name || 'Producto';
        const cantidad = item.quantity || 1;
        return `${cantidad}x ${nombreProducto}`;
    }).join(", ")
    : "Sin detalle de ítems";

        const tr = document.createElement("tr");
        tr.innerHTML = `
            <td><strong>#${sale.saleId}</strong></td>
            <td>${hora}</td>
            <td>${sale.paymentMethod || 'Efectivo'}</td>
            <td><small>${itemsSummary}</small></td>
            <td><strong>${formatoDinero(sale.total)}</strong></td>
        `;
        tbody.appendChild(tr);
    });
}

function iniciarPollingVentas(shiftId) {
    // Detener cualquier polling anterior para no duplicar intervalos
    detenerPollingVentas();

    // Carga inicial
    cargarVentasTurno(shiftId);

    // Consultar cada 10 segundos
    salesPollingInterval = setInterval(() => {
        cargarVentasTurno(shiftId);
    }, 10000); 
}

function detenerPollingVentas() {
    if (salesPollingInterval) {
        clearInterval(salesPollingInterval);
        salesPollingInterval = null;
    }
}

//Se obtiene el usuario actual del localStorage y se devuelve un objeto con id y username. Si no hay usuario o hay un error al parsear, se devuelve null.
function obtenerUsuarioActual() {
    const usuario = localStorage.getItem("user");
    if(usuario) {
        try {
            const userObj = JSON.parse(usuario);
            return {
                id: userObj.id || null,
                username: userObj.username || null
            }
        } catch (error) {
            console.error("Error al leer usuario:", error);
            return null;
        }
    }
}


function mostrarMensaje(texto, tipo = "info") {

    if (!mensaje) return;

    mensaje.textContent = texto;

    mensaje.className = `mensaje ${tipo}`;

}


function ocultarMensaje() {

    if (!mensaje) return;

    mensaje.className = "mensaje oculto";

    mensaje.textContent = "";

}



function formatoDinero(valor) {

    const numero =
        Number(valor) || 0;

    return numero.toLocaleString("es-MX", {
        style: "currency",
        currency: "MXN"
    });

}


function formatoFecha(fecha) {

    if (!fecha) return "-";

    const date = new Date(fecha);

    if (isNaN(date.getTime())) {
        return fecha;
    }

    return date.toLocaleString("es-MX");

}


async function abrirTurno() {
    ocultarMensaje();

    const usuarioActual = obtenerUsuarioActual();
    const amount = Number(openingAmount.value);

    if (!usuarioActual || !usuarioActual.id) {
        mostrarMensaje("No se detectó la sesión del cajero. Por favor inicia sesión nuevamente.","error");
        return;
    }

    const errorMonto = validarFondoInicial(openingAmount.value);
    if (errorMonto) {
        mostrarMensaje(errorMonto, "error");
        openingAmount.focus();
        return;
    }

    btnAbrir.disabled = true;
    btnAbrir.textContent = "Abriendo turno...";

    try {

        const token = obtenerToken();
        const body = {cashierid: usuarioActual.id, openingamount: amount};
        const headers = {"Content-Type":"application/json"};

        if (token) {
            headers["Authorization"] = `Bearer ${token}`;
        }

        const response = await fetch(`${API_SHIFT_URL}/api/shift/open`,
                {
                    method: "POST",
                    headers: headers,
                    body: JSON.stringify(body)
                }
            );

        const data = await response.json().catch(() => ({}));

        if (!response.ok) {
            const error = data.message || data.Message || data.error || `HTTP ${response.status}`;
            throw new Error(error);
        }

        const shiftId = data.shiftId || data.shiftid || data.id;


        if (!shiftId) {
            mostrarMensaje("El turno se abrió, pero el backend no devolvió shiftId. Solicita que /api/shift/open incluya el identificador del turno.","error");
            console.warn("Respuesta de /api/shift/open:",data);
            return;
        }

        // GUARDAR TURNO

        localStorage.setItem(
            "shiftId",
            shiftId
        );

        localStorage.setItem(
            "cashierId",
            usuarioActual.id
        );

        localStorage.setItem(
            "cashierUsername",
            usuarioActual.username
        );

        localStorage.setItem(
            "openingAmount",
            amount
        );


        // Actualizar interfaz

        mostrarTurnoAbierto(shiftId,usuarioActual.username,amount);


        mostrarMensaje(
            data.message ||
            "Turno iniciado correctamente.",
            "exito"
        );


    } catch (error) {

        console.error(
            "Error al abrir turno:",
            error
        );

        mostrarMensaje(
            "Error al abrir turno: " +
            error.message,
            "error"
        );

    } finally {

        btnAbrir.disabled = false;

        btnAbrir.textContent =
            "Abrir día de venta";

    }

}



function mostrarTurnoAbierto(
    shiftId,
    cashierUsername,
    amount
) {

    seccionApertura.classList.add("oculto");

    seccionTurno.classList.remove("oculto");

    seccionCorte.classList.add("oculto");


    // Estado superior

    estadoTurno.textContent =
        "● Turno abierto";

    estadoTurno.className =
        "estado abierto";


    // Información

    document.getElementById("resumen-cajero").textContent =cashierUsername;


    document.getElementById(
        "resumen-shift"
    ).textContent =
        `#${shiftId}`;


    document.getElementById(
        "resumen-apertura"
    ).textContent =
        formatoDinero(amount);


    document.getElementById(
        "turno-info"
    ).textContent =
        `Turno #${shiftId}`;


    // Limpiar cierre

    actualCash.value = "";

    closeNotes.value = "";

    iniciarPollingVentas(shiftId);
}


async function cerrarTurno() {
    ocultarMensaje();

    const shiftId = localStorage.getItem("shiftId");
    const cashierId = localStorage.getItem("cashierId");

    if (!shiftId) {
        mostrarMensaje("No existe un turno activo.","error");
        finalizarTurnoLocal();
        seccionTurno.classList.add("oculto");
        seccionApertura.classList.remove("oculto");
        return;
    }

    // --------------------------------------
    // Dinero contado
    // --------------------------------------

const errorMonto = validarDineroContado(actualCash.value);
    
    if (errorMonto) {
        mostrarMensaje(errorMonto, "error");
        actualCash.focus();
        return;
    }

    const countedCash = Number(actualCash.value);

    const notes =
        closeNotes.value.trim();


    // --------------------------------------
    // Confirmación
    // --------------------------------------

    if (!confirm("¿Estás seguro de cerrar el turno?\n\nUna vez cerrado no se registrarán más ventas en este turno.")) {
        return;
    }


    // --------------------------------------
    // Botón
    // --------------------------------------

    btnCerrar.disabled = true;

    btnCerrar.textContent =
        "Cerrando turno...";


    try {

        const token =
            obtenerToken();


        // ----------------------------------
        // Body
        // ----------------------------------

        const body = {

            shiftid:
                Number(shiftId),

            cashierid:
                cashierId,

            actualcash:
                countedCash,

            notes:
                notes

        };


        // ----------------------------------
        // Headers
        // ----------------------------------

        const headers = {

            "Content-Type":
                "application/json"

        };


        if (token) {

            headers["Authorization"] =
                `Bearer ${token}`;

        }


        // ----------------------------------
        // Petición
        // ----------------------------------

        const response =
            await fetch(
                `${API_SHIFT_URL}/api/shift/close`,
                {
                    method: "POST",
                    headers: headers,
                    body: JSON.stringify(body)
                }
            );


        const data =
            await response.json()
                .catch(() => ({}));


        if (!response.ok) {
            const error = data.message || data.Message || data.error || `HTTP ${response.status}`;

            if (error.includes("no existe") || error.includes("cerrado")){
                finalizarTurnoLocal();
                seccionTurno.classList.add("oculto");
                seccionApertura.classList.remove("oculto");
                estadoTurno.textContent = "● Sin turno activo";
                estadoTurno.className = "estado sin-turno";

                throw new Error("El turno anterior fue cerrado anteriormente. Se ha restablecido la pantalla para que puedas abrir un nuevo turno.");
            }
            throw new Error(error);
        }


        mostrarMensaje(
            data.message ||
            "Turno cerrado correctamente.",
            "exito"
        );


        // ----------------------------------
        // Consultar corte Z
        // ----------------------------------

        await obtenerCorteZ(
            Number(shiftId)
        );


    } catch (error) {

        console.error(
            "Error al cerrar turno:",
            error
        );

        mostrarMensaje(
            "Error al cerrar turno: " +
            error.message,
            "error"
        );

    } finally {

        btnCerrar.disabled = false;

        btnCerrar.textContent =
            "Cerrar turno";

    }

}

async function obtenerCorteZ(
    shiftId
) {

    try {

        const token =
            obtenerToken();


        const headers = {
            "Content-Type":
                "application/json"
        };


        if (token) {

            headers["Authorization"] =
                `Bearer ${token}`;

        }


        const response =
            await fetch(
                `${API_CUT_URL}/api/cut/zcuts?shiftId=${shiftId}`,
                {
                    method: "GET",
                    headers: headers
                }
            );


        const data =
            await response.json()
                .catch(() => ({}));


        if (!response.ok) {

            const error =
                data.message ||
                data.Message ||
                data.error ||
                `HTTP ${response.status}`;

            throw new Error(error);

        }


        console.log(
            "Respuesta corte Z:",
            data
        );


        // Obtener corte

        let corte = (Array.isArray(data.cuts) && data.cuts.length > 0) ? data.cuts[0] : null;;


        if (!corte) {
            mostrarMensaje("El turno fue cerrado, pero todavía no se encontró el corte Z.", "info");
            finalizarTurnoLocal();
            return;
        }

        mostrarCorte(corte);
        finalizarTurnoLocal();


    } catch (error) {

        console.error(
            "Error al obtener corte Z:",
            error
        );

        mostrarMensaje(
            "Turno cerrado, pero no fue posible obtener el corte Z: " +
            error.message,
            "error"
        );

        // El turno ya fue cerrado en backend.
        // Limpiamos los datos locales.

        finalizarTurnoLocal();

    }

}


function mostrarCorte(corte) {

    seccionTurno.classList.add("oculto");
    seccionApertura.classList.add("oculto");
    seccionCorte.classList.remove("oculto");

    // Información

    document.getElementById(
        "corte-cajero"
    ).textContent =
        corte.cashierUsername || "-";


    document.getElementById(
        "corte-shift"
    ).textContent =
        corte.shiftId != null
            ? `#${corte.shiftId}`
            : "-";


    document.getElementById(
        "corte-apertura"
    ).textContent =
        formatoFecha(corte.openedAt);


    document.getElementById(
        "corte-cierre"
    ).textContent =
        formatoFecha(corte.closedAt);


    document.getElementById(
        "corte-opening"
    ).textContent =
        formatoDinero(corte.openingCash);


    document.getElementById(
        "corte-sales"
    ).textContent =
        formatoDinero(corte.totalSales);


    document.getElementById(
        "corte-count"
    ).textContent =
        corte.totalSalesCount ?? 0;


    document.getElementById(
        "corte-expected"
    ).textContent =
        formatoDinero(corte.expectedCash);


    document.getElementById(
        "corte-actual"
    ).textContent =
        formatoDinero(corte.actualCash);


    document.getElementById(
        "corte-difference"
    ).textContent =
        formatoDinero(corte.cashDifference);

    // Estado

    const status =
        document.getElementById(
            "corte-status"
        );


    const auditStatus =
        corte.auditStatus ||
        "SIN ESTADO";


    status.textContent =
        auditStatus;


    status.className =
        "resultado-corte";


    if (
        auditStatus
            .toUpperCase()
            .includes("FALTANTE")
    ) {

        status.classList.add(
            "faltante"
        );

    } else if (
        auditStatus
            .toUpperCase()
            .includes("SOBRANTE")
    ) {

        status.classList.add(
            "sobrante"
        );

    } else {

        status.classList.add(
            "correcto"
        );

    }

    //notas 
    document.getElementById(
        "corte-notes"
    ).textContent =
        corte.notes ||
        "Sin observaciones";

    // Estados
    estadoTurno.textContent =
        "● Turno cerrado";

    estadoTurno.className =
        "estado cerrado";

}


// LIMPIAR TURNO LOCAL

function finalizarTurnoLocal() {
    detenerPollingVentas();
    localStorage.removeItem(
        "shiftId"
    );

    localStorage.removeItem(
        "cashierId"
    );

    localStorage.removeItem(
        "cashierUsername"
    );

    localStorage.removeItem(
        "openingAmount"
    );

}

function restaurarTurno() {

    const shiftId = localStorage.getItem("shiftId");
    const cashierName = localStorage.getItem("cashierUsername") || "Cajero";
    const amount = localStorage.getItem("openingAmount");

    if (shiftId && amount !== null) {
        mostrarTurnoAbierto(
            shiftId,
            cashierName,
            Number(amount)
        );
    }else{
        seccionApertura.classList.remove("oculto");
        seccionTurno.classList.add("oculto");
    }
}

// EVENTOS

if (btnAbrir) {

    btnAbrir.addEventListener(
        "click",
        abrirTurno
    );

}


if (btnCerrar) {

    btnCerrar.addEventListener(
        "click",
        cerrarTurno
    );

}

restaurarTurno();