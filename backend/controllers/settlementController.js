const Settlement = require('../models/Settlement');
const Group = require('../models/Group');
const Notification = require('../models/Notification');

exports.createSettlement = async (req, res) => {
  try {
    const { from, to, amount } = req.body;
    const groupId = req.params.id;

    if (!from || !to || !amount) {
      return res.status(400).json({ error: 'from, to, and amount required.' });
    }

    const group = await Group.findById(groupId);
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

    const fromUser = await (require('../models/User')).findById(from);
    const toUser = await (require('../models/User')).findById(to);

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

    return res.status(201).json(populated);
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
