import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { WorkersController } from './workers.controller';
import { WorkersService } from './workers.service';
import { WorkersRepository } from './workers.repository';
import { WorkersProcessor, WORKERS_QUEUE } from './workers.processor';
import { NotificationsModule } from '../notifications/notifications.module';
import { BidsModule } from '../bids/bids.module';
import { StorageModule } from '../storage/storage.module';

@Module({
  imports: [
    NotificationsModule,
    BidsModule,
    StorageModule,
    BullModule.registerQueue({ name: WORKERS_QUEUE }),
  ],
  controllers: [WorkersController],
  providers: [WorkersService, WorkersRepository, WorkersProcessor],
  exports: [WorkersService],
})
export class WorkersModule {}
