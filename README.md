# VintedIA2

Application prototype d'une version light de Vinted.

**Auteur** : Marouan Boulli 

**Formation** : Master 2 MIAGE IA2

**Année** : 2024

## Informations utiles

### Comptes utilisateurs

- **User 1** :  
Login : user1@gmail.com  
Password : tototo  

- **User 2** :   
Login : user2@gmail.com  
Password : tototo

### Emulateur

L'application a été testée et son bon fonctionnement validé sur :  
- Mon smartphone personnel : Google Pixel 8 (8 GB de RAM)
- Un émulateur d'Android Studio : Pixel 8 API 35 | x86_64 (6 GB de RAM)

**Important**: le modèle d'IA utilisé dans l'application possédant une taille importante (150 MB), il est primordiale d'avoir un émulateur avec suffisamment de RAM pour pouvoir le charger.  
Une autre solution pour éviter ces prérequis liés à la mémoire aurait été d'héberger le modèle sur un serveur distinct (e.g. en python avec FastAPI).

### Images de test

Les images pour tester le modèle d'IA sont disponibles dans le dossier [ai_model/](./ai_model/img_test/).  
Il s'agit d'images quelconques téléchargées sur le web.

## Structure des dossiers principaux

- [ai_model/](./ai_model/) : contient le notebook utilisé pour tester et exporter le modèle d'IA au format onnx, ainsi que les images de test.
- [assets/model/](./assets/model/) : modèle exporté au format onnx.
- [lib/screens/](./lib/screens/) : toutes les pages de l'application dans des fichiers distincts.
- [lib/services/](./lib/services/) : implémentation du service de prédiction du plugin [onnxruntime](https://pub.dev/packages/onnxruntime).
- [lib/utils/](./lib/utils/) : fichiers utiles pour le preprocessing des données d'entrée du modèle d'IA (explications plus détaillées ci-dessous).



## Classification des images de vêtements

Le modèle d'intelligence artificielle utilisé n'est pas un modèle classique de classification, il s'agit d'un modèle de classification "zero shot" (multi-modal) développé par OpenAI et nommé [CLIP](https://huggingface.co/docs/transformers/en/model_doc/clip).  
Ce type de modèles prend en entrée deux informations : 
- Une image à classifier.
- Une liste de catégories sous forme de texte, par exemple dans le cadre de cette application :
```python
["a photo of a dress", "a photo of a t-shirt", "a photo of pants", "a photo of a jacket", "a photo of underwear", "a photo of shoes", "a photo of hat", "a photo of a sweater"]
```

Ce modèle présente deux avantages notables comparé aux modèles de classiques :
- Il a déjà été entraîné sur des millions d'images, nul besoin de le ré-entraîner.
- Il est généralisable à un grand nombre de catégories, inutile de collecter un nouveau dataset avec des nouvelles catégories, pour en ajouter des nouvelles il suffit des les ajouter à la liste de catégories donnée en entrée du modèle.

**Note :** il convient toutefois de noter qu'en général la taille en mémoire de ce type de modèle est conséquente. C'est pourquoi une technique de quantification permettant de réduire significativement la taille du modèle tout en préservant une précision convenable est utilisée dans ce projet (cf [Quantification avec ONNXRuntime](https://onnxruntime.ai/docs/performance/model-optimizations/quantization.html)).  
  
Un autre modèle similaire mais plus léger développé par Apple et nommé [MobileCLIP](https://huggingface.co/apple/MobileCLIP-S1) a aussi été testé. Cependant, il n'a pas été retenu car le processus de quantification sur ce modèle ne permet pas de conserver une précision acceptable.  
  
Ces expérimentations et l'export du modèle d'IA sont disponible dans le notebook [clothes-classification.ipynb](./ai_model/clothes_classification.ipynb) dans le dossier [ai_model](./ai_model/).  

### Workflow de déploiement du modèle sur Flutter

#### Export et quantification du modèle

Le modèle étant un modèle PyTorch, il n'est pas possible de l'utiliser tel quel sur Flutter. Il faut passer par un runtime adapté à l'environnement mobile et supporté par Flutter. Deux solutions principales sont possibles : 
- Utiliser le runtime [TensorflowLite](https://www.tensorflow.org/lite/guide?hl=fr) développé par Google, auquel cas il faut exporter le modèle au format **.tflite**.
- Utiliser le runtime [ONNXRuntime](https://onnxruntime.ai/) développé par Microsoft, auquel cas il faut exporter le modèle au format **.onnx**.

La seconde solution est préférée à la première car il est plus simple d'exporter un modèle PyTorch en format .onnx plutôt que .tflite.  
Un plugin Flutter nommé [onnxruntime](https://pub.dev/packages/onnxruntime) est utilisé pour effectuer les prédictions avec le modèle onnx sur Flutter.  

Voici les étapes nécessaires pour exporter le modèle au format onnx :
- Charger le modèle PyTorch en utilisant la bibliothèque [transformers](https://huggingface.co/docs/transformers/index) de HuggingFace.
- Etablir la liste des catégories à classifier et les tokeniser en utilisant le tokenizer fournit par la bibliothèque. Le modèle ne prend pas en entrée les catégories sous forme de texte mais plutôt sous forme de tokens. Les tokens obtenus correspondant à la liste de catégories à prédire doivent ensuite être exportés sous forme de liste .dart pour être réutilisés dans l'application Flutter en entrée du modèle.
- Tester le modèle sur des images.
- Exporter le modèle au format .onnx.
- Quantifier le modèle pour réduire sa taille : on passe de 600 MB à 150 MB avec une perte de précision non significative. 

Toutes ces étapes sont réalisées dans le notebook [clothes-classification.ipynb](./ai_model/clothes_classification.ipynb) dans le dossier [ai_model](./ai_model/).

#### Utilisation du modèle dans Flutter

Comme mentionné précédemment, il faut utiliser le plugin [onnxruntime](https://pub.dev/packages/onnxruntime).  
Son utilisation est matérialisée dans le fichier [onnx_service.dart](./lib/services/onnx_service.dart) dans le dossier [lib/services/](./lib/services/).  
C'est ensuite la page [add_clothing_item_page.dart](./lib/screens/add_clothing_item_page.dart) dans le dossier [lib/screens/](./lib/screens/) qui utilise ce service pour prédire la catégorie de vêtement à partir de l'image uploadé par l'utilisateur.
  
Deux autres fichiers sont importants pour l'utilisation du modèle : 
- [input_ids.dart](./lib/utils/input_ids.dart) dans le dossier [lib/utils/](./lib/utils/) : contient la liste des tokens correspondant aux catégories à classifier.
- [image_preprocessing.dart](./lib/utils/image_preprocessing.dart) dans le dossier [lib/utils/](./lib/utils/) : contient le preprocessing à appliquer sur l'image d'entrée du modèle.

### Notebook pour l'export du modèle

**(Cette partie n'est pas nécessaire pour faire tourner l'application, le modèle est déjà prêt.)**

Le notebook [clothes-classification.ipynb](./ai_model/clothes_classification.ipynb) dans le dossier [ai_model](./ai_model/) permet de réaliser totues les étapes nécessaires à l'export du modèle.  
Toutes les dépendances Python nécessaires se trouvent dans le Pipfile.  
  
Pour installer les dépendances Python :
```
cd ai_model
```
```
pip install pipenv
```
```
pipenv install
```

## Références

[HuggingFace transformers](https://huggingface.co/docs/transformers/index)  
[Modèle CLIP](https://huggingface.co/docs/transformers/en/model_doc/clip)  
[ONNXRuntime](https://onnxruntime.ai/)  
[Quantification avec ONNXRuntime](https://onnxruntime.ai/docs/performance/model-optimizations/quantization.html)  
[Plugin onnxruntime](https://pub.dev/packages/onnxruntime)