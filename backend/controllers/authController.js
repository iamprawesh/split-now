const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { admin } = require('../config/firebase');

const generateTokens = (user) => {
  const accessToken = jwt.sign(
    { id: user._id, firebaseUid: user.firebaseUid, name: user.name, email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
  return { accessToken };
};

exports.firebaseLogin = async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ error: 'Firebase ID token required.' });
    }

    const decoded = await admin.auth().verifyIdToken(idToken);

    let user = await User.findOne({ firebaseUid: decoded.uid });
    if (!user) {
      user = await User.create({
        firebaseUid: decoded.uid,
        name: decoded.name || 'Anonymous',
        email: decoded.email || '',
        avatar: decoded.picture || '',
      });
    } else {
      let updated = false;
      if (decoded.name && user.name !== decoded.name) { user.name = decoded.name; updated = true; }
      if (decoded.email && user.email !== decoded.email) { user.email = decoded.email; updated = true; }
      if (decoded.picture && user.avatar !== decoded.picture) { user.avatar = decoded.picture; updated = true; }
      if (updated) await user.save();
    }

    const tokens = generateTokens(user);
    return res.status(200).json({
      ...tokens,
      user: { id: user._id, name: user.name, email: user.email, avatar: user.avatar },
    });
  } catch (error) {
    return res.status(401).json({ error: 'Invalid Firebase token.' });
  }
};

exports.refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token required.' });
    }
    const decoded = jwt.verify(refreshToken, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }
    const tokens = generateTokens(user);
    return res.status(200).json(tokens);
  } catch (error) {
    return res.status(401).json({ error: 'Invalid refresh token.' });
  }
};

exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-fcmTokens');
    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }
    return res.status(200).json(user);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.updateFcmToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) {
      return res.status(400).json({ error: 'FCM token required.' });
    }
    const user = await User.findById(req.user.id);
    const exists = user.fcmTokens.includes(fcmToken);
    if (!exists) {
      user.fcmTokens.push(fcmToken);
      await user.save();
    }
    console.log(`[Auth] FCM token ${exists ? 'already exists' : 'pushed'} for user ${req.user.id}`);
    return res.status(200).json({ message: 'FCM token updated.' });
  } catch (error) {
    console.error('[Auth] FCM token update error:', error.message);
    return res.status(500).json({ error: error.message });
  }
};
