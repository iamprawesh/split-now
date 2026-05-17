const Settlement = require('../models/Settlement');
const Group = require('../models/Group');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { sendGroupNotification, sendPushNotification } = require('../services/notificationService');

exports.createSettlement = async (req, res) => {
  try {
    const { from, to, amount } = req.body;
    const groupId = req.params.id;

    if (!from || !to || !amount) {
      return res.status(400).json({ error: 'from, to, and amount required.' });
    }

    const group = await Group.findById(groupId).populate('members.user');
    if (!group) {
      return res.status(404).json({ error: 'Group not found.' });
    }

    const settlement = await Settlement.create({
      group: groupId,
      from,
      to,
      amount,
    });

    const populated = await Settlement.findById(settlement._id)
      .populate('from', 'name email avatar')
      .populate('to', 'name email avatar');

    const fromUser = await User.findById(from);
    const toUser = await User.findById(to);

    const notifyMsg = `${fromUser.name} paid $${amount} to ${toUser.name} in ${group.name}`;
    await Notification.create({
      user: from,
      type: 'settlement',
      message: `You paid $${amount} to ${toUser.name}`,
      refId: settlement._id,
    });
    await Notification.create({
      user: to,
      type: 'settlement',
      message: `${fromUser.name} paid you $${amount}`,
      refId: settlement._id,
    });

    sendGroupNotification(
      group, from,
      'Payment Settled',
      `${fromUser.name} paid $${amount} to ${toUser.name} in ${group.name}`,
      { groupId, type: 'settlement' }
    ).catch(err => console.error('[Push] settlement notification failed:', err.message));

    return res.status(201).json(populated);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.remindUser = async (req, res) => {
  try {
    const { id: groupId, userId } = req.params;
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ error: 'Group not found.' });
    }

    const requester = group.members.find(
      m => m.user.toString() === req.user.id && m.leftAt === null
    );
    if (!requester) {
      return res.status(403).json({ error: 'Not a group member.' });
    }

    await sendPushNotification(
      userId,
      'Payment Reminder',
      `${req.user.name || 'Someone'} reminded you to settle up in ${group.name}`,
      { groupId, type: 'payment_reminder' }
    );

    return res.status(200).json({ message: 'Reminder sent.' });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.getSettlements = async (req, res) => {
  try {
    const settlements = await Settlement.find({ group: req.params.id })
      .populate('from', 'name email avatar')
      .populate('to', 'name email avatar')
      .sort({ settledAt: -1 });

    return res.status(200).json(settlements);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};
