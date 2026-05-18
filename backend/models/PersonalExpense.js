const mongoose = require('mongoose');

const personalExpenseSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  amount: { type: Number, required: true },
  categoryId: { type: String, default: 'other' },
  date: { type: Date, default: Date.now },
  notes: { type: String, default: '' },
}, { timestamps: true });

module.exports = mongoose.model('PersonalExpense', personalExpenseSchema);
