import React, { useState, useEffect } from 'react';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:4000/api';

export default function App() {
  const [mode, setMode] = useState('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [token, setToken] = useState(localStorage.getItem('token') || '');
  const [profile, setProfile] = useState(null);
  const [error, setError] = useState('');

  useEffect(() => {
    if (token) {
      fetch(`${API_URL}/profile`, { headers: { Authorization: 'Bearer ' + token } })
        .then(r => r.ok ? r.json() : Promise.reject())
        .then(data => setProfile(data))
        .catch(() => setProfile(null));
    }
  }, [token]);

  function submit(e) {
    e.preventDefault();
    setError('');
    const path = mode === 'login' ? 'login' : 'register';
    fetch(`${API_URL}/${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    }).then(async r => {
      const data = await r.json();
      if (!r.ok) throw new Error(data.error || 'Error');
      if (mode === 'login') {
        setToken(data.token);
        localStorage.setItem('token', data.token);
      } else {
        setMode('login');
      }
    }).catch(err => setError(err.message));
  }

  function logout() {
    setToken('');
    localStorage.removeItem('token');
    setProfile(null);
  }

  if (token && profile) {
    return (
      <div>
        <h3>Profile</h3>
        <div>Email: {profile.email}</div>
        <div>ID: {profile.id}</div>
        <div>Created: {new Date(profile.created_at).toString()}</div>
        <button onClick={logout}>Logout</button>
      </div>
    );
  }

  return (
    <div>
      <h3>{mode === 'login' ? 'Login' : 'Register'}</h3>
      <form onSubmit={submit}>
        <div>
          <label>Email: <input value={email} onChange={e => setEmail(e.target.value)} /></label>
        </div>
        <div>
          <label>Password: <input type="password" value={password} onChange={e => setPassword(e.target.value)} /></label>
        </div>
        <button type="submit">Submit</button>
      </form>
      {error && <div>{error}</div>}
      <button onClick={() => setMode(mode === 'login' ? 'register' : 'login')}>
        Switch to {mode === 'login' ? 'Register' : 'Login'}
      </button>
    </div>
  );
}
