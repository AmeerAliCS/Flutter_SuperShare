
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare5/pages/Home.dart';
import 'package:fluttershare5/pages/post_screen.dart';
import 'package:fluttershare5/pages/profile.dart';
import 'package:fluttershare5/widget/header.dart';
import 'package:fluttershare5/widget/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {

  getActivityFeed() async {
    QuerySnapshot snapshot = await activityFeedRef.document(currentUser.id).collection('feedItems')
        .orderBy('timestamp' ,descending: true).limit(50).getDocuments();
    List<ActivityFeedItem> feedItem = [];
    snapshot.documents.forEach((doc){
      feedItem.add(ActivityFeedItem.fromDocument(doc));
    });
    return feedItem;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: header(context , titleText: "Activity" , elevation: 1.0 , opacity: 0.90),
        body: Container(
          child: FutureBuilder(
            future: getActivityFeed(),
            builder: (context , snapshot){
              if(!snapshot.hasData){
                return circularProgress();
              }
              return ListView(
                children: snapshot.data,
              );
            },
          ),
        ),
    );
  }
}

Widget mediaPreview;
String activityItemText;

class ActivityFeedItem extends StatelessWidget {

  final String userId;
  final String displayName;
  final String type;
  final String mediaUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final Timestamp timestamp;

  ActivityFeedItem({
    this.displayName ,this.userId , this.type ,this.mediaUrl ,
    this.postId , this.userProfileImg , this.commentData , this.timestamp
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc){
    return ActivityFeedItem(
      userId: doc['userId'],
      displayName: doc['displayName'],
      type: doc['type'],
      mediaUrl: doc['mediaUrl'],
      postId: doc['postId'],
      userProfileImg: doc['userProfileImg'],
      commentData: doc['commentData'],
      timestamp: doc['timestamp'],
    );
  }

  showPost(context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => PostScreen(
      postId: postId, userId: userId,
        ),
      ),
    );
  }

  configureMediaPreview(context) {
    if (type == "like" || type == 'comment') {
      mediaPreview = GestureDetector(
//        onTap: () => showPost(context), --------------------------- Error--------------------------
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: CachedNetworkImageProvider(mediaUrl),
                  ),
                ),
              )),
        ),
      );
    } else {
      mediaPreview = Text('');
    }

    if (type == 'like') {
      activityItemText = "liked your post";
    } else if (type == 'follow') {
      activityItemText = "is following you";
    } else if (type == 'comment') {
      activityItemText = 'replied: $commentData';
    } else {
      activityItemText = "Error: Unknown type '$type'";
    }
  }
  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Theme.of(context).primaryColor,
                  ),
                  children: [
                    TextSpan(
                      text: displayName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' $activityItemText',
                    ),
                  ]),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}

showProfile(context , {String profileId}){
  Navigator.push(context, MaterialPageRoute(builder: (context) => Profile(profileId: profileId)));
}

