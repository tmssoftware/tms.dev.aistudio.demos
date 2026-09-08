unit SampleDataBaseGenerator;

interface

uses
  System.SysUtils,
  System.Classes,
  FireDAC.Comp.Client;

procedure CreateSampleData(Connection: TFDConnection);

implementation

procedure CreateSampleData(Connection: TFDConnection);
begin
  // Create comprehensive sample database structure

  // Customers table
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''customers'' AND xtype=''U'') ' +
    'CREATE TABLE customers (' +
    '  id int IDENTITY(1,1) PRIMARY KEY, ' +
    '  first_name nvarchar(50) NOT NULL, ' +
    '  last_name nvarchar(50) NOT NULL, ' +
    '  email nvarchar(100) UNIQUE NOT NULL, ' +
    '  phone nvarchar(20), ' +
    '  address nvarchar(200), ' +
    '  city nvarchar(50), ' +
    '  state nvarchar(20), ' +
    '  zip_code nvarchar(10), ' +
    '  country nvarchar(50) DEFAULT ''USA'', ' +
    '  date_created datetime2 DEFAULT GETDATE(), ' +
    '  last_login datetime2, ' +
    '  is_active bit DEFAULT 1, ' +
    '  customer_type nvarchar(20) DEFAULT ''Regular'', ' +
    '  credit_limit decimal(10,2) DEFAULT 1000.00 ' +
    ')'
  );

  // Products table
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''products'' AND xtype=''U'') ' +
    'CREATE TABLE products (' +
    '  id int IDENTITY(1,1) PRIMARY KEY, ' +
    '  product_code nvarchar(20) UNIQUE NOT NULL, ' +
    '  name nvarchar(100) NOT NULL, ' +
    '  description nvarchar(500), ' +
    '  category nvarchar(50), ' +
    '  brand nvarchar(50), ' +
    '  unit_price decimal(10,2) NOT NULL, ' +
    '  cost_price decimal(10,2), ' +
    '  stock_quantity int DEFAULT 0, ' +
    '  min_stock_level int DEFAULT 10, ' +
    '  weight decimal(8,3), ' +
    '  dimensions nvarchar(50), ' +
    '  is_active bit DEFAULT 1, ' +
    '  date_created datetime2 DEFAULT GETDATE(), ' +
    '  last_updated datetime2 ' +
    ')'
  );

  // Categories table
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''categories'' AND xtype=''U'') ' +
    'CREATE TABLE categories (' +
    '  id int IDENTITY(1,1) PRIMARY KEY, ' +
    '  name nvarchar(50) UNIQUE NOT NULL, ' +
    '  description nvarchar(200), ' +
    '  parent_category_id int, ' +
    '  is_active bit DEFAULT 1, ' +
    '  FOREIGN KEY (parent_category_id) REFERENCES categories(id) ' +
    ')'
  );

  // Orders table
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''orders'' AND xtype=''U'') ' +
    'CREATE TABLE orders (' +
    '  id int IDENTITY(1,1) PRIMARY KEY, ' +
    '  order_number nvarchar(20) UNIQUE NOT NULL, ' +
    '  customer_id int NOT NULL, ' +
    '  order_date datetime2 DEFAULT GETDATE(), ' +
    '  ship_date datetime2, ' +
    '  delivery_date datetime2, ' +
    '  order_status nvarchar(20) DEFAULT ''Pending'', ' +
    '  shipping_address nvarchar(200), ' +
    '  shipping_city nvarchar(50), ' +
    '  shipping_state nvarchar(20), ' +
    '  shipping_zip nvarchar(10), ' +
    '  shipping_cost decimal(8,2) DEFAULT 0, ' +
    '  tax_amount decimal(8,2) DEFAULT 0, ' +
    '  discount_amount decimal(8,2) DEFAULT 0, ' +
    '  total_amount decimal(10,2), ' +
    '  payment_method nvarchar(30), ' +
    '  notes nvarchar(500), ' +
    '  FOREIGN KEY (customer_id) REFERENCES customers(id) ' +
    ')'
  );

  // Order Items table
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''order_items'' AND xtype=''U'') ' +
    'CREATE TABLE order_items (' +
    '  id int IDENTITY(1,1) PRIMARY KEY, ' +
    '  order_id int NOT NULL, ' +
    '  product_id int NOT NULL, ' +
    '  quantity int NOT NULL, ' +
    '  unit_price decimal(10,2) NOT NULL, ' +
    '  discount_percent decimal(5,2) DEFAULT 0, ' +
    '  line_total decimal(10,2), ' +
    '  FOREIGN KEY (order_id) REFERENCES orders(id), ' +
    '  FOREIGN KEY (product_id) REFERENCES products(id) ' +
    ')'
  );

  // Suppliers table
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''suppliers'' AND xtype=''U'') ' +
    'CREATE TABLE suppliers (' +
    '  id int IDENTITY(1,1) PRIMARY KEY, ' +
    '  company_name nvarchar(100) NOT NULL, ' +
    '  contact_name nvarchar(100), ' +
    '  email nvarchar(100), ' +
    '  phone nvarchar(20), ' +
    '  address nvarchar(200), ' +
    '  city nvarchar(50), ' +
    '  state nvarchar(20), ' +
    '  country nvarchar(50), ' +
    '  website nvarchar(100), ' +
    '  rating decimal(3,1), ' +
    '  is_active bit DEFAULT 1 ' +
    ')'
  );

  // Product Suppliers table (many-to-many)
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''product_suppliers'' AND xtype=''U'') ' +
    'CREATE TABLE product_suppliers (' +
    '  id int IDENTITY(1,1) PRIMARY KEY, ' +
    '  product_id int NOT NULL, ' +
    '  supplier_id int NOT NULL, ' +
    '  supplier_product_code nvarchar(50), ' +
    '  lead_time_days int, ' +
    '  minimum_order_qty int, ' +
    '  cost_price decimal(10,2), ' +
    '  is_preferred bit DEFAULT 0, ' +
    '  FOREIGN KEY (product_id) REFERENCES products(id), ' +
    '  FOREIGN KEY (supplier_id) REFERENCES suppliers(id), ' +
    '  UNIQUE(product_id, supplier_id) ' +
    ')'
  );

  // Insert sample categories
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM categories WHERE name = ''Electronics'') ' +
    'INSERT INTO categories (name, description) VALUES ' +
    '(''Electronics'', ''Electronic devices and accessories''), ' +
    '(''Computers'', ''Desktop and laptop computers''), ' +
    '(''Mobile Devices'', ''Smartphones and tablets''), ' +
    '(''Audio'', ''Headphones, speakers, and audio equipment''), ' +
    '(''Gaming'', ''Gaming consoles and accessories''), ' +
    '(''Home & Garden'', ''Home improvement and garden supplies''), ' +
    '(''Books'', ''Physical and digital books''), ' +
    '(''Clothing'', ''Men and women clothing''), ' +
    '(''Sports'', ''Sports equipment and apparel''), ' +
    '(''Office Supplies'', ''Office furniture and supplies'')'
  );

  // Insert sample suppliers
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM suppliers WHERE company_name = ''Tech Solutions Inc'') ' +
    'INSERT INTO suppliers (company_name, contact_name, email, phone, address, city, state, country, rating) VALUES ' +
    '(''Tech Solutions Inc'', ''John Smith'', ''john@techsolutions.com'', ''555-0101'', ''123 Tech Ave'', ''San Francisco'', ''CA'', ''USA'', 4.8), ' +
    '(''Global Electronics'', ''Sarah Johnson'', ''sarah@globalelec.com'', ''555-0102'', ''456 Circuit Blvd'', ''Austin'', ''TX'', ''USA'', 4.5), ' +
    '(''Mobile World Co'', ''Mike Chen'', ''mike@mobileworld.com'', ''555-0103'', ''789 Wireless St'', ''Seattle'', ''WA'', ''USA'', 4.7), ' +
    '(''Audio Pro Ltd'', ''Emma Davis'', ''emma@audiopro.com'', ''555-0104'', ''321 Sound Ave'', ''Nashville'', ''TN'', ''USA'', 4.6), ' +
    '(''Home Solutions'', ''David Wilson'', ''david@homesol.com'', ''555-0105'', ''654 Home Blvd'', ''Denver'', ''CO'', ''USA'', 4.3)'
  );

  // Insert sample customers
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM customers WHERE email = ''alice.johnson@email.com'') ' +
    'INSERT INTO customers (first_name, last_name, email, phone, address, city, state, zip_code, customer_type, credit_limit) VALUES ' +
    '(''Alice'', ''Johnson'', ''alice.johnson@email.com'', ''555-1001'', ''123 Oak St'', ''Portland'', ''OR'', ''97201'', ''Premium'', 5000.00), ' +
    '(''Bob'', ''Smith'', ''bob.smith@email.com'', ''555-1002'', ''456 Pine Ave'', ''Denver'', ''CO'', ''80202'', ''Regular'', 2000.00), ' +
    '(''Carol'', ''Brown'', ''carol.brown@email.com'', ''555-1003'', ''789 Elm Dr'', ''Seattle'', ''WA'', ''98101'', ''Premium'', 7500.00), ' +
    '(''David'', ''Wilson'', ''david.wilson@email.com'', ''555-1004'', ''321 Maple Ln'', ''Austin'', ''TX'', ''73301'', ''Regular'', 1500.00), ' +
    '(''Emma'', ''Davis'', ''emma.davis@email.com'', ''555-1005'', ''654 Cedar St'', ''Phoenix'', ''AZ'', ''85001'', ''VIP'', 10000.00), ' +
    '(''Frank'', ''Miller'', ''frank.miller@email.com'', ''555-1006'', ''987 Birch Ave'', ''Miami'', ''FL'', ''33101'', ''Regular'', 2500.00), ' +
    '(''Grace'', ''Taylor'', ''grace.taylor@email.com'', ''555-1007'', ''147 Spruce Dr'', ''Chicago'', ''IL'', ''60601'', ''Premium'', 4000.00), ' +
    '(''Henry'', ''Anderson'', ''henry.anderson@email.com'', ''555-1008'', ''258 Willow St'', ''Boston'', ''MA'', ''02101'', ''Regular'', 1800.00), ' +
    '(''Ivy'', ''Thompson'', ''ivy.thompson@email.com'', ''555-1009'', ''369 Poplar Ave'', ''San Diego'', ''CA'', ''92101'', ''Premium'', 6000.00), ' +
    '(''Jack'', ''White'', ''jack.white@email.com'', ''555-1010'', ''741 Ash Dr'', ''Las Vegas'', ''NV'', ''89101'', ''VIP'', 12000.00)'
  );

  // Insert sample products
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM products WHERE product_code = ''LAPTOP-001'') ' +
    'INSERT INTO products (product_code, name, description, category, brand, unit_price, cost_price, stock_quantity, weight) VALUES ' +
    '(''LAPTOP-001'', ''Professional Laptop 15.6"'', ''High-performance laptop for business use'', ''Computers'', ''TechBrand'', 1299.99, 899.99, 25, 2.3), ' +
    '(''PHONE-001'', ''Smartphone Pro Max'', ''Latest flagship smartphone with advanced camera'', ''Mobile Devices'', ''MobileCorp'', 999.99, 699.99, 50, 0.2), ' +
    '(''HDPH-001'', ''Wireless Headphones'', ''Premium noise-cancelling wireless headphones'', ''Audio'', ''SoundTech'', 299.99, 199.99, 75, 0.3), ' +
    '(''MONI-001'', ''4K Monitor 27"'', ''Ultra HD monitor for professional work'', ''Electronics'', ''ViewCorp'', 449.99, 299.99, 30, 5.2), ' +
    '(''KEYB-001'', ''Mechanical Keyboard'', ''RGB gaming mechanical keyboard'', ''Gaming'', ''GameGear'', 129.99, 79.99, 100, 1.1), ' +
    '(''MOUS-001'', ''Gaming Mouse'', ''High-precision gaming mouse with RGB lighting'', ''Gaming'', ''GameGear'', 79.99, 49.99, 150, 0.1), ' +
    '(''TABL-001'', ''Tablet 10.9"'', ''Versatile tablet for work and entertainment'', ''Mobile Devices'', ''TechBrand'', 599.99, 399.99, 40, 0.5), ' +
    '(''SPKR-001'', ''Bluetooth Speaker'', ''Portable wireless speaker with deep bass'', ''Audio'', ''SoundTech'', 99.99, 59.99, 80, 0.8), ' +
    '(''CHRG-001'', ''Wireless Charger'', ''Fast wireless charging pad'', ''Electronics'', ''PowerTech'', 49.99, 29.99, 200, 0.3), ' +
    '(''CASE-001'', ''Laptop Bag'', ''Protective laptop carrying case'', ''Office Supplies'', ''CarryPro'', 39.99, 24.99, 120, 0.6)'
  );

  // Insert sample orders
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM orders WHERE order_number = ''ORD-2024-001'') ' +
    'INSERT INTO orders (order_number, customer_id, order_date, order_status, shipping_address, shipping_city, shipping_state, shipping_zip, shipping_cost, tax_amount, total_amount, payment_method) VALUES ' +
    '(''ORD-2024-001'', 1, ''2024-01-15'', ''Delivered'', ''123 Oak St'', ''Portland'', ''OR'', ''97201'', 15.99, 104.00, 1419.98, ''Credit Card''), ' +
    '(''ORD-2024-002'', 2, ''2024-01-20'', ''Shipped'', ''456 Pine Ave'', ''Denver'', ''CO'', ''80202'', 12.99, 76.00, 1088.98, ''PayPal''), ' +
    '(''ORD-2024-003'', 3, ''2024-02-01'', ''Processing'', ''789 Elm Dr'', ''Seattle'', ''WA'', ''98101'', 19.99, 32.00, 379.98, ''Credit Card''), ' +
    '(''ORD-2024-004'', 4, ''2024-02-10'', ''Delivered'', ''321 Maple Ln'', ''Austin'', ''TX'', ''73301'', 8.99, 42.00, 579.98, ''Debit Card''), ' +
    '(''ORD-2024-005'', 5, ''2024-02-15'', ''Pending'', ''654 Cedar St'', ''Phoenix'', ''AZ'', ''85001'', 25.99, 156.00, 2081.98, ''Credit Card'')'
  );

  // Insert sample order items
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM order_items WHERE order_id = 1 AND product_id = 1) ' +
    'INSERT INTO order_items (order_id, product_id, quantity, unit_price, line_total) VALUES ' +
    '(1, 1, 1, 1299.99, 1299.99), ' +   // Order 1: Laptop
    '(1, 10, 1, 39.99, 39.99), ' +       // Order 1: Laptop Bag
    '(2, 2, 1, 999.99, 999.99), ' +      // Order 2: Phone
    '(3, 3, 1, 299.99, 299.99), ' +      // Order 3: Headphones
    '(3, 8, 1, 99.99, 99.99), ' +        // Order 3: Speaker
    '(4, 4, 1, 449.99, 449.99), ' +      // Order 4: Monitor
    '(4, 5, 1, 129.99, 129.99), ' +      // Order 4: Keyboard
    '(5, 7, 2, 599.99, 1199.98), ' +     // Order 5: 2x Tablets
    '(5, 9, 3, 49.99, 149.97), ' +       // Order 5: 3x Wireless Chargers
    '(5, 6, 4, 79.99, 319.96)'           // Order 5: 4x Gaming Mice
  );

  // Insert sample product-supplier relationships
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM product_suppliers WHERE product_id = 1 AND supplier_id = 1) ' +
    'INSERT INTO product_suppliers (product_id, supplier_id, supplier_product_code, lead_time_days, minimum_order_qty, cost_price, is_preferred) VALUES ' +
    '(1, 1, ''TS-LAPTOP-001'', 7, 5, 899.99, 1), ' +
    '(2, 3, ''MW-PHONE-001'', 14, 10, 699.99, 1), ' +
    '(3, 4, ''AP-HDPH-001'', 5, 20, 199.99, 1), ' +
    '(4, 2, ''GE-MONI-001'', 10, 3, 299.99, 1), ' +
    '(5, 1, ''TS-KEYB-001'', 7, 25, 79.99, 1), ' +
    '(6, 1, ''TS-MOUS-001'', 7, 50, 49.99, 1), ' +
    '(7, 3, ''MW-TABL-001'', 12, 8, 399.99, 1), ' +
    '(8, 4, ''AP-SPKR-001'', 5, 30, 59.99, 1), ' +
    '(9, 2, ''GE-CHRG-001'', 14, 100, 29.99, 1), ' +
    '(10, 5, ''HS-CASE-001'', 3, 50, 24.99, 1)'
  );

  // Create materialized reporting tables instead of views

  // Customer Orders Summary Table
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''customer_order_summary'' AND xtype=''U'') ' +
    'CREATE TABLE customer_order_summary (' +
    '  id int IDENTITY(1,1) PRIMARY KEY, ' +
    '  customer_id int NOT NULL, ' +
    '  customer_name nvarchar(100) NOT NULL, ' +
    '  email nvarchar(100), ' +
    '  order_id int NOT NULL, ' +
    '  order_number nvarchar(20), ' +
    '  order_date datetime2, ' +
    '  order_status nvarchar(20), ' +
    '  total_amount decimal(10,2), ' +
    '  last_updated datetime2 DEFAULT GETDATE(), ' +
    '  FOREIGN KEY (customer_id) REFERENCES customers(id), ' +
    '  FOREIGN KEY (order_id) REFERENCES orders(id) ' +
    ')'
  );

  // Product Inventory Status Table
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''product_inventory_status'' AND xtype=''U'') ' +
    'CREATE TABLE product_inventory_status (' +
    '  id int IDENTITY(1,1) PRIMARY KEY, ' +
    '  product_id int NOT NULL, ' +
    '  product_code nvarchar(20), ' +
    '  product_name nvarchar(100), ' +
    '  category nvarchar(50), ' +
    '  brand nvarchar(50), ' +
    '  unit_price decimal(10,2), ' +
    '  stock_quantity int, ' +
    '  min_stock_level int, ' +
    '  stock_status nvarchar(20), ' +
    '  reorder_needed bit, ' +
    '  days_of_stock int, ' +
    '  last_updated datetime2 DEFAULT GETDATE(), ' +
    '  FOREIGN KEY (product_id) REFERENCES products(id) ' +
    ')'
  );

  // Order Details Extended Table
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''order_details_extended'' AND xtype=''U'') ' +
    'CREATE TABLE order_details_extended (' +
    '  id int IDENTITY(1,1) PRIMARY KEY, ' +
    '  order_id int NOT NULL, ' +
    '  order_number nvarchar(20), ' +
    '  order_date datetime2, ' +
    '  order_status nvarchar(20), ' +
    '  customer_id int, ' +
    '  customer_name nvarchar(100), ' +
    '  product_id int, ' +
    '  product_name nvarchar(100), ' +
    '  category nvarchar(50), ' +
    '  quantity int, ' +
    '  unit_price decimal(10,2), ' +
    '  line_total decimal(10,2), ' +
    '  profit_margin decimal(5,2), ' +
    '  last_updated datetime2 DEFAULT GETDATE(), ' +
    '  FOREIGN KEY (order_id) REFERENCES orders(id), ' +
    '  FOREIGN KEY (customer_id) REFERENCES customers(id), ' +
    '  FOREIGN KEY (product_id) REFERENCES products(id) ' +
    ')'
  );

  // Sales Analytics Table
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''sales_analytics'' AND xtype=''U'') ' +
    'CREATE TABLE sales_analytics (' +
    '  id int IDENTITY(1,1) PRIMARY KEY, ' +
    '  report_date date NOT NULL, ' +
    '  total_orders int, ' +
    '  total_sales decimal(12,2), ' +
    '  avg_order_value decimal(10,2), ' +
    '  unique_customers int, ' +
    '  top_product_id int, ' +
    '  top_product_sales decimal(10,2), ' +
    '  top_category nvarchar(50), ' +
    '  top_category_sales decimal(10,2), ' +
    '  created_at datetime2 DEFAULT GETDATE() ' +
    ')'
  );

  // Customer Analytics Table
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''customer_analytics'' AND xtype=''U'') ' +
    'CREATE TABLE customer_analytics (' +
    '  id int IDENTITY(1,1) PRIMARY KEY, ' +
    '  customer_id int NOT NULL, ' +
    '  total_orders int DEFAULT 0, ' +
    '  total_spent decimal(12,2) DEFAULT 0, ' +
    '  avg_order_value decimal(10,2) DEFAULT 0, ' +
    '  first_order_date datetime2, ' +
    '  last_order_date datetime2, ' +
    '  customer_lifetime_days int, ' +
    '  preferred_category nvarchar(50), ' +
    '  customer_segment nvarchar(20), ' +
    '  last_updated datetime2 DEFAULT GETDATE(), ' +
    '  FOREIGN KEY (customer_id) REFERENCES customers(id) ' +
    ')'
  );

  // Product Performance Table
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM sysobjects WHERE name=''product_performance'' AND xtype=''U'') ' +
    'CREATE TABLE product_performance (' +
    '  id int IDENTITY(1,1) PRIMARY KEY, ' +
    '  product_id int NOT NULL, ' +
    '  total_quantity_sold int DEFAULT 0, ' +
    '  total_revenue decimal(12,2) DEFAULT 0, ' +
    '  total_profit decimal(12,2) DEFAULT 0, ' +
    '  avg_selling_price decimal(10,2), ' +
    '  times_ordered int DEFAULT 0, ' +
    '  popularity_rank int, ' +
    '  profit_margin_percent decimal(5,2), ' +
    '  last_sale_date datetime2, ' +
    '  performance_category nvarchar(20), ' +
    '  last_updated datetime2 DEFAULT GETDATE(), ' +
    '  FOREIGN KEY (product_id) REFERENCES products(id) ' +
    ')'
  );

  // Now populate these reporting tables with data

  // Populate customer_order_summary
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM customer_order_summary) ' +
    'INSERT INTO customer_order_summary (customer_id, customer_name, email, order_id, order_number, order_date, order_status, total_amount) ' +
    'SELECT ' +
    '  c.id, ' +
    '  c.first_name + '' '' + c.last_name, ' +
    '  c.email, ' +
    '  o.id, ' +
    '  o.order_number, ' +
    '  o.order_date, ' +
    '  o.order_status, ' +
    '  o.total_amount ' +
    'FROM customers c ' +
    'INNER JOIN orders o ON c.id = o.customer_id'
  );

  // Populate product_inventory_status
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM product_inventory_status) ' +
    'INSERT INTO product_inventory_status (product_id, product_code, product_name, category, brand, unit_price, stock_quantity, min_stock_level, stock_status, reorder_needed, days_of_stock) ' +
    'SELECT ' +
    '  p.id, ' +
    '  p.product_code, ' +
    '  p.name, ' +
    '  p.category, ' +
    '  p.brand, ' +
    '  p.unit_price, ' +
    '  p.stock_quantity, ' +
    '  p.min_stock_level, ' +
    '  CASE ' +
    '    WHEN p.stock_quantity = 0 THEN ''Out of Stock'' ' +
    '    WHEN p.stock_quantity <= p.min_stock_level THEN ''Low Stock'' ' +
    '    WHEN p.stock_quantity <= (p.min_stock_level * 2) THEN ''Medium Stock'' ' +
    '    ELSE ''In Stock'' ' +
    '  END, ' +
    '  CASE WHEN p.stock_quantity <= p.min_stock_level THEN 1 ELSE 0 END, ' +
    '  CASE WHEN p.stock_quantity > 0 THEN p.stock_quantity / GREATEST(p.min_stock_level, 1) ELSE 0 END ' +
    'FROM products p ' +
    'WHERE p.is_active = 1'
  );

  // Populate order_details_extended
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM order_details_extended) ' +
    'INSERT INTO order_details_extended (order_id, order_number, order_date, order_status, customer_id, customer_name, product_id, product_name, category, quantity, unit_price, line_total, profit_margin) ' +
    'SELECT ' +
    '  o.id, ' +
    '  o.order_number, ' +
    '  o.order_date, ' +
    '  o.order_status, ' +
    '  c.id, ' +
    '  c.first_name + '' '' + c.last_name, ' +
    '  oi.product_id, ' +
    '  p.name, ' +
    '  p.category, ' +
    '  oi.quantity, ' +
    '  oi.unit_price, ' +
    '  oi.line_total, ' +
    '  CASE WHEN p.cost_price > 0 THEN ((oi.unit_price - p.cost_price) / oi.unit_price) * 100 ELSE 0 END ' +
    'FROM orders o ' +
    'INNER JOIN customers c ON o.customer_id = c.id ' +
    'INNER JOIN order_items oi ON o.id = oi.order_id ' +
    'INNER JOIN products p ON oi.product_id = p.id'
  );

  // Populate customer_analytics
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM customer_analytics) ' +
    'INSERT INTO customer_analytics (customer_id, total_orders, total_spent, avg_order_value, first_order_date, last_order_date, customer_lifetime_days, customer_segment) ' +
    'SELECT ' +
    '  c.id, ' +
    '  COUNT(o.id), ' +
    '  SUM(o.total_amount), ' +
    '  AVG(o.total_amount), ' +
    '  MIN(o.order_date), ' +
    '  MAX(o.order_date), ' +
    '  DATEDIFF(day, MIN(o.order_date), MAX(o.order_date)), ' +
    '  CASE ' +
    '    WHEN SUM(o.total_amount) >= 5000 THEN ''VIP'' ' +
    '    WHEN SUM(o.total_amount) >= 2000 THEN ''Premium'' ' +
    '    WHEN COUNT(o.id) >= 3 THEN ''Loyal'' ' +
    '    ELSE ''Regular'' ' +
    '  END ' +
    'FROM customers c ' +
    'LEFT JOIN orders o ON c.id = o.customer_id ' +
    'GROUP BY c.id'
  );

  // Populate product_performance
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM product_performance) ' +
    'INSERT INTO product_performance (product_id, total_quantity_sold, total_revenue, total_profit, avg_selling_price, times_ordered, profit_margin_percent, last_sale_date, performance_category) ' +
    'SELECT ' +
    '  p.id, ' +
    '  COALESCE(SUM(oi.quantity), 0), ' +
    '  COALESCE(SUM(oi.line_total), 0), ' +
    '  COALESCE(SUM((oi.unit_price - p.cost_price) * oi.quantity), 0), ' +
    '  COALESCE(AVG(oi.unit_price), p.unit_price), ' +
    '  COUNT(oi.id), ' +
    '  CASE WHEN p.cost_price > 0 THEN ((p.unit_price - p.cost_price) / p.unit_price) * 100 ELSE 0 END, ' +
    '  MAX(o.order_date), ' +
    '  CASE ' +
    '    WHEN COALESCE(SUM(oi.line_total), 0) >= 2000 THEN ''Top Seller'' ' +
    '    WHEN COALESCE(SUM(oi.line_total), 0) >= 1000 THEN ''Good Performer'' ' +
    '    WHEN COALESCE(SUM(oi.line_total), 0) > 0 THEN ''Moderate Seller'' ' +
    '    ELSE ''No Sales'' ' +
    '  END ' +
    'FROM products p ' +
    'LEFT JOIN order_items oi ON p.id = oi.product_id ' +
    'LEFT JOIN orders o ON oi.order_id = o.id ' +
    'WHERE p.is_active = 1 ' +
    'GROUP BY p.id, p.unit_price, p.cost_price'
  );

  // Populate sales_analytics with sample daily data
  Connection.ExecSQL(
    'IF NOT EXISTS (SELECT * FROM sales_analytics) ' +
    'INSERT INTO sales_analytics (report_date, total_orders, total_sales, avg_order_value, unique_customers, top_category) ' +
    'SELECT ' +
    '  CONVERT(date, o.order_date), ' +
    '  COUNT(*), ' +
    '  SUM(o.total_amount), ' +
    '  AVG(o.total_amount), ' +
    '  COUNT(DISTINCT o.customer_id), ' +
    '  ''Electronics'' ' +
    'FROM orders o ' +
    'GROUP BY CONVERT(date, o.order_date)'
  );
end;

end.
