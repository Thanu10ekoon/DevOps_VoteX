import React, { useState, useEffect } from 'react';
import './App.css';

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

  return (
    <div className="app-container">
      <div className="brand">
        <h1>VoteX</h1>
        <small>Login {token && profile ? 'Profile' : ''}</small>
      </div>
      {token && profile ? (
        <div className="profile">
          <dl>
            <dt>Email</dt><dd>{profile.email}</dd>
            <dt>ID</dt><dd>{profile.id}</dd>
            <dt>Created</dt><dd>{new Date(profile.created_at).toLocaleString()}</dd>
          </dl>
          <button onClick={logout}>Logout</button>
        </div>
      ) : (
        <>
          <h3>{mode === 'login' ? 'Login to VoteX' : 'Create Account'}</h3>
          <form onSubmit={submit}>
            <label>Email
              <input type="email" value={email} onChange={e => setEmail(e.target.value)} required />
            </label>
            <label>Password
              <input type="password" value={password} onChange={e => setPassword(e.target.value)} required />
            </label>
            <button type="submit">{mode === 'login' ? 'Login' : 'Register'}</button>
          </form>
          {error && <div className="error">{error}</div>}
          <div className="toggle">
            <button type="button" className="secondary" onClick={() => setMode(mode === 'login' ? 'register' : 'login')}>
              {mode === 'login' ? 'Need an account? Register' : 'Have an account? Login'}
            </button>
          </div>
        </>
      )}
      <footer>Future feature: create polls & vote (coming soon).</footer>
    </div>
  );
}
