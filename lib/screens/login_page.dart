import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Contrôleurs pour les champs de texte
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Instance de FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Variable pour le message d'erreur
  String? _errorMessage;

  // Fonction pour gérer la connexion
  void _signIn() async {
    String login = _loginController.text.trim();
    String password = _passwordController.text;

    if (login.isEmpty || password.isEmpty) {
      // Les champs sont vides, afficher un message d'erreur
      setState(() {
        _errorMessage = 'Les champs ne doivent pas être vides.';
      });
      return;
    }

    try {
      // Tentative de connexion
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: login,
        password: password,
      );
      // Connexion réussie, redirection vers la page suivante
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      // Gestion des erreurs de connexion
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'Aucun utilisateur trouvé pour cet email.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Mot de passe incorrect.';
        } else {
          _errorMessage = 'Login ou mot de passe incorrect';
        }
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur : $e';
      });
  }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('VintedIA2'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _loginController,
                decoration: const InputDecoration(
                  labelText: 'Login',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true, // Le champ est obfusqué
              ),
              const SizedBox(height: 16),
              // Afficher le message d'erreur s'il y en a un
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _signIn,
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}