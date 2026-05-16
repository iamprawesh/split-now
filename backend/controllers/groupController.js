const { nanoid } = require('nanoid');
const Group = require('../models/Group');
const User = require('../models/User');
const Notification = require('../models/Notification');

exports.createGroup = async (req, res) => {
  try {
    const { name, description } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'Group name is required.' });
    }

    const group = await Group.create({
      name: name.trim(),
      description: description || '',
      members: [{ user: req.user.id, role: 'admin' }],
      createdBy: req.user.id,
    });

    const populated = await Group.findById(group._id)
      .populate('members.user', 'name email avatar');

    return res.status(201).json(populated);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.getGroups = async (req, res) => {
  try {
    const groups = await Group.find({
      'members': { $elemMatch: { user: req.user.id, leftAt: null } },
    }).populate('members.user', 'name email avatar')
      .sort({ updatedAt: -1 });

    return res.status(200).json(groups);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.getGroup = async (req, res) => {
  try {
    const group = await Group.findById(req.params.id)
      .populate('members.user', 'name email avatar');

    if (!group) {
      return res.status(404).json({ error: 'Group not found.' });
    }

    const isMember = group.members.some(
      m => m.user._id.toString() === req.user.id && m.leftAt === null
    );
    if (!isMember) {
      return res.status(403).json({ error: 'Not a member of this group.' });
    }

    return res.status(200).json(group);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.addMembers = async (req, res) => {
  try {
    const { userIds } = req.body;
    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      return res.status(400).json({ error: 'userIds array required.' });
    }

    const group = await Group.findById(req.params.id);
    if (!group) {
      return res.status(404).json({ error: 'Group not found.' });
    }

    const memberIds = group.members.filter(m => m.leftAt === null).map(m => m.user.toString());
    const newUsers = userIds.filter(id => !memberIds.includes(id));

    for (const uid of newUsers) {
      group.members.push({ user: uid, role: 'member' });
    }

    await group.save();

    const populated = await Group.findById(group._id)
      .populate('members.user', 'name email avatar');

    for (const uid of newUsers) {
      await Notification.create({
        user: uid,
        type: 'member_joined',
        message: `You were added to the group "${group.name}"`,
        refId: group._id,
      });
    }

    return res.status(200).json(populated);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.removeMember = async (req, res) => {
  try {
    const { userId } = req.params;
    const group = await Group.findById(req.params.id);

    if (!group) {
      return res.status(404).json({ error: 'Group not found.' });
    }

    const requester = group.members.find(
      m => m.user.toString() === req.user.id && m.leftAt === null
    );
    if (!requester || requester.role !== 'admin') {
      return res.status(403).json({ error: 'Only admins can remove members.' });
    }

    const member = group.members.find(
      m => m.user.toString() === userId && m.leftAt === null
    );
    if (!member) {
      return res.status(404).json({ error: 'Member not found.' });
    }

    if (member.role === 'admin') {
      const adminCount = group.members.filter(
        m => m.role === 'admin' && m.leftAt === null
      ).length;
      if (adminCount <= 1) {
        return res.status(400).json({ error: 'Cannot remove the last admin.' });
      }
    }

    member.leftAt = new Date();
    await group.save();

    const populated = await Group.findById(group._id)
      .populate('members.user', 'name email avatar');

    return res.status(200).json(populated);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.promoteMember = async (req, res) => {
  try {
    const { userId } = req.params;
    const group = await Group.findById(req.params.id);

    if (!group) {
      return res.status(404).json({ error: 'Group not found.' });
    }

    const requester = group.members.find(
      m => m.user.toString() === req.user.id && m.leftAt === null
    );
    if (!requester || requester.role !== 'admin') {
      return res.status(403).json({ error: 'Only admins can promote.' });
    }

    const member = group.members.find(
      m => m.user.toString() === userId && m.leftAt === null
    );
    if (!member) {
      return res.status(404).json({ error: 'Member not found.' });
    }

    member.role = 'admin';
    await group.save();

    const populated = await Group.findById(group._id)
      .populate('members.user', 'name email avatar');

    return res.status(200).json(populated);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.leaveGroup = async (req, res) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group) {
      return res.status(404).json({ error: 'Group not found.' });
    }

    const member = group.members.find(
      m => m.user.toString() === req.user.id && m.leftAt === null
    );
    if (!member) {
      return res.status(404).json({ error: 'You are not a member.' });
    }

    if (member.role === 'admin') {
      const adminCount = group.members.filter(
        m => m.role === 'admin' && m.leftAt === null
      ).length;
      if (adminCount <= 1) {
        return res.status(400).json({ error: 'Promote another admin before leaving.' });
      }
    }

    member.leftAt = new Date();
    await group.save();

    return res.status(200).json({ message: 'Left the group.' });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.generateInvite = async (req, res) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group) {
      return res.status(404).json({ error: 'Group not found.' });
    }

    const member = group.members.find(
      m => m.user.toString() === req.user.id && m.leftAt === null
    );
    if (!member || member.role !== 'admin') {
      return res.status(403).json({ error: 'Only admins can generate invites.' });
    }

    const code = nanoid(10);
    group.invite = {
      code,
      createdBy: req.user.id,
      expiresAt: req.body.expiresAt || null,
      maxUses: req.body.maxUses || null,
      useCount: 0,
    };
    await group.save();

    return res.status(200).json({
      code,
      link: `https://splitwise.app/join/${code}`,
      qrData: JSON.stringify({ type: 'group_invite', code, groupId: group._id }),
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.joinByInvite = async (req, res) => {
  try {
    const { code } = req.params;
    const group = await Group.findOne({ 'invite.code': code });

    if (!group) {
      return res.status(404).json({ error: 'Invalid invite code.' });
    }

    if (group.invite.expiresAt && group.invite.expiresAt < new Date()) {
      return res.status(400).json({ error: 'Invite has expired.' });
    }

    if (group.invite.maxUses && group.invite.useCount >= group.invite.maxUses) {
      return res.status(400).json({ error: 'Invite has reached max uses.' });
    }

    const existingMember = group.members.find(
      m => m.user.toString() === req.user.id && m.leftAt === null
    );
    if (existingMember) {
      return res.status(400).json({ error: 'Already a member.' });
    }

    const wasMember = group.members.find(
      m => m.user.toString() === req.user.id && m.leftAt !== null
    );
    if (wasMember) {
      wasMember.leftAt = null;
      wasMember.joinedAt = new Date();
    } else {
      group.members.push({ user: req.user.id, role: 'member' });
    }

    group.invite.useCount += 1;
    await group.save();

    await Notification.create({
      user: req.user.id,
      type: 'member_joined',
      message: `You joined the group "${group.name}"`,
      refId: group._id,
    });

    const populated = await Group.findById(group._id)
      .populate('members.user', 'name email avatar');

    return res.status(200).json(populated);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.updateGroup = async (req, res) => {
  try {
    const { name, description } = req.body;
    const group = await Group.findById(req.params.id);

    if (!group) {
      return res.status(404).json({ error: 'Group not found.' });
    }

    const requester = group.members.find(
      m => m.user.toString() === req.user.id && m.leftAt === null
    );
    if (!requester || requester.role !== 'admin') {
      return res.status(403).json({ error: 'Only admins can edit group.' });
    }

    if (name !== undefined) group.name = name.trim();
    if (description !== undefined) group.description = description;

    await group.save();

    const populated = await Group.findById(group._id)
      .populate('members.user', 'name email avatar');

    return res.status(200).json(populated);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.searchUsers = async (req, res) => {
  try {
    const { q } = req.query;
    if (!q || q.length < 1) {
      return res.status(400).json({ error: 'Search query required (min 1 char).' });
    }

    const users = await User.find({
      $or: [
        { name: { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } },
      ],
    }).select('name email avatar').limit(20);

    return res.status(200).json(users);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};
