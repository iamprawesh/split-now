const jwt = require('jsonwebtoken');
const { admin } = require('../config/firebase');
const User = require('../models/User');

const verifyToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Access denied. No token provided.' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }
};

const firebaseAuth = async (req, res, next) => {
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
    }

    req.firebaseUser = user;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid Firebase token.' });
  }
};

module.exports = { verifyToken, firebaseAuth };
