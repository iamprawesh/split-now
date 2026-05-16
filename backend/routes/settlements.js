const express = require('express');
const router = express.Router({ mergeParams: true });
const settlementController = require('../controllers/settlementController');
const { verifyToken } = require('../middleware/auth');

router.use(verifyToken);

/**
 * @openapi
 * /api/groups/{groupId}/settlements:
 *   get:
 *     summary: List settlements in a group
 *     tags: [Settlements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: List of settlements
 *   post:
 *     summary: Record a settlement (payment between members)
 *     tags: [Settlements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               from: { type: string }
 *               to: { type: string }
 *               amount: { type: number }
 *     responses:
 *       201:
 *         description: Settlement recorded
 */
router.get('/', settlementController.getSettlements);
router.post('/', settlementController.createSettlement);

module.exports = router;
