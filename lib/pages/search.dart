import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare5/models/user.dart';
import 'package:fluttershare5/pages/Home.dart';
import 'package:fluttershare5/pages/profile.dart';
import 'package:fluttershare5/widget/progress.dart';

import 'activity_feed.dart';
//import 'package:cached_network_image/cached_network_image.dart';


class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}
// with AutomaticKeepAliveClientMixin<Search>
class _SearchState extends State<Search>  {

  Future<QuerySnapshot> searchResultFuture;
  TextEditingController searchController = TextEditingController();

  handleSearch(String query){
    Future<QuerySnapshot> user = usersRef.where('displayName' , isGreaterThanOrEqualTo: query)
        .getDocuments();
    setState(() {
      searchResultFuture = user;
    });
  }

  clearSearch(){
    searchController.clear();
  }

  AppBar buildSearchField(){
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Search for a user...",
          filled: true,
          prefixIcon: Icon(Icons.account_box ,size: 28.0,),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: clearSearch,
          )
        ),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  Container buildNoContent(){
    // Responsive app
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset('assets/images/search.svg' ,
            height: orientation == Orientation.portrait ? 300.0 : 200.0,
            ),
            Text('Find user' , textAlign: TextAlign.center ,style: TextStyle(fontSize: 60.0 ,  color: Colors.white),)
          ],
        ),
      ),
    );
  }

  buildSearchResult(){
    return FutureBuilder(
      future: searchResultFuture,
      builder: (context , snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        snapshot.data.documents.forEach((doc){
          User user = User.fromDocument(doc);
          UserResult searchResult = UserResult(user);
          searchResults.add(searchResult);
        });
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
//    super.build(context);
    return Scaffold(
        backgroundColor: searchResultFuture == null ? Colors.white70 : Colors.white,
        appBar: buildSearchField(),
        body: searchResultFuture == null ? buildNoContent() : buildSearchResult(),
    );
  }

//  @override
//  // TODO: implement wantKeepAlive
//  bool get wantKeepAlive => true;
}



class UserResult extends StatelessWidget{
  final User user;
  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
    //  color: Theme.of(context).primaryColor.withOpacity(0.7),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context , profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: NetworkImage(user.photoUrl),
              ),
              title: Text(user.displayName , style: TextStyle(color: Theme.of(context).primaryColor , fontWeight: FontWeight.bold),),
              subtitle: Text(user.bio , style: TextStyle(color: Theme.of(context).primaryColor),),
            ),
          ),
        //  Divider(height: 2.0, color: Colors.grey,)
        ],
      ),
    );
  }

}