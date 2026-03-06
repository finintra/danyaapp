# Docker Setup for Odoo 15 with FLF Performance Modules

This setup includes Odoo 15 with the custom FLF Performance modules.

## Prerequisites

1. Docker Desktop must be running on your machine
2. Docker Compose (usually included with Docker Desktop)

## Starting Odoo

1. Make sure Docker Desktop is running
2. Start the containers:

```bash
docker-compose up -d
```

This will:
- Start a PostgreSQL 13 database
- Start Odoo 15 with the custom modules from `flf_perfo/` directory
- Start Backend2 service (for web app) on port 3002
- Make Odoo available at http://localhost:8069
- Make Backend2 API available at http://localhost:3002

## Accessing Odoo

1. Open your browser and go to: http://localhost:8069
2. On first run, you'll see the database creation screen
3. Create a new database or use an existing one
4. The modules `flf_performance` and `flf_perfom_synt_data` will be available in Apps

## Installing the Modules

After creating/selecting a database:

1. Go to **Apps** menu
2. Remove the "Apps" filter to see all modules
3. Search for "FLF Performance"
4. Click **Install** on:
   - `flf_performance` (main module)
   - `flf_perfom_synt_data` (synthetic data generator - depends on flf_performance)

## Backend2 Configuration

Backend2 is the second backend service for web application. It connects to an external Odoo server at `https://dev.odoo15.emuaport.com/`.

### Setting up Backend2

1. Create a `.env` file in the project root or set environment variables:

```bash
# Backend2 Odoo Configuration
BACKEND2_ODOO_URL=https://dev.odoo15.emuaport.com/
BACKEND2_ODOO_DB=your_database_name
BACKEND2_ODOO_USERNAME=your_odoo_username
BACKEND2_ODOO_PASSWORD=your_odoo_password
BACKEND2_JWT_SECRET=your-jwt-secret-key
BACKEND2_CREDENTIALS_ENCRYPTION_KEY=your-encryption-key-32-characters-long!!
```

2. Start Backend2 with docker-compose:

```bash
docker-compose up -d backend2
```

3. Backend2 will be available at `http://localhost:3002`
4. Health check endpoint: `http://localhost:3002/health`

## Viewing Logs

To see Odoo logs:

```bash
docker-compose logs -f odoo
```

To see database logs:

```bash
docker-compose logs -f db
```

To see Backend2 logs:

```bash
docker-compose logs -f backend2
```

Or view log files directly:
- Error logs: `backend2/logs2/error.log`
- Combined logs: `backend2/logs2/combined.log`

## Stopping Odoo

```bash
docker-compose down
```

To also remove volumes (this will delete all data):

```bash
docker-compose down -v
```

## Module Structure

The modules are mounted from:
- `./flf_perfo/flf_performance/` → Available as `flf_performance` module
- `./flf_perfo/flf_perfom_synt_data/` → Available as `flf_perfom_synt_data` module

## Troubleshooting

### Docker daemon not running
If you see "Cannot connect to the Docker daemon", make sure Docker Desktop is running.

### Port already in use
If port 8069 is already in use, you can change it in `docker-compose.yml`:
```yaml
ports:
  - "8070:8069"  # Use 8070 instead of 8069
```

### Modules not visible
1. Make sure the modules are in the correct directory structure
2. Check Odoo logs: `docker-compose logs odoo`
3. In Odoo, go to Settings → Activate Developer Mode
4. Go to Apps → Update Apps List
5. Remove the "Apps" filter and search for "FLF"

