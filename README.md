Script to automate the installation of PostgreSQL 16 on Rocky Linux for Veeam Backup and Replication v12+
=========================================================================================================
Requirements: a freshly installed Rocky Linux 9 machine with at least 4 CPUs and 8GB RAM and a second disk still to be partitioned

The script initializes the second disk /dev/sdb that will be used to store PostgreSQL data and include the "pg_stat_statements" library to the PostgreSQL configuration.
Ultimately, the script suggest the subsequent steps to be performed on Veeam Backup and Replication to ensure that the PostgreSQL target instance is configured according to the recommended hardware resources values
(Source: https://helpcenter.veeam.com/docs/backup/powershell/set-vbrpsqldatabaseserverlimits.html?ver=120) 
The default 'postgres' user password (P455w0rd) can easily be defined in the script itself.

Overview
========
This script automates the installation and basic configuration of PostgreSQL 16 on Rocky Linux 9 systems. It is designed to simplify the process of preparing a PostgreSQL environment, including optional tuning and service configuration, in environments where PostgreSQL will be used by Veeam Backup & Replication with PostgreSQL as the configuration database.

Features
========
Adds the official PostgreSQL 16 repository
Installs PostgreSQL 16 and its contrib package
Initializes the PostgreSQL database
Starts and enables the PostgreSQL service
Sets the PostgreSQL superuser password (postgres)
Optionally creates a database and user (via customization)
Provides comments and placeholders for advanced tuning

Requirements
============
Operating System: Rocky Linux 9 (or compatible RHEL-based systems)
Privileges: Must be run as root or with sudo
Network Access: Required to reach the PostgreSQL Yum repository

Usage
=====
1. Download the Script
curl -O https://raw.githubusercontent.com/RaffaeleV/installPSQL16/main/installPSQL16.sh
chmod +x installPSQL16.sh

2. Run the Script
sudo ./installPSQL16.sh

Customization
=============
The script includes several commented lines and placeholders to help you tailor the installation to your needs:

Set Custom Password
Edit the line:
PGPASSWORD='ChangeMe123!'
to set a secure password for the default postgres user.

Create Additional Users and Databases
Uncomment and edit the following lines at the end of the script to create a database and a user:

# su - postgres -c "psql -c \"CREATE DATABASE mydb;\""
# su - postgres -c "psql -c \"CREATE USER myuser WITH ENCRYPTED PASSWORD 'mypassword';\""
# su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE mydb TO myuser;\""

Tune PostgreSQL Settings (Optional)
You can use Veeam's Set-VBRPSQLDatabaseServerLimits PowerShell cmdlet to generate PostgreSQL tuning recommendations:

Set-VBRPSQLDatabaseServerLimits -OSType Linux -CPUCount <CPU> -MemorySize <MB>
Then apply the resulting SQL configuration manually as instructed in the script.

Notes
=====
No firewall or SELinux rules are modified by default.
The script is intended for test/dev or initial setup use cases. For production deployments, further hardening and tuning is recommended.

License
=======
This script is provided as-is under the MIT license. Use at your own risk.
