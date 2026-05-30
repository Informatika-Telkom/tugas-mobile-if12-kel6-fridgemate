import 'package:cloud_firestore/cloud_firestore.dart';

abstract class BaseRepository<T> {
  final FirebaseFirestore firestore;
  final String collectionPath;

  BaseRepository({required this.firestore, required this.collectionPath});

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection(collectionPath);

  Future<List<T>> getAll();
  
  Future<T?> getById(String id);
  
  Future<void> create(String id, T item);
  
  Future<void> update(String id, T item);
  
  Future<void> delete(String id);
}
