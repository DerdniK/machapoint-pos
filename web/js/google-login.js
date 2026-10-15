import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/+esm';

const SUPABASE_URL = 'https://rbhdpforntgwfbuqychm.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_niMghnGw3H6wuJbE9eV_fg_E_RrLFXm';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Dominio oficial: el login con Google siempre regresa aquí, sin importar desde qué URL se abrió la página
// (por ejemplo, el endpoint del bucket de S3). En desarrollo local se usa el origen actual.
const SITE_URL = 'https://changarrodesus.store';
const esLocal = ['localhost', '127.0.0.1'].includes(window.location.hostname);
const BASE_URL = esLocal ? window.location.origin : SITE_URL;

export async function signInWithGoogle() {
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: `${BASE_URL}/callback.html`,
      queryParams: { prompt: 'select_account' } 
    }
  });

  if (error) {
    const msg = document.getElementById('mensaje');
    if (msg) msg.textContent = 'Error al iniciar sesión: ' + error.message;
    console.error('Error Google OAuth:', error);
  }
}

// Si la pantalla de google-login.html es solo una pantalla intermedia de redirección:
window.addEventListener('DOMContentLoaded', () => {
  signInWithGoogle();
});