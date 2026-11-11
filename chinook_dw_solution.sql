DROP DATABASE IF EXISTS chinook_dw;
CREATE DATABASE chinook_dw;

USE chinook_dw;

CREATE TABLE Customer_Dim (
    CustomerId INT NOT NULL,
    FirstName VARCHAR(40) NOT NULL,
    LastName VARCHAR(20) NOT NULL,
    Company VARCHAR(80),
    Address VARCHAR(70),
    City VARCHAR(40),
    State VARCHAR(40),
    Country VARCHAR(40),
    PostalCode VARCHAR(10),
    Phone VARCHAR(24),
    Fax VARCHAR(24),
    Email VARCHAR(60) NOT NULL,
    PRIMARY KEY (CustomerId)
);

ALTER TABLE Customer_Dim
ADD COLUMN CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN UpdateDate DATETIME DEFAULT CURRENT_TIMESTAMP
ON UPDATE CURRENT_TIMESTAMP;

INSERT INTO Customer_Dim
(CustomerId, FirstName, LastName, Company, Address, City,
State, Country, PostalCode, Phone, Fax, Email)
SELECT
CustomerId, FirstName, LastName, Company, Address, City,
State, Country, PostalCode, Phone, Fax, Email
FROM Chinook_oltp.Customer;   SELECT * FROM Customer_Dim LIMIT 10;

CREATE TABLE Track_Dim (
    TrackId INT NOT NULL,
    TrackName VARCHAR(200) NOT NULL,
    AlbumTitle VARCHAR(160),
    ArtistName VARCHAR(120),
    GenreName VARCHAR(120),
    Composer VARCHAR(220),
    Milliseconds INT,
    Bytes INT,
    UnitPrice DECIMAL(10,2),
    PRIMARY KEY (TrackId)
);

ALTER TABLE Track_Dim
    ADD COLUMN CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN UpdateDate DATETIME DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP;
    
INSERT INTO Track_Dim
    (TrackId, TrackName, AlbumTitle, ArtistName, GenreName,
     Composer, Milliseconds, Bytes, UnitPrice)
SELECT
    t.TrackId,
    t.Name,
    a.Title,
    ar.Name,
    g.Name,
    t.Composer,
    t.Milliseconds,
    t.Bytes,
    t.UnitPrice
FROM Chinook_oltp.Track t
LEFT JOIN Chinook_oltp.Album  a ON t.AlbumId = a.AlbumId
LEFT JOIN Chinook_oltp.Artist ar ON a.ArtistId = ar.ArtistId
LEFT JOIN Chinook_oltp.Genre  g  ON t.GenreId = g.GenreId;

SELECT COUNT(*) FROM Track_Dim;

SELECT MIN(YEAR(InvoiceDate)) AS MinYear,
    MAX(YEAR(InvoiceDate)) AS MaxYear
FROM Chinook_oltp.Invoice;

CREATE TABLE Date_Dim (
    DateKey DATE NOT NULL,
    Day INT NOT NULL,
    Month INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    Quarter INT NOT NULL,
    Year INT NOT NULL,
    PRIMARY KEY (DateKey)
);

DROP PROCEDURE IF EXISTS Populate_Date_Dim;
DELIMITER $$
CREATE PROCEDURE Populate_Date_Dim(IN start_year INT, IN end_year INT)
BEGIN
    DECLARE d DATE;
    DECLARE last_d DATE;
    SET d = MAKEDATE(start_year, 1);
    SET last_d = MAKEDATE(end_year + 1, 1) - INTERVAL 1 DAY;
    WHILE d <= last_d DO
        INSERT INTO Date_Dim (DateKey, Day, Month, MonthName, Quarter, Year)
        VALUES (d, DAY(d), MONTH(d), MONTHNAME(d), QUARTER(d), YEAR(d));
        SET d = d + INTERVAL 1 DAY;
    END WHILE;
END$$
DELIMITER ;

SET @min_y = (SELECT MIN(YEAR(InvoiceDate)) FROM Chinook_oltp.Invoice);
SET @max_y = (SELECT MAX(YEAR(InvoiceDate)) FROM Chinook_oltp.Invoice);
CALL Populate_Date_Dim(@min_y, @max_y);

SELECT MIN(DateKey), MAX(DateKey), COUNT(*) FROM Date_Dim;

CREATE TABLE Invoice_Fact (
    InvoiceId   INT NOT NULL,
    TrackId     INT NOT NULL,
    CustomerId  INT NOT NULL,
    SaleDateID  DATE NOT NULL,
    TotalQuantity INT NOT NULL,
    TotalAmount   DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (InvoiceId, TrackId),
    CONSTRAINT FK_Fact_Customer FOREIGN KEY (CustomerId)
        REFERENCES Customer_Dim (CustomerId),
    CONSTRAINT FK_Fact_Track FOREIGN KEY (TrackId)
        REFERENCES Track_Dim (TrackId),
    CONSTRAINT FK_Fact_Date FOREIGN KEY (SaleDateID)
        REFERENCES Date_Dim (DateKey)
);

INSERT INTO Invoice_Fact
    (InvoiceId, TrackId, CustomerId, SaleDateID, TotalQuantity, TotalAmount)
SELECT
    il.InvoiceId,
    il.TrackId,
    i.CustomerId,
    DATE(i.InvoiceDate),
    SUM(il.Quantity),
    SUM(il.UnitPrice * il.Quantity)
FROM Chinook_oltp.InvoiceLine il
JOIN Chinook_oltp.Invoice i ON il.InvoiceId = i.InvoiceId
GROUP BY il.InvoiceId, il.TrackId, i.CustomerId, DATE(i.InvoiceDate);

SELECT COUNT(*) FROM Invoice_Fact;

CREATE OR REPLACE VIEW Chinook_Datamart AS
SELECT
    f.InvoiceId, f.TrackId, f.CustomerId, f.SaleDateID,
    f.TotalQuantity, f.TotalAmount,
    c.FirstName, c.LastName, c.Company, c.Address, c.City, c.State,
    c.Country, c.PostalCode, c.Phone, c.Fax, c.Email,
    c.CreatedDate AS Customer_CreatedDate,
    c.UpdateDate AS Customer_UpdateDate,
    t.TrackName, t.AlbumTitle, t.ArtistName, t.GenreName, t.Composer,
    t.Milliseconds, t.Bytes, t.UnitPrice,
    t.CreatedDate AS Track_CreatedDate,
    t.UpdateDate AS Track_UpdateDate,
    d.Day, d.Month, d.MonthName, d.Quarter, d.Year
    FROM Invoice_Fact f
LEFT JOIN Customer_Dim c ON f.CustomerId = c.CustomerId
LEFT JOIN Track_Dim    t ON f.TrackId    = t.TrackId
LEFT JOIN Date_Dim     d ON f.SaleDateID = d.DateKey;

SELECT * FROM Chinook_Datamart LIMIT 20;

SELECT COUNT(*) FROM Customer_Dim;   
SELECT COUNT(*) FROM Track_Dim;      
SELECT COUNT(*) FROM Date_Dim;      
SELECT COUNT(*) FROM Invoice_Fact;   
SELECT COUNT(*) FROM Chinook_Datamart; 


SELECT SUM(TotalAmount) FROM Invoice_Fact;
SELECT SUM(Total) FROM Chinook_oltp.Invoice;