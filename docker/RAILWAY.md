# Deploy FreeLLMAPI on Railway

Two ways to deploy. **GitHub is optional.**

| Method | GitHub needed? | Best for |
|--------|----------------|----------|
| **A. Official Docker image** | No | Fastest first deploy |
| **B. Your Git repo** | Yes (your fork) | Tracking `railway.toml` + custom Dockerfile changes |

---

## Before you deploy (do this on your PC)

### 1. Back up secrets and database

```powershell
cd "c:\Users\Aniket-Laptop\OneDrive\Documents\freellmapi"
.\scripts\backup-railway-data.ps1
```

This creates `backups/railway-YYYYMMDD-HHMMSS/` with:

- `freeapi.db` — dashboard login, provider keys, unified API key
- `ENCRYPTION_KEY.txt` — copied from your local `.env` (required to decrypt keys in the DB)

**Keep this folder private.** Do not commit it to Git.

### 2. (Optional) Test Docker locally

Requires [Docker Desktop](https://www.docker.com/products/docker-desktop/).

```powershell
cd "c:\Users\Aniket-Laptop\OneDrive\Documents\freellmapi"
docker compose up -d
# open http://localhost:3001
docker compose down
```

---

## Method A — Docker image only (no GitHub)

1. Sign up at [railway.com](https://railway.com) (free trial, no credit card).
2. **New Project** → **Deploy Docker Image**.
3. Image: `ghcr.io/tashfeenahmed/freellmapi:latest`
4. **Variables** (service → Variables):

   | Variable | Value |
   |----------|--------|
   | `ENCRYPTION_KEY` | Same 64-char hex from your local `.env` |
   | `NODE_ENV` | `production` |

   Railway sets `PORT` automatically — the app reads it.

5. **Settings → Volumes → Add Volume**
   - Mount path: `/app/server/data`
   - Railway does not support `VOLUME` in the Dockerfile; the dashboard mount is required.

6. **Settings → Networking → Generate Domain** (public URL).

7. Redeploy after adding the volume.

8. Open `https://your-app.up.railway.app` and either:
   - **Fresh setup:** create admin account, re-add provider keys, or
   - **Migrate DB:** copy `freeapi.db` into the volume (see [Migrate local data](#migrate-local-data) below).

---

## Method B — Deploy from your GitHub repo

Use this if you want Railway to rebuild from your copy of the repo (includes `railway.toml`).

### 1. Push to **your** GitHub (not required for Method A)

```powershell
cd "c:\Users\Aniket-Laptop\OneDrive\Documents\freellmapi"
git remote -v
# If you only have origin → upstream repo, add your fork:
# git remote add mine https://github.com/YOUR_USER/freellmapi.git
# git push mine main
```

Create a **new empty repo** on GitHub under your account, then:

```powershell
git remote add mine https://github.com/YOUR_USER/freellmapi.git
git push -u mine main
```

Do **not** commit `.env`, `server/data/`, or `backups/` (already in `.gitignore`).

### 2. Connect Railway to GitHub

1. Railway → **New Project** → **Deploy from GitHub repo**.
2. Select your `freellmapi` repo.
3. Railway detects the `Dockerfile` and `railway.toml`.

### 3. Same as Method A: variables + volume + domain

- `ENCRYPTION_KEY` = your local key
- Volume mount: `/app/server/data`
- Generate public domain

---

## Migrate local data

If you use the **same `ENCRYPTION_KEY`** and copy **`freeapi.db`** into `/app/server/data`, you keep:

- Dashboard email/password
- Provider API keys
- Unified `freellmapi-...` key
- Fallback chain order

**Easiest path:** start fresh on Railway and re-enter keys (no file copy).

**To copy the database:**

1. Deploy once with volume mounted at `/app/server/data`.
2. Install Railway CLI: `npm install -g @railway/cli`, then `railway login` and `railway link -s "@freellmapi/server"`.
3. Stop your local server, then run:
   ```powershell
   .\scripts\upload-db-to-railway.ps1
   ```
   Or manually:
   ```powershell
   railway volume files --volume "@freellmapi/server-volume" upload server\data\freeapi.db /freeapi.db --overwrite
   railway redeploy -y
   ```

After upload, redeploy and open your Railway URL — log in with your existing credentials.

---

## After deploy — use the API

| Setting | Value |
|---------|--------|
| Base URL | `https://YOUR-APP.up.railway.app/v1` |
| API key | Your unified `freellmapi-...` key (from Keys page) |

---

## Free plan notes

- Trial: ~$5 credit, 30 days, no card.
- After trial: downgrade to **Free** plan ($1/month usage credit, not a charge).
- Limits: ~0.5 GB RAM, 0.5 GB volume — enough for FreeLLMAPI.
- If usage exceeds $1/month, services pause until next month.

---

## Security

- Railway gives you a **public URL**. Anyone with your unified key can use your proxy.
- Use a strong dashboard password and unified key.
- Prefer not sharing the Railway URL; consider access only from tools you control.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Keys invalid after deploy | `ENCRYPTION_KEY` must match the key used when keys were saved |
| Data lost after redeploy | Volume must be mounted at `/app/server/data` |
| Health check fails | Ensure `ENCRYPTION_KEY` is set; check deploy logs |
| 502 / timeout on chat | Same as local — slow models in fallback chain; reorder in dashboard |
