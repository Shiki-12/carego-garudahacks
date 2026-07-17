import { SQLDatabase } from "encore.dev/storage/sqldb";

// Define the database instance, Encore will automatically provision PostgreSQL
export const db = new SQLDatabase("carego", {
  migrations: "./migrations",
});
