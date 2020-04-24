import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
//  final String username;
  final String email;
  final String photoUrl;
  final String displayName;
  final String bio;
  bool isVerified = false;
  bool isBan = false;

  User({this.id, this.email, this.photoUrl, this.displayName, this.bio ,this.isVerified , this.isBan
  });

  factory User.fromDocument(DocumentSnapshot doc){
    return User(
      isVerified: doc['isVerified'],
      id: doc['id'],
//      username: doc['username'],
      email: doc['email'] ,
      photoUrl: doc['photoUrl'] ,
      displayName: doc['displayName'] ,
      bio: doc['bio'],
      isBan: doc['isBan']
    );
  }
}

