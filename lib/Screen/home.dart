import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
//import 'package:provider/provider.dart';

class Image {
  final String imageName;

  Image({this.imageName});

  factory Image.fromJson(Map<String, dynamic> parsedJson) {
    return Image(imageName: parsedJson['formatted_address']);
  }
}

class Localisation {
  final List<Image> images;

  Localisation({this.images});

  factory Localisation.fromJson(Map<String, dynamic> parsedJson) {
    var list = parsedJson['results'] as List;
    print('list : ${list.runtimeType}');

    List<Image> imagesList = list.map((i) => Image.fromJson(i)).toList();

    return Localisation(images: imagesList);
  }
}

List<Localisation> analyseCars(String responseBody) {
  final parsedJson = json.decode(responseBody);
  return parsedJson<Localisation>((json) => Localisation.fromJson(json))
      .toList();
}
/*
Future<List<Localisation>> fetchCars(Position place) async {
  String url =
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=${place.latitude},${place.longitude}&key=AIzaSyBR046smIiQUeRbBaErZWkgtdiMFmOlAlc";
  final reponse = await http.get(Uri.parse(url));
  print("urlll : $url");
  List<Localisation> resultat = analyseCars(reponse.body);
  return resultat;
}
*/
//------------------------------------------

Future<Map> getLocation(Position place) async {
  String url =
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=34.881789,-1.316699&key=AIzaSyBR046smIiQUeRbBaErZWkgtdiMFmOlAlc";
  http.Response response = await http.get(Uri.parse(url));
  print(Uri.parse(url));
  String source = response.body;
  return json.decode(source);
}

//------------------------------------------

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //--------------------------------------------------

  bool hasConnection = false;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> subscription;

  Stream get connectionChange => connectionChangeController.stream;
  StreamController connectionChangeController = StreamController.broadcast();

  void _connectionChange(ConnectivityResult result) async {
    bool newStateConnection = await checkConnection();
    setState(() {
      hasConnection = newStateConnection;
    });
    if (hasConnection) {
      try {
        _getCurrentLocation();
      } catch (e) {
        print("Error: ${e.toString()}");
      }
    }
  }
  //----------------------

  void updateLocation(Position place) async {
    Map locationMap = await getLocation(place);
    setState(() {
      _currentAddress = locationMap["results"][0]["formatted_address"];
    });
  }

  //----------------------

  Future<bool> checkConnection() async {
    bool previousConnection = hasConnection;

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          hasConnection = true;
        });
      } else {
        setState(() {
          hasConnection = false;
        });
      }
    } on SocketException catch (_) {
      setState(() {
        hasConnection = false;
      });
    }

    //The connection status changed send out an update to all listeners
    if (previousConnection != hasConnection) {
      connectionChangeController.add(hasConnection);
    }

    return hasConnection;
  }

  //--------------------------------------------------
  //final Geolocator geoLocator =Geolocator();
  Position _currentPosition;
  String _currentAddress;
  Position position;

  // Stream <Position> positionStream =

  @override
  void dispose() async {
    super.dispose();
    await subscription.cancel();
  }

  @override
  void initState() {
    super.initState();
    checkConnection().then((value) => _getCurrentLocation());
    _connectivity.onConnectivityChanged.listen(_connectionChange);
    _getCurrentLocation();
    _checkGps();
  }

  Future _checkGps() async {
    if (!(await Geolocator.isLocationServiceEnabled())) {
      if (Theme.of(context).platform == TargetPlatform.android ||
          Theme.of(context).platform == TargetPlatform.iOS) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Impossible d'obtenir votre emplacement actuel"),
              content: const Text(
                  "S'il vous plaît veuillez assurer d'activer le GPS et après réessayer"),
              actions: <Widget>[
                // ignore: deprecated_member_use
                FlatButton(
                  child: Text(
                    'Terminer',
                    style: TextStyle(color: Colors.tealAccent[200]),
                  ),
                  onPressed: () {
                    //android_setting.AppSettings.openLocationSettings();
                    AppSettings.openLocationSettings();
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

  Future<void> _getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      /* setState(() {
        _getAddressFromLatLng(position);
      });
      */
    }).catchError((e) {
      print(e);
    });
  }

/*
  _getAddressFromLatLng(Position currentPlace) async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(
          currentPlace.latitude, currentPlace.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.subLocality} ${place.locality} ${place.postalCode}" +
                " ${place.country} ${place.isoCountryCode}";
      });

    } catch (e) {
      print(e);
    }
  }
*/
  // ignore: cancel_subscriptions
  Stream<Position> positionStreamSubcription = Geolocator.getPositionStream();

  // ignore: close_sinks

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: positionStreamSubcription,
      builder: (context, snapShot) {
        if (snapShot.hasData) {
          _currentPosition = snapShot.data;
          updateLocation(snapShot.data);
          //_getAddressFromLatLng(snapShot.data);
          //print(fetchCars(snapShot.data).toString());
          //print(_currentPosition == null ? 'Unknown' : _currentPosition.latitude.toString() + ', ' + _currentPosition.longitude.toString());

        }
        return Scaffold(
          appBar: AppBar(
            title: Text(
              "Illik'Track",
            ),
            centerTitle: true,
          ),
          body: hasConnection
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Container(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.location_on,
                                color: Colors.deepOrangeAccent,
                                size: 30,
                              ),
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
                                        (snapShot.hasData
                                            ? "lat : ${_currentPosition.latitude.toString()}  lon : ${_currentPosition.longitude.toString()}"
                                            : "location"),
                                        style: TextStyle(
                                          fontSize: 14,
                                        )),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Container(
                                      child: (_currentPosition != null &&
                                              _currentAddress != null)
                                          ? Text(
                                              _currentAddress,
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.tealAccent[200],
                                              ),
                                            )
                                          : Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 12.0, bottom: 2.0),
                                              child: LinearProgressIndicator(
                                                minHeight: 5,
                                              ),
                                            ),
                                    ),
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
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Text(
                    "Vérifiez votre internet",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
        );
      },
    );
  }
}
