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
app.use(cors({
  origin: true, // Allow all origins in development (localhost:3000, localhost:3001, localhost:5173, mobile, etc.)
  credentials: true,
  allowedHeaders: ['Content-Type', 'Authorization'],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
}));
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
  console.log(`📋 Registered routes: /api/auth/login, /api/auth/register, /api/auth/me, /api/products, /api/orders, /api/stocks, /api/finance/*, /api/ai/*, /api/dashboard/overview`);
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
