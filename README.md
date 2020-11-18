# Introduction 
These scripts are helpful to support Databricks migration during Azure subscription migration. Databricks migration doesn't come by default service of Azure, so re-creating the existing setup on the newly created Databricks platform demands a lot of manual works, and with these scripts that manual activities have been automated. The scripts folder consists of 3 main PowerShell scripts that essentially perform the below jobs.

- Prerquisite.ps1 -This scripts imports essential packages
- DatabricksBeforeMigration.ps1- Download all artifacts including DBFS files on your local machines
- DatabricksAfterMigration.ps1 - Uploads all artifacts back to newly created Databricks platform and also create all users, groups, add users in previously defined groups, and create pre-defined scopes.
