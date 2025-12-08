import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:moviles/viewmodels/user_viewmodel.dart';
import 'package:provider/provider.dart';

import '/cache/user_cache.dart';
import '/repositories/user_repository.dart';
import '/models/user.dart';
import '/utils/current_screen.dart';

class UserEditForm extends StatefulWidget {
  const UserEditForm({super.key});

  @override
  State<UserEditForm> createState() => _UserEditFormState();
}

class _UserEditFormState extends State<UserEditForm> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final budgetController = TextEditingController();
  final dietController = TextEditingController();

  final UserRepository _userRepo = UserRepository();

  bool loading = true;
  bool _isConnected = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  File? selectedImage;
  User? userData;

  @override
  void initState() {
    super.initState();
    
    CurrentScreenState.active = CurrentScreen.editUser;
    _listenConnectivity();
    loadUserData();
  }

  @override
  void dispose() {
    
    CurrentScreenState.active = CurrentScreen.home;
    _connectivitySubscription.cancel();
    super.dispose();
  }

  // --- Conectividad ---
  void _listenConnectivity() {
   
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      final connected = result != ConnectivityResult.none;

     

      if (connected != _isConnected) {
        setState(() => _isConnected = connected);

        if (!_isConnected) {
          
          _showOfflineAlert();
        } else {
          
          syncCachedUpdates();
          _showOnlineAlert();
        }
      }
    });
  }

  // --- AlertDialogs ---
  void _showOfflineAlert() {
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("You're Offline"),
        content: const Text(
          "Changes will be saved locally and uploaded once connection returns.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  void _showOnlineAlert() {
   
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Connection Restored"),
        content: const Text("Syncing pending updates..."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  // --- Cargar info usuario ---
  Future<void> loadUserData() async {
   
    final uid = fbAuth.FirebaseAuth.instance.currentUser!.uid;

    final user = await _userRepo.getUser(uid);

    if (user == null) {
      
      return;
    }

    

    userData = user;

    nameController.text = user.name;
    emailController.text = user.email;
    budgetController.text = user.preferences["budget"]?.toString() ?? "";
    dietController.text = user.preferences["diet"] ?? "";

    setState(() => loading = false);
  }

  Future<void> selectImage() async {
    
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) {
     
      return;
    }
   
    setState(() => selectedImage = File(picked.path));
  }


  Future<void> saveChanges() async {
    if (userData == null) {
      return;
    }
    final uid = userData!.id;
    if (passwordController.text.isNotEmpty) {
     
      await _updatePassword(passwordController.text);
    }
    String? profileUrl = userData!.profilePicture;
    if (selectedImage != null) {
      profileUrl = await _userRepo.uploadProfilePicture(uid, selectedImage!.path);   
    }
    final updatedUser = User(
      id: uid,
      name: nameController.text,
      email: emailController.text,
      ownerUid: userData!.ownerUid,
      role: userData!.role,
      preferences: {
        "budget": budgetController.text,
        "diet": dietController.text,
      },
      favoriteRestaurants: userData!.favoriteRestaurants,
      profilePicture: profileUrl,
      createdAt: userData!.createdAt,
      updatedAt: userData!.updatedAt,
    );
    if (!_isConnected) {
      UserCache.put(uid, updatedUser.toFirestore());
      _showSnack("Changes saved locally (offline).");
      return;
    }
    try {
      await _userRepo.updateUser(user: updatedUser);
      userData = updatedUser;
      final userVM = context.read<UserViewModel>();
      userVM.currentUser = updatedUser;
      userVM.notifyListeners();
      _showSnack("Changes saved successfully!");
    } catch (e) {
    }
  }

  Future<void> _updatePassword(String newPassword) async {

    final user = fbAuth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.updatePassword(newPassword);
      
      _showSnack("Password updated successfully!");
    } on fbAuth.FirebaseAuthException catch (e) {
      
      if (e.code == 'requires-recent-login') {
        _showSnack("Please re-login to change your password.");
      } else {
        _showSnack("Error updating password: ${e.message}");
      }
    }
  }

    Future<void> syncCachedUpdates() async {
    

    if (UserCache.isEmpty()) {
     
      return;
    }

    final uid = fbAuth.FirebaseAuth.instance.currentUser!.uid;
    final pending = UserCache.get(uid);

    if (pending == null) {
      
      return;
    }

   

    try {
      await _userRepo.updateUserRaw(uid: uid, data: pending);
      
      UserCache.clear();
      
    } catch (e) {
     
    }
  }


  void _showSnack(String msg) {
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // UI
  @override
  Widget build(BuildContext context) {
    if (loading) {
      
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

   

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FF),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 170, 98, 153),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Foto
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: const Color(0xFF6A1B9A),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : (userData!.profilePicture != null
                              ? NetworkImage(userData!.profilePicture!)
                              : const AssetImage("assets/user.png")) as ImageProvider,
                    ),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF6A1B9A),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        onPressed: selectImage,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Panel 1
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF6A1B9A)),
                ),
                child: Column(
                  children: [
                    _field("Name", nameController),
                    _field("Email", emailController),
                    _field("Password", passwordController, isPassword: true),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Panel 2
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF6A1B9A)),
                ),
                child: Column(
                  children: [
                    _field("Budget", budgetController, inputType: TextInputType.number),
                    _field("Diet", dietController),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType? inputType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF6A1B9A)),
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
