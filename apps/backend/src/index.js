import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import router from './routes/index.js';
import { errorHandler } from './middleware/errorHandler.js';

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

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 404 Handler
app.use((_req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Centralized Error Handler
app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`🚀 Tiga Angkatan Backend Server running on http://localhost:${PORT}`);
});

export default app;
