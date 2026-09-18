# Running Rutzfin Java Backend on a Raspberry Pi (PostgreSQL)

This guide covers everything from first boot to a running production service.
Tested on Raspberry Pi 4 / Pi 5 (ARM64) running Raspberry Pi OS (64-bit, Bookworm).

---

## 1. Prerequisites on the Pi

### Install Java 25
Spring Boot 3.x is compatible with Java 25, and this project is configured for the latest LTS runtime.

```bash
sudo apt update
sudo apt install -y openjdk-25-jdk
java -version   # should print openjdk 25.x.x
```

### Install Maven

```bash
sudo apt install -y maven
mvn -version    # should print Apache Maven 3.x
```

### Install Git

```bash
sudo apt install -y git
```

---

## 2. Install PostgreSQL on the Pi

```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start  postgresql

# Verify PostgreSQL is running
sudo systemctl status postgresql
```

### Create the database and user

```bash
sudo -u postgres psql
```

Inside the `psql` prompt:

```sql
CREATE DATABASE rutzfin;
CREATE USER rutzfin_user WITH ENCRYPTED PASSWORD 'YourStrongPassword!';
GRANT ALL PRIVILEGES ON DATABASE rutzfin TO rutzfin_user;

-- PostgreSQL 15+ requires this extra step
\c rutzfin
GRANT ALL ON SCHEMA public TO rutzfin_user;

\q
```

### Run the SQL scripts

Clone the repo first (see Section 3), then run the five scripts in order:

```bash
cd ~/rutzfin/sql/postgresql

psql -U rutzfin_user -d rutzfin -f 01_schema.sql
psql -U rutzfin_user -d rutzfin -f 02_seed_data.sql
psql -U rutzfin_user -d rutzfin -f 03_indexes.sql
psql -U rutzfin_user -d rutzfin -f 04_views.sql
psql -U rutzfin_user -d rutzfin -f 05_functions.sql
```

> If `psql` prompts for a password, enter the one you set above.
> You can create a `~/.pgpass` file to avoid typing it each time:
> ```
> localhost:5432:rutzfin:rutzfin_user:YourStrongPassword!
> ```
> Then `chmod 600 ~/.pgpass`.

---

## 3. GitHub — Push from Windows & Clone on the Pi

### On your development machine (Windows)

1. **Create a GitHub repository** at https://github.com/new  
   Name it `rutzfin`. Leave it empty (no README).

2. **Initialize git and push** from the project root:

```powershell
# Run from C:\Users\rwany\OneDrive\Documents\Projects\rutzfin
git init
git add .
git commit -m "Initial commit: Spring Boot/JDBC backend + React frontend + PostgreSQL SQL"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/rutzfin.git
git push -u origin main
```

> Replace `YOUR_USERNAME` with your GitHub username.

### On the Raspberry Pi

```bash
git clone https://github.com/YOUR_USERNAME/rutzfin.git
cd rutzfin
```

---

## 4. Configure Environment Variables

```bash
cd backend-java
cp .env.example .env
nano .env
```

Fill in your values:

```
PG_HOST=localhost
PG_PORT=5432
PG_DATABASE=rutzfin
PG_USERNAME=rutzfin_user
PG_PASSWORD=YourStrongPassword!
PORT=8000
```

Load the variables into your current shell session:

```bash
export $(grep -v '^#' .env | xargs)
```

---

## 5. Build the Frontend (optional — skip if you only need the API)

```bash
# Install Node.js on the Pi if needed:
#   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
#   sudo apt install -y nodejs

cd ~/rutzfin/frontend
npm install
npm run build
# Output lands in backend-java/src/main/resources/static/ (configured in vite.config.js)
```

---

## 6. Build the Fat JAR

```bash
cd ~/rutzfin/backend-java
mvn clean package -DskipTests
```

This produces `target/rutzfin-backend-1.0.0.jar` — a single self-contained file that
includes Spring Boot, Tomcat, and all dependencies.

---

## 7. Run the Backend

```bash
# From the backend-java/ directory
export $(grep -v '^#' .env | xargs)
java -jar target/rutzfin-backend-1.0.0.jar
```

You should see:

```
Started RutzfinApplication in X.XXX seconds
Tomcat started on port 8000
```

Test it:

```
http://<pi-ip-address>:8000/health
http://<pi-ip-address>:8000/api/dashboard
```

---

## 8. Run as a systemd Service (auto-start on boot)

This keeps the backend running permanently and restarts it automatically if it crashes.
It also starts **after PostgreSQL** is ready.

### Create the service file

```bash
sudo nano /etc/systemd/system/rutzfin.service
```

Paste the following (replace `/home/pi` with your actual home directory and update
the password):

```ini
[Unit]
Description=Rutzfin Banking API
After=network-online.target postgresql.service
Wants=network-online.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/rutzfin/backend-java
ExecStart=/usr/bin/java -jar /home/pi/rutzfin/backend-java/target/rutzfin-backend-1.0.0.jar
Restart=on-failure
RestartSec=10

Environment=PG_HOST=localhost
Environment=PG_PORT=5432
Environment=PG_DATABASE=rutzfin
Environment=PG_USERNAME=rutzfin_user
Environment=PG_PASSWORD=YourStrongPassword!
Environment=PORT=8000

[Install]
WantedBy=multi-user.target
```

### Enable and start

```bash
sudo systemctl daemon-reload
sudo systemctl enable rutzfin     # auto-start on boot
sudo systemctl start  rutzfin

# Check status
sudo systemctl status rutzfin

# View live logs
journalctl -u rutzfin -f
```

---

## 9. Updating the App (git pull + rebuild)

```bash
cd ~/rutzfin
git pull
cd backend-java
mvn clean package -DskipTests
sudo systemctl restart rutzfin
```

---

## API Endpoints Reference

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Liveness probe + DB connectivity |
| GET | `/api/dashboard` | Executive KPI metrics |
| GET | `/api/branches` | Branch performance |
| GET | `/api/customers` | Customer list with totals |
| GET | `/api/customers/{id}` | All accounts for one customer |
| GET | `/api/transactions/{accountId}?limit=50` | Recent transactions |
| GET | `/api/fraud/alerts` | Open fraud alert queue |
| GET | `/api/loans/health` | Loan portfolio risk |
| GET | `/api/analytics/monthly-trends` | Monthly transaction trends |
| GET | `/api/analytics/customer-segments` | Customer tier segmentation |
| POST | `/api/transfer` | Execute fund transfer |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Connection refused` on port 5432 | `sudo systemctl start postgresql` |
| `password authentication failed` | Double-check `PG_PASSWORD` matches the one set in `psql` |
| `permission denied for schema public` | Run `GRANT ALL ON SCHEMA public TO rutzfin_user;` inside `psql -U postgres -d rutzfin` |
| `java: command not found` | `sudo apt install -y openjdk-25-jdk` |
| Port 8000 in use | Set `PORT=8001` in `.env` and re-export |
| Slow first request | Normal — HikariCP initialises the connection pool on first use |
| Service fails at boot | Check `journalctl -u rutzfin` — PostgreSQL may not be fully ready; `RestartSec=10` handles it |
