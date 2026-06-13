import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:fitness/config.dart';

class PlanPurchasePage extends StatefulWidget {
  final Map<String, dynamic> planData;

  const PlanPurchasePage({super.key, required this.planData});

  @override
  State<PlanPurchasePage> createState() => _PlanPurchasePageState();
}

class _PlanPurchasePageState extends State<PlanPurchasePage> {
  late TextEditingController cardNumberController;
  late TextEditingController cardHolderController;
  late TextEditingController expiryController;
  late TextEditingController cvvController;

  bool isProcessing = false;
  bool isPlanFree = false;

  @override
  void initState() {
    super.initState();
    cardNumberController = TextEditingController();
    cardHolderController = TextEditingController();
    expiryController = TextEditingController();
    cvvController = TextEditingController();

    // Check if plan is free
    final price = widget.planData['price'];
    isPlanFree = price == null || price == 0 || price == '0' || price == '0.0';
  }

  @override
  void dispose() {
    cardNumberController.dispose();
    cardHolderController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  Future<void> _processPurchase() async {
    if (!isPlanFree) {
      // Validate card details for paid plans
      if (cardNumberController.text.isEmpty) {
        _showSnackBar('Please enter card number', isError: true);
        return;
      }
      if (cardNumberController.text.replaceAll(' ', '').length < 13) {
        _showSnackBar('Card number must be at least 13 digits', isError: true);
        return;
      }
      if (cardHolderController.text.isEmpty) {
        _showSnackBar('Please enter card holder name', isError: true);
        return;
      }
      if (expiryController.text.isEmpty) {
        _showSnackBar('Please enter expiry date', isError: true);
        return;
      }
      if (!expiryController.text.contains('/')) {
        _showSnackBar('Expiry date format should be MM/YY', isError: true);
        return;
      }
      if (cvvController.text.isEmpty) {
        _showSnackBar('Please enter CVV', isError: true);
        return;
      }
      if (cvvController.text.length < 3) {
        _showSnackBar('CVV must be at least 3 digits', isError: true);
        return;
      }
    }

    setState(() => isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final username = prefs.getString('username');

      if (token == null || username == null) {
        _showSnackBar('Authentication error', isError: true);
        return;
      }

      // our backend now exposes a more RESTful endpoint that lives under
      // /plans and only requires the plan id in the path.  we no longer need
      // to send the username or coach name in the body – the server derives
      // both from the JWT token and the plan record.
      final url =
          "${Config.apiBaseUrl}/plans/${widget.planData['id']}/purchase";

      // we can still send card details if we like, but the API ignores them.
      final Map<String, dynamic> body = {};
      if (!isPlanFree) {
        body.addAll({
          "card_number": cardNumberController.text.replaceAll(' ', ''),
          "card_holder": cardHolderController.text,
          "expiry": expiryController.text,
          "cvv": cvvController.text,
        });
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body.isEmpty ? null : jsonEncode(body),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Plan purchased successfully!', isError: false);

        // Save purchase notification
        await _savePurchaseNotification(username);

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context, true); // Return true to refresh plans list
          }
        });
      } else {
        _showSnackBar(
          'Failed to purchase plan: ${response.statusCode}',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _savePurchaseNotification(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];

      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': 'Payment Succeeded',
        'message': 'Plan "${widget.planData['title']}" purchased successfully!',
        'time': 'now',
        'type': 'purchase',
      };

      notificationsJson.insert(0, jsonEncode(notification));
      await prefs.setStringList('notifications', notificationsJson);
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF1CFF4D),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050D09),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B1A12), Color(0xFF050D09)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Purchase Plan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Plan Summary Card
                  _buildPlanSummary(),
                  const SizedBox(height: 30),

                  // Payment Section (Only for Paid Plans)
                  if (!isPlanFree) ...[
                    Text(
                      "PAYMENT DETAILS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCardForm(),
                  ] else
                    // Free Plan Section
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 64,
                            color: const Color(0xFF1CFF4D),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "This is a Free Plan",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "No payment required. Click confirm to proceed.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Confirm Button
                  _buildConfirmButton(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSummary() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2A22).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF1CFF4D).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.planData['title'] ?? 'Plan',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.person,
                    label: widget.planData['coach_name'] ?? 'Coach',
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    icon: Icons.calendar_today,
                    label: '${widget.planData['duration'] ?? 0} weeks',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Price',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    isPlanFree ? 'FREE' : '\$${widget.planData['price'] ?? 0}',
                    style: const TextStyle(
                      color: Color(0xFF1CFF4D),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1CFF4D).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1CFF4D).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1CFF4D)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        _buildCardInput(
          label: "Card Number",
          controller: cardNumberController,
          hint: "1234 5678 9012 3456",
          maxLength: 19,
          icon: Icons.credit_card,
        ),
        const SizedBox(height: 16),
        _buildCardInput(
          label: "Card Holder Name",
          controller: cardHolderController,
          hint: "John Doe",
          icon: Icons.person,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCardInput(
                label: "Expiry",
                controller: expiryController,
                hint: "MM/YY",
                maxLength: 5,
                icon: Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardInput(
                label: "CVV",
                controller: cvvController,
                hint: "123",
                maxLength: 3,
                isPassword: true,
                icon: Icons.lock,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int? maxLength,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          maxLength: maxLength,
          keyboardType: label == "Card Number"
              ? TextInputType.number
              : TextInputType.text,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white30),
            prefixIcon: Icon(icon, color: const Color(0xFF1CFF4D)),
            filled: true,
            fillColor: const Color(0xFF1A2A22),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            counterText: "",
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: const Color(0xFF1CFF4D).withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1CFF4D)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isProcessing ? null : _processPurchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1CFF4D),
          disabledBackgroundColor: const Color(
            0xFF1CFF4D,
          ).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Text(
                isPlanFree ? "Confirm Free Plan" : "Complete Purchase",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
