USE master
GO

IF DB_ID('ProductManagementSystem') IS NOT NULL
    DROP DATABASE ProductManagementSystem;

DECLARE @data_path NVARCHAR(256);
SET @data_path = (
        SELECT SUBSTRING(physical_name, 1, CHARINDEX(N'master.mdf', LOWER(physical_name)) - 1)
        FROM master.sys.master_files
        WHERE database_id = 1 AND file_id = 1
        );

EXECUTE ('CREATE DATABASE ProductManagementSystem
ON PRIMARY (NAME=ProductManagementSystem_data, FILENAME=''' + @data_path + '\ProductManagementSystem_data.mdf'', SIZE=20MB, MAXSIZE=Unlimited, FILEGROWTH=5%)
LOG ON (NAME=ProductManagementSystem_log, FILENAME=''' + @data_path + '\ProductManagementSystem_log.ldf'', SIZE=10MB, MAXSIZE=100MB, FILEGROWTH=2MB)
');
GO

USE ProductManagementSystem;
Go
-- Schema Creation
CREATE SCHEMA pd;
GO

USE ProductManagementSystem;

-- Create table for categories
CREATE TABLE pd.Categories (
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL,
    Description TEXT
);
GO
USE ProductManagementSystem;

-- Create table for suppliers
CREATE TABLE pd.Suppliers (
    SupplierID INT PRIMARY KEY,
    CompanyName VARCHAR(100) NOT NULL,
    ContactName VARCHAR(100),
    ContactTitle VARCHAR(100),
    Address VARCHAR(255),
    City VARCHAR(100),
    Region VARCHAR(100),
    PostalCode VARCHAR(20),
    Country VARCHAR(100),
    Phone VARCHAR(50),
    Email VARCHAR(100),
    Website VARCHAR(255)
);
GO
USE ProductManagementSystem;

-- Create table for products
CREATE TABLE pd.Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(255) NOT NULL,
    CategoryID INT,
    SupplierID INT,
    UnitPrice DECIMAL(10,2),
    UnitsInStock INT,
    UnitsOnOrder INT,
    ReorderLevel INT,
    Discontinued BIT DEFAULT 0,
    FOREIGN KEY (CategoryID) REFERENCES pd.Categories(CategoryID),
    FOREIGN KEY (SupplierID) REFERENCES pd.Suppliers(SupplierID)
);
GO
USE ProductManagementSystem;

-- Create a table for storing customers within the "pd" schema
CREATE TABLE pd.Customers (
    CustomerID INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Email VARCHAR(100),
    Phone VARCHAR(20),
    Address VARCHAR(255),
    City VARCHAR(100),
    State VARCHAR(100),
    PostalCode VARCHAR(20),
    Country VARCHAR(100)
);
GO
USE ProductManagementSystem;

-- Create a table for storing orders within the "pd" schema
CREATE TABLE pd.Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    OrderDate DATE,
    ShipDate DATE,
    TotalAmount DECIMAL(10,2),
    FOREIGN KEY (CustomerID) REFERENCES pd.Customers(CustomerID)
);
GO
USE ProductManagementSystem;

-- Create a table for storing employee information
CREATE TABLE pd.Employees (
    EmployeeID INT Primary key,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Email VARCHAR(100),
    HireDate DATE,
    Department VARCHAR(100),
    Salary DECIMAL(10,2)
);

USE ProductManagementSystem;
GO
-- Create a table for tracking order details
CREATE TABLE pd.OrderDetails (
    OrderDetailID INT PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    UnitPrice DECIMAL(10,2),
    Quantity INT,
    Discount DECIMAL(4,2),
    FOREIGN KEY (OrderID) REFERENCES pd.Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES pd.Products(ProductID)
);
GO
USE ProductManagementSystem;

-- Create a table for storing payment information
CREATE TABLE pd.Payments (
    PaymentID INT IDENTITY PRIMARY KEY,
    OrderID INT,
    PaymentDate DATE,
    Amount DECIMAL(10,2),
    PaymentMethod VARCHAR(50),
    FOREIGN KEY (OrderID) REFERENCES pd.Orders(OrderID)
);

GO
USE ProductManagementSystem;

-- Create a table for tracking product audit trail
CREATE TABLE pd.ProductAuditTrail (
    AuditTrailID INT IDENTITY PRIMARY KEY,
    ProductID INT,
    Action VARCHAR(50),
    ActionDate DATETIME,
    FOREIGN KEY (ProductID) REFERENCES pd.Products(ProductID)
);
GO

USE ProductManagementSystem;
-- Alter the Suppliers table in the "pd" schema
ALTER TABLE pd.Suppliers
ALTER COLUMN Phone VARCHAR(11); -- Set the maximum length to 11 characters
GO
USE ProductManagementSystem;
-- Drop the State column from the Customers table in the "pd" schema
ALTER TABLE pd.Customers
DROP COLUMN State;
GO
USE ProductManagementSystem;
-- Drop the Country column from the Customers table in the "pd" schema
ALTER TABLE pd.Customers
DROP COLUMN Country;
GO

USE ProductManagementSystem;
-- Add the Country column to the Customers table in the "pd" schema
ALTER TABLE pd.Customers
ADD Country VARCHAR(30);
GO

USE ProductManagementSystem;

-- Add a nonclustered index to the OrderDate column in the Orders table
CREATE NONCLUSTERED INDEX IX_OrderDate ON pd.Orders (OrderDate);
GO

USE ProductManagementSystem;

-- Create a sequence named OrderIDSeq
CREATE SEQUENCE OrderIDSeq
    START WITH 1
    INCREMENT BY 1;
GO


-- Create a view named ProductView
CREATE VIEW ProductView
AS
SELECT ProductID, ProductName, UnitPrice, UnitsInStock
FROM pd.Products;
GO

-- Create a view named OrderDetailsView with encryption
CREATE VIEW OrderDetailsView
WITH ENCRYPTION
AS
SELECT OD.OrderDetailID, O.OrderID, P.ProductName, OD.UnitPrice, OD.Quantity, OD.Discount
FROM pd.OrderDetails OD
JOIN pd.Orders O ON OD.OrderID = O.OrderID
JOIN pd.Products P ON OD.ProductID = P.ProductID;

GO

-- Create a view named CustomerOrderView with schema binding
CREATE VIEW CustomerOrderView
WITH SCHEMABINDING
AS
SELECT 
    C.CustomerID, C.FirstName, C.LastName, O.OrderID, O.OrderDate, O.TotalAmount
FROM 
    pd.Customers C
JOIN 
    pd.Orders O ON C.CustomerID = O.CustomerID;

GO


-- Create a stored procedure named InsertProduct
CREATE PROCEDURE InsertProduct
    @ProductName NVARCHAR(100),
    @UnitPrice DECIMAL(10, 2),
    @UnitsInStock INT
AS
BEGIN
   
    INSERT INTO pd.Products (ProductName, UnitPrice, UnitsInStock)
    VALUES (@ProductName, @UnitPrice, @UnitsInStock);
END;

GO

-- Create a stored procedure named InsertProductWithTransaction
CREATE PROCEDURE InsertProductWithTransaction
    @ProductName NVARCHAR(100),
    @UnitPrice DECIMAL(10, 2),
    @UnitsInStock INT
AS
BEGIN
    -- Begin the transaction
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Insert the new product
        INSERT INTO pd.Products (ProductName, UnitPrice, UnitsInStock)
        VALUES (@ProductName, @UnitPrice, @UnitsInStock);

        -- Commit the transaction
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if an error occurs
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Raise the error
        THROW;
    END CATCH;
END;
GO

-- Create an after trigger named AfterInsertProduct
CREATE TRIGGER AfterInsertProduct
ON pd.Products
AFTER INSERT
AS
BEGIN
    -- Insert records into ProductAuditTrail table for each inserted product
    INSERT INTO pd.ProductAuditTrail (ProductID, Action, ActionDate)
    SELECT 
        inserted.ProductID,
        'Inserted',
        GETDATE()
    FROM 
        inserted;
END;

GO

-- Create a table-valued function named GetProductsWithLowStock
CREATE FUNCTION GetProductsWithLowStock()
RETURNS TABLE
AS
RETURN
(
    SELECT ProductID, ProductName, UnitsInStock
    FROM pd.Products
    WHERE UnitsInStock < 10
);

GO

-- Create a scalar function named CalculateTotalPrice
CREATE FUNCTION CalculateTotalPrice
(
    @UnitPrice DECIMAL(10, 2),
    @Quantity INT
)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @TotalPrice DECIMAL(10, 2);

    -- Calculate total price
    SET @TotalPrice = @UnitPrice * @Quantity;

    -- Return the total price
    RETURN @TotalPrice;
END;
GO
