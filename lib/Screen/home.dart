import 'dart:async';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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
  final Geolocator geoLocator = Geolocator()..forceAndroidLocationManager;
  Position _currentPosition;
  String _currentAddress;

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
    if (!(await Geolocator().isLocationServiceEnabled())) {
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

  _getCurrentLocation() {
    geoLocator
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
      List<Placemark> p = await geoLocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

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

  @override
  Widget build(BuildContext context) {
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
                    child: MaterialButton(
                      color: Colors.grey[800],
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                      splashColor: Colors.black12,
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
                                  Text('Location :',
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
                      onPressed: () {
                        _getCurrentLocation();
                        _checkGps();
                      },
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
  }
}
