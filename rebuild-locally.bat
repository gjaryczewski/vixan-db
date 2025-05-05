@echo off

dotnet build

sqlcmd -S "(localdb)\MSSQLLocalDB" -d master -i drop-local-databases.sql -v EnvironmentName="Local" -v DatabaseName="vixandb"

sqlpackage /a:Publish /sf:src/bin/Debug/Vixan.Db.dacpac /tsn:"(localdb)\MSSQLLocalDB" /tdn:vixandb