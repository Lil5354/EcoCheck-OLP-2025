import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';

/// Show Loading Dialog
void showLoadingDialog(BuildContext context, {String? message}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (context) => WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: AppColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                message ?? 'Đang xử lý...',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Show Error Dialog
void showErrorDialog(
  BuildContext context, {
  String? title,
  required String message,
  VoidCallback? onOk,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        title ?? AppStrings.error,
        style: AppTextStyles.h4.copyWith(color: AppColors.error),
      ),
      content: Text(message, style: AppTextStyles.bodyMedium),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onOk?.call();
          },
          child: Text(
            AppStrings.ok,
            style: AppTextStyles.button.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    ),
  );
}

/// Show Success Dialog
void showSuccessDialog(
  BuildContext context,
  String title,
  String message, {
  VoidCallback? onConfirm,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        title,
        style: AppTextStyles.h4.copyWith(color: AppColors.success),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
          child: Text(
            AppStrings.ok,
            style: AppTextStyles.button.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    ),
  );
}

/// Show Confirmation Dialog
Future<bool?> showConfirmationDialog(
  BuildContext context,
  String title,
  String message, {
  String? confirmText,
  String? cancelText,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: AppTextStyles.h4),
      content: Text(message, style: AppTextStyles.bodyMedium),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text(
            cancelText ?? AppStrings.cancel,
            style: AppTextStyles.button.copyWith(color: AppColors.grey),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text(
            confirmText ?? AppStrings.confirm,
            style: AppTextStyles.button.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    ),
  );
}
