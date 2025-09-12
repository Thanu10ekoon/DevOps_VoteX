# VoteX (Login MVP)

VoteX will become an online polling & voting platform where users can create public or private polls and others can vote. This initial MVP implements only user registration, login, JWT session handling, and a simple profile endpoint. Poll creation & voting features will be added later.

## Stack
- React frontend (Create React App style build) + plain CSS (no Tailwind/Bootstrap)
- Node.js + Express backend (JWT auth, bcrypt password hashing)
- MySQL 8 database
- Docker / docker-compose orchestration (Nginx serves static build + proxies /api)

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

## Roadmap (Future)
- Poll entity (title, options, visibility: public/private)
- Vote submissions with per-user and per-IP safeguards
- Real-time vote updates (WebSocket or polling)
- Results sharing links & access control
- Admin / owner poll management & close scheduling
- Password reset & email verification

## Notes
- Minimal security posture (no refresh tokens, no password complexity enforcement yet).
- Replace `JWT_SECRET`, add rate limiting & HTTPS in production.
- All styling is plain CSS via `App.css` and `index.css`.
