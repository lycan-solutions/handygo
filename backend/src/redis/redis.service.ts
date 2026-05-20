import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client: Redis | null = null;

  constructor(private readonly configService: ConfigService) {}

  onModuleInit() {
    const url = this.configService.get<string>('redis.url');
    if (!url) {
      this.logger.warn('REDIS_URL not set — Redis features will be unavailable');
      return;
    }
    try {
      this.client = new Redis(url, { lazyConnect: false, enableOfflineQueue: false });
      this.client.on('error', (err) => this.logger.warn(`Redis error: ${err.message}`));
      this.logger.log('Redis client created');
    } catch (err: any) {
      this.logger.warn(`Redis init failed — Redis features will be unavailable: ${err.message}`);
    }
  }

  async onModuleDestroy() {
    if (this.client) await this.client.quit();
  }

  getClient(): Redis | null {
    return this.client;
  }

  async set(key: string, value: string, ttlSeconds?: number): Promise<void> {
    if (!this.client) return;
    if (ttlSeconds) {
      await this.client.set(key, value, 'EX', ttlSeconds);
    } else {
      await this.client.set(key, value);
    }
  }

  async get(key: string): Promise<string | null> {
    if (!this.client) return null;
    return this.client.get(key);
  }

  async del(key: string): Promise<void> {
    if (!this.client) return;
    await this.client.del(key);
  }

  async exists(key: string): Promise<boolean> {
    if (!this.client) return false;
    const count = await this.client.exists(key);
    return count > 0;
  }

  async setJson(
    key: string,
    value: object,
    ttlSeconds?: number,
  ): Promise<void> {
    await this.set(key, JSON.stringify(value), ttlSeconds);
  }

  async getJson<T>(key: string): Promise<T | null> {
    const raw = await this.get(key);
    if (!raw) return null;
    return JSON.parse(raw) as T;
  }
}
