@echo off
dotnet build
sqlpackage /Action:Publish /SourceFile:src/bin/Debug/Vixan.Db.dacpac /TargetServerName:"(localdb)\MSSQLLocalDB" /TargetDatabaseName:vixandb