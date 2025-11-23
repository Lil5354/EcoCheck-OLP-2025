# EcoCheck-OLP-2025 - Dynamic Waste Collection System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

EcoCheck is a comprehensive, FIWARE-based platform for dynamic waste collection management, designed for the OLP 2025 competition. It includes a backend API, a frontend web manager, a complete database stack (PostgreSQL, PostGIS, TimescaleDB), and the FIWARE Orion-LD Context Broker.

## 🚀 Quick Start (5-10 Minutes)

This guide will walk you through setting up the entire EcoCheck platform on your local machine using Docker.

### 1. Prerequisites

Make sure you have the following software installed and running:

- **Git**: For cloning the repository.
- **Docker Desktop**: To run the containerized application stack. Ensure the Docker engine is running before you start.

### 2. Installation & Setup

**Step 1: Clone the Repository**

Open your terminal and clone the project:

```bash
git clone https://github.com/Lil5354/EcoCheck-OLP-2025.git
cd EcoCheck-OLP-2025
```

**Step 2: Launch All Services**

This single command will build the necessary Docker images and start all services (Backend, Frontend, Databases, FIWARE Broker) in the background.

```bash
docker compose up -d --build
```

The first time you run this, it may take several minutes to download and build everything.

**Step 3: Run Database Migrations (Crucial Step)**

After the containers are up and running, the PostgreSQL database is still empty. You **must** run the migration scripts to create the tables and seed initial data. 

Execute the following command in your terminal:

```bash
docker compose exec postgres bash -c "cd /app/db && bash ./run_migrations.sh"
```

This command runs the migration script *inside* the running `postgres` container. You should see a success message with a summary of the created tables and records.

### 3. Verification

Your environment is now ready! You can verify that all services are running correctly by accessing these URLs in your browser:

| Service | URL | Expected Result |
| :--- | :--- | :--- |
| **Frontend Web Manager** | `http://localhost:3001` | The EcoCheck login page. |
| **Backend Health Check** | `http://localhost:3000/health` | A JSON response like `{"status":"ok"}`. |
| **FIWARE Orion-LD** | `http://localhost:1026/version` | A JSON response with Orion-LD version info. |

### 4. Project Structure

- `/backend`: Node.js backend API.
- `/frontend-web-manager`: React-based web application for managers.
- `/db`: Contains all database-related files:
  - `/init`: SQL scripts for initial database setup (e.g., creating extensions).
  - `/migrations`: SQL scripts for creating schema and seeding data.
  - `run_migrations.sh` / `.ps1`: Scripts to run migrations.
- `docker-compose.yml`: Defines all the services, networks, and volumes for the project.
- `README.md`: This file.

## 🔧 Troubleshooting

Here are solutions to common issues you might encounter.

**Q: I get an error like `Cannot connect to the Docker daemon`.**

**A:** This means Docker Desktop is not running. Open the Docker Desktop application and wait for the engine to start (the whale icon should be steady).

**Q: A service (e.g., `backend`) is not starting or is unhealthy.**

**A:** Check the logs for that specific container to find the error message. Replace `backend` with the name of the service you want to inspect.

```bash
docker compose logs --tail=100 backend
```

**Q: I want to reset my database and start over.**

**A:** To completely remove all data (including database volumes) and stop all containers, run:

```bash
docker compose down -v
```

After this, you can go back to **Step 2** of the installation to start fresh.

**Q: How can I connect to the PostgreSQL database directly?**

**A:** You can use any database client (like DBeaver, pgAdmin, or `psql`) with these credentials:
- **Host**: `localhost`
- **Port**: `5432`
- **Database**: `ecocheck`
- **User**: `ecocheck_user`
- **Password**: `ecocheck_pass`

Or, you can get a shell inside the container:

```bash
docker compose exec postgres psql -U ecocheck_user -d ecocheck
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
