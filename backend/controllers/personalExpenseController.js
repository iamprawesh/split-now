const mongoose = require('mongoose');
const PersonalExpense = require('../models/PersonalExpense');

exports.getPersonalExpenses = async (req, res) => {
  try {
    const expenses = await PersonalExpense.find({ user: req.user.id })
      .sort({ date: -1 });
    return res.status(200).json(expenses);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.createPersonalExpense = async (req, res) => {
  try {
    const { title, amount, categoryId, date, notes } = req.body;

    if (!title || !amount) {
      return res.status(400).json({ error: 'Title and amount are required.' });
    }

    const expense = await PersonalExpense.create({
      user: req.user.id,
      title,
      amount,
      categoryId: categoryId || 'other',
      date: date || new Date(),
      notes: notes || '',
    });

    return res.status(201).json(expense);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.getPersonalExpense = async (req, res) => {
  try {
    const expense = await PersonalExpense.findOne({
      _id: req.params.expenseId,
      user: req.user.id,
    });

    if (!expense) {
      return res.status(404).json({ error: 'Expense not found.' });
    }

    return res.status(200).json(expense);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.updatePersonalExpense = async (req, res) => {
  try {
    const { title, amount, categoryId, date, notes } = req.body;

    const expense = await PersonalExpense.findOne({
      _id: req.params.expenseId,
      user: req.user.id,
    });

    if (!expense) {
      return res.status(404).json({ error: 'Expense not found.' });
    }

    if (title !== undefined) expense.title = title;
    if (amount !== undefined) expense.amount = amount;
    if (categoryId !== undefined) expense.categoryId = categoryId;
    if (date !== undefined) expense.date = date;
    if (notes !== undefined) expense.notes = notes;

    await expense.save();
    return res.status(200).json(expense);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.deletePersonalExpense = async (req, res) => {
  try {
    const expense = await PersonalExpense.findOneAndDelete({
      _id: req.params.expenseId,
      user: req.user.id,
    });

    if (!expense) {
      return res.status(404).json({ error: 'Expense not found.' });
    }

    return res.status(200).json({ message: 'Expense deleted.' });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.getPersonalExpenseAnalytics = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);

    const categoryTotals = await PersonalExpense.aggregate([
      { $match: { user: userId } },
      {
        $group: {
          _id: '$categoryId',
          total: { $sum: '$amount' },
          count: { $sum: 1 },
        },
      },
      { $sort: { total: -1 } },
    ]);

    const monthlyTotals = await PersonalExpense.aggregate([
      { $match: { user: userId } },
      {
        $group: {
          _id: { year: { $year: '$date' }, month: { $month: '$date' } },
          total: { $sum: '$amount' },
          count: { $sum: 1 },
        },
      },
      { $sort: { '_id.year': 1, '_id.month': 1 } },
    ]);

    const totalSpent = categoryTotals.reduce((sum, c) => sum + c.total, 0);

    return res.status(200).json({
      totalSpent,
      totalExpenses: categoryTotals.reduce((sum, c) => sum + c.count, 0),
      categoryTotals,
      monthlyTotals,
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};
