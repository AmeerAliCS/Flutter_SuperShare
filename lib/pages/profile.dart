import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare5/models/user.dart';
import 'package:fluttershare5/pages/Home.dart';
import 'package:fluttershare5/pages/edit_profile.dart';
import 'package:fluttershare5/widget/header.dart';
import 'package:fluttershare5/widget/post_tile.dart';
import 'package:fluttershare5/widget/progress.dart';
import 'package:fluttershare5/widget/post.dart';

class Profile extends StatefulWidget {

  final String profileId;
  Profile({this.profileId });


  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser?.id;

  bool isLoading = false;
  bool isFollowing = false;
  String postOrientation = 'grid';
  final DateTime timestamp = DateTime.now();
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  List<Post> posts = [];
  String displayName;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getDisplayName();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  getDisplayName() async{
    await usersRef.document(widget.profileId).get().then((DocumentSnapshot doc){
      User user = User.fromDocument(doc);
      setState(() {
        displayName = user.displayName;
      });
    });
  }

  checkIfFollowing() async{
    DocumentSnapshot snapshot = await followersRef.document(widget.profileId)
        .collection('userFollowers').document(currentUserId).get();
    setState(() {
      isFollowing = snapshot.exists;
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .document(widget.profileId).collection('userFollowers').getDocuments();
    setState(() {
      followersCount = snapshot.documents.length;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef.document(widget.profileId)
        .collection('userFollowing').getDocuments();
    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    }
    else if(posts.isEmpty){
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset('assets/images/no_content.svg' , height: 200.0,),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
            ),
            Text('No Posts' , style: TextStyle(color: Theme.of(context).accentColor , fontSize: 40.0 , fontWeight: FontWeight.bold),)
          ],
        ),
      );
    }

    else if(postOrientation == 'grid'){
    List<GridTile> gridTile = [];
    posts.forEach((post){
      gridTile.add(GridTile(
        child: PostTile(post),
      ));
    });
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      crossAxisSpacing: 1.5,
      mainAxisSpacing: 1.5,
      physics: NeverScrollableScrollPhysics(),
      children: gridTile,
    );
  }
    else if(postOrientation == 'list'){
    return Column(
      children: posts,
    );
  }

  }



  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  editProfile(){
    Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfile(currentUserId: currentUserId,)));
  }

  buildButton({String text , Function function}){
    return Container(
      width: 220.0,
      height: 27.0,
      padding: EdgeInsets.only(top: 2.0),
      child: SizedBox(
        width: 235.0,
        height: 27.0,
        child: FlatButton(
          onPressed: function,
          child: Text(text , style: TextStyle(color: isFollowing ? Theme.of(context).primaryColor : Colors.white ,fontWeight: FontWeight.bold),),
        ),
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isFollowing ? Colors.white : Theme.of(context).accentColor,
        border: Border.all(
          color: isFollowing ? Colors.grey :  Theme.of(context).accentColor
        ),
        borderRadius: BorderRadius.circular(5.0)
      ),
    );
  }

  buildProfileButton() {
    bool isProfileOwner = currentUserId == widget.profileId;
    if(isProfileOwner){
      return buildButton(text: 'Edit Profile', function: editProfile);
    }
    else if(isFollowing){
      return buildButton(text: 'Unfollow' , function: handleUnFollowUser);
    }
    else if(!isFollowing){
      return buildButton(text: 'Follow' , function: handleFollowUser);
    }
  }

  handleUnFollowUser(){
    setState(() {
      isFollowing = false;
    });
    followersRef.document(widget.profileId)
        .collection('userFollowers').document(currentUserId).get().then((doc){
          if(doc.exists){
            doc.reference.delete();
          }
    });

    followingRef.document(currentUserId)
        .collection('userFollowing').document(widget.profileId).get().then((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });

    activityFeedRef.document(widget.profileId).collection('feedItems').document(currentUserId).get().then((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });
  }

  handleFollowUser(){
    setState(() {
      isFollowing = true;
    });
    followersRef.document(widget.profileId)
        .collection('userFollowers').document(currentUserId).setData({});

    followingRef.document(currentUserId)
        .collection('userFollowing').document(widget.profileId).setData({});

    activityFeedRef.document(widget.profileId).collection('feedItems').document(currentUserId).setData({
      "type": "follow",
      "timestamp": timestamp,
      'ownerId' : widget.profileId ,
      "userId": currentUser.id,
      "username": currentUser.username,
      "userProfileImg": currentUser.photoUrl,
    });
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context , snapshot){
        if (!snapshot.hasData){
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[

              CircleAvatar(
                radius: 40.0,
                backgroundColor: Colors.grey,
                backgroundImage: NetworkImage(user.photoUrl),
              ),

              SizedBox(height: 10.0,),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    child: Text('@${user.username}' , style: TextStyle(fontSize: 16 , fontWeight: FontWeight.bold),),
                  ),

                  Padding(
                    padding: EdgeInsets.only(left: 2.0),
                  ),
                  Container(
                    child: user.isVerified
                        ? Icon(
                            Icons.verified_user,
                            color: Colors.blue,
                            size: 18.0,
                          )
                        : Text(''),
                  )
                ],
              ),

              SizedBox(height: 12.0,),

              Column(
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      buildCountColumn("posts", postCount),
                      SizedBox(width: 15.0,),
                      Container(
                        height: 30.0,
                        width: 0.14,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 15.0,),
                      buildCountColumn("followers", followersCount),
                      SizedBox(width: 15.0,),
                      Container(
                        height: 30.0,
                        width: 0.20,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 15.0,),
                      buildCountColumn("following", followingCount),
                    ],
                  ),

                  SizedBox(height: 15.0,),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      buildProfileButton(),
                    ],
                  ),

                  SizedBox(height: 7.0,),

                  Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.only(top: 2.0),
                      child: Text(
                        user.bio,
                      ),
                    ),


                ],
              ),
            ],
          ),
        );
      },
    );
  }

//  buildProfileHeader() {
//    return FutureBuilder(
//      future: usersRef.document(widget.profileId).get(),
//      builder: (context, snapshot) {
//        if (!snapshot.hasData) {
//          return circularProgress();
//        }
//         User user = User.fromDocument(snapshot.data);
//        return Padding(
//          padding: EdgeInsets.all(16.0),
//          child: Column(
//            children: <Widget>[
//              Row(
//                children: <Widget>[
//                  CircleAvatar(
//                    radius: 40.0,
//                    backgroundColor: Colors.grey,
//                    backgroundImage: NetworkImage(user.photoUrl),
//                  ),
//                  Expanded(
//                    flex: 1,
//                    child: Column(
//                      children: <Widget>[
//                        Row(
//                          mainAxisSize: MainAxisSize.max,
//                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                          children: <Widget>[
//                            buildCountColumn("posts", postCount),
//                            buildCountColumn("followers", followersCount),
//                            buildCountColumn("following", followingCount),
//                          ],
//                        ),
//
//                        Row(
//                          children: <Widget>[
//                            Padding(padding: EdgeInsets.only(top: 8.0),)
//                          ],
//                        ),
//
//                        Row(
//                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                          children: <Widget>[
//                            buildProfileButton(),
//                          ],
//                        ),
//                      ],
//                    ),
//                  ),
//                ],
//              ),
//
//              Row(
//                children: <Widget>[
//                  Container(
//                    alignment: Alignment.centerLeft,
//                    padding: EdgeInsets.only(top: 12.0),
//                    child: Text(
//                      user.username,
//                      style: TextStyle(
//                        fontWeight: FontWeight.bold,
//                        fontSize: 16.0,
//                      ),
//                    ),
//                  ),
//
//                  Padding(
//                    padding: EdgeInsets.only(left: 2.0),
//                  ),
//                  Container(
//                    margin: EdgeInsets.only(top: 12.0),
//                    child: user.isVerified ?
//                    Icon(Icons.verified_user , color: Colors.blue, size: 18.0,): Text(''),
//                  )
//                ],
//              ),
//
//              Container(
//                alignment: Alignment.centerLeft,
//                padding: EdgeInsets.only(top: 4.0),
//                child: Text(
//                  user.displayName,
//                  style: TextStyle(
//                    fontWeight: FontWeight.bold,
//                  ),
//                ),
//              ),
//
//              Container(
//                alignment: Alignment.centerLeft,
//                padding: EdgeInsets.only(top: 2.0),
//                child: Text(
//                  user.bio,
//                ),
//              ),
//            ],
//          ),
//        );
//      },
//    );
//  }

  setPostOrientation(String orientation){
    setState(() {
      this.postOrientation = orientation;
    });
  }

  buildTogglePostOrientation(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.grid_on),
          color: postOrientation == 'grid' ? Theme.of(context).accentColor.withOpacity(0.6) : Colors.grey,
          onPressed: () => setPostOrientation('grid'),
        ),

        IconButton(
          icon: Icon(Icons.list),
          color: postOrientation == 'list' ? Theme.of(context).accentColor.withOpacity(0.6) : Colors.grey,
          onPressed: () => setPostOrientation('list'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    final bool isAuthUser = currentUser.id == widget.profileId;

    return Scaffold(

      appBar: header(context , titleText: '${displayName != null ? displayName : ''}'
        , elevation: 0.0 , opacity: 0.0  , backButton: isAuthUser ? false : true),

      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(height: 0.0,),
          buildTogglePostOrientation(),
          Divider(height: 0.0,),
          buildProfilePosts()
        ],
      ),
    );
  }
}
