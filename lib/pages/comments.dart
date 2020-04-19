import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare5/pages/Home.dart';
import 'package:fluttershare5/widget/custom_image.dart';
import 'package:fluttershare5/widget/header.dart';
import 'package:fluttershare5/widget/progress.dart';
import 'package:timeago/timeago.dart' as timeago;


class Comments extends StatefulWidget {

  final String postId;
  final String ownerId;
  final String mediaUrl;

  Comments({this.postId , this.ownerId , this.mediaUrl});

  @override
  _CommentsState createState() => _CommentsState(
    postId: postId,
    ownerId: ownerId,
    mediaUrl: mediaUrl
  );
}

class _CommentsState extends State<Comments> {

  final String postId;
  final String ownerId;
  final String mediaUrl;
  TextEditingController commentController = TextEditingController();
  final DateTime timestamp = DateTime.now();


  _CommentsState({this.postId , this.ownerId , this.mediaUrl});

  addComment(){
    commentsRef.document(postId).collection('comments').add({
      'username' : currentUser.username ,
      'comment' : commentController.text,
      'avatarUrl' : currentUser.photoUrl,
      'timestamp' : timestamp ,
      'userId' : currentUser.id
    });
    bool isNotPostOwner = ownerId != currentUser.id;
    if (isNotPostOwner) {
      activityFeedRef.document(ownerId).collection('feedItems').add({
        "type": "comment",
        "commentData": commentController.text,
        "timestamp": timestamp,
        "postId": postId,
        "userId": currentUser.id,
        "username": currentUser.username,
        "userProfileImg": currentUser.photoUrl,
        "mediaUrl": mediaUrl,
      });
    }
    commentController.clear();
  }

  buildComment(){
    return StreamBuilder(
      stream: commentsRef.document(postId).collection('comments')
          .orderBy('timestamp' , descending: true).snapshots(),
      builder: (context , snapshot){
        if (!snapshot.hasData){
          return circularProgress();
        }
        List<Comment> comment = [];
        snapshot.data.documents.forEach((doc){
          comment.add(Comment.fromDocument(doc));
        });
        return ListView(
          children: comment,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context , titleText: 'Comments' , elevation: 1.0 , opacity: 0.90),
      body: Column(
        children: <Widget>[
          Expanded(
            child: buildComment(),
          ),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Write a comment...',
              ),
            ),
            trailing: OutlineButton(
              onPressed: addComment,
              borderSide: BorderSide.none,
              child: Text('post'),
            ),
          )
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {

  final String username;
  final String comment;
  final String avatarUrl;
  final String userId;
  final Timestamp timestamp;

  Comment({this.username , this.comment ,this.avatarUrl ,this.userId ,this.timestamp});

  factory Comment.fromDocument(DocumentSnapshot doc){
    return Comment(
      username: doc['username'],
      comment: doc['comment'],
      avatarUrl: doc['avatarUrl'],
      userId: doc['userId'],
      timestamp: doc['timestamp'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: RichText(
            text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: <TextSpan>[
                  TextSpan(text: '$username' , style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ' $comment')
                ]
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        Divider()
      ],
    );
  }
}

