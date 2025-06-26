CREATE TABLE [DW].[DimPointConversionRate] (
    ConversionRateKey      INT IDENTITY(1,1) PRIMARY KEY,   -- Surrogate Key
    PointConversionRateID  INT NOT NULL,                    -- Business Key from SA
    Rate                   DECIMAL(18,6) NOT NULL,
    Currency               NVARCHAR(255) NOT NULL,
    EffectiveFrom          DATETIME NOT NULL,
    EffectiveTo            DATETIME NULL,
    IsCurrent              BIT NOT NULL
);
GO
