'use strict';
window.RefreshBtn = {
    // accion: función async que hace la petición forzada
    bind(btn, accion, cooldownMs = 10000) {
        if (!btn) return;
        let ocupado = false;
        btn.addEventListener('click', async () => {
            if (ocupado) return;
            ocupado = true;
            btn.disabled = true;
            btn.classList.add('is-loading');
            try { await accion(); }
            finally {
                btn.classList.remove('is-loading');
                setTimeout(() => { ocupado = false; btn.disabled = false; }, cooldownMs);
            }
        });
    },
    marcar(el, t = Date.now()) {
        if (!el) return;
        el.textContent = 'Actualizado: ' + new Date(t).toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' });
    }
};