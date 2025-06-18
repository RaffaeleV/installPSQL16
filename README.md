Script to automate the installation of PostgreSQL 16 on Rocky Linux for Veeam Backup and Replication v12+
=========================================================================================================
Requirements: a freshly installed Rocky Linux 9 machine with at least 4 CPUs and 8GB RAM and a second disk still to be partitioned

The script initializes the second disk /dev/sdb that will be used to store PostgreSQL data and include the "pg_stat_statements" library to the PostgreSQL configuration.
Ultimately, the script suggest the subsequent steps to be performed on Veeam Backup and Replication to ensure that the PostgreSQL target instance is configured according to the recommended hardware resources values
(Source: https://helpcenter.veeam.com/docs/backup/powershell/set-vbrpsqldatabaseserverlimits.html?ver=120) 
The default 'postgres' user password (P455w0rd) can easily be defined in the script itself.
