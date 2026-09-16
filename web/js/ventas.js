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


function obtenerToken() {
    return localStorage.getItem("authToken");
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
    const amount =
        Number(openingAmount.value);


    if (!usuarioActual.id) {

        mostrarMensaje(
            "No se detectó la sesión del cajero. Por favor inicia sesión nuevamente.",
            "error"
        );

        return;
    }


    if (isNaN(amount) || amount < 0 || openingAmount.value.trim() === "") {

        mostrarMensaje(
            "Ingresa un fondo inicial válido.",
            "error"
        );

        return;
    }


    // --------------------------------------
    // Deshabilitar botón
    // --------------------------------------

    btnAbrir.disabled = true;

    btnAbrir.textContent =
        "Abriendo turno...";


    try {

        const token =
            obtenerToken();


        // ----------------------------------
        // Body
        // ----------------------------------

        const body = {

            cashierid: usuarioActual.id,

            openingamount: amount

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
                `${API_SHIFT_URL}/api/shift/open`,
                {
                    method: "POST",
                    headers: headers,
                    body: JSON.stringify(body)
                }
            );


        const data =
            await response.json()
                .catch(() => ({}));


        // ----------------------------------
        // Error HTTP
        // ----------------------------------

        if (!response.ok) {

            const error =
                data.message ||
                data.Message ||
                data.error ||
                `HTTP ${response.status}`;

            throw new Error(error);

        }


        // ----------------------------------
        // IMPORTANTE
        // ----------------------------------
        //
        // El backend actualmente debería
        // devolver shiftId.
        //
        // Si todavía no lo devuelve,
        // no podemos asociar correctamente
        // las ventas al turno.
        //

        const shiftId =
            data.shiftId ||
            data.shiftid ||
            data.id;


        if (!shiftId) {

            mostrarMensaje(
                "El turno se abrió, pero el backend no devolvió shiftId. Solicita que /api/shift/open incluya el identificador del turno.",
                "error"
            );

            console.warn(
                "Respuesta de /api/shift/open:",
                data
            );

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

        mostrarTurnoAbierto(
            shiftId,
            usuarioActual.username,
            amount
        );


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

}


async function cerrarTurno() {

    ocultarMensaje();


    // Recuperar datos

    const shiftId =
        localStorage.getItem("shiftId");

    const cashierId =
        localStorage.getItem("cashierId");


    if (!shiftId) {

        mostrarMensaje(
            "No existe un turno activo.",
            "error"
        );

        return;
    }

    // --------------------------------------
    // Dinero contado
    // --------------------------------------

    const countedCash =
        Number(actualCash.value);


    if (isNaN(countedCash) || countedCash < 0 || actualCash.value.trim() === "") {

        mostrarMensaje(
            "Ingresa el dinero contado en caja.",
            "error"
        );

        return;
    }


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

            const error =
                data.message ||
                data.Message ||
                data.error ||
                `HTTP ${response.status}`;

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

    const shiftId =
        localStorage.getItem("shiftId");

    const cashierName = localStorage.getItem("cashierUsername") || "Cajero";

    const amount =
        localStorage.getItem("openingAmount");


    if (
        shiftId &&
        amount !== null
    ) {

        mostrarTurnoAbierto(
            shiftId,
            cashierName,
            Number(amount)
        );

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