/**
 * ZeroCarbonix EWMS — Notifications Controller
 * Manages in-app notifications and delivery status
 */

const { repository } = require('../../database/ewms_repository');

class NotificationsController {
  list(req, res) {
    const notifs = repository.notifications.filter(
      n => n.recipientId === req.user.id || n.recipientId === `emp-${req.user.id}`
    );

    const unreadCount = notifs.filter(n => !n.read).length;

    res.json({
      success: true,
      unreadCount,
      data: notifs,
    });
  }

  markRead(req, res) {
    const { id } = req.params;
    const notif = repository.notifications.find(n => n.id === id);
    if (!notif) {
      return res.status(404).json({ error: 'Notification not found' });
    }

    notif.read = true;
    res.json({
      success: true,
      data: notif,
    });
  }

  markAllRead(req, res) {
    repository.notifications.forEach(n => {
      if (n.recipientId === req.user.id || n.recipientId === `emp-${req.user.id}`) {
        n.read = true;
      }
    });

    res.json({
      success: true,
      message: 'All notifications marked as read',
    });
  }
}

module.exports = new NotificationsController();
