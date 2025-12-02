// Run Migration 020: Recalculate Levels and Badges
// Node.js script to run migration directly using pg

const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const db = new Pool({
  connectionString: process.env.DATABASE_URL || 
    'postgresql://ecocheck_admin:ecocheck2025@localhost:5432/ecocheck_olp',
});

async function runMigration() {
  console.log('========================================');
  console.log('Running Migration 020: Recalculate Levels and Badges');
  console.log('========================================');
  console.log('');

  try {
    // Test connection
    await db.query('SELECT 1');
    console.log('✓ Database connection successful');
    console.log('');

    // Read migration file
    const migrationFile = path.join(__dirname, 'migrations', '020_recalculate_levels_badges.sql');
    if (!fs.existsSync(migrationFile)) {
      throw new Error(`Migration file not found: ${migrationFile}`);
    }

    const sql = fs.readFileSync(migrationFile, 'utf8');
    console.log('Running migration: 020_recalculate_levels_badges.sql');
    console.log('');

    // Split by semicolon and execute each statement
    const statements = sql
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--') && s !== 'BEGIN' && s !== 'COMMIT');

    for (const statement of statements) {
      if (statement.trim()) {
        try {
          await db.query(statement);
        } catch (err) {
          // Ignore "already exists" errors for functions
          if (!err.message.includes('already exists')) {
            throw err;
          }
        }
      }
    }

    console.log('');
    console.log('✓ Migration completed successfully!');
    console.log('');
    console.log('What was done:');
    console.log('  - Updated level calculation logic (1-10 levels)');
    console.log('  - Updated trigger to use new level calculation');
    console.log('  - Recalculated levels for all users based on current points');
    console.log('');

  } catch (error) {
    console.error('✗ Migration failed:', error.message);
    process.exit(1);
  } finally {
    await db.end();
  }
}

runMigration();

