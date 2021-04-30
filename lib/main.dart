import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_settings/app_settings.dart'as android_setting;
import 'dart:io';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
        cupertinoOverrideTheme: CupertinoThemeData(
          primaryContrastingColor: Colors.tealAccent[200],
          primaryColor: Colors.tealAccent[200],
        ),
        bottomSheetTheme: BottomSheetThemeData(
            shape: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            modalElevation: 10),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
  Position _currentPosition;
  String _currentAddress;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _checkGps();
  }

  Future _checkGps() async {
    if (!(await Geolocator().isLocationServiceEnabled())) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Impossible d'obtenir votre emplacement actuel"),
              content:
              const Text("S'il vous plaît veuillez assurer d'activer le GPS et après réessayer"),
              actions: <Widget>[
                // ignore: deprecated_member_use
                FlatButton(
                  child: Text('Terminer',style: TextStyle(color: Colors.tealAccent[200]),),
                  onPressed: () {
                    android_setting.AppSettings.openLocationSettings();
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  _getCurrentLocation() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });
      _getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.subLocality} ${place.locality} ${place.postalCode}"+
                " ${place.country} ${place.isoCountryCode}";
      });
    } catch (e) {
      print(e);
    }
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Illik'Track" , ),
        centerTitle: true,
      ),
      body:SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                  decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(15)
                  ),
                  ///put
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: InkWell(
                    child: Container(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.location_on,color: Colors.deepOrangeAccent,size: 30,),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                    'Location :',
                                    style: TextStyle(fontSize: 14,)
                                ),
                                SizedBox(
                                  height: 5,
                                ) ,
                                Container(
                                  child: (_currentPosition != null &&
                                      _currentAddress != null) ? Text(_currentAddress,
                                      style: TextStyle(fontSize: 18,color:Colors.tealAccent[200] )
                                  ) : Padding(
                                    padding: const EdgeInsets.only(top: 12.0,bottom: 2.0),
                                    child: LinearProgressIndicator(
                                      minHeight: 5,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                        ],
                      ),

                    ),
                    onTap: (){ _getCurrentLocation(); _checkGps ();},
                  )),
            )
          ],
        ),
      ),

    );
  }
}
