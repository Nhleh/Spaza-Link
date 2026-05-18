import { auth } from './firebase';

export async function apiRequest(endpoint: string, options: RequestInit = {}, explicitToken?: string) {
  const user = auth.currentUser;
  const headers = new Headers(options.headers || {});

  if (explicitToken) {
    headers.set('Authorization', `Bearer ${explicitToken}`);
  } else if (user) {
    const token = await user.getIdToken();
    headers.set('Authorization', `Bearer ${token}`);
  }

  if (!(options.body instanceof FormData) && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json');
  }

  try {
    const response = await fetch(endpoint, {
      ...options,
      headers,
    });

    if (!response.ok) {
      const errorBody = await response.json().catch(() => ({}));
      const errorMsg = errorBody.error || `HTTP error! status: ${response.status}`;
      return Promise.reject({ message: errorMsg, status: response.status });
    }

    return response.json();
  } catch (err: any) {
    console.error(`API Request failed for ${endpoint}:`, err);
    throw err;
  }
}
