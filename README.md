# VoteX Simple Login (React + Node + MySQL + Docker)

Minimal example of a login/register flow without styling.

## Stack
- React (CRA style) frontend served via Nginx
- Node.js + Express backend (JWT auth, bcrypt passwords)
- MySQL 8 database
- Docker / docker-compose orchestration

## Endpoints
- POST /api/register { email, password }
- POST /api/login { email, password } -> { token }
- GET /api/profile (Authorization: Bearer <token>)
- GET /api/health

## Quick Start (Docker)
```powershell
# From repo root
docker compose build
docker compose up -d
# Wait a few seconds for MySQL + migrations (init script)
# Frontend: http://localhost:3000
# Backend API direct: http://localhost:4000/api/health
```

## Rebuild Frontend After Changes
```powershell
docker compose build client
docker compose up -d client
```

## Environment Variables
Change values in `docker-compose.yml` as needed:
- DB_HOST, DB_USER, DB_PASSWORD, DB_NAME
- JWT_SECRET

## Development Without Docker (Optional)
Install dependencies locally first.
```powershell
# Backend
yarn --cwd server install  # or: npm install --prefix server
# Start backend
npm run --prefix server dev
# In another terminal for MySQL (if you have local MySQL running adjust creds).

# Frontend
npx create-react-app dummy # only if you need react-scripts globally, else skip
npm install --prefix client react-scripts
npm start --prefix client
```
Adjust `REACT_APP_API_URL` in `client/src/App.js` or set env var before build.

## Notes
- This is intentionally minimal; no refresh token flow, no password rules, no HTTPS termination.
- For production, replace `JWT_SECRET` and consider using a secrets manager.
