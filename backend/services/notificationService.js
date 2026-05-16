const { admin } = require('../config/firebase');
const User = require('../models/User');

exports.sendPushNotification = async (userId, title, body, data = {}) => {
  try {
    const user = await User.findById(userId);
    if (!user || !user.fcmTokens || user.fcmTokens.length === 0) {
      console.log(`[Push] No FCM tokens for user ${userId}`);
      return;
    }
    console.log(`[Push] Sending to user ${userId}, tokens: ${user.fcmTokens.length}`);

    const invalidTokens = [];

    for (const token of user.fcmTokens) {
      try {
        await admin.messaging().send({
          token,
          notification: { title, body },
          data,
          apns: {
            payload: { aps: { sound: 'default' } },
          },
        });
      } catch (error) {
        console.error(`[Push] Send error for token ${token.substring(0, 20)}...:`, error.code || error.message);
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

exports.sendGroupNotification = async (group, excludeUserId, title, body, data = {}) => {
  try {
    const allIds = group.members
      .filter(m => m.leftAt === null && m.user && m.user._id)
      .map(m => ({ id: m.user._id.toString(), name: m.user.name || '?' }));

    console.log(`[Push] excludeUserId="${excludeUserId}" type=${typeof excludeUserId}`);
    console.log(`[Push] All active members: ${allIds.map(m => `${m.name}(${m.id})`).join(', ')}`);

    const memberIds = allIds
      .filter(m => m.id !== excludeUserId)
      .map(m => m.id);

    console.log(`[Push] After exclude: ${memberIds.length} recipients`);

    for (const uid of memberIds) {
      await exports.sendPushNotification(uid, title, body, data);
    }
  } catch (error) {
    console.error('[Push] sendGroupNotification error:', error.message);
  }
};
