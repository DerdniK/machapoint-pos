import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm'

const supabase = createClient(
  'https://rbhdpforntgwfbuqychm.supabase.co',
  'sb_publishable_niMghnGw3H6wuJbE9eV_fg_E_RrLFXm' // pégala aquí, la encuentras en Project Settings > API
)

async function signInWithGoogle() {
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: `${window.location.origin}/callback.html`

    }
  })

  if (error) {
    document.getElementById('mensaje').textContent =
      'Error al iniciar sesión: ' + error.message
    console.error(error)
  }
  // Si no hay error, Supabase redirige automáticamente a Google
}

// Se dispara apenas se carga la página
signInWithGoogle()