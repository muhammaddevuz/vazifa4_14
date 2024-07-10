import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:dars_14/services/yandex_map_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController textEditingController = TextEditingController();
  late YandexMapController mapController;
  List<MapObject>? polylines;
  List<SearchItem> searchResults = [];
  Point myCurrentLocation = const Point(
    latitude: 41.2856806,
    longitude: 69.9034646,
  );

  Point najotTalim = const Point(
    latitude: 41.2856806,
    longitude: 69.2034646,
  );

  void onMapCreated(YandexMapController controller) {
    mapController = controller;
    mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: myCurrentLocation,
          zoom: 10,
        ),
      ),
    );
    setState(() {});
  }

  void onCameraPositionChanged(
    CameraPosition position,
    CameraUpdateReason reason,
    bool finished,
  ) async {

  }

  

  @override
  void initState() {
    super.initState();
    YandexMapService.requestLocationPermission().then((granted) {
      if (granted) {
        init();
      } else {
        // Ruxsat berilmagan holatni qayta ishlash
        print('Ruxsat berilmadi');
      }
    });
  }

  void init() async {
    Position? position = await YandexMapService.getCurrentLocation();
    if (position != null) {
      setState(() {
        myCurrentLocation = Point(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      });
    }
     onShowMyLocationPressed();
    setState(() {});
  }

  void searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    try {
      final searchResultWithSession = await YandexSearch.searchByText(
        searchText: query,
        geometry: Geometry.fromBoundingBox(
          BoundingBox(
            northEast: Point(latitude: 55.771899, longitude: 37.632206),
            southWest: Point(latitude: 55.771000, longitude: 37.631000),
          ),
        ),
        searchOptions: const SearchOptions(),
      );

      final searchResult = await searchResultWithSession.$2;

      setState(() {
        searchResults = searchResult.items ?? [];
      });
    } catch (e) {
      print('Qidiruv natijalarni olishda xatolik yuz berdi: $e');
      setState(() {
        searchResults = [];
      });
    }
  }

  void selectLocation(SearchItem item) async {
    final point = item.geometry.first.point;

    if (point != null) {
      mapController.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: point, zoom: 14),
        ),
      );

      // Polylines ni yaratish va chizish
      polylines = await YandexMapService.getDirection(myCurrentLocation, point);

      setState(() {
        searchResults = [];
        textEditingController.text = item.name;
      });
    }
  }

  void onShowMyLocationPressed() async {
  // Foydalanuvchi joriy joylashuvi
  Position? position = await YandexMapService.getCurrentLocation();
  if (position != null) {
    setState(() {
      myCurrentLocation = Point(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    });
    mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: myCurrentLocation, zoom: 14),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yandex Map Search Example'),
        actions: [
          IconButton(
            onPressed: () async {
              final res = await mapController.getUserCameraPosition();
              mapController.moveCamera(
                CameraUpdate.zoomOut(),
              );
            },
            icon: Icon(Icons.remove_circle),
          ),
          IconButton(
            onPressed: () {
              mapController.moveCamera(
                CameraUpdate.zoomIn(),
              );
            },
            icon: Icon(Icons.add_circle),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: textEditingController,
                  onChanged: searchLocation,
                  decoration: const InputDecoration(
                    hintText: 'Enter location to search',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
              ),
              if (searchResults.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final item = searchResults[index];
                      return ListTile(
                        title: Text(item.name),
                        onTap: () => selectLocation(item),
                      );
                    },
                  ),
                ),
              Expanded(
                flex: 2,
                child: YandexMap(
                  onMapCreated: onMapCreated,
                  onCameraPositionChanged: onCameraPositionChanged,
                  mapType: MapType.map,
                  mapObjects: [
                    PlacemarkMapObject(
                      mapId: const MapObjectId("najotTalim"),
                      point: najotTalim,
                      icon: PlacemarkIcon.single(
                        PlacemarkIconStyle(
                          image: BitmapDescriptor.fromAssetImage(
                            "assets/route_start.png",
                          ),
                        ),
                      ),
                    ),
                    PlacemarkMapObject(
                      mapId: const MapObjectId("myCurrentLocation"),
                      point: myCurrentLocation,
                      icon: PlacemarkIcon.single(
                        PlacemarkIconStyle(
                          image: BitmapDescriptor.fromAssetImage(
                            "assets/place.png",
                          ),
                        ),
                      ),
                    ),
                    if (polylines != null) ...polylines!,
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onShowMyLocationPressed,
        child: Icon(Icons.gps_fixed),
      ),
    );
  }
}
