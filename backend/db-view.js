const sqlite3 = require('sqlite3').verbose();

// Connect to database
const db = new sqlite3.Database('./database.db', (err) => {
    if (err) {
        console.error('Error connecting to database:', err);
        return;
    }
    console.log('Connected to database');
    
    // View all users
    db.all(`SELECT id, name, email, role, created_at FROM users`, [], (err, rows) => {
        if (err) {
            console.error('Error:', err);
            return;
        }
        console.log('\nUsers in database:');
        console.table(rows);
        
        // Close database connection
        db.close((err) => {
            if (err) {
                console.error('Error closing database:', err);
                return;
            }
            console.log('Database connection closed');
        });
    });
});
