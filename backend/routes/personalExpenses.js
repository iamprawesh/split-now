const express = require('express');
const router = express.Router();
const personalExpenseController = require('../controllers/personalExpenseController');
const { verifyToken } = require('../middleware/auth');

router.use(verifyToken);

/**
 * @openapi
 * /api/me/expenses:
 *   get:
 *     summary: List current user's personal expenses
 *     tags: [Personal Expenses]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of personal expenses
 *   post:
 *     summary: Create a personal expense
 *     tags: [Personal Expenses]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title: { type: string }
 *               amount: { type: number }
 *               categoryId: { type: string }
 *               date: { type: string }
 *               notes: { type: string }
 *     responses:
 *       201:
 *         description: Expense created
 */
router.get('/', personalExpenseController.getPersonalExpenses);
router.post('/', personalExpenseController.createPersonalExpense);
router.get('/analytics', personalExpenseController.getPersonalExpenseAnalytics);

/**
 * @openapi
 * /api/me/expenses/{expenseId}:
 *   get:
 *     summary: Get a personal expense
 *     tags: [Personal Expenses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: expenseId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Expense details
 *   put:
 *     summary: Update a personal expense
 *     tags: [Personal Expenses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: expenseId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Expense updated
 *   delete:
 *     summary: Delete a personal expense
 *     tags: [Personal Expenses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: expenseId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Expense deleted
 */
router.get('/:expenseId', personalExpenseController.getPersonalExpense);
router.put('/:expenseId', personalExpenseController.updatePersonalExpense);
router.delete('/:expenseId', personalExpenseController.deletePersonalExpense);

module.exports = router;
