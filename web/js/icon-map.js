/* Genera el menú principal con iconos SVG en línea para TODAS las páginas.
 * Para cambiar el menú, edita solo el arreglo MENU de este archivo.
 */
(function () {
  "use strict";

  // Íconos SVG (viewBox 24x24, trazo = currentColor para heredar el color del CSS)
  const ICONOS = {
    catalogo:
      '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>',
    ventas:
      '<path d="M3 3v18h18"/><path d="M7 15l4-4 3 3 5-6"/>',
    carrito:
      '<circle cx="9" cy="20" r="1"/><circle cx="18" cy="20" r="1"/><path d="M1 1h4l2.7 13.4a2 2 0 0 0 2 1.6h9.7a2 2 0 0 0 2-1.6L23 6H6"/>',
    productos:
      '<path d="M21 8l-9-5-9 5v8l9 5 9-5z"/><path d="M3 8l9 5 9-5"/><path d="M12 13v8"/>',
    usuarios:
      '<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
    historial:
      '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    stock:
      '<path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/>'
  };

  // Definición del menú (única fuente de verdad)
  const MENU = [
    { href: "catalogo.html",  texto: "Catálogo",  icono: "catalogo" },
    { href: "ventas.html",    texto: "Ventas",    icono: "ventas" },
    { href: "carrito.html",   texto: "Carrito",   icono: "carrito" },
    { href: "productos.html", texto: "Productos", icono: "productos", admin: true },
    { href: "usuarios.html",  texto: "Usuarios",  icono: "usuarios",  admin: true },
    { href: "historial.html", texto: "Historial", icono: "historial", admin: true },
    { href: "stock.html",     texto: "Stock",     icono: "stock",     admin: true }
  ];

  const SVG_NS = "http://www.w3.org/2000/svg";

  function crearSvg(nombre) {
    const svg = document.createElementNS(SVG_NS, "svg");
    svg.setAttribute("viewBox", "0 0 24 24");
    svg.setAttribute("class", "icono-menu");
    svg.setAttribute("aria-hidden", "true");
    svg.setAttribute("focusable", "false");
    svg.innerHTML = ICONOS[nombre] || "";
    return svg;
  }

  function paginaActual() {
    const archivo = location.pathname.split("/").pop();
    return archivo || "catalogo.html"; // por si se abre la raíz
  }

  function construirMenu(ul) {
    const actual = paginaActual();
    ul.classList.add("nav-principal");
    ul.textContent = ""; // limpia el contenido previo

    MENU.forEach(function (item) {
      const li = document.createElement("li");
      const a = document.createElement("a");
      a.href = item.href;

      if (item.admin) a.setAttribute("data-role", "admin");

      if (item.href === actual) {
        a.classList.add("activo");
        a.setAttribute("aria-current", "page");
      }

      const span = document.createElement("span");
      span.className = "texto-menu";
      span.textContent = item.texto;

      a.appendChild(crearSvg(item.icono));
      a.appendChild(span);
      li.appendChild(a);
      ul.appendChild(li);
    });
  }

  function iniciar() {
    // Busca el <ul> del menú: [data-mp-nav] o, si no existe, el primer "nav ul"
    const ul = document.querySelector("[data-mp-nav]") || document.querySelector("nav ul");
    if (ul) construirMenu(ul);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", iniciar);
  } else {
    iniciar();
  }
})();