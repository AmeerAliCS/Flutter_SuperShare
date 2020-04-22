import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare5/models/user.dart';
import 'package:fluttershare5/pages/Home.dart';
import 'package:fluttershare5/widget/progress.dart';

class EditProfile extends StatefulWidget {

  final String currentUserId;
  EditProfile({this.currentUserId});


  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {

  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = false;
  User user;
  bool _displayNameValid = true;
  bool _bioValid = true;

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc =  await usersRef.document(widget.currentUserId).get();
    user = User.fromDocument(doc);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  Column buildDisplayNameField(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text('Display Name', style: TextStyle(color: Colors.grey),),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: 'Update Display Name',
            errorText: _displayNameValid ? null : "Display Name too short",
          ),
        )
      ],
    );
  }

  Column buildBioField(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text('Bio', style: TextStyle(color: Colors.grey),),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: 'Update Bio',
            errorText: _bioValid ? null : 'Bio too long'
          ),
        )
      ],
    );
  }

  updateProfileData(){
    setState(() {
      displayNameController.text.trim().length < 3 ||
      displayNameController.text.isEmpty ||
      displayNameController.text.length > 30 ? _displayNameValid = false : _displayNameValid = true;

      bioController.text.trim().length > 100 ? _bioValid = false : _bioValid = true;

    });

    if(_displayNameValid && _bioValid){
      usersRef.document(widget.currentUserId).updateData({
        'displayName' : displayNameController.text,
        'bio' : bioController.text
      });
      SnackBar snackBar = SnackBar(content: Text('Profile updated!'),);
      scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

//  logout() async {
//    await googleSignIn.signOut();
//    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
//  }

  logout() async {
    await googleSignIn.signOut();
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => Home()), (
        Route<dynamic> route) => false);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back , color: Theme.of(context).primaryColor,),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white.withOpacity(0.90),
        elevation: 1,
        title: Text('Edit Profile' , style: TextStyle(color: Theme.of(context).primaryColor),),
        centerTitle: true,
        actions: <Widget>[
          FlatButton(
            child: Text('Save' , style: TextStyle(color: Theme.of(context).primaryColor , fontSize: 17)),
            onPressed: (){
              updateProfileData();
              Timer(Duration(seconds: 1),(){
                Navigator.pop(context);
              });
            },
          )
        ],
      ),
      body: isLoading ? circularProgress() : ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 16.0 , bottom: 8.0),
                  child: CircleAvatar(
                    radius: 50.0,
                    backgroundImage: NetworkImage(user.photoUrl),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: <Widget>[
                      buildDisplayNameField(),
                      buildBioField()
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: FlatButton.icon(
                    onPressed: logout,
                    label: Text('Logout', style: TextStyle(color: Colors.red , fontSize: 22.0),),
                    icon: Icon(Icons.exit_to_app , color: Colors.red ,size: 22.0,),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
