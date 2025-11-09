# Quick Fix for EC2 Database Issue

## Problem
1. The database `votex` doesn't exist because the MySQL container reused an old volume
2. The `init.sql` was created as a directory instead of a file by Ansible

## Immediate Fix (SSH into EC2)

```bash
# SSH into EC2
ssh -i ~/.ssh/votex_key ubuntu@54.220.183.213

# Navigate to project directory
cd votex

# Stop all containers
sudo docker compose down

# Remove the database volume to force reinitialization
sudo docker volume rm votex_db_data

# Fix the init.sql directory issue
sudo rm -rf db/init.sql

# Download the correct init.sql file
sudo mkdir -p db
sudo curl -o db/init.sql https://raw.githubusercontent.com/Thanu10ekoon/DevOps_VoteX/main/db/init.sql

# Or manually create it
sudo nano db/init.sql
# Paste the contents from your local db/init.sql file, then Ctrl+X, Y, Enter

# Fix permissions
sudo chown ubuntu:ubuntu db/init.sql
sudo chmod 644 db/init.sql

# Verify it's a file (not a directory)
ls -la db/

# Start services again (init.sql will run)
sudo docker compose up -d

# Wait 30 seconds for database to initialize
sleep 30

# Check logs to verify database is created
sudo docker compose logs db | grep "Creating database"

# Verify containers are running
sudo docker ps

# Test the application
curl http://localhost:4000/api/health
```

## Expected Output

You should see in the logs:
```
db-1 | [Note] [Entrypoint]: Creating database votex
db-1 | [Note] [Entrypoint]: /docker-entrypoint-initdb.d/init.sql: running
```

## Test Registration

After the fix:
```bash
curl -X POST http://localhost:4000/api/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

Should return:
```json
{"success":true}
```

## Permanent Fix

The Ansible playbook has been updated to automatically remove the database volume on each deployment, ensuring the database is always properly initialized.

Push the updated code:
```bash
git add .
git commit -m "Fix: Ensure database volume is recreated on deployment"
git push origin main
```

The pipeline will redeploy with the fix automatically.
