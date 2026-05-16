const { admin } = require('../config/firebase');
const User = require('../models/User');

exports.sendPushNotification = async (userId, title, body) => {
  try {
    const user = await User.findById(userId);
    if (!user || !user.fcmTokens || user.fcmTokens.length === 0) return;

    const invalidTokens = [];

    for (const token of user.fcmTokens) {
      try {
        await admin.messaging().send({
          token,
          notification: { title, body },
          apns: { payload: { aps: { sound: 'default' } } },
        });
      } catch (error) {
        if (error.code === 'messaging/invalid-registration-token' ||
            error.code === 'messaging/registration-token-not-registered') {
          invalidTokens.push(token);
        }
      }
    }

    if (invalidTokens.length > 0) {
      user.fcmTokens = user.fcmTokens.filter(t => !invalidTokens.includes(t));
      await user.save();
    }
  } catch (error) {
    console.error('Push notification error:', error.message);
  }
};

exports.sendGroupNotification = async (group, excludeUserId, title, body) => {
  const memberIds = group.members
    .filter(m => m.leftAt === null && m.user.toString() !== excludeUserId)
    .map(m => m.user);

  for (const uid of memberIds) {
    await exports.sendPushNotification(uid, title, body);
  }
};
