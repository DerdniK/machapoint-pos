const API_URL =
    "https://tmvksz56enigo6ojk25lfvg6x40vigzo.lambda-url.us-east-1.on.aws";


const listaUsuarios =
    document.getElementById("listaUsuarios");

const modal =
    document.getElementById("modalUsuario");

const formUsuario =
    document.getElementById("formUsuario");

const btnAgregarUsuario =
    document.getElementById("btnAgregarUsuario");

const cerrarModal =
    document.getElementById("cerrarModal");

const tituloModal =
    document.getElementById("tituloModal");


function obtenerToken() {

    return localStorage.getItem("authToken");

}

// Función para realizar peticiones a la API con el token de autenticación

async function apiFetch(endpoint, options = {}) {

    const token = obtenerToken();

    const headers = {
        "Content-Type": "application/json",
        ...options.headers
    };

    if (token) {
        headers["Authorization"] =
            `Bearer ${token}`;
    }

    const response = await fetch(
        `${API_URL}${endpoint}`,
        {
            ...options,
            headers
        }
    );

    const data = await response.json();

    if (!response.ok) {

        throw new Error(
            data.message ||
            "Error al comunicarse con el servidor"
        );

    }

    return data;
}

// Registrar usuario - CREATE

async function registrarUsuario(usuario) {

    try {

        const data = await apiFetch(
            "https://tmvksz56enigo6ojk25lfvg6x40vigzo.lambda-url.us-east-1.on.aws/api/users/auth/register",
            {
                method: "POST",

                body: JSON.stringify(usuario)
            }
        );

        alert(
            data.message ||
            "Usuario registrado correctamente"
        );

        return true;

    } catch (error) {

        console.error(error);

        alert(
            "No se pudo registrar el usuario: " +
            error.message
        );

        return false;
    }
}

// actualizar usuario - UPDATE

async function actualizarUsuario(usuario) {

    try {

        const data = await apiFetch(
            "https://tmvksz56enigo6ojk25lfvg6x40vigzo.lambda-url.us-east-1.on.aws/api/users/update",
            {
                method: "PUT",

                body: JSON.stringify(usuario)
            }
        );

        alert(
            data.message ||
            "Usuario actualizado"
        );

        return true;

    } catch (error) {

        console.error(error);

        alert(
            "No se pudo actualizar: " +
            error.message
        );

        return false;
    }
}

// eliminar usuario - DELETE

async function eliminarUsuario(userId) {

    const confirmar = confirm(
        "¿Seguro que quieres eliminar este usuario?"
    );

    if (!confirmar) {
        return;
    }

    try {

        const data = await apiFetch(
            "https://tmvksz56enigo6ojk25lfvg6x40vigzo.lambda-url.us-east-1.on.aws/api/users/delete",
            {
                method: "DELETE",

                body: JSON.stringify({
                    UserID: userId
                })
            }
        );

        alert(
            data.message ||
            "Usuario eliminado"
        );

        cargarUsuarios();

    } catch (error) {

        console.error(error);

        alert(
            "No se pudo eliminar el usuario: " +
            error.message
        );
    }
}

// Abir modal para agregar usuario

btnAgregarUsuario.addEventListener(
    "click",
    () => {

        formUsuario.reset();

        document.getElementById("userId").value = "";

        document.getElementById("password").required = true;

        tituloModal.textContent =
            "Agregar usuario";

        modal.classList.remove("oculto");

    }
);
   // cerrar modal al dar click en la X
cerrarModal.addEventListener(
    "click",
    () => {

        modal.classList.add("oculto");

    }
);


// se utiliza el mismo formulario para agregar y actualizar usuarios

formUsuario.addEventListener(
    "submit",
    async (event) => {

        event.preventDefault();


        const userId =
            document.getElementById("userId").value;

        const username =
            document.getElementById("username").value;

        const password =
            document.getElementById("password").value;

        const firstname =
            document.getElementById("firstname").value;

        const lastname =
            document.getElementById("lastname").value;

        const roleid =
            Number(
                document.getElementById("roleid").value
            );


        let resultado;


        // =========================
        // CREAR
        // =========================

        if (!userId) {

            const usuario = {

                username,
                password,
                firstname,
                lastname,
                roleid
            };

            resultado =
                await registrarUsuario(usuario);

        }


        // =========================
        // EDITAR
        // =========================

        else {

            const usuario = {

                Userid: userId,
                Username: username,
                firstname,
                lastname,
                roleid
            };

            resultado =
                await actualizarUsuario(usuario);

        }


        if (resultado) {

            modal.classList.add("oculto");

            cargarUsuarios();

        }

    }
);

// editar usuario - abrir modal con datos del usuario

function abrirEditarUsuario(usuario) {

    document.getElementById("userId").value =
        usuario.userid;

    document.getElementById("username").value =
        usuario.username;

    document.getElementById("firstname").value =
        usuario.firstname ?? "";

    document.getElementById("lastname").value =
        usuario.lastname ?? "";

    document.getElementById("roleid").value =
        usuario.roleid;


    // Normalmente NO debes recuperar
    // ni mostrar una contraseña existente.

    document.getElementById("password").value = "";
    document.getElementById("password").required = false;


    tituloModal.textContent =
        "Editar usuario";


    modal.classList.remove("oculto");

}


// Recuperar usuarios - READ

async function cargarUsuarios() {

    try {

        const data = await apiFetch(
            "https://tmvksz56enigo6ojk25lfvg6x40vigzo.lambda-url.us-east-1.on.aws/api/users",
            {
                method: "GET"
            }
        );

        mostrarUsuarios(data.users);

    } catch (error) {

        console.error(
            "Error cargando usuarios:",
            error
        );

        listaUsuarios.innerHTML = `
            <tr>
                <td colspan="4">
                    No se pudieron cargar los usuarios
                </td>
            </tr>
        `;
    }
}

// json en filas 

function mostrarUsuarios(usuarios) {

    listaUsuarios.innerHTML = "";


    usuarios.forEach(usuario => {

        const fila =
            document.createElement("tr");


        const rol =
            usuario.roleid === 1
                ? "Administrador"
                : "Empleado";


        fila.innerHTML = `

            <td>
                ${usuario.username}
            </td>

            <td>
                ${usuario.firstname ?? ""}
                ${usuario.lastname ?? ""}
            </td>

            <td>
                ${rol}
            </td>

            <td>

                <button
                    class="btn-editar"
                >
                    Editar
                </button>

                <button
                    class="btn-eliminar"
                >
                    Eliminar
                </button>

            </td>

        `;


        fila
            .querySelector(".btn-editar")
            .addEventListener(
                "click",
                () => {

                    abrirEditarUsuario(usuario);

                }
            );


        fila
            .querySelector(".btn-eliminar")
            .addEventListener(
                "click",
                () => {

                    eliminarUsuario(
                        usuario.userid
                    );

                }
            );


        listaUsuarios.appendChild(fila);

    });

}

// Cargar usuarios al cargar la página (hay que rezar)

document.addEventListener(
    "DOMContentLoaded",
    cargarUsuarios
);
