// Function URL de ServicioUsers
const API_USERS_URL = 'https://tmvksz56enigo6ojk25lfvg6x40vigzo.lambda-url.us-east-1.on.aws/api/users';
// const API_USERS_URL = 'http://localhost:8080/api/users';

const formulario = document.getElementById('login');
const mensaje = document.getElementById('mensaje');
const loginButton = document.getElementById('loginButton');

function setLoading(isLoading) {
    if (!loginButton) return;
    loginButton.classList.toggle('is-loading', isLoading);
    loginButton.disabled = isLoading;
    loginButton.setAttribute('aria-busy', isLoading);
}

/* ==========================
   PANTALLA DE CARGA
========================== */
window.addEventListener('load', () => {
    const loader = document.getElementById('loader');
    if (loader) {
        setTimeout(() => {
            loader.classList.add('oculto');
        }, 1500);
    }
});

/* ==========================
   LOGIN
========================== */
if (formulario) {
    formulario.addEventListener('submit', async (event) => {
        event.preventDefault();
        const usuario = document.getElementById('username').value.trim();
        const password = document.getElementById('password').value.trim();

        if (mensaje) mensaje.textContent = '';
        setLoading(true);

        try {
            const respuesta = await fetch(`${API_USERS_URL}/auth/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    Username: usuario,
                    Password: password
                })
            });

            const data = await respuesta.json().catch(() => ({}));
            console.log('HTTP Status:', respuesta.status);
            console.log('Respuesta cruda del backend:', data);

            if (!respuesta.ok) {
                console.error('Error del servidor:', data);
                const errorBackend =
                    data.message ||
                    data.Message ||
                    data.error ||
                    data.Error ||
                    `Error HTTP ${respuesta.status}`;
                throw new Error(errorBackend);
            }

            // Búsqueda exhaustiva del JWT en todas las nomenclaturas habituales de C#/.NET
            const token =
                data.token ||
                data.Token ||
                data.jwt ||
                data.JWT ||
                data.accessToken ||
                data.AccessToken ||
                data.access_token ||
                data.authData?.token ||
                data.authData?.Token ||
                data.AuthData?.Token ||
                data.AuthData?.token ||
                data.data?.token ||
                data.data?.Token ||
                data.Data?.Token;

            if (!token) {
                console.error('Estructura completa de data sin token:', JSON.stringify(data, null, 2));
                throw new Error(`El backend devolvió 200 OK pero no se halló el token. Propiedades recibidas: ${Object.keys(data).join(', ')}`);
            }

            console.log('Token JWT capturado con éxito:', token);

            // Guardar token bajo la misma key que usa Google OAuth
            localStorage.setItem('authToken', token);
            localStorage.setItem('user', JSON.stringify({
                username: data.username || data.Username || usuario,
                id: data.userId || data.Userid || data.UserId || ''
            }));

            // Redireccionar al catálogo
            window.location.href = 'catalogo.html';

        } catch (error) {
            console.error('Error en login:', error);
            if (mensaje) mensaje.textContent = error.message;
            setLoading(false);
        }
    });
}