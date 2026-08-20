

import 'package:http/http.dart' as http;
import 'dart:convert';
class AuthService{
static const String baseUrl = "http://192.168.0.105:8081";

Future<http.Response> register(
  String name,
  String email,
  String password
) async{
  final url =  Uri.parse('$baseUrl/api/auth/register');
  final response = await http.post(
    url,
    headers :{
      'Content-Type' : 'application/json',
    },
    body: jsonEncode({
      'name' : name ,
      'email' : email,
      'password' : password
    }),
  );
  if(response.statusCode == 201){

  }
  return response;
}
}
