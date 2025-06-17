#!/bin/bash

# PostgreSQL 16 Installation with Data on a Second Disk (Rocky Linux 9)

set -euo pipefail

# --- CONFIGURABLE VARIABLES ---
DATA_DISK="/dev/sdb"
DATA_MOUNT="/pgdata"
POSTGRES_VERSION="16"
PGUSER="postgres"
PGDATA="${DATA_MOUNT}/pgsql/${POSTGRES_VERSION}/data"
psqlpassword='Pa$$w0rd'

# --- Step 1: Install PostgreSQL ---
echo "Installing PostgreSQL $POSTGRES_VERSION..."

sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql${POSTGRES_VERSION}-server postgresql${POSTGRES_VERSION}-contrib

# Install versionlock plugin
echo "Installing versionlock support..."
sudo dnf install -y 'dnf-command(versionlock)'

# Lock PostgreSQL packages to prevent unintended upgrades
sudo dnf versionlock postgresql${POSTGRES_VERSION}*

# --- Step 2: Prepare the Second Disk ---
echo "Preparing second disk ($DATA_DISK) for PostgreSQL data..."

if [ ! -b "$DATA_DISK" ]; then
    echo "Device $DATA_DISK not found. Aborting."
    exit 1
fi

if lsblk "$DATA_DISK" | grep -q part; then
    echo "$DATA_DISK already has a partition. Skipping partitioning."
else
    sudo parted -s "$DATA_DISK" mklabel gpt
    sudo parted -s "$DATA_DISK" mkpart primary ext4 0% 100%
    udevadm settle
fi

PART="${DATA_DISK}1"
if ! blkid "$PART" &>/dev/null; then
    echo "Formatting partition $PART as ext4..."
    sudo mkfs.ext4 "$PART"
fi

sudo mkdir -p "$DATA_MOUNT"
UUID=$(sudo blkid -s UUID -o value "$PART")
grep -q "$DATA_MOUNT" /etc/fstab || echo "UUID=$UUID  $DATA_MOUNT  ext4  defaults  0 2" | sudo tee -a /etc/fstab
mount | grep -q "$DATA_MOUNT" || sudo mount "$DATA_MOUNT"

# Prepare the PostgreSQL data directory
sudo mkdir -p "$PGDATA"
sudo chown -R "$PGUSER:$PGUSER" "$DATA_MOUNT"
sudo chmod 700 "$PGDATA"

# --- Step 3: Initialize PostgreSQL Data Directory ---
echo "Initializing PostgreSQL in $PGDATA..."
sudo -u "$PGUSER" /usr/pgsql-${POSTGRES_VERSION}/bin/initdb -D "$PGDATA"

# --- Step 4: Configure PostgreSQL ---
CONF="$PGDATA/postgresql.conf"
HBA="$PGDATA/pg_hba.conf"

sudo sed -i "s/^#*max_connections = .*/max_connections = 200/" "$CONF"
sudo sed -i "s/^#*shared_preload_libraries = .*/shared_preload_libraries = 'pg_stat_statements'/" "$CONF"
sudo sed -i "s/^#*listen_addresses = .*/listen_addresses = '*'/g" "$CONF"
echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a "$HBA" > /dev/null

# --- Step 5: Override Systemd PGDATA and Start Service ---
echo "Configuring systemd to use custom PGDATA..."

PG_SERVICE="/etc/systemd/system/postgresql-${POSTGRES_VERSION}.service.d"
sudo mkdir -p "$PG_SERVICE"
echo -e "[Service]\nEnvironment=PGDATA=$PGDATA" | sudo tee "$PG_SERVICE/override.conf"
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now postgresql-${POSTGRES_VERSION}

# --- Step 6: Set postgres password ---
echo "Setting password for postgres user..."
sudo -u "$PGUSER" psql -c "ALTER USER postgres WITH PASSWORD '${psqlpassword}';"

# --- Step 7: Open Firewall Port ---
echo "Opening PostgreSQL port in firewall..."
sudo firewall-cmd --zone=public --permanent --add-port=5432/tcp
sudo firewall-cmd --reload

# --- Done ---
echo "PostgreSQL $POSTGRES_VERSION installed and using $PGDATA on $DATA_DISK."
