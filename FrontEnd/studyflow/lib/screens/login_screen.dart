import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  
const LoginScreen({super.key});
@override
  State<LoginScreen> createState() {
    
    return _LoginScreenState();
  }
}

class _LoginScreenState extends State<LoginScreen> {
   bool ispasswordHidden = true;
  TextEditingController emailController =  TextEditingController();
  TextEditingController passwordController =   TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey();
  @override
  void dispose(){
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
   
  }
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return 
    Scaffold(
        body:
        SafeArea(
          child: 
            SingleChildScrollView(
              child:
              Padding(
                padding: EdgeInsets.all(20),
                child: 
                Column(
                  children: [
                    Image.asset('assets/images/study_flow_logo.png',
                    height: 115,
                    width: 115,
                    ),
                    Text("StudyFlow",
                    style: 
                    TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      color:Color.fromRGBO(99, 102, 214, 1.2) ,
                    ),
                    ),
                    SizedBox(height: 25,),
                    
                    Text("Welcome back",
                          style:TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize : 32
                          )
                        
                      ),
                    SizedBox(height: 5,),
                    Text("Enter your details to continue",
                      ),
                    SizedBox(height: 10,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      
                      children: [
                      Text("Email",
                      style: TextStyle(
                      ),
                    ),
                    SizedBox(height: 5,),
                    Form(
                      key: formKey,
                      child: Column(
                      children: [
                        TextFormField(
                          validator: (value){
                        if(value ==  null || value.isEmpty){
                          return "Email is required";
                        }
                        else if(!value.contains("@")){
                          return "please enter a valid email";
                        }
                        return null;

                      },
                      
                        controller:  emailController,
                        decoration: InputDecoration(
                        hintText: "student@university.edu",
                        prefixIcon: 
                        Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        )
                      ),
                      
                    ),
                    Row(
                      children: [
                      Text("password"),
                      Spacer(),
                      TextButton(
                        onPressed:(){
                        },
                      child: Text("Forgot password?",
                        style: TextStyle(
                          color: Color.fromRGBO(53, 37, 205, 1.2) ,
                          decoration: TextDecoration.underline,
                        ),
                      ))
                      ],
                    ),
                    TextFormField(
                      
                      obscureText: ispasswordHidden,
                      controller:  passwordController,
                      decoration: InputDecoration(
                        hintText: "enter your password",
                        prefixIcon: 
                        Icon(Icons.lock),
                        suffixIcon: IconButton(onPressed: (){
                          setState(() {
                            ispasswordHidden = !ispasswordHidden;
                          });
                        }, 
                        icon: Icon( !ispasswordHidden?Icons.visibility:Icons.visibility_off)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        )
                      ),
                      validator: (value){
                        if(value ==  null || value.isEmpty){
                          return "password is required";
                        }
                        return null;

                      },
                    ),
                      ],
                    ),)
                    ],),
                    
                    SizedBox(height: 20,),
                    ElevatedButton(onPressed:(){
                      
                      bool isValid = formKey.currentState?.validate() ?? false;
                      if(isValid){
                        print("valid form");
                      }
                    },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(53, 37, 205,1.0),
                        foregroundColor: Colors.white,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        minimumSize: 
                        Size( double.infinity, 60),
                      ),
                    child: Text("Login  ->",
                      style: 
                      TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      )),
                      SizedBox(height: 20,),
                      Text.rich(
                        TextSpan(
                          text: 'Don\'t have an account? ',
                          children: [
                            TextSpan(
                              
                              text: 'Sign Up',
                            recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                    Navigator.push(context
                                    , MaterialPageRoute(
                                      builder: 
                                      (context){
                                      return SignUpScreen();
                                    },
                                    ));
                                },
                              style: TextStyle(
                                color: Color.fromRGBO(53, 37, 205,1.2),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                          ),
                        ]
                      )
                    )
                  ],
                )
              ), 
            )
          )
        );
  }
}
