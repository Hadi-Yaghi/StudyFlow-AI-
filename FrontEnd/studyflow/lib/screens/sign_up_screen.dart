import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() {
    return _SignUpScreenState();
  }
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool agreedtoTerms = false;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool hasMinlength = false;
  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasNumber = false;
  bool hasSpecialCharacter = false;
  bool ispasswordfocus = true;
  FocusNode passwordFocuseNode = FocusNode();
  int strength = 0;
  @override
  void initState() {
    int weak = 0;
    int medium = 1;
    int strong = 2;

    super.initState();
    passwordController.addListener(() {
      int length = passwordController.text.length;
      setState(() {
        if (length < 5) {
          strength = weak;
        } else if (length >= 5 && length <= 8) {
          strength = medium;
        } else {
          strength = strong;
        }
        hasMinlength = length >= 8;
        hasUppercase = RegExp(r'[A-Z]').hasMatch(passwordController.text);
        hasLowercase = RegExp(r'[a-z]').hasMatch(passwordController.text);
        hasNumber = RegExp(r'[0-9]').hasMatch(passwordController.text);
        hasSpecialCharacter = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]')
            .hasMatch(passwordController.text);
      });
    });
    passwordFocuseNode.addListener(() {
      setState(() {
        if (ispasswordfocus) {
          ispasswordfocus = passwordFocuseNode.hasFocus;
        }
      });
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/study_flow_logo.png',
                      height: 90,
                      width: 90,
                    ),
                    Text(
                      "Create Account",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text("Join StudyFlow and organize your acadmic \n life."),
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("FULL NAME"),
                    ),
                    Form(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: nameController,
                            validator: (value) {
                              if (value == null) {
                                return "name is required";
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: "Jane Doe",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text("EMAIL ADDRESS"),
                          ),
                          TextFormField(
                            controller: emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Email Address is Required";
                              } else if (!value.contains("@")) {
                                return "please Enter  a  valid Email Address";
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: "student@university.edu",
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text("PASSWORD"),
                          ),
                          TextFormField(
                            controller: passwordController,
                            autofocus: false,
                            decoration: InputDecoration(
                              hintText: "••••••••••••",
                              prefixIcon: Icon(Icons.lock),
                              
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.visibility),
                              ),
                            ),
                            focusNode: passwordFocuseNode,
                          ),

                          SizedBox(height: 3),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              strength == 0
                                  ? "Weak"
                                  : strength == 1
                                  ? "Medium"
                                  : "Strong",
                            ),
                          ),
                          SizedBox(height: 5),
                          LinearProgressIndicator(
                            value: strength / 2,
                            color: strength == 0
                                ? Colors.red
                                : strength == 1
                                ? Colors.orange
                                : Colors.green,
                          ),
                          if (ispasswordfocus)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                              "At least 8 characters",
                                  style: TextStyle(
                                    decoration: hasMinlength
                                    ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                   ),
                                          ),
                                    SizedBox(width: 5,),
                                    Icon(
                                      hasMinlength
                                          ?  Icons.check_circle
                                          : Icons.circle_outlined,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text("CONFIRM PASSWORD"),
                          ),
                          TextField(
                            decoration: InputDecoration(
                              hintText: "••••••••••••",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: Icon(Icons.lock),
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        Checkbox(
                          value: agreedtoTerms,
                          onChanged: (value) => {},
                        ),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'I agree to the ',
                              children: [
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: Color.fromRGBO(53, 37, 205, 1.2),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: Color.fromRGBO(53, 37, 205, 1.2),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(53, 37, 205, 1.0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        minimumSize: Size(double.infinity, 60),
                      ),
                      child: Text(
                        "CREATE ACCOUNT ->",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),

                    SizedBox(height: 25),
                    Divider(
                      color: Colors.grey,
                      thickness: 1,
                      indent: 0,
                      endIndent: 0,
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: "Already have an Account?",
                            children: [
                              TextSpan(
                                text: 'Login',
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return LoginScreen();
                                        },
                                      ),
                                    );
                                  },
                                style: TextStyle(
                                  color: Color.fromRGBO(53, 37, 205, 1.2),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
