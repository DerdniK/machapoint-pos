// ==========================================
// MACHAPOINT POS - Gestión de turnos y cortes
// ==========================================
'use strict';

const API_SHIFT_URL = "https://hdkp6ejncitdyw5yfwyxc4sj4i0srjxb.lambda-url.us-east-1.on.aws";
const API_CUT_URL = "https://2v34s2xxn4rxq6utaxaaoawpb40soivi.lambda-url.us-east-1.on.aws";
const API_SALES_BY_SHIFT_URL = "https://6uxm3jz7xwth5cliak6zk6dudi0iseih.lambda-url.us-east-1.on.aws/api/sale/by-shift";

const $ = id => document.getElementById(id);
const seccionApertura = $("seccion-apertura");
const seccionTurno = $("seccion-turno");
const seccionCorte = $("seccion-corte");
const estadoTurno = $("estado-turno");
const mensaje = $("mensaje");
const openingAmount = $("opening-amount");
const actualCash = $("actual-cash");
const closeNotes = $("close-notes");
const btnAbrir = $("btn-abrir-turno");
const btnCerrar = $("btn-cerrar-turno");

const SHIFT_KEYS = ["shiftId", "cashierId", "cashierUsername", "openingAmount"];
const POLL_BASE_MS = 10000;
const POLL_MAX_MS = 60000;

// ---------- Validación de montos ----------
const MONTO_MIN = 0.99;
const MONTO_MAX = 20000;
const MONTO_MAX_CARACTERES = 8; // permite 20000.00

function filtrarMonto(input) {
    let v = input.value.replace(",", ".").replace(/[^\d.]/g, "");
    const partes = v.split(".");
    if (partes.length > 2) v = partes[0] + "." + partes.slice(1).join("");
    if (v.includes(".")) {
        const [e, d] = v.split(".");
        v = e + "." + d.slice(0, 2);
    }
    input.value = v.slice(0, MONTO_MAX_CARACTERES);
}

[openingAmount, actualCash].forEach(input => {
    if (!input) return;
    input.maxLength = MONTO_MAX_CARACTERES;
    input.addEventListener("input", () => filtrarMonto(input));
    input.addEventListener("paste", () => setTimeout(() => filtrarMonto(input), 0));
});

function validarMonto(texto, { etiqueta, minimoExclusivo }) {
    const v = texto.trim();
    if (v === "") return `Ingresa ${etiqueta}.`;
    if (!/^\d+(\.\d{1,2})?$/.test(v)) return "Formato inválido. Usa solo números y máximo 2 decimales.";
    if (v.length > MONTO_MAX_CARACTERES) return `El monto no puede tener más de ${MONTO_MAX_CARACTERES} caracteres.`;
    const n = Number(v);
    if (minimoExclusivo && n <= MONTO_MIN) return `El monto debe ser mayor a $${MONTO_MIN}.`;
    if (n > MONTO_MAX) return `El monto no puede ser mayor a $${MONTO_MAX.toLocaleString("es-MX")}.`;
    return null;
}
const validarFondoInicial = t => validarMonto(t, { etiqueta: "un fondo inicial", minimoExclusivo: true });
const validarDineroContado = t => validarMonto(t, { etiqueta: "el dinero contado en caja", minimoExclusivo: false });

// ---------- Utilidades ----------
function obtenerUsuarioActual() {
    try {
        const u = JSON.parse(localStorage.getItem("user") || "null");
        if (!u) return null;
        return { id: u.id || null, username: u.username || u.nombre || u.email || "Cajero" };
    } catch { return null; }
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
    return (Number(valor) || 0).toLocaleString("es-MX", { style: "currency", currency: "MXN" });
}
function formatoFecha(fecha) {
    if (!fecha) return "-";
    const d = new Date(fecha);
    return isNaN(d.getTime()) ? String(fecha) : d.toLocaleString("es-MX");
}
const setText = (id, txt) => { const e = $(id); if (e) e.textContent = txt; };
const sleep = ms => new Promise(r => setTimeout(r, ms));

function finalizarTurnoLocal() {
    detenerPollingVentas();
    SHIFT_KEYS.forEach(k => localStorage.removeItem(k));
}

// ---------- Ventas del turno (polling encadenado, con pausa y backoff) ----------
let pollTimer = null;
let pollShiftId = null;
let pollFallos = 0;
let pollEnCurso = false;

async function cargarVentasTurno(shiftId) {
    try {
        const res = await Api.request(`${API_SALES_BY_SHIFT_URL}?shiftId=${encodeURIComponent(shiftId)}`,
            { method: "GET", timeout: 10000 });
        if (!res.ok) return false;
        const data = await res.json();
        if (data.success && Array.isArray(data.data)) renderizarTablaVentas(data.data);
        return true;
    } catch {
        return false; // red lenta: se reintenta con backoff
    }
}

function filaVacia(tbody) {
    const tr = document.createElement("tr");
    const td = document.createElement("td");
    td.colSpan = 5;
    td.className = "texto-vacio";
    td.textContent = "No hay ventas registradas en este turno.";
    tr.appendChild(td);
    tbody.replaceChildren(tr);
}

function renderizarTablaVentas(ventas) {
    const tbody = $("tabla-ventas-body");
    if (!tbody) return;
    if (ventas.length === 0) { filaVacia(tbody); return; }

    const frag = document.createDocumentFragment();
    ventas.forEach(sale => {
        const hora = sale.createdAt
            ? new Date(sale.createdAt).toLocaleTimeString("es-MX", { hour: "2-digit", minute: "2-digit" })
            : "-";
        const items = Array.isArray(sale.items) && sale.items.length > 0
            ? sale.items.map(i => `${i.quantity || 1}x ${i.product_name || i.productName || i.name || "Producto"}`).join(", ")
            : "Sin detalle de ítems";

        const tr = document.createElement("tr");
        const celdas = [
            [`#${sale.saleId}`, "strong"],
            [hora],
            [sale.paymentMethod || "-"],
            [items, "small"],
            [formatoDinero(sale.total), "strong"]
        ];
        celdas.forEach(([txt, envoltorio]) => {
            const td = document.createElement("td");
            if (envoltorio) {
                const w = document.createElement(envoltorio);
                w.textContent = txt;
                td.appendChild(w);
            } else td.textContent = txt;
            tr.appendChild(td);
        });
        frag.appendChild(tr);
    });
    tbody.replaceChildren(frag);
}

function programarPolling(ms) {
    clearTimeout(pollTimer);
    if (pollShiftId) pollTimer = setTimeout(cicloPolling, ms);
}

async function cicloPolling() {
    if (!pollShiftId || pollEnCurso) return;
    if (document.hidden) return; // se reanuda en visibilitychange
    pollEnCurso = true;
    const ok = await cargarVentasTurno(pollShiftId);
    pollEnCurso = false;
    pollFallos = ok ? 0 : pollFallos + 1;
    programarPolling(Math.min(POLL_BASE_MS * 2 ** pollFallos, POLL_MAX_MS));
}

function iniciarPollingVentas(shiftId) {
    detenerPollingVentas();
    pollShiftId = shiftId;
    cicloPolling();
}

function detenerPollingVentas() {
    clearTimeout(pollTimer);
    pollTimer = null;
    pollShiftId = null;
    pollFallos = 0;
}

document.addEventListener("visibilitychange", () => {
    if (!document.hidden && pollShiftId) { clearTimeout(pollTimer); cicloPolling(); }
});

// ---------- Abrir turno ----------
async function abrirTurno() {
    ocultarMensaje();
    const usuario = obtenerUsuarioActual();
    if (!usuario || !usuario.id) {
        mostrarMensaje("No se detectó la sesión del cajero. Por favor inicia sesión nuevamente.", "error");
        return;
    }
    const errorMonto = validarFondoInicial(openingAmount.value);
    if (errorMonto) { mostrarMensaje(errorMonto, "error"); openingAmount.focus(); return; }
    const amount = Number(openingAmount.value);

    btnAbrir.disabled = true;
    btnAbrir.textContent = "Abriendo turno...";
    try {
        const res = await Api.request(`${API_SHIFT_URL}/api/shift/open`, {
            method: "POST",
            body: JSON.stringify({ cashierid: usuario.id, openingamount: amount }),
            timeout: 20000
        });
        const data = await res.json().catch(() => ({}));
        if (!res.ok) throw new Error(await Api.errorDe(res));

        const shiftId = data.shiftId || data.shiftid || data.id;
        if (!shiftId) {
            mostrarMensaje("El turno se abrió, pero el servidor no devolvió el identificador del turno.", "error");
            return;
        }
        localStorage.setItem("shiftId", shiftId);
        localStorage.setItem("cashierId", usuario.id);
        localStorage.setItem("cashierUsername", usuario.username);
        localStorage.setItem("openingAmount", amount);

        mostrarTurnoAbierto(shiftId, usuario.username, amount);
        mostrarMensaje(data.message || "Turno iniciado correctamente.", "exito");
    } catch (error) {
        mostrarMensaje("Error al abrir turno: " + error.message, "error");
    } finally {
        btnAbrir.disabled = false;
        btnAbrir.textContent = "Abrir día de venta";
    }
}

function mostrarTurnoAbierto(shiftId, cashierUsername, amount) {
    seccionApertura.classList.add("oculto");
    seccionTurno.classList.remove("oculto");
    seccionCorte.classList.add("oculto");

    estadoTurno.textContent = "● Turno abierto";
    estadoTurno.className = "estado abierto";

    setText("resumen-cajero", cashierUsername);
    setText("resumen-shift", `#${shiftId}`);
    setText("resumen-apertura", formatoDinero(amount));
    setText("turno-info", `Turno #${shiftId}`);

    actualCash.value = "";
    closeNotes.value = "";
    iniciarPollingVentas(shiftId);
}

// ---------- Cerrar turno ----------
function volverAApertura() {
    finalizarTurnoLocal();
    seccionTurno.classList.add("oculto");
    seccionApertura.classList.remove("oculto");
    estadoTurno.textContent = "● Sin turno activo";
    estadoTurno.className = "estado sin-turno";
}

async function cerrarTurno() {
    ocultarMensaje();
    const shiftId = localStorage.getItem("shiftId");
    const cashierId = localStorage.getItem("cashierId");

    if (!shiftId) {
        mostrarMensaje("No existe un turno activo.", "error");
        volverAApertura();
        return;
    }
    const errorMonto = validarDineroContado(actualCash.value);
    if (errorMonto) { mostrarMensaje(errorMonto, "error"); actualCash.focus(); return; }

    const countedCash = Number(actualCash.value);
    const notes = closeNotes.value.trim();
    if (!confirm("¿Estás seguro de cerrar el turno?\n\nUna vez cerrado no se registrarán más ventas en este turno.")) return;

    btnCerrar.disabled = true;
    btnCerrar.textContent = "Cerrando turno...";
    const cashierName = localStorage.getItem("cashierUsername");

    try {
        const res = await Api.request(`${API_SHIFT_URL}/api/shift/close`, {
            method: "POST",
            body: JSON.stringify({ shiftid: Number(shiftId), cashierid: cashierId, actualcash: countedCash, notes }),
            timeout: 20000
        });
        const data = await res.json().catch(() => ({}));

        if (!res.ok) {
            const crudo = String(data.message || data.Message || data.error || "").toLowerCase();
            // Probable cierre previo (p. ej. la respuesta se perdió por red lenta): intentamos recuperar el corte
            if (res.status === 409 || crudo.includes("no existe") || crudo.includes("cerrado")) {
                mostrarMensaje("El turno ya estaba cerrado. Recuperando el corte...", "info");
                await obtenerCorteZ(cashierName, Number(shiftId));
                return;
            }
            throw new Error(await Api.errorDe(res));
        }

        mostrarMensaje(data.message || "Turno cerrado correctamente.", "exito");
        await obtenerCorteZ(cashierName, Number(shiftId));
    } catch (error) {
        mostrarMensaje("Error al cerrar turno: " + error.message, "error");
    } finally {
        btnCerrar.disabled = false;
        btnCerrar.textContent = "Cerrar turno";
    }
}

// ---------- Corte Z (con reintentos: puede tardar en estar disponible) ----------
async function consultarCorte(shiftId) {
    const res = await Api.request(`${API_CUT_URL}/api/cut/zcuts?shiftId=${encodeURIComponent(shiftId)}`,
        { method: "GET", timeout: 10000 });
    if (!res.ok) throw new Error(await Api.errorDe(res));
    const data = await res.json().catch(() => ({}));
    return Array.isArray(data.cuts) && data.cuts.length > 0 ? data.cuts[0] : null;
}

async function obtenerCorteZ(cashierName, shiftId) {
    const esperas = [0, 1500, 3000, 5000];
    let ultimoError = null;
    for (const espera of esperas) {
        if (espera) await sleep(espera);
        try {
            const corte = await consultarCorte(shiftId);
            if (corte) {
                mostrarCorte(corte, cashierName);
                finalizarTurnoLocal();
                return;
            }
        } catch (e) { ultimoError = e; }
    }
    // El turno ya está cerrado en el servidor: se limpia lo local y se avisa
    mostrarMensaje(ultimoError
        ? "Turno cerrado, pero no fue posible obtener el corte Z: " + ultimoError.message
        : "El turno fue cerrado, pero todavía no se encontró el corte Z.", ultimoError ? "error" : "info");
    finalizarTurnoLocal();
}

function mostrarCorte(corte, cashierName) {
    seccionTurno.classList.add("oculto");
    seccionApertura.classList.add("oculto");
    seccionCorte.classList.remove("oculto");

    setText("corte-cajero", cashierName || corte.cashierUsername || "-");
    setText("corte-shift", corte.shiftId != null ? `#${corte.shiftId}` : "-");
    setText("corte-apertura", formatoFecha(corte.openedAt));
    setText("corte-cierre", formatoFecha(corte.closedAt));
    setText("corte-opening", formatoDinero(corte.openingCash));
    setText("corte-sales", formatoDinero(corte.totalSales));
    setText("corte-count", corte.totalSalesCount ?? 0);
    setText("corte-expected", formatoDinero(corte.expectedCash));
    setText("corte-actual", formatoDinero(corte.actualCash));
    setText("corte-difference", formatoDinero(corte.cashDifference));

    const status = $("corte-status");
    const audit = corte.auditStatus || "SIN ESTADO";
    status.textContent = audit;
    status.className = "resultado-corte";
    const u = audit.toUpperCase();
    status.classList.add(u.includes("FALTANTE") ? "faltante" : u.includes("SOBRANTE") ? "sobrante" : "correcto");

    setText("corte-notes", corte.notes || "Sin observaciones");
    estadoTurno.textContent = "● Turno cerrado";
    estadoTurno.className = "estado cerrado";
}

// ---------- Restaurar turno ----------
function restaurarTurno() {
    const shiftId = localStorage.getItem("shiftId");
    const amount = localStorage.getItem("openingAmount");
    const guardado = localStorage.getItem("cashierId");
    const usuario = obtenerUsuarioActual();

    if (shiftId && amount !== null) {
        // El turno guardado debe pertenecer al usuario con sesión iniciada
        if (usuario && usuario.id && guardado && String(guardado) !== String(usuario.id)) {
            finalizarTurnoLocal();
            seccionApertura.classList.remove("oculto");
            seccionTurno.classList.add("oculto");
            mostrarMensaje("Había un turno local de otro cajero. Ese turno debe cerrarlo su titular al iniciar sesión.", "error");
            return;
        }
        const nombre = localStorage.getItem("cashierUsername");
        mostrarTurnoAbierto(shiftId, nombre && nombre !== "null" ? nombre : "Cajero", Number(amount));
    } else {
        seccionApertura.classList.remove("oculto");
        seccionTurno.classList.add("oculto");
    }
}

if (btnAbrir) btnAbrir.addEventListener("click", abrirTurno);
if (btnCerrar) btnCerrar.addEventListener("click", cerrarTurno);

restaurarTurno();