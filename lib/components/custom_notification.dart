import 'package:flutter/material.dart';
import '../../constants.dart';

class CustomNotification extends StatelessWidget {
  const CustomNotification({
    super.key,
    required this.title,
    required this.message,
    this.sku, // ✅ Added SKU parameter
    this.image,
    this.onPressed,
    required this.onClose,
    this.isError = false,
  });

  final String title;
  final String message;
  final String? sku; // ✅ SKU Field
  final String? image;
  final VoidCallback? onPressed;
  final VoidCallback onClose;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final Color stripColor = isError ? const Color(0xFFFF3B30) : const Color(0xFF4CAF50);
    final Color iconColor = isError ? const Color(0xFFFF3B30) : const Color(0xFF4CAF50);
    final Color iconBgColor = isError ? const Color(0xFFFF3B30).withOpacity(0.1) : const Color(0xFF4CAF50).withOpacity(0.1);
    final Color borderColor = isError ? const Color(0xFFFF3B30).withOpacity(0.3) : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: stripColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Image
                        if (image != null && image!.isNotEmpty)
                          Container(
                            width: 56,
                            height: 56,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                              image: DecorationImage(
                                image: NetworkImage(image!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 56,
                            height: 56,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isError ? Icons.delete_outline : Icons.check_circle_outline,
                              color: iconColor,
                              size: 28,
                            ),
                          ),

                        // Text Content
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),

                              // ✅ SKU Section (Green & Bold)
                              if (sku != null && sku!.isNotEmpty && !isError) ...[
                                const SizedBox(height: 2),
                                Text(
                                  "SKU: $sku",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4CAF50), // Green
                                  ),
                                ),
                              ],

                              const SizedBox(height: 6),
                              Text(
                                message,
                                maxLines: 4, // Allow more lines for error messages
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isError ? Colors.red.shade700 : Colors.grey.shade700, // Red text if error
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // View Button
                        if (onPressed != null && !isError)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: TextButton(
                              onPressed: onPressed,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                backgroundColor: primaryColor.withOpacity(0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                "View",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),

                        // Close Button
                        if (isError || onPressed == null)
                          InkWell(
                            onTap: onClose,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Icon(Icons.close, size: 22, color: Colors.grey.shade400),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}