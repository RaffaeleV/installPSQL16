Script to automate the installation of PostgreSQL 16 on Rocky Linux for Veeam Backup and Replication v12+
=========================================================================================================

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

Initializes the second disk /dev/sdb that will be used to store PostgreSQL data

Include the "pg_stat_statements" library to the PostgreSQL configuration

Suggest the subsequent steps to be performed on Veeam Backup and Replication to ensure that the PostgreSQL target instance is configured according to the recommended hardware resources values (Source: https://helpcenter.veeam.com/docs/backup/powershell/set-vbrpsqldatabaseserverlimits.html?ver=120) 

Requirements
============
Operating System: Rocky Linux 9

Resources: At least 4 CPUs and 8GB RAM and a second disk still to be partitioned

Privileges: Must be run as root or with sudo

Network Access: Required to reach the PostgreSQL Yum repository

Usage
=====
Download the Script:

curl -O https://raw.githubusercontent.com/RaffaeleV/installPSQL16/main/installPSQL16.sh

Make it executable:

chmod +x installPSQL16.sh

Run the Script:

sudo ./installPSQL16.sh

Customization
=============
Edit the line PGPASSWORD='P455w0rd' to set a secure password for the default postgres user.

Change the subnet (192.168.1.0/24) to match the IP range of your clients.

Then apply the resulting SQL configuration manually as instructed in the script.

Disclaimer
==========
The script is intended for test/dev or initial setup use cases. For production deployments, further hardening and tuning is recommended.

License
=======
This script is provided as-is under the MIT license. Use at your own risk.
