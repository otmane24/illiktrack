import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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
  Position _currentPosition;
  String _currentAddress;
  Position position;

  @override
  void dispose() async {
    super.dispose();
    await subscription.cancel();
  }

  @override
  void initState() {
    super.initState();
    _checkGps();
    checkConnection().then((value) => _getCurrentLocation());
    _connectivity.onConnectivityChanged.listen(_connectionChange);
    _getCurrentLocation();
  }

  //------------------------ About GPS ------------------------------
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
      setState(() {
        _currentPosition = position;
        updateLocation(position);
      });
    }).catchError((e) {
      print(e);
    });
  }

  Future<Map> getLocation(Position place) async {
    try {
      String url =
          "https://maps.googleapis.com/maps/api/geocode/json?latlng=${place.latitude},${place.longitude}&key=AIzaSyBR046smIiQUeRbBaErZWkgtdiMFmOlAlc";
      http.Response response = await http.get(Uri.parse(url));
      String source = response.body;
      return json.decode(source);
    } catch (e) {
      print(e);
    }
    return null;
  }

  void updateLocation(Position place) async {
    try {
      await getLocation(place).then((locationMap) {
        setState(() {
          _currentAddress = locationMap["results"][0]["formatted_address"];
        });
      });
    } catch (e) {
      print(e);
    }
  }

  // ignore: cancel_subscriptions
  Stream<Position> positionStreamSubscription = Geolocator.getPositionStream();

  // ignore: close_sinks
//-----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: positionStreamSubscription,
      builder: (context, snapShot) {
        if (snapShot.hasData) {
          _currentPosition = snapShot.data;
          updateLocation(snapShot.data);
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
                                    Text("Location",
                                        style: TextStyle(
                                          fontSize: 16,
                                        )),
                                    SizedBox(
                                      height: 10,
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
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Container(
                                      child: Text(
                                          (snapShot.hasData
                                              ? "lat : ${_currentPosition.latitude.toString()}  lon : ${_currentPosition.longitude.toString()}"
                                              : ""),
                                          style: TextStyle(
                                            fontSize: 14,
                                          )),
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
