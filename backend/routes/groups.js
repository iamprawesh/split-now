const express = require('express');
const router = express.Router();
const groupController = require('../controllers/groupController');
const { verifyToken } = require('../middleware/auth');

router.use(verifyToken);

/**
 * @openapi
 * /api/groups:
 *   get:
 *     summary: List user's groups
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of groups
 *   post:
 *     summary: Create a new group
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name: { type: string }
 *               description: { type: string }
 *     responses:
 *       201:
 *         description: Group created
 */
router.get('/', groupController.getGroups);
router.post('/', groupController.createGroup);

/**
 * @openapi
 * /api/groups/search-users:
 *   get:
 *     summary: Search users by name or email
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: q
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Matching users
 */
router.get('/search-users', groupController.searchUsers);

/**
 * @openapi
 * /api/groups/{id}:
 *   get:
 *     summary: Get group details
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Group details
 */
router.get('/:id', groupController.getGroup);

/**
 * @openapi
 * /api/groups/{id}:
 *   put:
 *     summary: Update group name/description (admin only)
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
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
 *               name: { type: string }
 *               description: { type: string }
 *     responses:
 *       200:
 *         description: Group updated
 */
router.put('/:id', groupController.updateGroup);

/**
 * @openapi
 * /api/groups/{id}/members:
 *   post:
 *     summary: Add members to group
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
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
 *               userIds:
 *                 type: array
 *                 items:
 *                   type: string
 *     responses:
 *       200:
 *         description: Members added
 */
router.post('/:id/members', groupController.addMembers);

/**
 * @openapi
 * /api/groups/{id}/members/{userId}:
 *   delete:
 *     summary: Remove a member from group
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Member removed
 */
router.delete('/:id/members/:userId', groupController.removeMember);

/**
 * @openapi
 * /api/groups/{id}/members/{userId}/promote:
 *   post:
 *     summary: Promote a member to admin
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Member promoted
 */
router.post('/:id/members/:userId/promote', groupController.promoteMember);

/**
 * @openapi
 * /api/groups/{id}/leave:
 *   post:
 *     summary: Leave a group
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Left the group
 */
router.post('/:id/leave', groupController.leaveGroup);

/**
 * @openapi
 * /api/groups/{id}/invite:
 *   post:
 *     summary: Generate invite code & QR data
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Invite generated
 */
router.post('/:id/invite', groupController.generateInvite);

/**
 * @openapi
 * /api/groups/join/{code}:
 *   post:
 *     summary: Join a group via invite code
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: code
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Joined group
 */
router.post('/join/:code', groupController.joinByInvite);

module.exports = router;
