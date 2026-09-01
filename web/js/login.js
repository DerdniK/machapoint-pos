//const API_URL = 'https://lvk5buixqe.execute-api.us-east-1.amazonaws.com/api/health';

// endpoint de login y registrer
const API_USER = 'https://lvk5buixqe.execute-api.us-east-1.amazonaws.com/api/auth';

const formulario = document.getElementById('login');
const mensaje = document.getElementById('mensaje');
const loginButton = document.getElementById('loginButton');


function setLoading(isLoading) {
    loginButton.classList.toggle('is-loading', isLoading);
    loginButton.disabled = isLoading;
    loginButton.setAttribute('aria-busy', isLoading);
}

/* ==========================
   PANTALLA DE CARGA
========================== */
window.addEventListener("load", () => {

    const loader = document.getElementById("loader");

    setTimeout(() => {

        loader.classList.add("oculto");

    }, 1500);

});

/* ==========================
   LOGIN
========================== */

formulario.addEventListener('submit', async (event) => {
    event.preventDefault();
    const usuario = document.getElementById('username').value;
    const password = document.getElementById('password').value;

    mensaje.textContent = '';
    setLoading(true);

    try {

        const respuesta = await fetch(API_USER, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            
            body: JSON.stringify({
                Username: usuario,
                Password: password

            })
        });
        const data = await respuesta.json();
        console.log('HTTP Status:', respuesta.status);
        console.log('Respuesta del backend:', data);

        if (!respuesta.ok) {
            console.error('Error completo:', data);
            const errorBackend =
                data.error ||
                data.Error ||
                data.message ||
                data.Message ||
                `Error HTTP ${respuesta.status}`;
            throw new Error(errorBackend);
        }

        console.log('Login exitoso:', data);

        // Guardar JWT
        const token = data.authData?.token;
        if (!token) {
            throw new Error('El backend no devolvió un JWT');
        }
        localStorage.setItem('authToken', token);

        // Redireccionar
        window.location.href = 'catalogo.html';
    } catch (error) {
        console.error('Error:', error);
        mensaje.textContent = error.message;
        setLoading(false);
    }
});