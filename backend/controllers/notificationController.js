const Notification = require('../models/Notification');

exports.getNotifications = async (req, res) => {
  try {
    const notifications = await Notification.find({ user: req.user.id })
      .sort({ createdAt: -1 })
      .limit(50);

    return res.status(200).json(notifications);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.markAsRead = async (req, res) => {
  try {
    await Notification.updateMany(
      { _id: { $in: req.body.ids }, user: req.user.id },
      { read: true }
    );
    return res.status(200).json({ message: 'Marked as read.' });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.getUnreadCount = async (req, res) => {
  try {
    const count = await Notification.countDocuments({ user: req.user.id, read: false });
    return res.status(200).json({ count });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};
