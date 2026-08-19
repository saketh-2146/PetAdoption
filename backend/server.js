require('dotenv').config();
const express = require('express');
const cors = require('cors');

// Initialize Firebase Admin
const { initializeFirebase } = require('./src/config/firebase');
initializeFirebase();

// Import routes
const healthRoutes = require('./src/routes/healthRoutes');
const petRoutes = require('./src/routes/petRoutes');
const applicationRoutes = require('./src/routes/applicationRoutes');
const authRoutes = require('./src/routes/authRoutes');

// Import error handler
const errorHandler = require('./src/middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api', healthRoutes);
app.use('/api/pets', petRoutes);
app.use('/api/applications', applicationRoutes);
app.use('/api/auth', authRoutes);

// 404 handler
app.use((req, res, next) => {
  res.status(404).json({
    success: false,
    message: 'API route not found'
  });
});

// Centralized error handler
app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
