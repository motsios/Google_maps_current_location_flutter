import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'locationService.dart';

void main() {
  runApp(MyApp());
}

StreamController gpsStreamController = StreamController.broadcast();
Stream gpsStream = gpsStreamController.stream;
StreamSubscription gpsStreamSubscription;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Google-Map Current Location'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  Completer<GoogleMapController> mapController = Completer();
  Set<Marker> markers = Set();
  bool askLocationRequestOnce = false;
  List latAndLong = [];
  void _onMapCreated(GoogleMapController controller) {
    mapController.complete(controller);
  }

  @override
  void initState() {
    super.initState();
    startLocationService();
  }

  startLocationService() async {
    Location _locationService = Location();
    bool locationStatus = await _locationService.serviceEnabled();
    if (locationStatus) {
      var locationService = LocationService();
      locationService.initialize();

      gpsStreamSubscription = gpsStream.listen((locationEvent) async {
        latAndLong = [];
        var split = locationEvent.toString().split(" ");
        latAndLong.add(split[0]);
        latAndLong.add(split[1]);

        WidgetsBinding.instance.addObserver(this);

        Marker resultMarker = Marker(
          markerId: MarkerId(Random().toString()),
          infoWindow: InfoWindow(
              title: 'Your current location',
              snippet:
                  split[2] + " " + split[3].substring(0, split[3].length - 7)),
          position: LatLng(double.parse(latAndLong[0].toString()),
              double.parse(latAndLong[1].toString())),
        );
        setState(() {
          markers.add(resultMarker);
        });
      });
    } else {
      if (!askLocationRequestOnce) {
        await _locationService.requestService();
        askLocationRequestOnce = true;
        startLocationService();
      }
    }
  }

  @override
  void dispose() {
    var locationService = LocationService();
    locationService.stopStreamer();
    if (gpsStreamSubscription != null) {
      gpsStreamSubscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: GoogleMap(
          mapType: MapType.hybrid,
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: latAndLong.length == 0
                ? LatLng(39.67786876031777, 20.832470453448813)
                : LatLng(double.parse(latAndLong[0].toString()),
                    double.parse(latAndLong[1].toString())),
            zoom: 11.0,
          ),
          markers: markers,
        ));
  }
}
