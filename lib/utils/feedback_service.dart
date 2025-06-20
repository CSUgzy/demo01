import 'package:flutter/material.dart';
import 'toast_util.dart';

class FeedbackService {
  // 显示成功的 SnackBar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 显示失败的 SnackBar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 显示通用的 SnackBar
  static void showSnackBar(
    BuildContext context, 
    String message, {
    Color backgroundColor = Colors.black87,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 显示确认对话框
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = "确认",
    String cancelText = "取消",
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text(cancelText),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text(confirmText),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    return result ?? false; // 如果用户点击外部关闭，则返回false
  }
  
  // 显示加载对话框
  static void showLoadingDialog(BuildContext context, {String message = "加载中..."}) {
    showDialog(
      context: context,
      barrierDismissible: false, // 用户不能通过点击外部关闭对话框
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }
  
  // 隐藏当前对话框
  static void hideDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
  
  // 使用Toast风格显示提示
  static void showToast(BuildContext context, String message, {bool isError = false}) {
    // 使用已有的ToastUtil
    ToastUtil.show(context, message, isError: isError);
  }
  
  // 显示成功Toast
  static void showSuccessToast(BuildContext context, String message) {
    ToastUtil.showSuccess(context, message);
  }
  
  // 显示错误Toast
  static void showErrorToast(BuildContext context, String message) {
    ToastUtil.showError(context, message);
  }
} 