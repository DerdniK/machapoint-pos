/* api.js - Cliente HTTP común (cargar DESPUÉS de role.js y ANTES del script de cada página)
   Timeout, reintentos con backoff (solo si se piden), manejo de 401/429/503, helpers seguros. */
(function () {
    'use strict';
    const sleep = ms => new Promise(r => setTimeout(r, ms));
    const backoff = i => Math.min(1000 * 2 ** i, 8000) + Math.random() * 300;

    function esc(v) {
        return String(v ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
    }
    function debounce(fn, ms = 200) {
        let t;
        return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); };
    }
    // Devuelve la URL normalizada solo si es https; si no, null
    function urlSegura(u) {
        try { const x = new URL(String(u)); return x.protocol === 'https:' ? x.href : null; } catch { return null; }
    }
    function mensajePorCodigo(s) {
        switch (s) {
            case 400: return 'Solicitud inválida. Revisa los datos ingresados.';
            case 401: return 'Sesión no válida. Inicia sesión nuevamente.';
            case 403: return 'No tienes permisos para realizar esta acción.';
            case 404: return 'Recurso no encontrado.';
            case 409: return 'El registro ya existe o hay un conflicto.';
            case 429: return 'Demasiadas solicitudes. Espera unos segundos e intenta de nuevo.';
            default: return s >= 500 ? 'Error del servidor. Intenta más tarde.' : `Ocurrió un error (HTTP ${s}).`;
        }
    }
    // Mensaje de error apto para el usuario. En 5xx nunca muestra el texto crudo del servidor.
    async function errorDe(res) {
        const data = await res.clone().json().catch(() => ({}));
        const m = data.message || data.Message || data.error || data.Error;
        if (res.status < 500 && res.status !== 429 && typeof m === 'string' && m.length > 0 && m.length < 200) return m;
        return mensajePorCodigo(res.status);
    }

    /* opts: { timeout=15000, retries=0, auth=true, ...fetchOptions }
       Usa retries>0 SOLO en GET o en peticiones idempotentes. */
    async function request(url, { timeout = 15000, retries = 0, auth = true, ...opts } = {}) {
        const headers = { ...(opts.body ? { 'Content-Type': 'application/json' } : {}), ...(opts.headers || {}) };
        if (auth) {
            const token = localStorage.getItem('authToken');
            if (!token) {
                if (window.Auth) window.Auth.forceLogout('Inicia sesión para continuar.');
                throw new Error('No hay sesión activa.');
            }
            headers.Authorization = `Bearer ${token}`;
        }
        for (let i = 0; ; i++) {
            const ctrl = new AbortController();
            const timer = setTimeout(() => ctrl.abort(), timeout);
            try {
                const res = await fetch(url, { ...opts, headers, signal: ctrl.signal });
                if (res.status === 401 && auth && window.Auth) window.Auth.forceLogout('Tu sesión expiró. Inicia sesión de nuevo.');
                if ((res.status === 429 || res.status === 503) && i < retries) {
                    const ra = Number(res.headers.get('Retry-After'));
                    await sleep(ra > 0 ? ra * 1000 : backoff(i));
                    continue;
                }
                return res;
            } catch (e) {
                if (i < retries) { await sleep(backoff(i)); continue; }
                throw new Error(e.name === 'AbortError'
                    ? 'La conexión es lenta y la solicitud tardó demasiado. Intenta de nuevo.'
                    : 'No se pudo conectar con el servidor. Revisa tu conexión.');
            } finally {
                clearTimeout(timer);
            }
        }
    }

    window.Api = { request, errorDe, esc, debounce, urlSegura, mensajePorCodigo };
})();