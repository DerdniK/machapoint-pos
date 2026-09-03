// Function URL de ServicioUsers
const API_USERS_URL = "https://tmvksz56enigo6ojk25lfvg6x40vigzo.lambda-url.us-east-1.on.aws/api/users";
// const API_USERS_URL = "http://localhost:8080/api/users";

const statusMsg = document.getElementById('user-status-msg');

// Helper para leer siempre el token más reciente de localStorage
function obtenerToken() {
    return localStorage.getItem('authToken');
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
        const payload = {
            username: document.getElementById('reg-username').value.trim(),
            password: document.getElementById('reg-password').value.trim(),
            firstname: document.getElementById('reg-firstname').value.trim(),
            lastname: document.getElementById('reg-lastname').value.trim(),
            roleid: parseInt(document.getElementById('reg-roleid').value, 10)
        };

        await ejecutarPeticion(`${API_USERS_URL}/auth/register`, 'POST', payload);
        formRegister.reset();
    });
}

// 3. Modificación (PATCH /api/users/auth/update)
const formUpdate = document.getElementById('form-update');
if (formUpdate) {
    formUpdate.addEventListener('submit', async (e) => {
        e.preventDefault();
        const payload = {
            Userid: document.getElementById('upd-userid').value.trim(),
            Username: document.getElementById('upd-username').value.trim()
        };

        await ejecutarPeticion(`${API_USERS_URL}/auth/update`, 'PATCH', payload);
        formUpdate.reset();
    });
}

// 4. Eliminación (DELETE /api/users/auth/delete)
const formDelete = document.getElementById('form-delete');
if (formDelete) {
    formDelete.addEventListener('submit', async (e) => {
        e.preventDefault();
        const payload = {
            Userid: document.getElementById('del-userid').value.trim()
        };

        await ejecutarPeticion(`${API_USERS_URL}/auth/delete`, 'DELETE', payload);
        formDelete.reset();
    });
}

async function ejecutarPeticion(url, method, body) {
    if (statusMsg) statusMsg.textContent = "Procesando...";

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

        const data = await res.json().catch(() => ({}));

        if (!res.ok) {
            const errorMsg = data.message || data.Message || data.error || `HTTP ${res.status}`;
            throw new Error(errorMsg);
        }

        if (statusMsg) {
            statusMsg.textContent = `Operación ${method} realizada con éxito.`;
        }
    } catch (err) {
        if (statusMsg) {
            statusMsg.textContent = "Error: " + err.message;
        }
    }
}