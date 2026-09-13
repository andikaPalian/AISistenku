import { Server as HttpServer } from 'node:http';
import { Server, Socket } from 'socket.io';
import { verifyAccessToken } from '@/utils/jwt.util.js';
import { prisma } from '@/config/database.config.js';
import { logger } from '@/utils/logger.js';
import { eventBus } from './event-bus.js';
import { env } from '@/config/env.config.js';

let ioInstance: Server | null = null;

export const getIO = (): Server | null => ioInstance;

export const initWebSocketGateway = (httpServer: HttpServer): Server => {
  const io = new Server(httpServer, {
    cors: {
      origin: env.FRONTEND_ORIGIN ? [env.FRONTEND_ORIGIN, '*'] : '*',
      methods: ['GET', 'POST'],
      credentials: true,
    },
    transports: ['websocket', 'polling'],
  });

  ioInstance = io;

  // Authentication Middleware
  io.use(async (socket: Socket, next) => {
    try {
      // Extract token from auth object or authorization header or query
      const authHeader = socket.handshake.headers.authorization;
      let rawToken: string | undefined = socket.handshake.auth?.token;

      if (!rawToken && authHeader && authHeader.startsWith('Bearer ')) {
        rawToken = authHeader.split(' ')[1];
      }

      if (!rawToken && socket.handshake.query?.token) {
        rawToken = Array.isArray(socket.handshake.query.token)
          ? socket.handshake.query.token[0]
          : socket.handshake.query.token;
      }

      if (!rawToken) {
        return next(new Error('AUTHENTICATION_REQUIRED'));
      }

      const verified = verifyAccessToken(rawToken);
      socket.data.userId = verified.userId;
      socket.data.name = verified.name;

      // Extract & Validate Business Context
      let businessId =
        socket.handshake.auth?.businessId ||
        socket.handshake.headers['x-business-id'] ||
        socket.handshake.query?.businessId;

      if (Array.isArray(businessId)) {
        businessId = businessId[0];
      }

      if (businessId && typeof businessId === 'string' && businessId.trim() !== '') {
        businessId = businessId.trim();
        // Verify user membership
        const member = await prisma.businessMember.findUnique({
          where: {
            businessId_userId: {
              businessId,
              userId: verified.userId,
            },
          },
        });
        if (member) {
          socket.data.businessId = businessId;
          socket.data.role = member.role;
        }
      }

      // Fallback: If no valid businessId specified, assign primary business
      if (!socket.data.businessId) {
        const primaryMembership = await prisma.businessMember.findFirst({
          where: { userId: verified.userId },
          orderBy: { createdAt: 'asc' },
        });

        if (primaryMembership) {
          socket.data.businessId = primaryMembership.businessId;
          socket.data.role = primaryMembership.role;
        }
      }

      return next();
    } catch (err: any) {
      logger.warn(`[WS GATEWAY] Auth rejected for socket ${socket.id}: ${err?.message || err}`);
      return next(new Error('INVALID_TOKEN'));
    }
  });

  // Connection Handler
  io.on('connection', (socket: Socket) => {
    const { userId, name, businessId } = socket.data;
    logger.info(`🔌 [WS CONNECTED] Socket ID: ${socket.id} | User: ${name} (${userId})`);

    if (businessId) {
      const room = `business:${businessId}`;
      socket.join(room);
      logger.info(`🏢 [WS ROOM JOINED] Socket ${socket.id} joined room: ${room}`);

      socket.emit('ws:ready', {
        status: 'connected',
        businessId,
        socketId: socket.id,
        timestamp: new Date().toISOString(),
      });
    }

    // Allow client to switch or join a specific business room
    socket.on('business:switch', async (newBusinessId: string) => {
      try {
        if (!newBusinessId || typeof newBusinessId !== 'string') return;
        const cleanId = newBusinessId.trim();

        const member = await prisma.businessMember.findUnique({
          where: {
            businessId_userId: {
              businessId: cleanId,
              userId: socket.data.userId,
            },
          },
        });

        if (member) {
          // Leave old room
          if (socket.data.businessId) {
            socket.leave(`business:${socket.data.businessId}`);
          }
          socket.data.businessId = cleanId;
          socket.data.role = member.role;
          socket.join(`business:${cleanId}`);
          logger.info(`🏢 [WS ROOM SWITCHED] Socket ${socket.id} switched to room: business:${cleanId}`);
          socket.emit('business:switched', { businessId: cleanId });
        }
      } catch (e: any) {
        logger.error(`[WS ROOM SWITCH ERROR] ${e.message}`);
      }
    });

    socket.on('disconnect', (reason) => {
      logger.info(`🔌 [WS DISCONNECTED] Socket ID: ${socket.id} (${reason})`);
    });
  });

  // Bridge internal EventBus events to WebSocket clients
  eventBus.onStockLowAlert((payload) => {
    const room = `business:${payload.businessId}`;
    logger.warn(
      `🚨 [WS BROADCAST] Low stock alert for room ${room}: ${payload.alerts.length} item(s) below minStock`
    );
    io.to(room).emit('stock:low-alert', payload);
  });

  eventBus.onStockMutated((payload) => {
    const room = `business:${payload.businessId}`;
    logger.info(
      `📦 [WS BROADCAST] Stock mutated for room ${room}: ${payload.stockName} (${payload.type} ${payload.quantity})`
    );
    io.to(room).emit('stock:mutated', payload);
  });

  logger.info('🚀 WebSocket Gateway initialized with tenant room isolation');

  return io;
};
