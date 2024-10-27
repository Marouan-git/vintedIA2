import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../services/onnx_service.dart';
import '../utils/image_preprocessing.dart';
import '../services/onnx_service.dart';

class AddClothingItemPage extends StatefulWidget {
  const AddClothingItemPage({Key? key}) : super(key: key);

  @override
  _AddClothingItemPageState createState() => _AddClothingItemPageState();
}

class _AddClothingItemPageState extends State<AddClothingItemPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  File? _imageFile;
  String? _category;

  // Method to pick image
  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        _detectCategory();
      }
    } catch (e) {
      print('Erreur lors de la sélection de l\'image : $e');
    }
  }

  // Detect category using AI model
  Future<void> _detectCategory() async {
    if (_imageFile != null) {
      try {
        // Preprocess image for ONNX model
        List<List<List<List<double>>>> preprocessedImage = await preprocessImage(_imageFile!);

        // Get the singleton instance of OnnxService
        final onnxService = OnnxService();
        
        // Call ONNX service to run inference
        //String detectedCategory = await runOnnxInference(preprocessedImage);
        String detectedCategory = await onnxService.runInference(preprocessedImage);

        setState(() {
          _category = detectedCategory;  // Update category with detected one
        });
      } catch (e) {
        print("Erreur lors de la détection de la catégorie: $e");
        setState(() {
          _category = "Autre";  // Fallback category
        });
      }
    }
  }

  void _saveClothingItem() async {
    if (_imageFile == null ||
        _titleController.text.isEmpty ||
        _sizeController.text.isEmpty ||
        _brandController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('Utilisateur non connecté.');
        return;
      }

      // Upload image to Firebase Storage
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('clothes_images').child(fileName);
      UploadTask uploadTask = ref.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      // Save to Firestore
      await _firestore.collection('clothes').add({
        'imageUrl': imageUrl,
        'title': _titleController.text.trim(),
        'category': _category,
        'size': _sizeController.text.trim(),
        'brand': _brandController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'ownerId': user.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vêtement ajouté avec succès.')),
      );

      // Reset the form
      setState(() {
        _imageFile = null;
        _titleController.clear();
        _sizeController.clear();
        _brandController.clear();
        _priceController.clear();
        _category = null;
      });
    } catch (e) {
      print('Erreur lors de la sauvegarde du vêtement : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout du vêtement.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter un vêtement'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: GestureDetector(
                onTap: _pickImage,
                child: _imageFile != null
                    ? ClipOval(
                        child: Image.file(
                          _imageFile!,
                          height: 100,
                          width: 100, 
                          fit: BoxFit.cover,
                        ),
                      )
                    : ClipOval(
                        child: Container(
                          height: 100,
                          width: 100, 
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.add_a_photo,
                            size: 50,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8), // Espacement entre l'image et le texte
            const Text(
              'Ajouter des photos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 32),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Titre'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: _category ?? ''),
              decoration: InputDecoration(labelText: 'Catégorie'),
              readOnly: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _sizeController,
              decoration: InputDecoration(labelText: 'Taille'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _brandController,
              decoration: InputDecoration(labelText: 'Marque'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Prix'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            SizedBox(height: 64),
            ElevatedButton(
              onPressed: _saveClothingItem,
              child: Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }
}