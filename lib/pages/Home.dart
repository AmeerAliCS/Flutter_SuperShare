import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttershare5/models/user.dart';
import 'package:fluttershare5/pages/create_account.dart';
import 'package:fluttershare5/pages/timeline.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttershare5/pages/activity_feed.dart';
import 'package:fluttershare5/pages/profile.dart';
import 'package:fluttershare5/pages/search.dart';
import 'package:fluttershare5/pages/upload.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


final GoogleSignIn googleSignIn = GoogleSignIn();
final usersRef = Firestore.instance.collection('users');
final postsRef = Firestore.instance.collection('posts');
final commentsRef = Firestore.instance.collection('comments');
final activityFeedRef = Firestore.instance.collection('feed');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final timelineRef = Firestore.instance.collection('timeline');
final StorageReference storageRef = FirebaseStorage.instance.ref();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  bool isAuth = false;
  var pageController = PageController();
  int pageIndex = 0;
  final _scaffoldkey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  final DateTime timestamp = DateTime.now();


  login(){
    googleSignIn.signIn();
  }
  logout(){
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex){
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex){
    pageController.animateToPage(
        pageIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut
    );
  }

  Scaffold buildAuthScreen(){
    return Scaffold(
      key: _scaffoldkey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),
//          RaisedButton(
//            child: Text('Logout'),
//            onPressed: logout,
//          ),
          Search(),
          Upload(currentUser: currentUser),
          ActivityFeed(),
          Profile(profileId: currentUser?.id)
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
      //  physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).accentColor,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera , size: 35.0,)),
          BottomNavigationBarItem(icon: Icon(Icons.favorite)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle
          )),
        ],
      ),
    );
  }


  Scaffold buildUnAuthScreen(){
    return Scaffold(
      body: Container(
        color: Colors.purple.withOpacity(0.030),
        child: Column(
//          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
             Padding(
               child: Text('Super Share' , style: GoogleFonts.cookie(color: Theme.of(context).primaryColor , fontSize: 65 ),),
               padding: EdgeInsets.only(top: 100.0),
             ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60.0),
                child: SvgPicture.asset('assets/images/networking.svg' , height: 200.0,),
              ),
            ),

            SizedBox(height: 50.0,),

            GestureDetector(
              onTap: login,
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/images/google_sign_in.png'),
                      fit: BoxFit.cover),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }

//  Scaffold buildUnAuthScreen(){
//    return Scaffold(
//      body: Container(
//        decoration: BoxDecoration(
//          gradient: LinearGradient(
//            begin: Alignment.topRight,
//            end: Alignment.bottomLeft,
//            colors: [
//              Colors.green,
//              Colors.purple,
//            ]
//          )
//        ),
//        alignment: Alignment.center,
//        child: Column(
//          mainAxisAlignment: MainAxisAlignment.center,
//          crossAxisAlignment: CrossAxisAlignment.center,
//          children: <Widget>[
//            Text('Super Share',style: TextStyle(
//              fontFamily: "Signatra",
//              fontSize: 50.0,
//              color: Colors.white,
//            ),
//            ),
//            GestureDetector(
//              onTap: login,
//              child: Container(
//                width: 260.0,
//                height: 60.0,
//                decoration: BoxDecoration(
//                  image: DecorationImage(
//                    image: AssetImage('assets/images/google_sign_in.png'),
//                    fit: BoxFit.cover
//                  ),
//                ),
//              ),
//            )
//          ],
//        ),
//      ),
//    );
//  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    pageController.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    pageController = PageController();
    // Detects when user signed in
    googleSignIn.onCurrentUserChanged.listen((account){
      handleSignIn(account);
    }, onError: (err){
      print('Error signing in: $err');
    });

    // Reauthenticate user when app is opened
    googleSignIn.signInSilently(suppressErrors: false).then((account){
      handleSignIn(account);
    }, onError: (err){
      print('Error signing in: $err');
    });
  }

  handleSignIn(GoogleSignInAccount account) async {
    if(account != null){
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
      configurePushNotification();
    } else{
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotification(){
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if(Platform.isIOS) getiOSPermission();

    _firebaseMessaging.getToken().then((token){
      print('Firebase Messaging Token $token \n');

      usersRef.document(user.id).updateData({
        'androidNotificationToken' : token
      });
    });

    _firebaseMessaging.configure(
//      onLaunch: (Map <String , dynamic> message) async {},
//      onResume: (Map <String , dynamic> message) async {},
      onMessage: (Map <String , dynamic> message) async {
        print("on message: $message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        if(recipientId == user.id){
          print('Notification shown!');
          SnackBar snackBar = SnackBar(
            content: Text(body , overflow: TextOverflow.ellipsis,),);
          _scaffoldkey.currentState.showSnackBar(snackBar);
        }
        print("Notification NOT shown");
      },

    );

  }

  getiOSPermission(){
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true , badge: true , sound: true  ));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings){
      print("Settings registered: $settings");
    });
  }

  createUserInFirestore() async {
    // 1) check if user exists in users collection in database (according to their id)
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(user.id).get();

    if (!doc.exists) {
      // 2) if the user doesn't exist, then we want to take them to the create account page
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));

      // 3) get username from create account, use it to make new user document in users collection
      if(username != null){
        usersRef.document(user.id).setData({
          'id': user.id,
          'username': username,
          'isVerified' : false ,
          'photoUrl': user.photoUrl,
          'email': user.email,
          'displayName': user.displayName,
          'bio': '',
          'timestamp': timestamp
        });
      }
      // make new user their own follower (to include their posts in their timeline)
      await followersRef
          .document(user.id)
          .collection('userFollowers')
          .document(user.id)
          .setData({});

      doc = await usersRef.document(user.id).get();
    }

    currentUser = User.fromDocument(doc);
  }

//    print(currentUser);
//    print('Name: ${currentUser.displayName}');


  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
