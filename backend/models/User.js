const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  firebaseUid: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  email: { type: String, default: '' },
  avatar: { type: String, default: '' },
  fcmTokens: [{ type: String }],
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
