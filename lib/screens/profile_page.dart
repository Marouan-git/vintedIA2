import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'package:flutter/services.dart';
import 'add_clothing_item_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Instances Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Contrôleurs de texte
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  DateTime? _selectedDate; // Pour la date de naissance

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Charger les données de l'utilisateur depuis Firestore
  void _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _loginController.text = data['login'] ?? '';
          _passwordController.text = '********'; // Mot de passe obfusqué
          _addressController.text = data['address'] ?? '';
          _postalCodeController.text = data['postalCode'] ?? '';
          _cityController.text = data['city'] ?? '';

          // Gestion de la date de naissance
          Timestamp? birthdayTimestamp = data['birthday'];
          if (birthdayTimestamp != null) {
            DateTime birthday = birthdayTimestamp.toDate();
            _selectedDate = birthday;
            _birthdayController.text = '${birthday.toLocal()}'.split(' ')[0];
          }
        });
      }
    }
  }

  // Sélecteur de date pour l'anniversaire
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
        _birthdayController.text = '${picked.toLocal()}'.split(' ')[0];
      });
  }

  // Sauvegarder les données en base
  void _saveUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Mettre à jour les informations dans Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'address': _addressController.text.trim(),
          'postalCode': _postalCodeController.text.trim(),
          'city': _cityController.text.trim(),
          'birthday': _selectedDate != null
              ? Timestamp.fromDate(_selectedDate!)
              : null,
        });

        // Mettre à jour le mot de passe si modifié
        if (_passwordController.text.isNotEmpty &&
            _passwordController.text != '********') {
          await user.updatePassword(_passwordController.text);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Informations mises à jour avec succès.')),
        );
      } catch (e) {
        print('Erreur lors de la mise à jour des données : $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Erreur lors de la mise à jour des informations.')),
        );
      }
    }
  }

  // Déconnexion de l'utilisateur
  void _logout() async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0),
      child: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Login (lecture seule)
              TextField(
                controller: _loginController,
                decoration: InputDecoration(labelText: 'Login'),
                readOnly: true,
              ),
              SizedBox(height: 16),
              // Mot de passe (obfusqué)
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
              ),
              SizedBox(height: 16),
              // Anniversaire
              TextField(
                controller: _birthdayController,
                decoration: InputDecoration(
                  labelText: 'Date de naissance',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: 16),
              // Adresse
              TextField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Adresse'),
              ),
              SizedBox(height: 16),
              // Code postal (clavier numérique)
              TextField(
                controller: _postalCodeController,
                decoration: InputDecoration(labelText: 'Code postal'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SizedBox(height: 16),
              // Ville
              TextField(
                controller: _cityController,
                decoration: InputDecoration(labelText: 'Ville'),
              ),
              SizedBox(height: 32),
              // Bouton Ajouter un vêtement
              ElevatedButton(
                onPressed: () {
                  // Naviguer vers la page d'ajout de vêtement
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddClothingItemPage(),
                    ),
                  );
                },
                child: Text('Ajouter un vêtement'),
              ),
              SizedBox(height: 16),
              // Bouton Valider
              ElevatedButton(
                onPressed: _saveUserData,
                child: Text('Valider'),
              ),
              SizedBox(height: 16),
              // Bouton Se déconnecter
              ElevatedButton(
                onPressed: _logout,
                child: Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
