CREATE TABLE [DW].[DimPerson] (
  -- Surrogate key for SCD Type 2 versions
  [PersonKey]                INT             IDENTITY(1,1) NOT NULL PRIMARY KEY,
  [PersonID]                 INT             NOT NULL,
  [NationalCode]             NVARCHAR(255)   NULL,
  [PassportNumber]           NVARCHAR(255)   NULL,
  [Name]                     NVARCHAR(255)   NULL,
  [Gender]                   NVARCHAR(255)   NULL,
  [DateOfBirth]              DATE            NULL,
  [City]                     NVARCHAR(255)   NULL,
  [Country]                  NVARCHAR(255)   NULL,
  [Email]                    NVARCHAR(255)   NULL,
  [Phone]                    NVARCHAR(255)   NULL,
  [Address]                  NVARCHAR(255)   NULL,
  [PostalCode]               NVARCHAR(255)   NULL,
  [EffectiveFrom]            DATETIME        NOT NULL,
  [EffectiveTo]              DATETIME        NULL,
  [PassportNumberIsCurrent]  BIT             NOT NULL
);
GO