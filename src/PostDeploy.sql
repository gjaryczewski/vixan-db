IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('src') AND name LIKE 'Test_')
BEGIN
    DECLARE @T int = 0;
    WHILE @T < 10
    BEGIN
        DECLARE @Script varchar(4000) = CONCAT('
            SELECT [value] AS Id
            INTO src.Test', @T, '
            FROM GENERATE_SERIES(1, 99950 + CAST(RAND() * 100 AS int))');
        EXECUTE (@Script);
        SET @T += 1;
    END
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('dst') AND name LIKE 'Test_')
BEGIN
    SET @T = 0;
    WHILE @T < 10
    BEGIN
        SET @Script = CONCAT('
            SELECT TOP(0) Id
            INTO dst.Test', @T, '
            FROM src.Test', @T);
        EXECUTE (@Script);
        SET @T += 1;
    END
END

IF NOT EXISTS (SELECT * FROM dbo.Scripts)
BEGIN
    SET @T = 0;
    WHILE @T < 10
    BEGIN
        SET @Script = CONCAT(
'DECLARE @Offset int = ISNULL((SELECT MAX(Id) FROM dst.Test', @T, '), 0);', CHAR(10),
'WHILE @Offset IS NOT NULL', CHAR(10),
'BEGIN', CHAR(10),
'    INSERT dst.Test', @T, ' (Id)', CHAR(10),
'        SELECT TOP(1000) Id', CHAR(10),
'        FROM src.Test', @T, CHAR(10),
'        WHERE Id > @Offset;', CHAR(10),
CHAR(10),
'    SET @Offset = ISNULL((SELECT MAX(Id) FROM dst.Test', @T, '), 0)', CHAR(10),
'END');
        INSERT dbo.Scripts (ScriptName, ScriptCode, SeqNum)
            VALUES (CONCAT('COPY_TEST', @T), @Script, @T + 1);
        SET @T += 1;
    END
END