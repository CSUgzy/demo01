import 'package:leancloud_storage/leancloud.dart';

class NotificationService {
  // 获取当前用户的通知列表 (支持分页)
  Future<List<LCObject>> fetchNotifications({int skip = 0, int limit = 20}) async {
    LCUser? currentUser = await LCUser.getCurrent();
    if (currentUser == null) {
      print('fetchNotifications: 当前用户未登录');
      return [];
    }
    
    print('fetchNotifications: 开始获取通知，skip=$skip, limit=$limit');
    try {
      LCQuery<LCObject> query = LCQuery('Notification');
      query.whereEqualTo('recipient', currentUser);
      query.orderByDescending('createdAt');
      query.skip(skip);
      query.limit(limit);
      // 可以根据需要 include 关联的帖子信息
      query.include('relatedProjectPost');
      query.include('relatedTalentPost');
      
      print('fetchNotifications: 执行查询...');
      final results = await query.find();
      print('fetchNotifications: 查询完成，找到 ${results?.length ?? 0} 条通知');
      return results ?? [];
    } catch (e) {
      print('Error fetching notifications: $e');
      if (e is LCException) {
        print('LeanCloud error code: ${e.code}, message: ${e.message}');
      }
      return [];
    }
  }

  // 获取未读通知数量
  Future<int> getUnreadNotificationCount() async {
    LCUser? currentUser = await LCUser.getCurrent();
    if (currentUser == null) {
      print('getUnreadNotificationCount: 当前用户未登录');
      return 0;
    }
    
    print('getUnreadNotificationCount: 开始获取未读通知数量');
    try {
      LCQuery<LCObject> query = LCQuery('Notification');
      query.whereEqualTo('recipient', currentUser);
      query.whereEqualTo('isRead', false); // 筛选未读
      
      print('getUnreadNotificationCount: 执行查询...');
      final count = await query.count();
      print('getUnreadNotificationCount: 查询完成，未读通知数量: $count');
      return count ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      if (e is LCException) {
        print('LeanCloud error code: ${e.code}, message: ${e.message}');
      }
      return 0;
    }
  }

  // 将所有未读通知标记为已读
  Future<bool> markAllAsRead() async {
    LCUser? currentUser = await LCUser.getCurrent();
    if (currentUser == null) {
      print('markAllAsRead: 当前用户未登录');
      return false;
    }

    print('markAllAsRead: 开始标记所有未读通知为已读');
    try {
      // 这是一个较复杂的操作，最好通过云函数来批量处理
      // 客户端实现：先查询所有未读通知，然后逐个或批量更新
      LCQuery<LCObject> query = LCQuery('Notification');
      query.whereEqualTo('recipient', currentUser);
      query.whereEqualTo('isRead', false);
      query.limit(1000); // 设置一个合理的上限
      
      print('markAllAsRead: 查询未读通知...');
      List<LCObject>? unreadNotifications = await query.find();
      print('markAllAsRead: 找到 ${unreadNotifications?.length ?? 0} 条未读通知');

      if (unreadNotifications != null && unreadNotifications.isNotEmpty) {
        for (var notification in unreadNotifications) {
          notification['isRead'] = true;
        }
        print('markAllAsRead: 批量保存更新...');
        await LCObject.saveAll(unreadNotifications);
        print('markAllAsRead: 批量保存完成');
      }
      return true;
    } catch (e) {
      print('Error marking all as read: $e');
      if (e is LCException) {
        print('LeanCloud error code: ${e.code}, message: ${e.message}');
      }
      return false;
    }
  }

  // 删除单条通知
  Future<bool> deleteNotification(String notificationId) async {
    print('deleteNotification: 开始删除通知，ID=$notificationId');
    try {
      LCObject notification = LCObject.createWithoutData('Notification', notificationId);
      print('deleteNotification: 执行删除操作...');
      await notification.delete();
      print('deleteNotification: 删除成功');
      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      if (e is LCException) {
        print('LeanCloud error code: ${e.code}, message: ${e.message}');
      }
      return false;
    }
  }
} 