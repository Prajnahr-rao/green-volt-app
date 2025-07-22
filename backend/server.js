const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const bcrypt = require('bcrypt');

const app = express();
const port = 3000;

// CORS configuration
app.use(cors({
  origin: true, // Allow all origins
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Accept'],
  credentials: true,
  preflightContinue: false,
  optionsSuccessStatus: 204
}));

// Handle preflight requests
app.options('*', cors());

app.use(express.json({ limit: '50mb' }));  // Increase JSON payload limit
app.use(express.urlencoded({ limit: '50mb', extended: true }));  // Increase URL-encoded payload limit

// Connect to SQLite database
const db = new sqlite3.Database('./database.db', (err) => {
  if (err) {
    console.error('Error connecting to database:', err);
  } else {
    console.log('Connected to SQLite database');
    // Create tables if they don't exist
    createTables();
  }
});

// Create tables
function createTables() {
  // Drop existing tables if they exist
  db.run('DROP TABLE IF EXISTS users', (err) => {
    if (err) {
      console.error('Error dropping users table:', err);
      return;
    }
    
    // Create new users table with all required fields
    db.run(`
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'User',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `, (err) => {
      if (err) {
        console.error('Error creating users table:', err);
      } else {
        console.log('Users table created successfully');
      }
    });
  });

  // Create products table
  db.run('DROP TABLE IF EXISTS products', (err) => {
    if (err) {
      console.error('Error dropping products table:', err);
      return;
    }

    db.run(`
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        stock_quantity INTEGER NOT NULL,
        image_url TEXT,
        category TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `, (err) => {
      if (err) {
        console.error('Error creating products table:', err);
      } else {
        console.log('Products table created successfully');
      }
    });
  });

  // Create services table
  db.run('DROP TABLE IF EXISTS services', (err) => {
    if (err) {
      console.error('Error dropping services table:', err);
      return;
    }

    db.run(`
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        image_url TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `, (err) => {
      if (err) {
        console.error('Error creating services table:', err);
      } else {
        console.log('Services table created successfully');
      }
    });
  });

  // Create locations table
  db.run('DROP TABLE IF EXISTS locations', (err) => {
    if (err) {
      console.error('Error dropping locations table:', err);
      return;
    }

    db.run(`
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        address TEXT NOT NULL,
        country TEXT NOT NULL,
        city TEXT NOT NULL,
        state TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `, (err) => {
      if (err) {
        console.error('Error creating locations table:', err);
      } else {
        console.log('Locations table created successfully');
      }
    });
  });
}

// Register new user
app.post('/register', async (req, res) => {
  try {
    const { name, email, password, role } = req.body;
    
    // Input validation
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email and password are required' });
    }

    // Email format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }

    // Hash password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Check if user already exists
    db.get('SELECT id FROM users WHERE email = ?', [email], (err, user) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      if (user) {
        return res.status(400).json({ error: 'Email already registered' });
      }

      // Insert new user
      const userRole = role || 'User'; // Default to 'User' if role not specified
      db.run(
        'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
        [name, email, hashedPassword, userRole],
        function(err) {
          if (err) {
            return res.status(500).json({ error: err.message });
          }
          res.json({
            id: this.lastID,
            message: 'Registration successful'
          });
        }
      );
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all users (excluding passwords)
app.get('/users', (req, res) => {
  db.all('SELECT id, name, email, role, created_at FROM users', [], (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(rows);
  });
});

// Login endpoint
app.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Input validation
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Get user from database
    db.get('SELECT * FROM users WHERE email = ?', [email], async (err, user) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      if (!user) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      // Compare password
      const match = await bcrypt.compare(password, user.password);
      if (!match) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      // Return user data (excluding password)
      res.json({
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        created_at: user.created_at
      });
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Product Management Routes
app.get('/products', (req, res) => {
  db.all('SELECT * FROM products', [], (err, rows) => {
    if (err) {
      console.error('Error fetching products:', err);
      return res.status(500).json({ error: 'Failed to fetch products' });
    }
    res.json(rows.map(row => ({
      id: row.id.toString(),
      name: row.name,
      description: row.description,
      price: row.price,
      stockQuantity: row.stock_quantity,
      imageUrl: row.image_url,
      category: row.category
    })));
  });
});

app.post('/products', (req, res) => {
  const { name, description, price, stockQuantity, imageUrl, category } = req.body;
  
  if (!name || !price || !category) {
    return res.status(400).json({ error: 'Name, price, and category are required' });
  }

  const sql = `
    INSERT INTO products (name, description, price, stock_quantity, image_url, category)
    VALUES (?, ?, ?, ?, ?, ?)
  `;
  
  db.run(sql, [name, description, price, stockQuantity, imageUrl, category], function(err) {
    if (err) {
      console.error('Error adding product:', err);
      return res.status(500).json({ error: 'Failed to add product' });
    }
    
    // Get the newly inserted product
    db.get('SELECT * FROM products WHERE id = ?', [this.lastID], (err, row) => {
      if (err) {
        console.error('Error fetching new product:', err);
        return res.status(500).json({ error: 'Failed to fetch new product' });
      }
      
      res.status(201).json({
        id: row.id.toString(),
        name: row.name,
        description: row.description,
        price: row.price,
        stockQuantity: row.stock_quantity,
        imageUrl: row.image_url,
        category: row.category
      });
    });
  });
});

app.put('/products/:id', (req, res) => {
  const { name, description, price, stockQuantity, imageUrl, category } = req.body;
  const productId = req.params.id;
  
  if (!name || !price || !category) {
    return res.status(400).json({ error: 'Name, price, and category are required' });
  }

  const sql = `
    UPDATE products 
    SET name = ?, description = ?, price = ?, stock_quantity = ?, image_url = ?, category = ?
    WHERE id = ?
  `;
  
  db.run(sql, [name, description, price, stockQuantity, imageUrl, category, productId], function(err) {
    if (err) {
      console.error('Error updating product:', err);
      return res.status(500).json({ error: 'Failed to update product' });
    }
    
    if (this.changes === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }
    
    // Get the updated product
    db.get('SELECT * FROM products WHERE id = ?', [productId], (err, row) => {
      if (err) {
        console.error('Error fetching updated product:', err);
        return res.status(500).json({ error: 'Failed to fetch updated product' });
      }
      
      res.json({
        id: row.id.toString(),
        name: row.name,
        description: row.description,
        price: row.price,
        stockQuantity: row.stock_quantity,
        imageUrl: row.image_url,
        category: row.category
      });
    });
  });
});

app.delete('/products/:id', (req, res) => {
  const productId = req.params.id;
  
  db.run('DELETE FROM products WHERE id = ?', [productId], function(err) {
    if (err) {
      console.error('Error deleting product:', err);
      return res.status(500).json({ error: 'Failed to delete product' });
    }
    
    if (this.changes === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }
    
    res.json({ message: 'Product deleted successfully' });
  });
});

// Service Management Routes
app.get('/services', (req, res) => {
  db.all('SELECT * FROM services', [], (err, rows) => {
    if (err) {
      console.error('Error fetching services:', err);
      return res.status(500).json({ error: 'Failed to fetch services' });
    }
    res.json(rows.map(row => ({
      id: row.id.toString(),
      name: row.name,
      description: row.description,
      price: row.price,
      imageUrl: row.image_url,
      createdAt: row.created_at
    })));
  });
});

app.post('/services', (req, res) => {
  const { name, description, price, imageUrl } = req.body;
  
  if (!name || !price) {
    return res.status(400).json({ error: 'Name and price are required' });
  }

  db.run(
    'INSERT INTO services (name, description, price, image_url) VALUES (?, ?, ?, ?)',
    [name, description, price, imageUrl],
    function(err) {
      if (err) {
        console.error('Error adding service:', err);
        return res.status(500).json({ error: 'Failed to add service' });
      }
      
      db.get('SELECT * FROM services WHERE id = ?', [this.lastID], (err, row) => {
        if (err) {
          console.error('Error fetching added service:', err);
          return res.status(500).json({ error: 'Failed to fetch added service' });
        }
        
        res.status(201).json({
          id: row.id.toString(),
          name: row.name,
          description: row.description,
          price: row.price,
          imageUrl: row.image_url,
          createdAt: row.created_at
        });
      });
    }
  );
});

app.put('/services/:id', (req, res) => {
  const { name, description, price, imageUrl } = req.body;
  const serviceId = req.params.id;
  
  if (!name || !price) {
    return res.status(400).json({ error: 'Name and price are required' });
  }

  db.run(
    'UPDATE services SET name = ?, description = ?, price = ?, image_url = ? WHERE id = ?',
    [name, description, price, imageUrl, serviceId],
    function(err) {
      if (err) {
        console.error('Error updating service:', err);
        return res.status(500).json({ error: 'Failed to update service' });
      }
      
      if (this.changes === 0) {
        return res.status(404).json({ error: 'Service not found' });
      }
      
      db.get('SELECT * FROM services WHERE id = ?', [serviceId], (err, row) => {
        if (err) {
          console.error('Error fetching updated service:', err);
          return res.status(500).json({ error: 'Failed to fetch updated service' });
        }
        
        res.json({
          id: row.id.toString(),
          name: row.name,
          description: row.description,
          price: row.price,
          imageUrl: row.image_url,
          createdAt: row.created_at
        });
      });
    }
  );
});

app.delete('/services/:id', (req, res) => {
  const serviceId = req.params.id;
  
  db.run('DELETE FROM services WHERE id = ?', [serviceId], function(err) {
    if (err) {
      console.error('Error deleting service:', err);
      return res.status(500).json({ error: 'Failed to delete service' });
    }
    
    if (this.changes === 0) {
      return res.status(404).json({ error: 'Service not found' });
    }
    
    res.json({ message: 'Service deleted successfully' });
  });
});

// Location Management Routes
app.get('/locations', (req, res) => {
  db.all('SELECT * FROM locations', [], (err, rows) => {
    if (err) {
      console.error('Error fetching locations:', err);
      return res.status(500).json({ error: 'Failed to fetch locations' });
    }
    res.json(rows.map(row => ({
      id: row.id.toString(),
      address: row.address,
      country: row.country,
      city: row.city,
      state: row.state,
      latitude: row.latitude,
      longitude: row.longitude,
      createdAt: row.created_at
    })));
  });
});

app.post('/locations', (req, res) => {
  const { address, country, city, state, latitude, longitude } = req.body;
  
  if (!address || !country || !city || !state || !latitude || !longitude) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  db.run(
    'INSERT INTO locations (address, country, city, state, latitude, longitude) VALUES (?, ?, ?, ?, ?, ?)',
    [address, country, city, state, latitude, longitude],
    function(err) {
      if (err) {
        console.error('Error adding location:', err);
        return res.status(500).json({ error: 'Failed to add location' });
      }
      
      db.get('SELECT * FROM locations WHERE id = ?', [this.lastID], (err, row) => {
        if (err) {
          console.error('Error fetching added location:', err);
          return res.status(500).json({ error: 'Failed to fetch added location' });
        }
        
        res.status(201).json({
          id: row.id.toString(),
          address: row.address,
          latitude: row.latitude,
          longitude: row.longitude,
          contactNumber: row.contact_number,
          email: row.email,
          createdAt: row.created_at
        });
      });
    }
  );
});

app.put('/locations/:id', (req, res) => {
  const { address, latitude, longitude, contactNumber, email } = req.body;
  const locationId = req.params.id;
  
  if (!address || !latitude || !longitude || !contactNumber || !email) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  db.run(
    'UPDATE locations SET address = ?, latitude = ?, longitude = ?, contact_number = ?, email = ? WHERE id = ?',
    [address, latitude, longitude, contactNumber, email, locationId],
    function(err) {
      if (err) {
        console.error('Error updating location:', err);
        return res.status(500).json({ error: 'Failed to update location' });
      }
      
      if (this.changes === 0) {
        return res.status(404).json({ error: 'Location not found' });
      }
      
      db.get('SELECT * FROM locations WHERE id = ?', [locationId], (err, row) => {
        if (err) {
          console.error('Error fetching updated location:', err);
          return res.status(500).json({ error: 'Failed to fetch updated location' });
        }
        
        res.json({
          id: row.id.toString(),
          address: row.address,
          latitude: row.latitude,
          longitude: row.longitude,
          contactNumber: row.contact_number,
          email: row.email,
          createdAt: row.created_at
        });
      });
    }
  );
});

app.delete('/locations/:id', (req, res) => {
  const locationId = req.params.id;
  
  db.run('DELETE FROM locations WHERE id = ?', [locationId], function(err) {
    if (err) {
      console.error('Error deleting location:', err);
      return res.status(500).json({ error: 'Failed to delete location' });
    }
    
    if (this.changes === 0) {
      return res.status(404).json({ error: 'Location not found' });
    }
    
    res.json({ message: 'Location deleted successfully' });
  });
});

// Update user
app.put('/users/:id', (req, res) => {
  const userId = req.params.id;
  const { name, email, role } = req.body;

  // Input validation
  if (!name || !email || !role) {
    return res.status(400).json({ error: 'Name, email and role are required' });
  }

  // Email format validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ error: 'Invalid email format' });
  }

  // Check if email is already taken by another user
  db.get('SELECT id FROM users WHERE email = ? AND id != ?', [email, userId], (err, user) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    if (user) {
      return res.status(400).json({ error: 'Email already taken by another user' });
    }

    // Update user
    db.run(
      'UPDATE users SET name = ?, email = ?, role = ? WHERE id = ?',
      [name, email, role, userId],
      function(err) {
        if (err) {
          return res.status(500).json({ error: err.message });
        }
        if (this.changes === 0) {
          return res.status(404).json({ error: 'User not found' });
        }

        // Get updated user
        db.get('SELECT id, name, email, role, created_at FROM users WHERE id = ?', [userId], (err, user) => {
          if (err) {
            return res.status(500).json({ error: err.message });
          }
          res.json(user);
        });
      }
    );
  });
});

// Delete user
app.delete('/users/:id', (req, res) => {
  const userId = req.params.id;

  db.run('DELETE FROM users WHERE id = ?', [userId], function(err) {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    if (this.changes === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json({ message: 'User deleted successfully' });
  });
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:3000`);
});
