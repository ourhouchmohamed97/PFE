import 'package:flutter/material.dart';

// COLORS :
const Color blueColor = Color.fromRGBO(0, 86, 210, 1);


// FONTS :
const TextStyle boldTextStyle = TextStyle(
  fontSize: 24,
  color: Color.fromARGB(255, 255, 255, 255),
  fontWeight: FontWeight.bold,
);




// WIDGETS :

//appBar

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final Color backgroundColor;
  final TextStyle? titleTextStyle;
  final bool showLogoutButton;
  final VoidCallback? onLogoutPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.backgroundColor = const Color.fromRGBO(0, 86, 210, 1),
    this.titleTextStyle,
    this.showLogoutButton = false,
    this.onLogoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color.fromARGB(255, 255, 255, 255)),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: titleTextStyle ?? const TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 255, 255)),
      ),
      centerTitle: true,
      backgroundColor: backgroundColor,
      actions: [
        if (showLogoutButton)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: onLogoutPressed,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}




// Backgroud
Widget BackgroundWidget({List<Widget> children = const []}) {
  return Scaffold(
  body: SafeArea(
    child: Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/images/bg.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
        Container(
              width: 146,
              height: 146,
              decoration: BoxDecoration(
                color: blueColor,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Image.asset(
                  'assets/images/bus.png',
                ),
              ),
            ),
      ],
    )
    ),
  );
}



// bottomBar
class CustomBottomBar extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const CustomBottomBar({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 68,
        width: double.infinity,
        color: blueColor, // Customize the color if needed
        alignment: Alignment.center,
        child: Text(
          text,
          style:boldTextStyle,  // Customize the text color if needed
          
        ),
      ),
    );
  }
}


// button 
class Mybutton extends StatelessWidget {
  final Function()? onTap;
  final String text;

  const Mybutton({super.key, required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10), // Adjusted padding
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: blueColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16, // Adjusted font size
            ),
            textAlign: TextAlign.center, // Center-align the text
            overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
            maxLines: 2, // Allow text to wrap to a second line if needed
          ),
        ),
      ),
    );
  }
}                 
  //squre Tile for google and apple
  class squareTile extends StatelessWidget {
  final String imagePath;
  final Function()? onTap;
   const squareTile({super.key , required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border : Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(16),
          color:Colors.grey[200],
        ),
        child: Image.asset(
          imagePath,
          height: 40,
        ),
      ),
    );
  }
}       

                   
                    
   
 



//textField

class CustomTextField extends StatefulWidget {
  final String labelText;
  final bool isPassword;
  final TextEditingController? controller;
  final TextStyle? labelStyle;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final String? errorText;

  const CustomTextField({
    super.key,
    required this.labelText,
    this.isPassword = false,
    this.controller,
    this.labelStyle,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.errorText,
  });

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  String? _internalErrorText;
  bool _obscureText = true; // State variable to toggle password visibility

  void validateInput(String value) {
    if (widget.validator != null) {
      setState(() {
        _internalErrorText = widget.validator!(value);
      });
    }
  }

  // Function to toggle password visibility
  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword ? _obscureText : false, // Control visibility for password fields
          keyboardType: widget.keyboardType,
          onChanged: validateInput,
          decoration: InputDecoration(
            labelText: widget.labelText,
            labelStyle: widget.labelStyle ??
                const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
            border: const UnderlineInputBorder(),
            contentPadding: const EdgeInsets.only(bottom: 5.0),
            errorText: widget.errorText ?? _internalErrorText, // Prioritize widget.errorText
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: _togglePasswordVisibility,
                  )
                : null, // Show eye icon only for password fields
          ),
        ),
      ],
    );
  }
}