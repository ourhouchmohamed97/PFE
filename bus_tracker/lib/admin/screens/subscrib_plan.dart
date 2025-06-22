import 'package:bus_tracker/admin/screens/add_pyment.dart';
import 'package:bus_tracker/admin/screens/admin_home.dart';
import 'package:bus_tracker/core/widgets/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SubscriptionPlanPage extends StatefulWidget {
  const SubscriptionPlanPage({super.key});

  @override
  _SubscriptionPlanPageState createState() => _SubscriptionPlanPageState();
}

class _SubscriptionPlanPageState extends State<SubscriptionPlanPage> {
  final String currentPlan = "Free"; // From user account
  String? selectedPlan; 
   String? companyId;// User's temporary selection
  Future<void> loadCompanyId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final adminDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!adminDoc.exists) return;

      final data = adminDoc.data();
      if (data == null || data['companyId'] == null) return;

      setState(() {
        companyId = data['companyId'] as String;
      });
    } catch (e) {
      debugPrint('Failed to load company ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Your Plan"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Green Alert
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDFF5E3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Your current subscription expires in 3 days. Upgrade today!",
                    style: TextStyle(color: Colors.green.shade900),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Plans
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  _buildPlanCard(
                    title: "Free",
                    price: "\$0",
                    features: [
                      "Basic app tracking",
                      "Limited analytics",
                      "Single user access",
                      "Community support",
                    ],
                    highlightTag: "Your Plan",
                  ),
                  _buildPlanCard(
                    title: "Plus",
                    price: "\$20",
                    features: [
                      "Advanced app tracking",
                      "Detailed insights dashboard",
                      "Multi-user collaboration",
                      "Priority email support",
                      "5GB data storage",
                    ],
                    highlightTag: "Most Popular",
                    highlightColor: Colors.amber,
                  ),
                  _buildPlanCard(
                    title: "Pro",
                    price: "\$200",
                    features: [
                      "Unlimited app tracking",
                      "Customizable reports",
                      "Dedicated account manager",
                      "Enterprise-grade security",
                      "Unlimited data storage",
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Continue Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ElevatedButton(
              onPressed: selectedPlan != null
                  ? () async {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
                            .get();

                        final companyId = userDoc.data()?['companyId'];

                        if (companyId != null) {
                          // ✅ Save the selected plan to company
                          await FirebaseFirestore.instance
                              .collection('companies')
                              .doc(companyId)
                              .update({'plan': selectedPlan});

                          // ✅ Navigate according to plan
                          if (selectedPlan == 'Free') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const AdminHomePage()),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>  AddPaymentMethodPage(companyId: companyId)),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Company ID not found.')),
                          );
                        }
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    selectedPlan != null ? blueColor : Colors.grey.shade300,
                foregroundColor:
                    selectedPlan != null ? Colors.white : Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Continue"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required List<String> features,
    String? highlightTag,
    Color highlightColor = Colors.blue,
  }) {
    bool isSelected =
        selectedPlan == title || (selectedPlan == null && currentPlan == title);
    bool isInitiallyCurrent = currentPlan == title && selectedPlan == null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlightTag != null)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: highlightColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  highlightTag,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("$price /month",
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (currentPlan == title && selectedPlan == null)
                  ? null
                  : () {
                      setState(() {
                        selectedPlan = title;
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isSelected ? Colors.blue : Colors.grey.shade200,
                foregroundColor: isSelected ? Colors.white : Colors.black,
              ),
              child: Text(
                (selectedPlan == title || isInitiallyCurrent)
                    ? "Current Plan"
                    : "Select Plan",
              ),
            ),
          )
        ],
      ),
    );
  }
}
