import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

AppBar header(context , {bool isAppTitle = false , String titleText , bool backButton = false , double opacity , double elevation}){
  return AppBar(
    leading: backButton ? IconButton(
      icon: Icon(Icons.arrow_back , color: Theme.of(context).primaryColor,),
      onPressed: () => Navigator.pop(context),
    ) : null,
    title: Text(isAppTitle ? 'Super Share' : titleText,
      style: isAppTitle? GoogleFonts.cookie(color: Theme.of(context).primaryColor , fontSize: 37 ): TextStyle(
          fontSize: 20.0,
          color: Theme.of(context).primaryColor
      ),
    ),
    centerTitle: true,
    backgroundColor: Colors.white.withOpacity(opacity),
    elevation: elevation,
  );
}