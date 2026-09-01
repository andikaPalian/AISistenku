import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import router from './routes/index.js';
import { errorHandler } from './middleware/errorHandler.js';
import { pingSupabase, getConnectionStatus } from './lib/supabase.js';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api', router);

// Health check — reports DB status so frontend / monitoring can detect issues
app.get('/health', async (_req, res) => {
  const dbStatus = getConnectionStatus();
  res.json({
    status: dbStatus === 'initialized' ? 'ok' : 'degraded',
    database: dbStatus,
    timestamp: new Date().toISOString(),
  });
});

// 404 Handler
app.use((_req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Centralized Error Handler
app.use(errorHandler);

app.listen(PORT, async () => {
  console.log(`🚀 Tiga Angkatan Backend Server running on http://localhost:${PORT}`);
  // Fail-fast: verify Supabase is reachable before serving requests
  const ping = await pingSupabase();
  if (ping.ok) {
    console.log('✅ Supabase connection verified');
  } else {
    console.warn(`⚠️  Supabase ping failed: ${ping.reason}${ping.error ? ' — ' + ping.error : ''}`);
    console.warn('   Server is running but database queries will fail until this is resolved.');
  }
});

export default app;
