import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const SUPABASE_URL = 'https://rbhdpforntgwfbuqychm.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_niMghnGw3H6wuJbE9eV_fg_E_RrLFXm';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

export async function signInWithGoogle() {
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: `${window.location.origin}/callback.html`
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