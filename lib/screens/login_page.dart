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

  // Fonction pour gérer la connexion
  void _signIn() async {
    String login = _loginController.text.trim();
    String password = _passwordController.text;

    if (login.isEmpty || password.isEmpty) {
      // Les champs sont vides, on ne fait rien
      print('Les champs ne doivent pas être vides.');
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
      if (e.code == 'user-not-found') {
        print('Aucun utilisateur trouvé pour cet email.');
      } else if (e.code == 'wrong-password') {
        print('Mot de passe incorrect.');
      } else {
        print('Erreur lors de la connexion : ${e.message}');
      }
    } catch (e) {
      print('Erreur : $e');
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