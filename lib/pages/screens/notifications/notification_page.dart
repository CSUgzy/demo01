import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud.dart';
import 'package:intl/intl.dart';
import '../../../services/notification_service.dart';
import '../../../utils/toast_util.dart';
import '../detail/post_detail_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();
  List<LCObject> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _skip = 0;
  final int _limit = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
    print("通知页面初始化");
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _notifications.isNotEmpty) {
        _silentMarkAllAsRead();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _skip = 0;
    });

    try {
      final notifications = await _notificationService.fetchNotifications(skip: _skip, limit: _limit);
      if (!mounted) return;
      
      setState(() {
        _notifications = notifications;
        _isLoading = false;
        _hasMoreData = notifications.length == _limit;
        _skip = notifications.length;
      });
      
      // 如果有通知，延迟1秒后静默标记为已读
      if (notifications.isNotEmpty) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _silentMarkAllAsRead();
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      print("Error loading notifications: $e");
      if (e is LCException) {
        print('LeanCloud error code: ${(e as LCException).code}, message: ${(e as LCException).message}');
      }
      
      setState(() {
        _isLoading = false;
      });
      ToastUtil.showError(context, '加载通知失败，请稍后再试');
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final moreNotifications = await _notificationService.fetchNotifications(skip: _skip, limit: _limit);
      if (!mounted) return;
      
      setState(() {
        _notifications.addAll(moreNotifications);
        _isLoadingMore = false;
        _hasMoreData = moreNotifications.length == _limit;
        _skip += moreNotifications.length;
      });
    } catch (e) {
      if (!mounted) return;
      
      print("Error loading more notifications: $e");
      if (e is LCException) {
        print('LeanCloud error code: ${(e as LCException).code}, message: ${(e as LCException).message}');
      }
      
      setState(() {
        _isLoadingMore = false;
      });
      ToastUtil.showError(context, '加载更多通知失败，请稍后再试');
    }
  }

  // 静默标记所有通知为已读（不触发UI更新）
  Future<void> _silentMarkAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      // 不调用setState，避免UI重新构建
    } catch (e) {
      print('Error silently marking all as read: $e');
      if (e is LCException) {
        print('LeanCloud error code: ${(e as LCException).code}, message: ${(e as LCException).message}');
      }
    }
  }
  
  // 标记所有通知为已读（带UI更新和用户反馈）
  Future<void> _markAllAsRead() async {
    try {
      final success = await _notificationService.markAllAsRead();
      if (success && mounted) {
        setState(() {
          for (var notification in _notifications) {
            notification['isRead'] = true;
          }
        });
        ToastUtil.showSuccess(context, '所有消息已标记为已读');
      } else if (mounted) {
        ToastUtil.showError(context, '标记已读失败');
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError(context, '标记已读失败: $e');
      }
    }
  }

  Future<void> _deleteNotification(String notificationId, int index) async {
    try {
      final success = await _notificationService.deleteNotification(notificationId);
      if (success) {
        setState(() {
          _notifications.removeAt(index);
        });
      } else {
        ToastUtil.showError(context, '删除通知失败');
      }
    } catch (e) {
      ToastUtil.showError(context, '删除通知失败: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ToastUtil.showError(context, message);
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 7) {
      return DateFormat('yyyy-MM-dd').format(time);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息中心'),
        actions: [
          TextButton(
            onPressed: _notifications.isEmpty ? null : _markAllAsRead,
            child: const Text('全部已读'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('暂无新消息'))
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _notifications.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final notification = _notifications[index];
                      final bool isRead = notification['isRead'] as bool? ?? false;
                      final String type = notification['type'] as String? ?? '';
                      final DateTime? createdAt = notification.createdAt;

                      return Dismissible(
                        key: Key(notification.objectId!),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          color: Colors.red,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '删除',
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          _deleteNotification(notification.objectId!, index);
                        },
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getNotificationColor(type),
                                child: Icon(
                                  _getNotificationIcon(type),
                                  color: Colors.white,
                                ),
                              ),
                              if (!isRead)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            notification['title'] as String? ?? '新消息',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            notification['content'] as String? ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            _formatTime(createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => _onNotificationTap(notification),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'system':
        return Icons.campaign;
      case 'interaction_collected':
        return Icons.favorite;
      case 'interaction_comment':
        return Icons.comment;
      case 'interaction_like':
        return Icons.thumb_up;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'system':
        return Colors.blue;
      case 'interaction_collected':
        return Colors.pink;
      case 'interaction_comment':
        return Colors.green;
      case 'interaction_like':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _onNotificationTap(LCObject notification) async {
    // 标记单条通知为已读
    if (!(notification['isRead'] as bool? ?? false)) {
      notification['isRead'] = true;
      try {
        await notification.save();
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        print("Error marking notification as read: $e");
      }
    }

    // 获取关联的帖子
    final projectPost = notification['relatedProjectPost'] as LCObject?;
    final talentPost = notification['relatedTalentPost'] as LCObject?;

    // 导航到相关帖子
    if (!mounted) return;
    
    if (projectPost != null && projectPost.objectId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailPage(
            postId: projectPost.objectId!,
            postType: 'Project',
          ),
        ),
      );
    } else if (talentPost != null && talentPost.objectId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailPage(
            postId: talentPost.objectId!,
            postType: 'Talent',
          ),
        ),
      );
    }
  }
} 