import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String _userRole = '';
  String get userRole => _userRole;

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
  
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // Get user role from Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (userDoc.exists) {
        _userRole = userDoc.data()?['role'] ?? 'employee';
      } else {
        _userRole = 'employee';
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.code == 'user-not-found') {
        throw 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        throw 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-email') {
        throw 'The email address is badly formatted.';
      } else if (e.code == 'invalid-credential') {
        throw 'Invalid credentials.';
      }
      throw e.message ?? 'An error occurred while signing in.';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw 'An unexpected error occurred.';
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> signOut() async {
    _userRole = '';
    await _auth.signOut();
  }
}
