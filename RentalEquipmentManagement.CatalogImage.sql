IF OBJECT_ID(N'dbo.CatalogImage', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CatalogImage (
        Directory VARCHAR(16) NOT NULL,
        Name VARCHAR(32) NOT NULL,
        Content VARBINARY(MAX) NOT NULL,
        CONSTRAINT PK_CatalogImage PRIMARY KEY (Directory, Name),
        CONSTRAINT CK_CatalogImage_Directory CHECK (Directory IN ('equipment', 'categories')),
        CONSTRAINT CK_CatalogImage_Content CHECK (DATALENGTH(Content) BETWEEN 12 AND 5242880)
    );
END;
