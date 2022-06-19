import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:location/location.dart' as location;
import 'main.dart';

StreamController controller = StreamController.broadcast();
Stream stream = controller.stream;
StreamController gpsController = StreamController.broadcast();

class LocationClass {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String timestamp;
  LocationClass(this.latitude, this.longitude, this.accuracy, this.timestamp);
}

class LocationService {
  static final LocationService _location = LocationService._internal();
  location.Location _locationService = location.Location();
  StreamSubscription<location.LocationData> _locationSubscription;
  Timer timer;
  factory LocationService() {
    return _location;
  }

  LocationService._internal();

  initialize() async {
    controller = StreamController.broadcast();
    stream = controller.stream;
    bool serviceStatus = await _locationService.serviceEnabled();
    if (serviceStatus) {
      try {
        await _locationService.requestPermission();
        if (await _locationService.hasPermission() ==
                location.PermissionStatus.granted ||
            await _locationService.hasPermission() ==
                location.PermissionStatus.grantedLimited) {
          if (!Platform.isAndroid) {
            geolocator.Position locationFromGeolocator;
            locationFromGeolocator =
                await geolocator.Geolocator.getCurrentPosition();

            LocationClass object;
            object = LocationClass(
                locationFromGeolocator.latitude,
                locationFromGeolocator.longitude,
                locationFromGeolocator.accuracy,
                '0');
            updateLocation(object);

            timer =
                Timer.periodic(Duration(milliseconds: 3000), (Timer t) async {
              locationFromGeolocator =
                  await geolocator.Geolocator.getCurrentPosition(
                      desiredAccuracy: geolocator.LocationAccuracy.high);

              LocationClass object;
              object = LocationClass(
                  locationFromGeolocator.latitude,
                  locationFromGeolocator.longitude,
                  locationFromGeolocator.accuracy,
                  '0');
              updateLocation(object);
            });
          } else {
            await _locationService.changeSettings(
                accuracy: location.LocationAccuracy.high, interval: 3000);

            _locationSubscription = _locationService.onLocationChanged
                .listen((location.LocationData result) async {
              updateLocation(result);
            });
          }
        }
      } catch (e) {}
    }
  }

  updateLocation(location) {
    var time = new DateTime.now().toString();
    gpsStreamController.add(location.latitude.toString() +
        " " +
        location.longitude.toString() +
        " " +
        time.toString());
  }

  stopStreamer() async {
    try {
      if (!Platform.isAndroid) {
        timer.cancel();
      } else {
        await _locationSubscription.cancel();
      }
      controller.close();
    } catch (e) {}
  }
}
