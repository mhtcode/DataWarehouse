CREATE TABLE [DW].[DimPerson] (
  [PersonKey] int PRIMARY KEY,
  [NationalCode] nvarchar(255),
  [PassportNumber] nvarchar(255),
  [Name] nvarchar(255),
  [Gender] nvarchar(255),
  [DateOfBirth] date,
  [City] nvarchar(255),
  [Country] nvarchar(255),
  [Email] nvarchar(255),
  [Phone] nvarchar(255),
  [Address] nvarchar(255),
  [PostalCode] nvarchar(255),
  [EffectiveFrom] datetime,
  [EffectiveTo] datetime,
  [PassportNumberIsCurrent] bit
)
GO
