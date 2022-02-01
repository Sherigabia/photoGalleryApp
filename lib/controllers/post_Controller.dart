import 'dart:io';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class PostController {
  //Creating an instance of firebase storage
  final firebase_storage.FirebaseStorage _firebaseStorage =
      firebase_storage.FirebaseStorage.instance;

  //creating an instance of cloud firestore
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  //file upload
  Future<String> uploadImage(File photo) async {
    //generate Random numbers
    final String randomID = const Uuid().v4();

    //adding a Reference for the file to uploaded (A reference is a pointer to a file within your specified storage bucket. This can be a file that already exists, or one that does not exist.)
    firebase_storage.Reference ref =
        await _firebaseStorage.ref().child('posts').child('$randomID.png');

    //Put file to be uploaded
    firebase_storage.UploadTask uploadTask = ref.putFile(photo);

    //Wait for the upload to finish
    firebase_storage.TaskSnapshot taskSnapshot =
        await uploadTask.whenComplete(() => ref.getDownloadURL());
    print(await taskSnapshot.ref.getDownloadURL());

    // Return Preview Link to the file uploaded
    return await taskSnapshot.ref.getDownloadURL();
  }

  //adding of data to firestore
  Future<bool> submitPost({required File image}) async {
    bool isSuccess = false;
    String postImageUrl = await uploadImage(image);

    //creating a collection
    final CollectionReference postCollection =
        _firebaseFirestore.collection('posts');

    await postCollection
        .add({
          'image_url': postImageUrl,
          'name': 'Sherigabia',
          'location': 'Tamale, Ghana',
          'profile_picture':
              'https://images.unsplash.com/photo-1593642702749-b7d2a804fbcf?ixid=MXwxMjA3fDF8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1400&q=80',
          'likesCount': Random().nextInt(100),
          'commentCount': Random().nextInt(100),
          'createdAt': FieldValue.serverTimestamp()
        })
        .then((value) => isSuccess = true)
        .catchError((onError) {
          print(onError);
          isSuccess = false;
        });
    return isSuccess;
  }
}
