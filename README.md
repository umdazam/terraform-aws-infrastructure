# Terraform AWS Infrastructure and PostgreSQL Database Project

## Project Overview

This project demonstrates AWS infrastructure provisioning using Terraform and PostgreSQL database management, including schema creation, seed data, reporting, backup, and restore procedures.

### Application Architecture

Internet → Application Load Balancer (ALB) → ECS/Fargate → Amazon RDS PostgreSQL

## Part 1: Terraform Infrastructure

Terraform modules provision the following AWS resources:

- VPC with public and private subnets
- Internet Gateway and NAT Gateway
- Public and private route tables
- Application Load Balancer
- ALB, ECS, and RDS security groups
- ECS cluster, task definition, and service
- Private Amazon RDS PostgreSQL database

### Security

- ALB handles incoming application traffic.
- ECS tasks run in private subnets.
- RDS runs in private subnets.
- RDS PostgreSQL access is restricted to the ECS security group on port 5432.

## Part 2: Dev and Prod Environments

Separate Terraform configurations are maintained for development and production.

Directory structure:

- `infra/envs/dev`
- `infra/envs/prod`
- `infra/modules`
- `infra/platform`

Environment-specific variables and backend configuration files are maintained separately.

## Part 3: GitHub Actions CI/CD

A GitHub Actions workflow is configured at:

`.github/workflows/terraform.yml`

The workflow includes:

- Terraform formatting checks
- Terraform initialization
- Terraform validation
- Terraform plan
- Plan output and artifact handling

AWS authentication is designed to use GitHub Actions OIDC.

## Part 4: PostgreSQL Database Schema

Two PostgreSQL tables are created:

### hotel_bookings

Stores hotel booking information, including:

- Booking ID
- Organization ID
- Hotel ID
- City
- Check-in and check-out dates
- Booking amount
- Booking status
- Creation timestamp

### booking_events

Stores booking-related events with:

- Event ID
- Booking ID
- Event type
- JSONB payload
- Creation timestamp

The booking_events table references hotel_bookings using a foreign key with cascading deletion.

## Part 5: Seed Data and Query Optimization

Seed data includes:

- 120 hotel bookings
- 4 organizations
- 5 cities
- 4 booking statuses
- 40 booking events

### Index Optimization

A composite covering index is created:

```sql
CREATE INDEX idx_hotel_bookings_city_created_at
ON hotel_bookings (city, created_at)
INCLUDE (org_id, status, amount);
```

The index supports city equality filtering and date-range filtering. Included columns may help the database perform index-only scans.

An additional index on `booking_events(booking_id)` improves booking event lookups.

### Reporting Query

The reporting query groups bookings by organization and status for a selected city over the last 30 days:

```sql
SELECT
    org_id,
    status,
    COUNT(*),
    SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

### Local Database Configuration

- `docker-compose.yml` defines the local PostgreSQL service.
- `.env.example` provides the required environment variable template.
- Database initialization scripts are located in `database/init/`.

The actual `.env` file contains local credentials and is excluded from Git.

## Part 6: Database Backup and Restore

Backup and restore scripts are located in:

- `scripts/backup.sh`
- `scripts/restore.sh`

### Backup

Run the backup script:

```bash
./scripts/backup.sh
```

The script:

- Loads PostgreSQL connection settings from `.env`.
- Creates the `backups/` directory if it does not exist.
- Generates a timestamped backup filename.
- Uses PostgreSQL custom-format backup through `pg_dump`.
- Removes an incomplete backup if the operation fails.

Example backup filename:

`hotel_booking_db_20261112_120000_XXXXXX.dump`

### Restore to a Fresh Database

Restore a selected backup into a new database:

```bash
./scripts/restore.sh backups/<backup-file>.dump
```

An optional database name can also be provided:

```bash
./scripts/restore.sh backups/<backup-file>.dump hotel_booking_restore_test
```

The restore script:

- Validates the supplied backup file.
- Checks the PostgreSQL client tools.
- Validates the target database name.
- Prevents overwriting an existing database.
- Validates the backup archive.
- Creates a fresh database.
- Restores the backup using `pg_restore`.
- Removes the incomplete target database if restoration fails.

### Restore Verification

After restoration, the script checks that both expected tables exist:

- `hotel_bookings`
- `booking_events`

It also executes row-count queries:

```sql
SELECT COUNT(*) FROM hotel_bookings;

SELECT COUNT(*) FROM booking_events;
```

The expected seed-data counts are:

| Table | Expected rows |
|---|---:|
| hotel_bookings | 120 |
| booking_events | 40 |

The restored row counts can be compared with the original database to verify the restored data.

## Security and Repository Hygiene

The `.gitignore` file excludes:

- Terraform state files
- Terraform working directories
- Local `.env` credentials
- Private keys
- Database backup files in `backups/`

The `.env.example` file is provided as a template without real credentials.

## Project Status

The Terraform configuration, PostgreSQL schema, seed data, Docker Compose configuration, and backup/restore scripts are prepared in the repository.

Infrastructure deployment and live database backup/restore execution require the relevant AWS and PostgreSQL environments and are not claimed as completed here.
