const Expense = require('../models/Expense');
const Group = require('../models/Group');
const User = require('../models/User');
const Notification = require('../models/Notification');
const balanceService = require('../services/balanceService');
const { sendGroupNotification } = require('../services/notificationService');

exports.createExpense = async (req, res) => {
  try {
    const { title, description, category, amount, paidBy, splitType, splits, date } = req.body;
    const groupId = req.params.id;

    if (!amount || !paidBy || !splitType || !splits) {
      return res.status(400).json({ error: 'Missing required fields.' });
    }

    const group = await Group.findById(groupId).populate('members.user');
    if (!group) {
      return res.status(404).json({ error: 'Group not found.' });
    }

    const isMember = group.members.some(
      m => m.user._id.toString() === req.user.id && m.leftAt === null
    );
    if (!isMember) {
      return res.status(403).json({ error: 'Not a member of this group.' });
    }

    const activeMembers = group.members.filter(m => m.leftAt === null);

    let calculatedSplits;
    try {
      calculatedSplits = balanceService.calculateSplitAmounts(
        amount, splitType, splits, activeMembers
      );
    } catch (err) {
      return res.status(400).json({ error: err.message });
    }

    const expense = await Expense.create({
      group: groupId,
      title: title || category || 'Expense',
      description: description || '',
      category: category || '',
      amount,
      paidBy,
      splitType,
      splits: calculatedSplits,
      date: date || new Date(),
    });

    const populated = await Expense.findById(expense._id)
      .populate('paidBy', 'name email avatar')
      .populate('splits.user', 'name email avatar');

    const payer = await User.findById(paidBy);
    for (const member of activeMembers) {
      const uid = member.user._id.toString();
      if (uid !== req.user.id) {
        await Notification.create({
          user: uid,
          type: 'expense_added',
          message: `${payer.name} added "${title}" ($${amount}) in ${group.name}`,
          refId: expense._id,
        });
      }
    }

    const payerName = payer?.name || 'Someone';
    console.log(`[Expense] Sending push for expense "${title}" by user ${req.user.id} (${req.user.name})`);
    sendGroupNotification(
      group, req.user.id,
      'New Expense',
      `${payerName} added "${title}" in ${group.name}`,
      { groupId, expenseId: expense._id.toString(), type: 'expense_added' }
    ).catch(err => console.error('[Push] sendGroupNotification failed:', err.message));

    return res.status(201).json(populated);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.getExpenses = async (req, res) => {
  try {
    const expenses = await Expense.find({ group: req.params.id })
      .populate('paidBy', 'name email avatar')
      .populate('splits.user', 'name email avatar')
      .sort({ date: -1 });

    return res.status(200).json(expenses);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.getExpense = async (req, res) => {
  try {
    const expense = await Expense.findById(req.params.expenseId)
      .populate('paidBy', 'name email avatar')
      .populate('splits.user', 'name email avatar');

    if (!expense) {
      return res.status(404).json({ error: 'Expense not found.' });
    }

    return res.status(200).json(expense);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.updateExpense = async (req, res) => {
  try {
    const { title, description, category, amount, paidBy, splitType, splits, date } = req.body;
    const expense = await Expense.findById(req.params.expenseId);

    if (!expense) {
      return res.status(404).json({ error: 'Expense not found.' });
    }

    const group = await Group.findById(expense.group).populate('members.user');
    if (!group) {
      return res.status(404).json({ error: 'Group not found.' });
    }

    const requester = group.members.find(
      m => m.user._id.toString() === req.user.id && m.leftAt === null
    );
    if (!requester || requester.role !== 'admin') {
      return res.status(403).json({ error: 'Only admins can edit expenses.' });
    }

    const activeMembers = group.members.filter(m => m.leftAt === null);

    const finalAmount = amount || expense.amount;
    const finalSplitType = splitType || expense.splitType;
    const finalSplits = splits || expense.splits;

    let calculatedSplits;
    try {
      calculatedSplits = balanceService.calculateSplitAmounts(
        finalAmount, finalSplitType, finalSplits, activeMembers
      );
    } catch (err) {
      return res.status(400).json({ error: err.message });
    }

    expense.title = title || expense.title;
    expense.description = description !== undefined ? description : expense.description;
    expense.category = category !== undefined ? category : expense.category;
    expense.amount = finalAmount;
    expense.paidBy = paidBy || expense.paidBy;
    expense.splitType = finalSplitType;
    expense.splits = calculatedSplits;
    expense.date = date || expense.date;

    await expense.save();

    const populated = await Expense.findById(expense._id)
      .populate('paidBy', 'name email avatar')
      .populate('splits.user', 'name email avatar');

    return res.status(200).json(populated);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.deleteExpense = async (req, res) => {
  try {
    const expense = await Expense.findById(req.params.expenseId);
    if (!expense) {
      return res.status(404).json({ error: 'Expense not found.' });
    }

    const group = await Group.findById(expense.group);
    if (!group) {
      return res.status(404).json({ error: 'Group not found.' });
    }

    const requester = group.members.find(
      m => m.user.toString() === req.user.id && m.leftAt === null
    );
    if (!requester || requester.role !== 'admin') {
      return res.status(403).json({ error: 'Only admins can delete expenses.' });
    }

    await Expense.findByIdAndDelete(req.params.expenseId);
    return res.status(200).json({ message: 'Expense deleted.' });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.getBalances = async (req, res) => {
  try {
    const groupId = req.params.id;
    const balanceMap = await balanceService.calculateBalances(groupId);
    const transactions = balanceService.simplifyDebts(balanceMap);

    return res.status(200).json({ balances: balanceMap, transactions });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};
