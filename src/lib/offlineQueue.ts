/**
 * Offline Queue System
 * Manages pending operations when device is offline
 * Syncs automatically when connection restored
 */

class OfflineQueue {
  private dbName = 'BusNStay_Offline';
  private version = 1;
  private db: IDBDatabase | null = null;
  private syncInProgress = false;

  /**
   * Initialize IndexedDB database
   */
  async init(): Promise<void> {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, this.version);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve();
      };

      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;

        // Store for pending operations
        if (!db.objectStoreNames.contains('queue')) {
          const queueStore = db.createObjectStore('queue', { keyPath: 'id' });
          queueStore.createIndex('device_id', 'device_id', { unique: false });
          queueStore.createIndex('sequence', 'sequence_number', { unique: false });
          queueStore.createIndex('processed', 'processed', { unique: false });
        }

        // Store for location updates
        if (!db.objectStoreNames.contains('locations')) {
          db.createObjectStore('locations', { keyPath: 'id' });
        }

        // Store for pending orders
        if (!db.objectStoreNames.contains('pending_orders')) {
          db.createObjectStore('pending_orders', { keyPath: 'offline_id' });
        }

        // Store for sync metadata
        if (!db.objectStoreNames.contains('sync_meta')) {
          db.createObjectStore('sync_meta', { keyPath: 'key' });
        }
      };
    });
  }

  /**
   * Add operation to queue
   */
  async enqueue(
    deviceId: string,
    action: string,
    payload: any,
    journeyId?: string
  ): Promise<string> {
    if (!this.db) throw new Error('Database not initialized');

    const sequence = await this.getNextSequence(deviceId);
    const id = this.generateId();

    const item = {
      id,
      device_id: deviceId,
      journey_id: journeyId,
      action,
      payload,
      sequence_number: sequence,
      processed: false,
      attempted_count: 0,
      created_at: new Date().toISOString(),
    };

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(['queue'], 'readwrite');
      const store = tx.objectStore('queue');
      const request = store.add(item);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(id);
    });
  }

  /**
   * Get all pending operations
   */
  async getPending(deviceId: string): Promise<any[]> {
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(['queue'], 'readonly');
      const store = tx.objectStore('queue');
      const index = store.index('device_id');
      const request = index.getAll(deviceId);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        const items = request.result as any[];
        resolve(items.filter((item) => !item.processed).sort((a, b) => a.sequence_number - b.sequence_number));
      };
    });
  }

  /**
   * Mark operation as processed
   */
  async markProcessed(id: string, errorMessage?: string): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(['queue'], 'readwrite');
      const store = tx.objectStore('queue');
      const request = store.get(id);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        const item = request.result;
        item.processed = true;
        item.processed_at = new Date().toISOString();
        if (errorMessage) item.error_message = errorMessage;

        const updateRequest = store.put(item);
        updateRequest.onerror = () => reject(updateRequest.error);
        updateRequest.onsuccess = () => resolve();
      };
    });
  }

  /**
   * Increment retry count
   */
  async incrementRetry(id: string): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(['queue'], 'readwrite');
      const store = tx.objectStore('queue');
      const request = store.get(id);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        const item = request.result;
        item.attempted_count = (item.attempted_count || 0) + 1;

        const updateRequest = store.put(item);
        updateRequest.onerror = () => reject(updateRequest.error);
        updateRequest.onsuccess = () => resolve();
      };
    });
  }

  /**
   * Store location offline
   */
  async storeLocation(
    journeyId: string,
    latitude: number,
    longitude: number,
    accuracy: number
  ): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');

    const location = {
      id: this.generateId(),
      journey_id: journeyId,
      latitude,
      longitude,
      accuracy,
      source: 'OFFLINE_CACHE',
      created_at: new Date().toISOString(),
      synced: false,
    };

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(['locations'], 'readwrite');
      const store = tx.objectStore('locations');
      const request = store.add(location);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve();
    });
  }

  /**
   * Get unsynced locations
   */
  async getUnsyncedLocations(journeyId: string): Promise<any[]> {
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(['locations'], 'readonly');
      const store = tx.objectStore('locations');
      const request = store.getAll();

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        const locations = request.result as any[];
        resolve(
          locations
            .filter((loc) => loc.journey_id === journeyId && !loc.synced)
            .sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime())
        );
      };
    });
  }

  /**
   * Mark locations as synced
   */
  async markLocationsSynced(locationIds: string[]): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(['locations'], 'readwrite');
      const store = tx.objectStore('locations');

      locationIds.forEach((id) => {
        const getRequest = store.get(id);
        getRequest.onsuccess = () => {
          const location = getRequest.result;
          location.synced = true;
          store.put(location);
        };
      });

      tx.onerror = () => reject(tx.error);
      tx.oncomplete = () => resolve();
    });
  }

  /**
   * Store pending order for offline creation
   */
  async storePendingOrder(offlineId: string, orderData: any): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');

    const order = {
      offline_id: offlineId,
      ...orderData,
      created_at: new Date().toISOString(),
      synced: false,
    };

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(['pending_orders'], 'readwrite');
      const store = tx.objectStore('pending_orders');
      const request = store.add(order);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve();
    });
  }

  /**
   * Get pending orders for journey
   */
  async getPendingOrders(journeyId: string): Promise<any[]> {
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(['pending_orders'], 'readonly');
      const store = tx.objectStore('pending_orders');
      const request = store.getAll();

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        const orders = request.result as any[];
        resolve(orders.filter((o) => o.journey_id === journeyId && !o.synced));
      };
    });
  }

  /**
   * Mark order as synced
   */
  async markOrderSynced(offlineId: string, serverId: string): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(['pending_orders'], 'readwrite');
      const store = tx.objectStore('pending_orders');
      const request = store.get(offlineId);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        const order = request.result;
        order.synced = true;
        order.server_id = serverId;
        order.synced_at = new Date().toISOString();

        const updateRequest = store.put(order);
        updateRequest.onerror = () => reject(updateRequest.error);
        updateRequest.onsuccess = () => resolve();
      };
    });
  }

  /**
   * Get sync metadata
   */
  async getSyncMeta(key: string): Promise<any> {
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(['sync_meta'], 'readonly');
      const store = tx.objectStore('sync_meta');
      const request = store.get(key);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result);
    });
  }

  /**
   * Set sync metadata
   */
  async setSyncMeta(key: string, value: any): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(['sync_meta'], 'readwrite');
      const store = tx.objectStore('sync_meta');
      const request = store.put({ key, value, updated_at: new Date().toISOString() });

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve();
    });
  }

  /**
   * Get queue statistics
   */
  async getQueueStats(deviceId: string): Promise<{
    total: number;
    pending: number;
    processed: number;
  }> {
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(['queue'], 'readonly');
      const store = tx.objectStore('queue');
      const index = store.index('device_id');
      const request = index.getAll(deviceId);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        const items = request.result as any[];
        resolve({
          total: items.length,
          pending: items.filter((i) => !i.processed).length,
          processed: items.filter((i) => i.processed).length,
        });
      };
    });
  }

  /**
   * Clear old synced items (older than 7 days)
   */
  async cleanOldData(daysToKeep: number = 7): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');

    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);

    return new Promise((resolve, reject) => {
      const tx = this.db!.transaction(['queue', 'locations'], 'readwrite');

      // Clean queue
      const queueStore = tx.objectStore('queue');
      const queueRequest = queueStore.getAllKeys();
      queueRequest.onsuccess = () => {
        const keys = queueRequest.result;
        keys.forEach((key) => {
          const getRequest = queueStore.get(key);
          getRequest.onsuccess = () => {
            const item = getRequest.result;
            if (
              item.processed &&
              new Date(item.processed_at) < cutoffDate
            ) {
              queueStore.delete(key);
            }
          };
        });
      };

      // Clean locations
      const locationStore = tx.objectStore('locations');
      const locationRequest = locationStore.getAllKeys();
      locationRequest.onsuccess = () => {
        const keys = locationRequest.result;
        keys.forEach((key) => {
          const getRequest = locationStore.get(key);
          getRequest.onsuccess = () => {
            const item = getRequest.result;
            if (
              item.synced &&
              new Date(item.created_at) < cutoffDate
            ) {
              locationStore.delete(key);
            }
          };
        });
      };

      tx.onerror = () => reject(tx.error);
      tx.oncomplete = () => resolve();
    });
  }

  // ==================== PRIVATE METHODS ====================

  private async getNextSequence(deviceId: string): Promise<number> {
    const meta = await this.getSyncMeta(`sequence_${deviceId}`);
    const current = meta?.value || 0;
    await this.setSyncMeta(`sequence_${deviceId}`, current + 1);
    return current + 1;
  }

  private generateId(): string {
    return `${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

// Export singleton instance
export const offlineQueue = new OfflineQueue();
