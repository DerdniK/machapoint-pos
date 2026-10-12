// Function URL de ServicioUsers
const API_USERS_URL = 'https://tmvksz56enigo6ojk25lfvg6x40vigzo.lambda-url.us-east-1.on.aws/api/users';

const formulario = document.getElementById('login');
const mensaje = document.getElementById('mensaje');
const loginButton = document.getElementById('loginButton');

function setLoading(isLoading) {
    if (!loginButton) return;
    loginButton.classList.toggle('is-loading', isLoading);
    loginButton.disabled = isLoading;
    loginButton.setAttribute('aria-busy', isLoading);
}

// Pantalla de carga 
window.addEventListener('load', () => {
    const loader = document.getElementById('loader');
    if (loader) setTimeout(() => loader.classList.add('oculto'), 1300);
});

// Mensajes del flujo de Google (callback.html redirige con ?error=...)
const errorUrl = new URLSearchParams(window.location.search).get('error');
if (errorUrl && mensaje) mensaje.textContent = 'No se pudo completar el inicio de sesión. Intenta de nuevo.';

// El contrato con el backend debería ser fijo; se aceptan solo las variantes conocidas
function extraerToken(d) {
    return d.token || d.Token || d.accessToken || d.AccessToken || d.authData?.token || d.AuthData?.Token || d.data?.token || d.Data?.Token;
}

if (formulario) {
    formulario.addEventListener('submit', async (event) => {
        event.preventDefault();
        if (loginButton && loginButton.disabled) return;

        const usuario = document.getElementById('username').value.trim();
        const password = document.getElementById('password').value; // sin trim: puede tener espacios

        if (mensaje) mensaje.textContent = '';
        setLoading(true);

        try {
            const respuesta = await Api.request(`${API_USERS_URL}/auth/login`, {
                method: 'POST',
                auth: false,
                timeout: 20000,
                body: JSON.stringify({ Username: usuario, Password: password })
            });
            const data = await respuesta.json().catch(() => ({}));

            if (!respuesta.ok) {
                // Mensaje genérico: no revela si el usuario existe ni detalles internos
                throw new Error(respuesta.status === 400 || respuesta.status === 401
                    ? 'Usuario o contraseña incorrectos.'
                    : await Api.errorDe(respuesta));
            }

            const token = extraerToken(data);
            if (!token) throw new Error('Respuesta inesperada del servidor. Contacta al administrador.');

            localStorage.setItem('authToken', token);
            localStorage.setItem('user', JSON.stringify({
                username: data.username || data.Username || usuario,
                id: data.userId || data.Userid || data.UserId || data.userid || ''
            }));
            window.location.href = 'catalogo.html';
        } catch (error) {
            if (mensaje) mensaje.textContent = error.message;
            setLoading(false);
        }
    });
}