require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const connectDB = require('./config/db');
const { initializeFirebase } = require('./config/firebase');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Static files (terms, privacy)
app.use(express.static('public'));

// Swagger setup
const swaggerSpec = swaggerJsdoc({
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Splitwise API',
      version: '1.0.0',
      description: 'Expense sharing app API',
    },
    servers: [{ url: `http://localhost:${PORT}` }],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
  },
  apis: ['./routes/*.js', './controllers/*.js'],
});
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.use('/api/auth', require('./routes/auth'));
app.use('/api/groups', require('./routes/groups'));
app.use('/api/groups/:id/expenses', require('./routes/expenses'));
app.use('/api/groups/:id/settlements', require('./routes/settlements'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/me/expenses', require('./routes/personalExpenses'));

// Initialize and start
const start = async () => {
  initializeFirebase();
  await connectDB();
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`API docs at http://localhost:${PORT}/api-docs`);
  });
};

start();
