import 'package:flutter/material.dart';
import 'maincross.dart';

class ErrorRoute extends StatelessWidget {
  ErrorRoute({ super.key, required this.error });
  String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text('Error', style: TextStyle(fontSize: 25, color: ColorTheme.GetTextColor(context)),),
            const Stack(
              alignment: Alignment.center,
              children: [
                Icon (Icons.error_outline, color: Colors.red, size: 180)
              ],
            ),
            Column(children: [
              Text(error != '' ? error : 'Unknown error'),
            ],),  
            Stack(
              alignment: Alignment.center, 
              children: [
                Icon(Icons.circle, color: ColorTheme.GetROCellColor(context), size: 100),
                IconButton(
                  onPressed: () {Navigator.popAndPushNamed(context, '/');}, 
                  iconSize: 60,
                  padding: const EdgeInsets.all(0) ,
                  alignment: Alignment.center,
                  icon: Icon (Icons.home, color: ColorTheme.GetTextColor(context))
                )   
                 
              ],
            )  

          ]
        ),
      ),
    );
  }
}    
    
    
    
