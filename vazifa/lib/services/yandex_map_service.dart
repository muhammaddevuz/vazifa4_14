import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:geolocator/geolocator.dart';

class YandexMapService {
  static Future<List<MapObject>> getDirection(
    Point from,
    Point to,
  ) async {
    final result = await YandexDriving.requestRoutes(
      points: [
        RequestPoint(point: from, requestPointType: RequestPointType.wayPoint),
        RequestPoint(point: to, requestPointType: RequestPointType.wayPoint),
      ],
      drivingOptions: DrivingOptions(
        initialAzimuth: 1,
        routesCount: 1,
        avoidTolls: true,
      ),
    );

    final drivingResults = await result.$2;

    if (drivingResults.error != null) {
      print("Joylashuv olinmadi");
      return [];
    }

    final points = drivingResults.routes!.map((route) {
      return PolylineMapObject(
        mapId: MapObjectId(UniqueKey().toString()),
        polyline: route.geometry,
      );
    }).toList();

    return points;
  }

  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Ruxsat rad etildi
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Foydalanuvchi ruxsat so'rovini butunlay rad etgan
      return false;
    }

    // Ruxsat berildi
    return true;
  }

  static Future<Position?> getCurrentLocation() async {
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      // Joylashuv xizmati yoqilmagan
      return null;
    }

    bool permissionGranted = await requestLocationPermission();
    if (!permissionGranted) {
      // Ruxsat berilmagan
      return null;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return position;
    } catch (e) {
      // Xato yuz berdi
      return null;
    }
  }
}
