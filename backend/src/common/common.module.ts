import { Global, Module } from '@nestjs/common';
import { InMemoryStore } from './in-memory.store';

/**
 * Global so every feature module shares the same in-memory store instance.
 * When moving to a real DB, this becomes the persistence module.
 */
@Global()
@Module({
  providers: [InMemoryStore],
  exports: [InMemoryStore],
})
export class CommonModule {}
