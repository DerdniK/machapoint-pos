/* ==========================================================================
   role.js - Sesión, roles y cierre de sesión (MachaPoint)
   Cargar en el <head>, ANTES de los demás scripts de la página:
     <script src="js/role.js"></script>                       -> exige sesión
     <script src="js/role.js" data-require="admin"></script>  -> exige sesión + admin
   - Redirige a index.html si no hay token o ya expiró.
   - En páginas con data-require="admin", manda a catalogo.html a quien no sea admin.
   - Elimina del DOM todo elemento con data-role="admin" cuando el usuario no es admin.
   - Cerrar sesión: bloqueada mientras haya un turno abierto; si no borra TODOS los datos locales.
   - Expone window.Auth para el resto de scripts.
   - Obtiene el usuario y rol del JWT o Login
   ========================================================================== */
(function () {
    'use strict';

    const TOKEN_KEY = 'authToken';
    const USER_KEY = 'user';
    const FLASH_KEY = 'authFlash';
    const LOGIN_PAGE = 'index.html';
    const HOME_PAGE = 'catalogo.html';

    // Claves del turno guardadas por ventas.js
    const SHIFT_KEYS = ['shiftId', 'cashierId', 'cashierUsername', 'openingAmount'];

    // Según usuarios.html: roleid 1 = Administrador, 2 = Usuario estándar.
    const ADMIN_ROLES = ['1', 'admin', 'administrator'];

    const script = document.currentScript;
    const requirement = (script && script.dataset.require) || 'auth'; // 'auth' | 'admin' | 'none'

    /* ---------- Sesión ---------- */

    function getToken() {
        return localStorage.getItem(TOKEN_KEY);
    }

    function getUser() {
        try {
            return JSON.parse(localStorage.getItem(USER_KEY) || 'null');
        } catch {
            return null;
        }
    }

    function decodeJwt(token) {
        if (!token) return null;
        try {
            const base64 = token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
            const json = decodeURIComponent(
                atob(base64)
                    .split('')
                    .map(c => '%' + c.charCodeAt(0).toString(16).padStart(2, '0'))
                    .join('')
            );
            return JSON.parse(json);
        } catch {
            return null;
        }
    }

    function isTokenExpired() {
        const claims = decodeJwt(getToken());
        return !!(claims && claims.exp && claims.exp * 1000 < Date.now());
    }

    /* ---------- Roles ---------- */

function extractRole(source) {
    if (!source || typeof source !== 'object') return null;
    const role = source.roleid || source.roleId || source.role || null;
    // 'authenticated' y 'anon' son roles de Postgres/Supabase, no del POS
    if (typeof role === 'string' &&
        ['authenticated', 'anon', 'service_role'].includes(role.toLowerCase())) return null;
    return role;
}

    function getRoles() {
        const claims = decodeJwt(getToken());
        const user = getUser();

        // 1. Intenta obtener el rol directamente del token (raíz o metadata)
        const tokenRole = extractRole(claims) || extractRole(claims && claims.app_metadata);

        // 2. Intenta obtener el rol de los datos de usuario guardados en login
        const loginRole = extractRole(user);

        // Prioridad: JWT primero, Login después.
        const activeRole = tokenRole || loginRole;

        return activeRole ? [String(activeRole).trim().toLowerCase()] : [];
    }

    function isAdmin() {
        return getRoles().some(role => ADMIN_ROLES.includes(role));
    }

    /* ---------- Cerrar sesión ---------- */

    // Borra TODO lo que la app guarda en el navegador (incluye turno y sesión de Supabase).
    function wipeAllData() {
        localStorage.clear();
        sessionStorage.clear();
    }

    function leaveToLogin(message) {
        if (message) sessionStorage.setItem(FLASH_KEY, message);
        window.location.replace(LOGIN_PAGE);
    }

    // Salida involuntaria (token vencido / 401): NO se puede cerrar el turno sin sesión válida,
    // así que se borra la sesión pero se CONSERVAN los datos del turno para poder cerrarlo
    // después de volver a iniciar sesión.
    function forceLogout(message) {
        const turno = SHIFT_KEYS
            .map(k => [k, localStorage.getItem(k)])
            .filter(([, v]) => v !== null);
        wipeAllData();
        turno.forEach(([k, v]) => localStorage.setItem(k, v));
        leaveToLogin(message);
    }

    // Cerrar sesión: solo se permite si NO hay un turno abierto.
    // El turno se cierra desde ventas.html (arqueo de caja); al cerrarlo, ventas.js
    // borra shiftId y el botón vuelve a funcionar.
    function logout() {
        if (localStorage.getItem('shiftId')) {
            const irAVentas = confirm(
                'Tienes un turno abierto. Ciérralo antes de cerrar sesión.\n\n' +
                '¿Ir a la pantalla de ventas para cerrarlo?'
            );
            if (irAVentas) window.location.href = 'ventas.html';
            return;
        }

        let avisoCarrito = '';
        try {
            if (JSON.parse(localStorage.getItem('carrito') || '[]').length > 0) {
                avisoCarrito = 'El carrito actual se vaciará.\n\n';
            }
        } catch { /* carrito corrupto: se limpia igual */ }

        if (!confirm(`${avisoCarrito}¿Cerrar sesión?`)) return;

        wipeAllData();
        leaveToLogin('Sesión cerrada.');
    }

    /* ---------- UI ---------- */

    function showToast(message) {
        const toast = document.createElement('div');
        toast.className = 'auth-toast';
        toast.setAttribute('role', 'status');
        toast.textContent = message;
        document.body.appendChild(toast);
        setTimeout(() => toast.remove(), 4000);
    }

    function applyRoleVisibility() {
        if (isAdmin()) return;
        document.querySelectorAll('[data-role="admin"]').forEach(el => el.remove());
        document.querySelectorAll('a[href$="usuarios.html"]').forEach(link => {
            (link.closest('li') || link).remove();
        });
    }

    function injectSessionControls() {
        const user = getUser() || {};
        const name = user.username || user.nombre || user.email || 'Sesión activa';

        const wrap = document.createElement('span');
        wrap.className = 'session-controls';

        const badge = document.createElement('span');
        badge.className = 'user-badge';
        badge.textContent = `${name} (${isAdmin() ? 'Admin' : 'Usuario'})`;

        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'btn-logout';
        button.dataset.logout = '';
        button.textContent = 'Cerrar sesión';
        button.addEventListener('click', logout);

        wrap.append(badge, button);

        const host = document.querySelector('nav ul') || document.querySelector('nav') || document.querySelector('header');
        if (!host) {
            wrap.classList.add('session-controls--floating');
            document.body.appendChild(wrap);
            return;
        }
        if (host.tagName === 'UL') {
            const li = document.createElement('li');
            li.appendChild(wrap);
            host.appendChild(li);
        } else {
            host.appendChild(wrap);
        }
    }

    /* ---------- API pública ---------- */

    window.Auth = { getToken, getUser, getRoles, isAdmin, logout, forceLogout, isTokenExpired };

    /* ---------- Guardas de acceso (corren antes de pintar la página) ---------- */

    if (requirement === 'none') return;

    if (!getToken() || isTokenExpired()) {
        forceLogout(getToken() ? 'Tu sesión expiró. Inicia sesión de nuevo.' : '');
        return;
    }

    if (requirement === 'admin' && !isAdmin()) {
        sessionStorage.setItem(FLASH_KEY, 'No tienes permisos para entrar a esa sección.');
        window.location.replace(HOME_PAGE);
        return;
    }

    document.addEventListener('DOMContentLoaded', () => {
        const flash = sessionStorage.getItem(FLASH_KEY);
        if (flash) {
            sessionStorage.removeItem(FLASH_KEY);
            showToast(flash);
        }
        applyRoleVisibility();
        if (!document.querySelector('[data-logout]')) injectSessionControls();
        else document.querySelectorAll('[data-logout]').forEach(b => b.addEventListener('click', logout));
    });
})();