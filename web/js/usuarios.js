// MACHAPOINT POS - Administración de usuarios (alta, búsqueda y edición)
'use strict';

const API_USERS_URL = 'https://tmvksz56enigo6ojk25lfvg6x40vigzo.lambda-url.us-east-1.on.aws/api/users';

// AJUSTAR si el endpoint que expone sp_view_users tiene otra ruta.
// Se llama con ?userid=<uuid> cuando se quiere un solo usuario (p_userid opcional).
const URL_LISTAR = `${API_USERS_URL}/auth/view`;
const URL_CREAR = `${API_USERS_URL}/auth/register`;
const URL_ACTUALIZAR = `${API_USERS_URL}/auth/update`;
const URL_ELIMINAR = `${API_USERS_URL}/auth/delete`;

const ROLES = [
    { id: 1, nombre: 'Administrador' },
    { id: 2, nombre: 'Trabajador' }
];

// ---------- Reglas de validación ----------
const USERNAME_MIN = 4;
const USERNAME_MAX = 20;
const NOMBRE_MIN = 2;
const NOMBRE_MAX = 30;
const PASSWORD_MIN = 8;
const PASSWORD_MAX = 64;

const USERNAME_VALIDO = /^[A-Za-z0-9_]+$/;
const USERNAME_INVALIDOS = /[^A-Za-z0-9_]/g;
const NOMBRE_VALIDO = /^[A-Za-zÀ-ÿñÑ]+(?: [A-Za-zÀ-ÿñÑ]+)*$/;
const NOMBRE_INVALIDOS = /[^A-Za-zÀ-ÿñÑ ]/g;

// ---------- DOM ----------
const $ = id => document.getElementById(id);
const formCrear = $('form-crear-usuario');
const btnCrear = $('btn-crear');
const msgCreacion = $('mensaje-creacion');
const buscador = $('buscador');
const msgLista = $('mensaje');
const tbody = $('tabla-usuarios');
const dialogo = $('dialogo-editar');
const formEditar = $('form-editar');
const btnGuardarEdicion = $('btn-guardar-edicion');
const btnCancelarEdicion = $('btn-cancelar-edicion');
const msgEdicion = $('mensaje-edicion');

let usuarios = [];
let usuarioEnEdicion = null;

// ---------- Utilidades ----------
function setMsg(el, texto, tipo = 'info') {
    if (!el) return;
    el.textContent = texto;
    el.classList.remove('mp-inline-msg--success', 'mp-inline-msg--error');
    if (tipo === 'error') el.classList.add('mp-inline-msg--error');
    else if (tipo === 'exito') el.classList.add('mp-inline-msg--success');
}

const esAdmin = () => !!(window.Auth && Auth.isAdmin());

function normalizarTexto(t) {
    return String(t ?? '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
}

function nombreRol(id) {
    const r = ROLES.find(x => x.id === Number(id));
    return r ? r.nombre : (id ? `Rol ${id}` : 'Sin rol');
}

// Id del usuario con sesión activa (guardado en login o, si no, claim "sub" del JWT)
function miUserId() {
    const u = window.Auth && Auth.getUser();
    if (u && u.id) return String(u.id).toLowerCase();
    try {
        const payload = JSON.parse(atob(Auth.getToken().split('.')[1].replace(/-/g, '+').replace(/_/g, '/')));
        return String(payload.sub || payload.userid || payload.userId || '').toLowerCase() || null;
    } catch { return null; }
}
const esMiCuenta = u => !!miUserId() && String(u.id).toLowerCase() === miUserId();

// sp_view_users devuelve: userId, username, firstName, lastName, roleId, createAt
function normalizarUsuario(u) {
    const o = {
        id: u.userId ?? u.userid ?? u.Userid ?? u.id,
        username: u.username ?? u.Username ?? '',
        firstName: u.firstName ?? u.firstname ?? '',
        lastName: u.lastName ?? u.lastname ?? '',
        roleId: Number(u.roleId ?? u.roleid ?? u.Roleid),
        createdAt: u.createAt ?? u.createdAt ?? u.createat ?? null
    };
    o._q = normalizarTexto(`${o.username} ${o.firstName} ${o.lastName}`);
    return o;
}

function formatoFecha(f) {
    if (!f) return '-';
    const d = new Date(f);
    return isNaN(d.getTime()) ? String(f) : d.toLocaleDateString('es-MX');
}

// Traduce errores crudos del backend (incluye Postgres) a mensajes legibles
function interpretarError(status, crudo) {
    const t = String(crudo || '').toLowerCase();
    if (t.includes('duplicate key') || t.includes('unique constraint') || status === 409) {
        return t.includes('username') || !t ? 'El nombre de usuario ya está en uso.' : 'Ya existe un registro con esos datos.';
    }
    if (t.includes('foreign key')) return 'El rol enviado no existe.';
    if (t.includes('not found') || t.includes('no existe') || t.includes('no encontrado')) return 'No se encontró el usuario.';
    if (crudo && String(crudo).length < 200) return String(crudo);
    return Api.mensajePorCodigo(status);
}

// Petición de escritura: lanza Error con mensaje apto para el usuario
async function enviar(url, method, body) {
    const res = await Api.request(url, { method, body: JSON.stringify(body), timeout: 20000 });
    const raw = await res.text();
    let data = {};
    try { data = raw ? JSON.parse(raw) : {}; } catch { /* respuesta no JSON */ }
    if (!res.ok || data.success === false) {
        const crudo = data.message || data.Message || data.error || '';
        throw new Error(res.status >= 500 && !/duplicate|unique|foreign/i.test(crudo)
            ? Api.mensajePorCodigo(res.status)
            : interpretarError(res.status, crudo));
    }
    return data;
}

// ---------- Bloqueo de input ----------
const sanitizarUsername = v => v.replace(USERNAME_INVALIDOS, '').slice(0, USERNAME_MAX);
const sanitizarNombre = v => v.replace(NOMBRE_INVALIDOS, '').replace(/ {2,}/g, ' ').slice(0, NOMBRE_MAX);

function bloquearInput(input, sanitizar) {
    if (!input) return;
    input.addEventListener('beforeinput', (e) => {
        if (e.data == null || e.inputType.startsWith('delete')) return;
        const ini = input.selectionStart ?? input.value.length;
        const fin = input.selectionEnd ?? input.value.length;
        const resultado = input.value.slice(0, ini) + e.data + input.value.slice(fin);
        if (sanitizar(resultado) !== resultado) e.preventDefault();
    });
    input.addEventListener('input', () => {
        const limpio = sanitizar(input.value);
        if (limpio !== input.value) input.value = limpio;
    });
}

function aplicarBloqueos() {
    ['reg-username', 'ed-username'].forEach(id => bloquearInput($(id), sanitizarUsername));
    ['reg-firstname', 'reg-lastname'].forEach(id => bloquearInput($(id), sanitizarNombre));
}

// ---------- Validación ----------
function validarUsername(username) {
    if (!username) return 'El username es obligatorio.';
    if (username.length < USERNAME_MIN) return `El username debe tener al menos ${USERNAME_MIN} caracteres.`;
    if (username.length > USERNAME_MAX) return `El username no puede tener más de ${USERNAME_MAX} caracteres.`;
    if (!USERNAME_VALIDO.test(username)) return 'El username solo puede contener letras (sin acentos), números y guion bajo (_).';
    return null;
}

function validarNombrePropio(valor, etiqueta) {
    if (!valor) return `El ${etiqueta} es obligatorio.`;
    if (valor.length < NOMBRE_MIN) return `El ${etiqueta} debe tener al menos ${NOMBRE_MIN} letras.`;
    if (valor.length > NOMBRE_MAX) return `El ${etiqueta} no puede tener más de ${NOMBRE_MAX} caracteres.`;
    if (!NOMBRE_VALIDO.test(valor)) return `El ${etiqueta} solo puede contener letras y espacios.`;
    return null;
}

function validarPassword(pw) {
    if (!pw) return 'La contraseña es obligatoria.';
    if (pw.length < PASSWORD_MIN) return `La contraseña debe tener al menos ${PASSWORD_MIN} caracteres.`;
    if (pw.length > PASSWORD_MAX) return `La contraseña no puede tener más de ${PASSWORD_MAX} caracteres.`;
    return null;
}

function validarRol(valor) {
    const r = parseInt(valor, 10);
    if (!ROLES.some(x => x.id === r)) return { error: 'Selecciona un rol válido (1 Administrador, 2 Trabajador).' };
    return { valor: r };
}

function validarAlta({ username, password, firstName, lastName, roleId }) {
    username = username.trim(); firstName = firstName.trim().replace(/ {2,}/g, ' '); lastName = lastName.trim().replace(/ {2,}/g, ' ');
    const err = validarUsername(username) || validarPassword(password)
        || validarNombrePropio(firstName, 'nombre') || validarNombrePropio(lastName, 'apellido');
    if (err) return { error: err };
    const rol = validarRol(roleId);
    if (rol.error) return rol;
    return { valores: { username, password, firstName, lastName, roleId: rol.valor } };
}

function validarEdicion({ username, roleId }) {
    username = username.trim();
    const err = validarUsername(username);
    if (err) return { error: err };
    const rol = validarRol(roleId);
    if (rol.error) return rol;
    return { valores: { username, roleId: rol.valor } };
}

// ---------- Listado ----------
async function cargarUsuarios() {
    setMsg(msgLista, 'Cargando usuarios...');
    try {
        const res = await Api.request(URL_LISTAR, { method: 'GET', retries: 2 });
        if (res.status === 403) {
            setMsg(msgLista, 'Tu usuario no tiene permisos para ver los usuarios.', 'error');
            return;
        }
        if (!res.ok) throw new Error(await Api.errorDe(res));

        const data = await res.json();
        const lista = data.users || data.user || data.data || (Array.isArray(data) ? data : []);
        usuarios = lista.map(normalizarUsuario);
        renderTabla();
    } catch (err) {
        setMsg(msgLista, 'No se pudieron cargar los usuarios: ' + err.message, 'error');
    }
}

function celda(texto, clase) {
    const td = document.createElement('td');
    td.textContent = texto;
    if (clase) td.className = clase;
    return td;
}

function celdaBadge(texto) {
    const td = document.createElement('td');
    const b = document.createElement('span');
    b.className = 'mp-badge';
    b.textContent = texto;
    td.appendChild(b);
    return td;
}

function crearFila(u) {
    const tr = document.createElement('tr');
    const tdAcc = document.createElement('td');

    if (esMiCuenta(u)) {
        // El usuario activo no puede modificar ni eliminar su propia cuenta
        const b = document.createElement('span');
        b.className = 'mp-badge';
        b.textContent = 'Tu cuenta';
        tdAcc.appendChild(b);
    } else {
        const editar = document.createElement('button');
        editar.type = 'button';
        editar.className = 'mp-btn mp-btn--dark pp-btn-sm';
        editar.textContent = 'Editar';
        editar.setAttribute('aria-label', `Editar ${u.username}`);
        editar.addEventListener('click', () => abrirEdicion(u));

        const eliminar = document.createElement('button');
        eliminar.type = 'button';
        eliminar.className = 'mp-btn pp-btn-secondary pp-btn-sm';
        eliminar.textContent = 'Eliminar';
        eliminar.setAttribute('aria-label', `Eliminar ${u.username}`);
        eliminar.addEventListener('click', () => eliminarUsuario(u));

        // tdAcc.append(editar, ' ', eliminar);
        tdAcc.append(editar);
    }

    tr.append(celda(u.username), celda(u.firstName), celda(u.lastName),
              celdaBadge(nombreRol(u.roleId)), celda(formatoFecha(u.createdAt)), tdAcc);
    return tr;
}

function renderTabla() {
    const termino = normalizarTexto(buscador.value);
    const lista = termino ? usuarios.filter(u => u._q.includes(termino)) : usuarios;
    tbody.replaceChildren();

    if (lista.length === 0) {
        setMsg(msgLista, usuarios.length
            ? `No se encontraron usuarios para "${buscador.value.trim()}".`
            : 'No hay usuarios registrados.');
        return;
    }
    setMsg(msgLista, '');
    const frag = document.createDocumentFragment();
    lista.forEach(u => frag.appendChild(crearFila(u)));
    tbody.appendChild(frag);
}

buscador.addEventListener('input', Api.debounce(renderTabla, 200));
buscador.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') { buscador.value = ''; renderTabla(); }
});

// ---------- Alta ----------
formCrear.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (btnCrear.disabled) return;
    if (!esAdmin()) { setMsg(msgCreacion, 'No tienes permisos para crear usuarios.', 'error'); return; }

    const v = validarAlta({
        username: $('reg-username').value,
        password: $('reg-password').value,
        firstName: $('reg-firstname').value,
        lastName: $('reg-lastname').value,
        roleId: $('reg-roleid').value
    });
    if (v.error) { setMsg(msgCreacion, v.error, 'error'); return; }

    const { username, password, firstName, lastName, roleId } = v.valores;
    btnCrear.disabled = true;
    setMsg(msgCreacion, 'Creando usuario...');
    try {
        await enviar(URL_CREAR, 'POST', { username, password, firstname: firstName, lastname: lastName, roleid: roleId });
        setMsg(msgCreacion, '¡Usuario creado con éxito!', 'exito');
        formCrear.reset();
        await cargarUsuarios();
    } catch (err) {
        setMsg(msgCreacion, 'Error al crear: ' + err.message, 'error');
    } finally {
        btnCrear.disabled = false;
    }
});

// ---------- Edición ----------
function abrirEdicion(u) {
    if (esMiCuenta(u)) { setMsg(msgLista, 'No puedes modificar tu propia cuenta.', 'error'); return; }
    usuarioEnEdicion = u;
    $('ed-username').value = u.username;
    $('ed-roleid').value = String(u.roleId);
    $('titulo-edicion').textContent = `Editar usuario: ${u.username}`;
    setMsg(msgEdicion, '');
    dialogo.showModal();
}

function cerrarEdicion() {
    dialogo.close();
    usuarioEnEdicion = null;
}

btnCancelarEdicion.addEventListener('click', cerrarEdicion);
dialogo.addEventListener('click', (e) => { if (e.target === dialogo) cerrarEdicion(); });

formEditar.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (btnGuardarEdicion.disabled) return;
    if (!esAdmin()) { setMsg(msgEdicion, 'No tienes permisos para editar usuarios.', 'error'); return; }
    if (!usuarioEnEdicion) return;
    const original = usuarioEnEdicion;
    if (esMiCuenta(original)) { setMsg(msgEdicion, 'No puedes modificar tu propia cuenta.', 'error'); return; }

    const v = validarEdicion({ username: $('ed-username').value, roleId: $('ed-roleid').value });
    if (v.error) { setMsg(msgEdicion, v.error, 'error'); return; }

    // Solo se envía lo que cambió
    const cambios = { Userid: original.id };
    if (v.valores.username !== original.username) cambios.Username = v.valores.username;
    if (v.valores.roleId !== original.roleId) cambios.Roleid = v.valores.roleId;
    if (Object.keys(cambios).length === 1) { setMsg(msgEdicion, 'No hay cambios que guardar.'); return; }

    btnGuardarEdicion.disabled = true;
    setMsg(msgEdicion, 'Guardando cambios...');
    try {
        const data = await enviar(URL_ACTUALIZAR, 'PATCH', cambios);
        cerrarEdicion();
        await cargarUsuarios();
        setMsg(msgLista, data.message || data.Message || 'Usuario actualizado con éxito.', 'exito');
    } catch (err) {
        setMsg(msgEdicion, 'Error al guardar: ' + err.message, 'error');
    } finally {
        btnGuardarEdicion.disabled = false;
    }
});

// ---------- Eliminación ----------
async function eliminarUsuario(u) {
    if (!esAdmin() || esMiCuenta(u)) return;
    if (!confirm(`¿Eliminar al usuario "${u.username}"? Esta acción no se puede deshacer.`)) return;
    setMsg(msgLista, 'Eliminando usuario...');
    try {
        const data = await enviar(URL_ELIMINAR, 'DELETE', { Userid: u.id });
        await cargarUsuarios();
        setMsg(msgLista, data.message || data.Message || 'Usuario eliminado con éxito.', 'exito');
    } catch (err) {
        setMsg(msgLista, 'Error al eliminar: ' + err.message, 'error');
    }
}

// ---------- Inicio ----------
aplicarBloqueos();
cargarUsuarios();