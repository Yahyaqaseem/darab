import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { Pool, QueryResult, QueryResultRow } from 'pg';

@Injectable()
export class DatabaseService implements OnModuleInit, OnModuleDestroy {
  private pool: Pool;
  private readonly logger = new Logger(DatabaseService.name);
  private isConnected = false;

  constructor() {
    this.pool = new Pool({
      host: process.env.DATABASE_HOST || 'localhost',
      port: parseInt(process.env.DATABASE_PORT || '5432', 10),
      user: process.env.DATABASE_USER || 'darb_admin',
      password: process.env.DATABASE_PASSWORD || 'darb_secret_password_2026',
      database: process.env.DATABASE_NAME || 'darb_db',
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    });
  }

  async onModuleInit() {
    this.checkConnection();
  }

  private async checkConnection() {
    try {
      const client = await this.pool.connect();
      const res = await client.query('SELECT PostGIS_Version()');
      this.logger.log(`🐘 Connected to PostgreSQL + PostGIS: ${res.rows[0].postgis_version}`);
      client.release();
      this.isConnected = true;
    } catch (err: any) {
      this.logger.warn(`⚠️ Database connection not ready yet (${err.message}). Operating in resilient memory mode.`);
      this.isConnected = false;
    }
  }

  async onModuleDestroy() {
    await this.pool.end();
  }

  get isDbConnected(): boolean {
    return this.isConnected;
  }

  async query<T extends QueryResultRow = any>(text: string, params?: any[]): Promise<QueryResult<T>> {
    const start = Date.now();
    try {
      const res = await this.pool.query<T>(text, params);
      const duration = Date.now() - start;
      if (duration > 500) {
        this.logger.warn(`Slow query (${duration}ms): ${text.substring(0, 100)}...`);
      }
      return res;
    } catch (error: any) {
      this.logger.error(`Database Query Error: ${error.message} - Query: ${text}`);
      throw error;
    }
  }
}
