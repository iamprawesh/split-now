const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  type: {
    type: String,
    enum: ['expense_added', 'expense_updated', 'expense_deleted', 'settlement', 'member_joined'],
    required: true,
  },
  message: { type: String, required: true },
  refId: { type: mongoose.Schema.Types.ObjectId },
  read: { type: Boolean, default: false },
}, { timestamps: true });

module.exports = mongoose.model('Notification', notificationSchema);
