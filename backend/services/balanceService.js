const Expense = require('../models/Expense');
const Settlement = require('../models/Settlement');

exports.calculateBalances = async (groupId) => {
  const expenses = await Expense.find({ group: groupId });
  const settlements = await Settlement.find({ group: groupId });

  const balanceMap = {};

  for (const expense of expenses) {
    const paidBy = expense.paidBy.toString();
    balanceMap[paidBy] = (balanceMap[paidBy] || 0) + expense.amount;

    for (const split of expense.splits) {
      const userId = split.user.toString();
      balanceMap[userId] = (balanceMap[userId] || 0) - split.amount;
    }
  }

  for (const settlement of settlements) {
    const from = settlement.from.toString();
    const to = settlement.to.toString();
    balanceMap[from] = (balanceMap[from] || 0) + settlement.amount;
    balanceMap[to] = (balanceMap[to] || 0) - settlement.amount;
  }

  return balanceMap;
};

exports.simplifyDebts = (balanceMap) => {
  const creditors = [];
  const debtors = [];

  for (const [userId, balance] of Object.entries(balanceMap)) {
    if (balance > 0.01) creditors.push({ userId, amount: balance });
    else if (balance < -0.01) debtors.push({ userId, amount: -balance });
  }

  creditors.sort((a, b) => b.amount - a.amount);
  debtors.sort((a, b) => b.amount - a.amount);

  const transactions = [];
  let i = 0, j = 0;

  while (i < debtors.length && j < creditors.length) {
    const payment = Math.min(debtors[i].amount, creditors[j].amount);
    transactions.push({
      from: debtors[i].userId,
      to: creditors[j].userId,
      amount: Math.round(payment * 100) / 100,
    });
    debtors[i].amount -= payment;
    creditors[j].amount -= payment;
    if (debtors[i].amount < 0.01) i++;
    if (creditors[j].amount < 0.01) j++;
  }

  return transactions;
};

exports.calculateSplitAmounts = (amount, splitType, splits, members) => {
  if (splitType === 'equal') {
    const splitUserIds = splits.map(s => s.user?.toString?.() || s.user);
    const included = members.filter(m => {
      const mid = m.user?._id?.toString?.() || m.user?.toString?.();
      return splitUserIds.includes(mid);
    });
    if (included.length === 0) throw new Error('No members selected for equal split.');
    const perPerson = Math.round((amount / included.length) * 100) / 100;
    const splits_result = included.map(m => ({
      user: m.user._id || m.user,
      value: 1,
      amount: perPerson,
    }));
    const remainder = Math.round((amount - splits_result.reduce((s, a) => s + a.amount, 0)) * 100) / 100;
    if (remainder !== 0 && splits_result.length > 0) {
      splits_result[splits_result.length - 1].amount += remainder;
      splits_result[splits_result.length - 1].amount = Math.round(splits_result[splits_result.length - 1].amount * 100) / 100;
    }
    return splits_result;
  }

  if (splitType === 'parts') {
    const totalParts = splits.reduce((s, sp) => s + sp.value, 0);
    if (totalParts <= 0) throw new Error('Total parts must be > 0');
    const splits_result = splits.map(sp => ({
      user: sp.user,
      value: sp.value,
      amount: Math.round((sp.value / totalParts) * amount * 100) / 100,
    }));
    const sum = splits_result.reduce((s, a) => s + a.amount, 0);
    const remainder = Math.round((amount - sum) * 100) / 100;
    if (remainder !== 0 && splits_result.length > 0) {
      splits_result[splits_result.length - 1].amount += remainder;
      splits_result[splits_result.length - 1].amount = Math.round(splits_result[splits_result.length - 1].amount * 100) / 100;
    }
    return splits_result;
  }

  if (splitType === 'percentage') {
    const totalPct = splits.reduce((s, sp) => s + sp.value, 0);
    if (Math.abs(totalPct - 100) > 0.01) throw new Error('Percentages must sum to 100');
    const splits_result = splits.map(sp => ({
      user: sp.user,
      value: sp.value,
      amount: Math.round((sp.value / 100) * amount * 100) / 100,
    }));
    const sum = splits_result.reduce((s, a) => s + a.amount, 0);
    const remainder = Math.round((amount - sum) * 100) / 100;
    if (remainder !== 0 && splits_result.length > 0) {
      splits_result[splits_result.length - 1].amount += remainder;
      splits_result[splits_result.length - 1].amount = Math.round(splits_result[splits_result.length - 1].amount * 100) / 100;
    }
    return splits_result;
  }

  if (splitType === 'custom') {
    const totalCustom = splits.reduce((s, sp) => s + sp.amount, 0);
    if (Math.abs(totalCustom - amount) > 0.01) throw new Error('Custom amounts must sum to the total amount');
    return splits.map(sp => ({
      user: sp.user,
      value: sp.amount,
      amount: sp.amount,
    }));
  }

  throw new Error('Invalid split type');
};
