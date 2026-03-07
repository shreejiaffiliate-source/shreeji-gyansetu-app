import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/course_model.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../screens/learning/lesson_player_screen.dart';
import '../../screens/learning/my_learning_screen.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/course_provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseModel course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear(); // Clean up listeners
    super.dispose();
  }

  // --- RAZORPAY HANDLERS ---

  void _startPayment() {
    // Get the effective price (discount price if available, otherwise original price)
    final String priceStr = widget.course.discountPrice ?? widget.course.price;
    final double price = double.tryParse(priceStr) ?? 0.0;

    var options = {
      'key': 'rzp_test_SOCWZ8L1q01O7W', // Replace with your actual key from Razorpay Dashboard
      'amount': (price * 100).toInt(), // Amount in paise
      'name': 'Shreeji GyanSetu',
      'description': widget.course.title,
      'prefill': {
        'contact': '9372149940', // Consider fetching from a UserProvider in future
        'email': 'kashyapdabhi23@gmail.com'
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error starting Razorpay: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // response.paymentId contains the ID returned by Razorpay
    if (response.paymentId != null) {
      _enrollUser(context, response.paymentId!);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("External Wallet selected: ${response.walletName}");
  }

  // --- SHARE FUNCTION ---
  void _shareCourse(BuildContext context) {
    final String baseUrl = "https://shreejigyansetu.com/courses/";
    final String shareUrl = "$baseUrl${widget.course.slug}/";

    final String message =
        "Check out this course: ${widget.course.title}\n\n"
        "Learn more at: $shareUrl\n\n"
        "Join Shreeji GyanSetu today!";

    Share.share(message, subject: 'Check out this course!');
  }

  // --- ENROLLMENT LOGIC ---
  // --- ENROLLMENT LOGIC ---
  Future<void> _enrollUser(BuildContext context, String paymentId) async {
    // Pass BOTH the course ID and the payment ID to the service
    final success = await ApiService().enrollInCourse(widget.course.id, paymentId);

    if (success) {
      if (!mounted) return;
      // Refresh the course list to update "isEnrolled" status globally
      await Provider.of<CourseProvider>(context, listen: false).fetchAllCourses();
      if (!mounted) return;
      _showSuccessDialog(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enrollment failed. Please contact support.")),
      );
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Congratulations!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "You have successfully enrolled in the course.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: "View Course",
              onPressed: () {
                Navigator.pop(context); // Close dialog
                if (widget.course.modules.isNotEmpty && widget.course.modules.first.lessons.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LessonPlayerScreen(lesson: widget.course.modules.first.lessons.first)),
                  );
                } else {
                  Navigator.pop(context); // Go back if no content
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.course.thumbnail,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.3),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          widget.course.level,
                          style: const TextStyle(color: AppColors.primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text("${widget.course.enrollmentCount} Students",
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13)),

                      const Spacer(),
                      if (widget.course.isEnrolled)
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "Enrolled",
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      else
                        GestureDetector(
                          onTap: _startPayment,
                          child: const Text(
                            "Enroll Now",
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(widget.course.title, style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Text("₹${widget.course.discountPrice ?? widget.course.price}", style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen)),
                      const SizedBox(width: 10),
                      if (widget.course.discountPrice != null)
                        Text("₹${widget.course.price}", style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textMuted)),
                      const Spacer(),

                      IconButton(
                        icon: const Icon(Icons.share, color: AppColors.primaryBlue),
                        onPressed: () => _shareCourse(context),
                      ),
                    ],
                  ),
                  const Divider(height: 40),

                  const Text("About this course", style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.course.description, style: const TextStyle(
                      color: AppColors.textMuted, height: 1.5)),

                  const SizedBox(height: 30),

                  const Text("Course Curriculum", style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (widget.course.modules.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text("Curriculum details coming soon.",
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    )
                  else
                    ...widget.course.modules.map((module) =>
                        _buildModuleSection(context, module)),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: CustomButton(
          text: widget.course.isEnrolled ? "Go to Dashboard" : "Enroll Now",
          isSecondary: true,
          onPressed: () {
            if (widget.course.isEnrolled) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyCoursesScreen()),
              );
            } else {
              _startPayment();
            }
          },
        ),
      ),
    );
  }

  Widget _buildModuleSection(BuildContext context, ModuleModel module) {
    final bool isModuleDone = module.lessons.isNotEmpty &&
        module.lessons.every((l) => l.isCompleted);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(12),
        color: isModuleDone ? AppColors.primaryGreen.withValues(alpha: 0.05) : null,
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Icon(
          isModuleDone ? Icons.verified : Icons.library_books,
          color: isModuleDone ? AppColors.primaryGreen : AppColors.primaryBlue,
        ),
        title: Text(
          module.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isModuleDone ? AppColors.primaryGreen : null,
          ),
        ),
        children: module.lessons.map((lesson) {
          final bool isLessonDone = lesson.isCompleted;

          return Container(
            color: isLessonDone ? AppColors.primaryGreen.withValues(alpha: 0.08) : Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.only(left: 32, right: 16),
              leading: Icon(
                isLessonDone
                    ? Icons.check_circle
                    : (widget.course.isEnrolled || lesson.isPreview)
                    ? Icons.play_circle_fill
                    : Icons.lock_outline,
                color: isLessonDone
                    ? AppColors.primaryGreen
                    : (widget.course.isEnrolled || lesson.isPreview)
                    ? AppColors.primaryCyan
                    : AppColors.textMuted,
                size: 20,
              ),
              title: Text(
                  lesson.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isLessonDone ? AppColors.textMuted : null,
                    fontWeight: isLessonDone ? FontWeight.w400 : FontWeight.w500,
                  )
              ),
              onTap: () {
                if (widget.course.isEnrolled || lesson.isPreview) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LessonPlayerScreen(lesson: lesson),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enroll in this course to unlock this lesson!")),
                  );
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
