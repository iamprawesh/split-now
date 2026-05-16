const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { verifyToken } = require('../middleware/auth');

/**
 * @openapi
 * /api/auth/firebase:
 *   post:
 *     summary: Sign in / register with Firebase ID token
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               idToken:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login successful
 *       401:
 *         description: Invalid token
 */
router.post('/firebase', authController.firebaseLogin);

/**
 * @openapi
 * /api/auth/refresh:
 *   post:
 *     summary: Refresh access token
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               refreshToken:
 *                 type: string
 *     responses:
 *       200:
 *         description: Token refreshed
 */
router.post('/refresh', authController.refreshToken);

/**
 * @openapi
 * /api/auth/profile:
 *   get:
 *     summary: Get current user profile
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User profile
 */
router.get('/profile', verifyToken, authController.getProfile);

/**
 * @openapi
 * /api/auth/fcm-token:
 *   post:
 *     summary: Save FCM device token
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               fcmToken:
 *                 type: string
 *     responses:
 *       200:
 *         description: Token saved
 */
router.post('/fcm-token', verifyToken, authController.updateFcmToken);

module.exports = router;
