#!/bin/bash

# PostgreSQL v16 Installation on Rocky Linux 9 with Second Disk for Data
# =======================================================================

set -euo pipefail

# --- Variables ---
DATA_DISK="/dev/sdb"
DATA_MOUNT="/pgdata"
POSTGRES_VERSION="16"
PGUSER="postgres"
PGDATA="${DATA_MOUNT}/pgsql/${POSTGRES_VERSION}/data"
psqlpassword='Pa$$w0rd'

# --- Prepare Second Disk ---

echo "💾 Preparing second disk ($DATA_DISK) for PostgreSQL data..."

# Create a single partition on the disk
sudo parted -s "$DATA_DISK" mklabel gpt
sudo parted -s "$DATA_DISK" mkpart primary ext4 0% 100%

# Wait for partition to be recognized
PART="${DATA_DISK}1"
udevadm settle

# Create filesystem
sudo mkfs.ext4 "$PART"

# Create mount point
sudo mkdir -p "$DATA_MOUNT"

# Get UUID and update /etc/fstab
UUID=$(sudo blkid -s UUID -o value "$PART")
echo "UUID=$UUID  $DATA_MOUNT  ext4  defaults  0 2" | sudo tee -a /etc/fstab

# Mount the disk
sudo mount "$DATA_MOUNT"

# Create PostgreSQL data directory
sudo mkdir -p "$PGDATA"
sudo chown -R "$PGUSER":"$PGUSER" "$DATA_MOUNT"
sudo chmod 700 "$PGDATA"

# --- Install PostgreSQL ---

echo "📦 Installing PostgreSQL $POSTGRES_VERSION..."

sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql${POSTGRES_VERSION}-server postgresql${POSTGRES_VERSION}-contrib
sudo dnf versionlock postgresql${POSTGRES_VERSION}*

# Initialize the DB on the new disk
echo "🔧 Initializing PostgreSQL in $PGDATA..."
sudo -u "$PGUSER" /usr/pgsql-${POSTGRES_VERSION}/bin/initdb -D "$PGDATA"

# --- Configuration Changes ---

echo "⚙️ Configuring PostgreSQL..."

CONF="$PGDATA/postgresql.conf"
HBA="$PGDATA/pg_hba.conf"

# Increase max connections
sudo sed -i "s/^#*max_connections = .*/max_connections = 200/" "$CONF"

# Enable pg_stat_statements
sudo sed -i "s/^#*shared_preload_libraries = .*/shared_preload_libraries = 'pg_stat_statements'/" "$CONF"

# Enable remote connections
sudo sed -i "s/^#*listen_addresses = .*/listen_addresses = '*'/g" "$CONF"
echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a "$HBA" > /dev/null

# --- Service Setup ---

echo "🔌 Enabling PostgreSQL service..."

# Update systemd to point to new PGDATA
PG_SERVICE="/etc/systemd/system/postgresql-${POSTGRES_VERSION}.service.d"
sudo mkdir -p "$PG_SERVICE"
echo -e "[Service]\nEnvironment=PGDATA=$PGDATA" | sudo tee "$PG_SERVICE/override.conf"
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

sudo systemctl enable --now postgresql-${POSTGRES_VERSION}

# --- Set Password ---

echo "🔐 Setting password for postgres user..."
sudo -u "$PGUSER" psql -c "ALTER USER postgres WITH PASSWORD '${psqlpassword}';"

# --- Firewall Configuration ---

echo "🔒 Configuring firewall..."
sudo firewall-cmd --zone=public --permanent --add-port=5432/tcp
sudo firewall-cmd --reload

echo "✅ PostgreSQL $POSTGRES_VERSION installation and configuration complete using separate disk at $DATA_MOUNT."
