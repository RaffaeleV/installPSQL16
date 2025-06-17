Script to automate the installation of PostgreSQL 16 for Veeam Backup and Replication v12+
If you want to depoly Veeam Backup and Replication v12 with an external PostgreSQL server, this script automate the installation and configuration of PostgreSQL 16 on a Rocky Linux 9 server.
PostgreSQL components required by VBR are also installed.
The default 'postgres' user password (Pa$$w0rd) can easily be defined in the script itself.
The script will also initialize a second disk /dev/sdb that will be used to store PostgreSQL data.
