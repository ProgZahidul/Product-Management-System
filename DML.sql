-- Insert demo data into Categories table
INSERT INTO pd.Categories (CategoryID, CategoryName, Description)
VALUES 
    (1, 'Electronics', 'Electronic devices and components'),
    (2, 'Clothing', 'Apparel and fashion accessories');

-- Insert demo data into Suppliers table
INSERT INTO pd.Suppliers (SupplierID, CompanyName, ContactName, ContactTitle, Address, City, Region, PostalCode, Country, Phone, Email, Website)
VALUES
    (1, 'ABC Electronics', 'John Doe', 'Sales Manager', '123 Main St', 'Dhaka', NULL, '12345', 'Bangladesh', '1234567890', 'info@abc.com', 'www.abc.com'),
    (2, 'Fashion World', 'Jane Smith', 'Marketing Manager', '456 Elm St', 'Chittagong', NULL, '54321', 'Bangladesh', '9876543210', 'info@fashionworld.com', 'www.fashionworld.com');

-- Insert demo data into Products table
INSERT INTO pd.Products (ProductID, ProductName, CategoryID, SupplierID, UnitPrice, UnitsInStock, UnitsOnOrder, ReorderLevel, Discontinued)
VALUES
    (1, 'Smartphone', 1, 1, 500.00, 50, 10, 5, 0),
    (2, 'Laptop', 1, 1, 1000.00, 20, 5, 3, 0),
    (3, 'T-Shirt', 2, 2, 20.00, 100, 20, 10, 0);

-- Insert demo data into Customers table
INSERT INTO pd.Customers (CustomerID, FirstName, LastName, Email, Phone, Address, City, PostalCode, Country)
VALUES
    (1, 'Alice', 'Smith', 'alice@example.com', '1234567890', '789 Oak St', 'Dhaka', '54321', 'Bangladesh'),
    (2, 'Bob', 'Johnson', 'bob@example.com', '9876543210', '456 Pine St', 'Chittagong', '12345', 'Bangladesh');

-- Insert demo data into Orders table
INSERT INTO pd.Orders (OrderID, CustomerID, OrderDate, ShipDate, TotalAmount)
VALUES
    (1, 1, '2024-03-27', '2024-03-28', 1500.00),
    (2, 2, '2024-03-28', '2024-03-29', 300.00);

-- Insert demo data into Employees table
INSERT INTO pd.Employees (EmployeeID, FirstName, LastName, Email, HireDate, Department, Salary)
VALUES
    (1, 'David', 'Brown', 'david@example.com', '2020-01-01', 'Sales', 30000.00),
    (2, 'Emma', 'Wilson', 'emma@example.com', '2020-02-01', 'Marketing', 35000.00);

-- Insert demo data into OrderDetails table
INSERT INTO pd.OrderDetails (OrderDetailID, OrderID, ProductID, UnitPrice, Quantity, Discount)
VALUES
    (1, 1, 1, 500.00, 2, 0),
    (2, 1, 2, 1000.00, 1, 0),
    (3, 2, 3, 20.00, 5, 0);

-- Insert demo data into Payments table
INSERT INTO pd.Payments (OrderID, PaymentDate, Amount, PaymentMethod)
VALUES
    (1, '2024-03-27', 1500.00, 'Credit Card'),
    (2, '2024-03-28', 300.00, 'Cash');

-- Insert demo data into ProductAuditTrail table (just for illustration purposes)
INSERT INTO pd.ProductAuditTrail (ProductID, Action, ActionDate)
VALUES
    (1, 'Inserted', GETDATE()),
    (2, 'Inserted', GETDATE());

-- Here, we have added demo data into several tables. You can adjust the values as per your requirements.
USE ProductManagementSystem;
GO

-- Demo Stored Procedure: CalculateTotalOrderAmount
CREATE PROCEDURE CalculateTotalOrderAmount
    @OrderID INT
AS
BEGIN
    DECLARE @TotalAmount DECIMAL(10, 2);

    SELECT @TotalAmount = SUM(UnitPrice * Quantity)
    FROM pd.OrderDetails
    WHERE OrderID = @OrderID;

    SELECT @TotalAmount AS TotalAmount;
END;
GO

-- Demo View: ActiveProductsView
CREATE VIEW ActiveProductsView
AS
SELECT ProductID, ProductName, UnitPrice, UnitsInStock
FROM pd.Products
WHERE Discontinued = 0;
GO

-- Demo Function: CalculateDiscountedPrice
CREATE FUNCTION CalculateDiscountedPrice
(
    @Price DECIMAL(10, 2),
    @Discount DECIMAL(4, 2)
)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @DiscountedPrice DECIMAL(10, 2);

    SET @DiscountedPrice = @Price - (@Price * @Discount / 100);

    RETURN @DiscountedPrice;
END;
GO

-- Demo Trigger: AfterInsertOrder
CREATE TRIGGER AfterInsertOrder
ON pd.Orders
AFTER INSERT
AS
BEGIN
    -- Update the OrderDetails table after an order is inserted
    UPDATE pd.OrderDetails
    SET Discount = 0.1
    FROM pd.OrderDetails od
    JOIN inserted i ON od.OrderID = i.OrderID;
END;
GO
