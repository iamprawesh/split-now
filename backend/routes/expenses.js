const express = require('express');
const router = express.Router({ mergeParams: true });
const expenseController = require('../controllers/expenseController');
const { verifyToken } = require('../middleware/auth');

router.use(verifyToken);

/**
 * @openapi
 * /api/groups/{groupId}/expenses:
 *   get:
 *     summary: List expenses in a group
 *     tags: [Expenses]
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
 *         description: List of expenses
 *   post:
 *     summary: Create an expense in a group
 *     tags: [Expenses]
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
 *               title: { type: string }
 *               description: { type: string }
 *               amount: { type: number }
 *               paidBy: { type: string }
 *               splitType: { type: string, enum: [equal, custom] }
 *               splits: { type: array, items: { type: object } }
 *               date: { type: string }
 *     responses:
 *       201:
 *         description: Expense created
 */
router.get('/', expenseController.getExpenses);
router.post('/', expenseController.createExpense);

/**
 * @openapi
 * /api/groups/{groupId}/balances:
 *   get:
 *     summary: Get simplified balances and debts
 *     tags: [Expenses]
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
 *         description: Balances and suggested transactions
 */
router.get('/balances', expenseController.getBalances); // note: defined before /:expenseId
router.get('/analytics', expenseController.getGroupExpenseAnalytics);

/**
 * @openapi
 * /api/expenses/{expenseId}:
 *   get:
 *     summary: Get an expense
 *     tags: [Expenses]
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
 *     summary: Update an expense
 *     tags: [Expenses]
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
 *     summary: Delete an expense
 *     tags: [Expenses]
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
router.get('/:expenseId', expenseController.getExpense);
router.put('/:expenseId', expenseController.updateExpense);
router.delete('/:expenseId', expenseController.deleteExpense);

module.exports = router;
