import 'package:flutter/material.dart';

/// 通知工具类，以Toast风格显示通知，避免干扰底部按钮
class ToastUtil {
  /// 显示浮动式轻量通知
  static void show(
    BuildContext context, 
    String message, {
    Duration duration = const Duration(seconds: 1),
    bool isError = false,
  }) {
    // 移除任何已经显示的SnackBar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // 获取屏幕尺寸
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        // 居中显示，略微偏下
        top: MediaQuery.of(context).size.height * 0.65,
        width: MediaQuery.of(context).size.width,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? Colors.redAccent.withOpacity(0.9) : Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // 定时移除通知
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
  
  /// 显示成功通知
  static void showSuccess(BuildContext context, String message) {
    show(context, message);
  }
  
  /// 显示错误通知
  static void showError(BuildContext context, String message) {
    show(context, message, isError: true, duration: const Duration(seconds: 2));
  }
} 