const mongoose = require('mongoose');

const memberSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  role: { type: String, enum: ['admin', 'member'], default: 'member' },
  joinedAt: { type: Date, default: Date.now },
  leftAt: { type: Date, default: null },
}, { _id: false });

const inviteSchema = new mongoose.Schema({
  code: { type: String, required: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  expiresAt: { type: Date, default: null },
  maxUses: { type: Number, default: null },
  useCount: { type: Number, default: 0 },
}, { _id: false });

const groupSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, default: '' },
  members: [memberSchema],
  invite: { type: inviteSchema, default: null },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
}, { timestamps: true });

module.exports = mongoose.model('Group', groupSchema);
