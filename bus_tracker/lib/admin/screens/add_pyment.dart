import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutterwave_standard/flutterwave.dart';


class AddPaymentMethodPage extends StatefulWidget {
  final String companyId;
  AddPaymentMethodPage({Key? key, required this.companyId}) : super(key: key);

  @override
  State<AddPaymentMethodPage> createState() => _AddPaymentMethodPageState();
}

class _AddPaymentMethodPageState extends State<AddPaymentMethodPage> {
   String? companyPlan;
  bool isLoading = true;
  String selectedMethod = 'Visa';
  bool isDefault = false;
  bool useBillingAddress = true;
  
  String? adminName;
  String? adminEmail;
  String? adminPhone;

  final _nameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expDateController = TextEditingController();
  final _cvvController = TextEditingController();
  @override
  void initState() {
    super.initState();
    fetchCompanyPlan();
     loadAdminInfo();
  }
  
  Future<void> loadAdminInfo() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

  if (doc.exists && doc['role'] == 'admin') {
    setState(() {
      adminName = doc['name'];
      adminEmail = doc['email'];
      adminPhone = doc['phone']; // Optional
    });
  } else {
    // Not an admin or doc doesn't exist
    print("User is not an admin or document not found.");
  }
}

  Future<void> fetchCompanyPlan() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .get();

      if (doc.exists) {
        setState(() {
          companyPlan = doc.data()?['plan'] ?? "plus"; // default plan if missing
          isLoading = false;
        });
      } else {
        // Company doc not found
        setState(() {
          companyPlan = "plus";
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching company plan: $e");
      setState(() {
        companyPlan = "plus";
        isLoading = false;
      });
    }
  }

  String getAmountBasedOnPlan() {
    if (companyPlan == null) return "0";
    if (companyPlan!.toLowerCase() == "plus") return "200";
    if (companyPlan!.toLowerCase() == "pro") return "2000";
    return "0";
  }
  Widget _buildCardTypeButton(String label, Widget icon, String method) {
    bool isSelected = selectedMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedMethod = method;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Column(
            children: [
              icon,
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.poppins(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      hintStyle: GoogleFonts.poppins(fontSize: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

 Future<void> _makePayment() async {
  if (_nameController.text.isEmpty ||
      _cardNumberController.text.isEmpty ||
      _expDateController.text.isEmpty ||
      _cvvController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill all fields.")),
    );
    return;
  }

  final flutterwave = Flutterwave(
    
    publicKey: "FLWPUBK_TEST-055b5e0bc0b3c0510776fb3b1e58e2bb-X",
    currency: "MAD",
    redirectUrl: "https://flutterwave.com",
    txRef: "TX-${DateTime.now().millisecondsSinceEpoch}",
    amount: getAmountBasedOnPlan(),
    customer: Customer(
      name: adminName,
      phoneNumber: adminPhone,
      email: adminEmail ?? "ezzahirhaytham@gmail.com",
    ),
    paymentOptions: "card, paypal",
    customization: Customization(title: "HayMobility Payment"),
    isTestMode: true,
  );

  final response = await flutterwave.charge(context);

  if (response.status == "successful") {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Payment successful!")),
    );
    Navigator.pop(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ Payment failed or cancelled.")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
    return const Center(child: CircularProgressIndicator());
  }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Add Payment Method', style: GoogleFonts.poppins()),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Text("Select Card Type", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 30),
            Row(
              children: [
                _buildCardTypeButton("Visa", Image.asset('assets/images/visa.png', height: 24), 'Visa'),
                const SizedBox(width: 10),
                _buildCardTypeButton("Mastercard", Image.asset('assets/images/mastercard.png', height: 30), 'Mastercard'),
                const SizedBox(width: 10),
                _buildCardTypeButton("PayPal", const Icon(FontAwesomeIcons.paypal, size: 30, color: Colors.blue), 'PayPal'),
              ],
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _nameController,
              decoration: _inputDecoration("John M. Doe", Icons.person_outline),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _cardNumberController,
              decoration: _inputDecoration("XXXX XXXX XXXX XXXX", Icons.credit_card),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(19),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expDateController,
                    decoration: _inputDecoration("MM/YY", Icons.date_range),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                      ExpiryDateFormatter(),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cvvController,
                    decoration: _inputDecoration("***", Icons.lock_outline),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            CheckboxListTile(
              value: isDefault,
              onChanged: (val) => setState(() => isDefault = val!),
              title: Text("Set as default payment method", style: GoogleFonts.poppins()),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              value: useBillingAddress,
              onChanged: (val) => setState(() => useBillingAddress = val!),
              title: Text("Use billing address from profile", style: GoogleFonts.poppins()),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: _makePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Center(
                child: Text("Save & Pay", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll('/', '');

    if (text.length >= 3) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    }

    if (text.length > 5) {
      text = text.substring(0, 5);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
