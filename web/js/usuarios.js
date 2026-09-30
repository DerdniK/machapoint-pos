// Function URL de ServicioUsers
const API_USERS_URL = "https://tmvksz56enigo6ojk25lfvg6x40vigzo.lambda-url.us-east-1.on.aws/api/users";
// const API_USERS_URL = "http://localhost:8080/api/users";

const statusMsg = document.getElementById('user-status-msg');

// Helper para leer siempre el token más reciente de localStorage
function obtenerToken() {
    return localStorage.getItem('authToken');
}

// Utilidades de mensajes al usuario
function mostrarError(mensaje) {
    if (statusMsg) {
        statusMsg.textContent = "Error: " + mensaje;
        statusMsg.style.color = "#d9534f";
    }
}

function mostrarExito(mensaje) {
    if (statusMsg) {
        statusMsg.textContent = mensaje;
        statusMsg.style.color = "#2e7d32";
    }
}

function mostrarProcesando() {
    if (statusMsg) {
        statusMsg.textContent = "Procesando...";
        statusMsg.style.color = "#333";
    }
}

// Aqui SOLO se valida que los campos tengan un formato correcto
// La existencia real la debe de crear el backend al hacer la llamada 

// No vacío, longitud > 3, solo letras (con acentos/ñ) y espacios
function esNombreValido(valor) {
    if (!valor) return false;
    const limpio = valor.trim();
    if (limpio.length === 0) return false;
    if (limpio.length <= 3) return false;
    const regex = /^[a-zA-ZÀ-ÿñÑ\s]+$/;
    return regex.test(limpio);
}

// No vacío, longitud > 3, letras/números/guion bajo (para username)
function esUsernameValido(valor) {
    if (!valor) return false;
    const limpio = valor.trim();
    if (limpio.length === 0) return false;
    if (limpio.length <= 3) return false;
    const regex = /^[a-zA-Z0-9_]+$/;
    return regex.test(limpio);
}

function esPasswordValida(password) {
    return typeof password === 'string' && password.length > 7;
}

function esRolValido(roleid) {
    return roleid === 1 || roleid === 2;
}

function esCampoNoVacio(valor) {
    return typeof valor === 'string' && valor.trim().length > 0;
}

// Valida formato UUID v4-ish. Esto NO confirma que el Userid
// exista en la base de datos, solo que "tiene forma" de UUID.
function esUUIDValido(valor) {
    if (!esCampoNoVacio(valor)) return false;
    const regexUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    return regexUUID.test(valor.trim());
}

// 1. Health check
async function checkHealth() {
    const healthEl = document.getElementById('health-status');
    if (!healthEl) return;

    try {
        const res = await fetch(`${API_USERS_URL}/health`);
        healthEl.textContent = res.ok ? "Servicio Users: Operativo" : "Servicio Users: Con fallas";
    } catch {
        healthEl.textContent = "Servicio Users: Offline";
    }
}
checkHealth();

// 2. Registro (POST /api/users/auth/register)
const formRegister = document.getElementById('form-register');
if (formRegister) {
    formRegister.addEventListener('submit', async (e) => {
        e.preventDefault();

        const username = document.getElementById('reg-username').value.trim();
        const password = document.getElementById('reg-password').value;
        const firstname = document.getElementById('reg-firstname').value.trim();
        const lastname = document.getElementById('reg-lastname').value.trim();
        const roleid = parseInt(document.getElementById('reg-roleid').value, 10);

        // --- Validaciones de formato ---
        if (!esUsernameValido(username)) {
            mostrarError("El nombre de usuario es obligatorio y debe tener más de 3 caracteres válidos (letras, números o guion bajo).");
            return;
        }
        if (!esPasswordValida(password)) {
            mostrarError("La contraseña debe tener más de 7 caracteres.");
            return;
        }
        if (!esNombreValido(firstname)) {
            mostrarError("El nombre es obligatorio y debe tener más de 3 caracteres válidos (solo letras).");
            return;
        }
        if (!esNombreValido(lastname)) {
            mostrarError("El apellido es obligatorio y debe tener más de 3 caracteres válidos (solo letras).");
            return;
        }
        if (!esRolValido(roleid)) {
            mostrarError("El rol solo puede ser '1' o '2'.");
            return;
        }

        // La existencia del username solo la puede confirmar el
        // backend al insertar (restricción UNIQUE en Postgres).
        // ejecutarPeticion() se encarga de traducir ese error.
        const payload = { username, password, firstname, lastname, roleid };

        await ejecutarPeticion(`${API_USERS_URL}/auth/register`, 'POST', payload, 'register');
        formRegister.reset();
    });
}

// 3. Modificación (users/auth/update)

const formUpdate = document.getElementById('form-update');
if (formUpdate) {
    formUpdate.addEventListener('submit', async (e) => {
        e.preventDefault();

        const userid = document.getElementById('upd-userid').value.trim();
        const username = document.getElementById('upd-username').value.trim();

        // --- Validaciones de formato ---
        if (!esCampoNoVacio(userid)) {
            mostrarError("El Userid es obligatorio.");
            return;
        }
        if (!esUUIDValido(userid)) {
            mostrarError("El Userid no tiene un formato válido (debe ser un UUID).");
            return;
        }
        if (!esUsernameValido(username)) {
            mostrarError("El nuevo nombre de usuario es obligatorio y debe tener más de 3 caracteres válidos.");
            return;
        }

        const payload = {
            Userid: userid,
            Username: username
        };

        await ejecutarPeticion(`${API_USERS_URL}/auth/update`, 'PATCH', payload, 'update');
        formUpdate.reset();
    });
}

// 4. Eliminación (DELETE)
const formDelete = document.getElementById('form-delete');
if (formDelete) {
    formDelete.addEventListener('submit', async (e) => {
        e.preventDefault();

        const userid = document.getElementById('del-userid').value.trim();

        // --- Validaciones de formato ---
        if (!esCampoNoVacio(userid)) {
            mostrarError("El Userid es obligatorio.");
            return;
        }
        if (!esUUIDValido(userid)) {
            mostrarError("El Userid no tiene un formato válido (debe ser un UUID).");
            return;
        }

        // Mismo caso que en update: el backend no confirma
        // existencia antes de eliminar.
        const payload = { Userid: userid };

        await ejecutarPeticion(`${API_USERS_URL}/auth/delete`, 'DELETE', payload, 'delete');
        formDelete.reset();
    });
}

// Ejecutor genérico de peticiones con manejo de errores
async function ejecutarPeticion(url, method, body, contexto) {
    mostrarProcesando();

    const currentToken = obtenerToken();
    const headers = {
        'Content-Type': 'application/json'
    };

    if (currentToken) {
        headers['Authorization'] = `Bearer ${currentToken}`;
    }

    try {
        const res = await fetch(url, {
            method: method,
            headers: headers,
            body: JSON.stringify(body)
        });

        let data = {};
        let rawText = '';
        try {
            rawText = await res.text();
            data = rawText ? JSON.parse(rawText) : {};
        } catch {
            // Respuesta sin cuerpo JSON válido (texto plano, HTML de error, etc.)
        }

        if (!res.ok) {
            const mensajeBackend = data.message || data.Message || data.error || rawText;
            const errorMsg = interpretarError(res.status, mensajeBackend, contexto);
            throw new Error(errorMsg);
        }

        mostrarExito(data.message || data.Message || `Operación ${method} realizada con éxito.`);
    } catch (err) {
        if (err instanceof TypeError) {
            mostrarError("No se pudo conectar con el servicio. Verifica tu conexión o intenta más tarde.");
        } else {
            mostrarError(err.message);
        }
    }
}

// Traduce mensajes crudos del backend (incluyendo errores de Postgres) a algo legible para el usuario final
function interpretarError(status, mensajeBackend, contexto) {
    const texto = (mensajeBackend || '').toString().toLowerCase();

    // Duplicate key de Postgres al registrar un username repetido
    if (texto.includes('duplicate key') || texto.includes('unique constraint')) {
        if (texto.includes('username')) {
            return "El nombre de usuario ya está en uso.";
        }
        return "Ya existe un registro con esos datos.";
    }

    // Violación de llave foránea (por ejemplo, roleid inexistente)
    if (texto.includes('foreign key')) {
        return "Uno de los datos enviados hace referencia a un registro que no existe (revisa el rol).";
    }

    // Userid no encontrado, si el SP llega a lanzar este tipo de error
    if (texto.includes('not found') || texto.includes('no existe') || texto.includes('no encontrado')) {
        return contexto === 'delete'
            ? "No se encontró ningún usuario con ese Userid para eliminar."
            : "No se encontró ningún usuario con ese Userid para actualizar.";
    }

    // Si el backend ya mandó un mensaje entendible, úsalo tal cual
    if (mensajeBackend && mensajeBackend.length > 0 && mensajeBackend.length < 200) {
        return mensajeBackend;
    }

    return mensajePorCodigo(status);
}

// Mensajes por defecto según código HTTP, por si el backend no envía nada útil
function mensajePorCodigo(status) {
    switch (status) {
        case 400: return "Solicitud inválida. Revisa los datos ingresados.";
        case 401: return "No autorizado. Inicia sesión nuevamente.";
        case 403: return "No tienes permisos para realizar esta acción.";
        case 404: return "Recurso no encontrado.";
        case 409: return "El registro ya existe (conflicto).";
        case 500: return "Error interno del servidor. Intenta más tarde.";
        default: return `Ocurrió un error (HTTP ${status}).`;
    }
}

// Utilidades de mensajes al usuario (Estilo SnackBar)
let snackbarTimeout;

function mostrarSnackBar(mensaje, tipo) {
    if (!statusMsg) return;
    
    // Asignar texto y limpiar clases anteriores
    statusMsg.textContent = mensaje;
    statusMsg.className = ''; 
    
    // Agregar clases necesarias para animarlo y colorearlo
    statusMsg.classList.add('show', tipo);

    // Reiniciar temporizador por si se spamean los botones
    clearTimeout(snackbarTimeout);
    
    // Ocultar automáticamente después de 3.5 segundos (excepto si está "Procesando")
    if (tipo !== 'processing') {
        snackbarTimeout = setTimeout(() => {
            statusMsg.classList.remove('show');
        }, 3500);
    }
}

function mostrarError(mensaje) {
    mostrarSnackBar("Error: " + mensaje, 'error');
}

function mostrarExito(mensaje) {
    mostrarSnackBar(mensaje, 'success');
}

function mostrarProcesando() {
    mostrarSnackBar("Procesando...", 'processing');
}