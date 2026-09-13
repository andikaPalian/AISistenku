import { EventEmitter } from 'node:events';

export interface LowStockItemAlert {
  stockId: string;
  name: string;
  category?: string;
  currentStock: number;
  minStock: number;
  unit: string;
  severity: 'warning' | 'critical';
}

export interface StockLowAlertPayload {
  businessId: string;
  orderCode?: string;
  alerts: LowStockItemAlert[];
  timestamp: string;
}

export interface StockMutatedPayload {
  businessId: string;
  stockId: string;
  stockName: string;
  currentStock: number;
  minStock: number;
  unit: string;
  source: string;
  type: 'IN' | 'OUT';
  quantity: number;
  timestamp: string;
}

class AppEventBus extends EventEmitter {
  emitStockLowAlert(payload: StockLowAlertPayload): boolean {
    return this.emit('stock:low-alert', payload);
  }

  onStockLowAlert(listener: (payload: StockLowAlertPayload) => void): this {
    return this.on('stock:low-alert', listener);
  }

  emitStockMutated(payload: StockMutatedPayload): boolean {
    return this.emit('stock:mutated', payload);
  }

  onStockMutated(listener: (payload: StockMutatedPayload) => void): this {
    return this.on('stock:mutated', listener);
  }
}

export const eventBus = new AppEventBus();
