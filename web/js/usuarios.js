const API_USERS_URL = "https://tmvksz56enigo6ojk25lfvg6x40vigzo.lambda-url.us-east-1.on.aws/api/users";
// const API_USERS_URL = "http://localhost:8080/api/users";

const token = localStorage.getItem('authToken');
const statusMsg = document.getElementById('user-status-msg');

// 1. Health check
async function checkHealth() {
    const healthEl = document.getElementById('health-status');
    try {
        const res = await fetch(`${API_USERS_URL}/health`);
        healthEl.textContent = res.ok ? "Servicio Users: Operativo" : "Servicio Users: Con fallas";
    } catch {
        healthEl.textContent = "Servicio Users: Offline";
    }
}
checkHealth();

// 2. Registro (POST /api/users/auth/register)
document.getElementById('form-register').addEventListener('submit', async (e) => {
    e.preventDefault();
    const payload = {
        username: document.getElementById('reg-username').value,
        password: document.getElementById('reg-password').value,
        firstname: document.getElementById('reg-firstname').value,
        lastname: document.getElementById('reg-lastname').value,
        roleid: parseInt(document.getElementById('reg-roleid').value, 10)
    };

    ejecutarPeticion(`${API_USERS_URL}/auth/register`, 'POST', payload);
});

// 3. Modificación (PATCH /api/users/auth/update)
document.getElementById('form-update').addEventListener('submit', async (e) => {
    e.preventDefault();
    const payload = {
        Userid: document.getElementById('upd-userid').value,
        Username: document.getElementById('upd-username').value
    };

    ejecutarPeticion(`${API_USERS_URL}/auth/update`, 'PATCH', payload);
});

// 4. Eliminación (DELETE /api/users/auth/delete)
document.getElementById('form-delete').addEventListener('submit', async (e) => {
    e.preventDefault();
    const payload = {
        Userid: document.getElementById('del-userid').value
    };

    ejecutarPeticion(`${API_USERS_URL}/auth/delete`, 'DELETE', payload);
});

async function ejecutarPeticion(url, method, body) {
    statusMsg.textContent = "Procesando...";
    try {
        const res = await fetch(url, {
            method: method,
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(body)
        });

        const data = await res.json().catch(() => ({}));
        if (!res.ok) throw new Error(data.message || `HTTP ${res.status}`);

        statusMsg.textContent = `Operación ${method} realizada con éxito.`;
    } catch (err) {
        statusMsg.textContent = "Error: " + err.message;
    }
}