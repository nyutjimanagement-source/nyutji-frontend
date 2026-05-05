/**
 * NYUTJI DATABASE MIGRATION SCRIPT
 * Deskripsi: Menambahkan kolom address dan pickup_note ke tabel orders
 */

const { Client } = require('pg');

// GANTI dengan detail koneksi database server Anda (sesuaikan dengan env server)
const dbConfig = {
  connectionString: process.env.DATABASE_URL || "postgres://postgres:password@localhost:5432/nyutji" 
};

const client = new Client(dbConfig);

async function runMigration() {
  console.log("--- Memulai Migrasi Database Nyutji ---");
  try {
    await client.connect();
    console.log("✅ Terhubung ke Database.");

    const sql = `
      ALTER TABLE orders ADD COLUMN IF NOT EXISTS address TEXT;
      ALTER TABLE orders ADD COLUMN IF NOT EXISTS pickup_note TEXT;
    `;

    await client.query(sql);
    console.log("✅ Migrasi Berhasil: Kolom 'address' dan 'pickup_note' telah ditambahkan.");
    
  } catch (err) {
    console.error("❌ Migrasi Gagal:", err.message);
  } finally {
    await client.end();
    console.log("--- Selesai ---");
  }
}

runMigration();
