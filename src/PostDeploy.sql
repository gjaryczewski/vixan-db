IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('src') AND name LIKE 'TestTable_')
BEGIN
    DECLARE @T int = 0;
    WHILE @T < 10
    BEGIN
        DECLARE @Script varchar(4000) = CONCAT('
            SELECT [value] AS TestValue
            INTO src.TestTable', @T, '
            FROM GENERATE_SERIES(1, 9500 + CAST(RAND() * 1000 AS int))');
        EXECUTE (@Script);
        SET @T += 1;
    END
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('dst') AND name LIKE 'TestTable_')
BEGIN
    SET @T = 0;
    WHILE @T < 10
    BEGIN
        SET @Script = CONCAT('
            SELECT TOP(0) TestValue
            INTO dst.TestTable', @T, '
            FROM src.TestTable', @T);
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
'DECLARE @Offset int = ISNULL((SELECT MAX(TestValue) FROM dst.TestTable', @T, '), 0);', CHAR(10),
'WHILE @Offset IS NOT NULL', CHAR(10),
'BEGIN', CHAR(10),
'    INSERT dst.TestTable', @T, ' (TestValue)', CHAR(10),
'        SELECT TOP(1000) TestValue', CHAR(10),
'        FROM src.TestTable', @T, CHAR(10),
'        WHERE TestValue > @Offset;', CHAR(10),
CHAR(10),
'    WAITFOR DELAY ''00:00:01'';', CHAR(10),
CHAR(10),
'    SET @Offset = (SELECT MAX(TestValue) FROM dst.TestTable', @T, ' WHERE TestValue > @Offset);', CHAR(10),
'END');
        INSERT dbo.Scripts (ScriptName, ScriptCode, SeqNum)
            VALUES (CONCAT('COPY_TEST', @T), @Script, @T + 1);
        SET @T += 1;
    END
END