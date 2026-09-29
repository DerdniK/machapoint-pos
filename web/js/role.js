/* ==========================================================================
   auth.js - Sesión, roles y cierre de sesión (MachaPoint)
   Cargar en el <head>, ANTES de los demás scripts de la página:

     <script src="js/auth.js"></script>                       -> exige sesión
     <script src="js/auth.js" data-require="admin"></script>  -> exige sesión + admin
   - Redirige a index.html si no hay token o ya expiró.
   - En páginas con data-require="admin", manda a catalogo.html a quien no sea admin.
   - Elimina del DOM todo elemento con data-role="admin" (y los links a usuarios.html)
     cuando el usuario no es admin.
   - Inyecta "usuario (rol)" + botón "Cerrar sesión" en nav / header.
   - Expone window.Auth para el resto de scripts.
   ========================================================================== */
(function () {
    'use strict';

    const TOKEN_KEY = 'authToken';
    const USER_KEY = 'user';
    const FLASH_KEY = 'authFlash';
    const LOGIN_PAGE = 'index.html';
    const HOME_PAGE = 'catalogo.html';

    // AJUSTAR SI HACE FALTA: valores de rol que cuentan como administrador.
    // Según usuarios.html: roleid 1 = Administrador, 2 = Usuario estándar.
    const ADMIN_ROLES = ['1', 'admin', 'Admin', 'administrator'];

    // Nombres de claim / propiedad donde puede venir el rol.
    const ROLE_KEYS = ['roleid', 'roleId', 'Roleid', 'RoleId',];

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

    function rolesFrom(source) {
        if (!source || typeof source !== 'object') return [];
        const found = [];
        ROLE_KEYS.forEach(key => {
            if (source[key] !== undefined && source[key] !== null) {
                found.push(...[].concat(source[key]));
            }
        });
        return found.map(r => String(r).trim().toLowerCase()).filter(Boolean);
    }

    // Prioridad: claims del JWT. Si el token no trae rol, se usa user.role (guardado en el login).
    function getRoles() {
        const claims = decodeJwt(getToken());
        const fromToken = [...rolesFrom(claims), ...rolesFrom(claims && claims.app_metadata)];
        return fromToken.length ? fromToken : rolesFrom(getUser());
    }

    function isAdmin() {
        return getRoles().some(role => ADMIN_ROLES.includes(role));
    }

    /* ---------- Cerrar sesión ---------- */

    function clearSession() {
        [TOKEN_KEY, USER_KEY, 'usuario', 'carrito'].forEach(k => localStorage.removeItem(k));
        // Sesión de Supabase (Google OAuth)
        Object.keys(localStorage)
            .filter(k => k.startsWith('sb-'))
            .forEach(k => localStorage.removeItem(k));
        // los datos del turno (shiftId, cashierId, ...) se conservan a propósito
        // para poder retomar un turno abierto al volver a iniciar sesión.
    }

    function forceLogout(message) {
        clearSession();
        if (message) sessionStorage.setItem(FLASH_KEY, message);
        window.location.replace(LOGIN_PAGE);
    }

    function logout() {
        const avisos = [];
        if (localStorage.getItem('shiftId')) avisos.push('Tienes un turno abierto (sigue abierto en el sistema).');
        try {
            if (JSON.parse(localStorage.getItem('carrito') || '[]').length > 0) {
                avisos.push('El carrito actual se vaciara.');
            }
        } catch { /* carrito corrupto: se limpia igual */ }

        const texto = avisos.length
            ? `${avisos.join('\n')}\n\n¿Cerrar sesión de todos modos?`
            : '¿Cerrar sesión?';

        if (!confirm(texto)) return;
        forceLogout();
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