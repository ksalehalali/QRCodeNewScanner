import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:background_location/background_location.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:location/location.dart' as loc;
import '../Assistants/assistantMethods.dart';
import '../Assistants/globals.dart';
import '../Assistants/request-assistant.dart';
import '../Data/current_data.dart';
import '../config-maps.dart';
import '../model/address.dart';
import '../model/location.dart';
import '../model/placePredictions.dart';
import '../services/audio_player.dart';

class LocationController extends GetxController {
  var pickUpAddress = ''.obs;
  var dropOffAddress = ''.obs;
  List placePredictionList = [].obs;
  var latPinLoc = 0.0.obs;
  var lngPinLoc = 0.0.obs;
  var startAddingPickUp = false.obs;
  var startAddingDropOff = false.obs;
  var buttonString = ''.obs;
  var addDropOff = false.obs;
  var addPickUp = false.obs;
  var tripCreatedDone = false.obs;
  var showPinOnMap =false.obs;
  var liveLocation = new LatLng(0.0, 0.0).obs;
  var currentLocation = new LatLng(29.376291619820897, 47.98638395798397).obs;
  var currentLocationG = new google_maps.LatLng(0.0, 0.0).obs;
  var liveLocationG = new google_maps.LatLng(0.0, 0.0).obs;
  var pickUpLocationAddress =''.obs;
  var dropOffLocationAddress = ''.obs;
  Address? pickUpLocation;
  Address? dropOffLocation ;
  Rx<Position> positionFromPin =Position(latitude: 29.37631633045168, accuracy: 0.0, altitude: 0.0, speed: 0.0, speedAccuracy: 0.0, longitude: 47.98637351560368, heading: 0.0, timestamp: null).obs;
  AudioPlayerService audioPlayerService = AudioPlayerService();
  bool isLocationUpdated = false;
  var myFavAddresses =[].obs;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    Timer(Duration(milliseconds: 100), () {
      getCurrentLocationFromChannel();

    });
    getLocation();
  }

  //get current location from ios channel
  static const locationChannel = MethodChannel('location');
  final arguments = {'name': 'khaled'};
  Future getCurrentLocationFromChannel() async {
    var value;
    try {
      value = await locationChannel.invokeMethod("getCurrentLocation", arguments);
      var lat = value['lat'];
      var lng = value['lng'];
      if (lng > 0.0) {
        print("value  , main :: ${value.toString()}");
       changePickUpAddress('Current Location');
        currentPosition = geo.Position(
          latitude: lat,
          longitude: lng,
          accuracy: 0.0,
          altitude: lat,
          speedAccuracy: 0.0,
          heading: 0.0,
          timestamp: DateTime.now(),
          speed: 0.0,
        );
        searchCoordinateAddress(LocationModel(lat, lng));

        addPickUp.value = true;
      } else {
        print('Wrong coordinates ###');
      }
    } catch (err) {
      print(err);
    }
  }

  Future updateMyLocationInSystem(LocationModel location)async{
    var headers = {
      'Authorization': 'bearer ${user.accessToken}',
      'Content-Type': 'application/json'
    };
    var request = http.Request('POST', Uri.parse('$baseURL/api/UserTracking'));
    request.body = json.encode({
      "BusID": "55be4b8f-abf6-48f3-52c8-08da1620ad87",
      "Longitude": location.longitude,
      "Latitude": location.latitude
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());


    }
    else {
      print(response.reasonPhrase);
    }

  }

  var location = loc.Location();
  geo.Position? currentPosition;
  double bottomPaddingOfMap = 0;
  late loc.PermissionStatus _permissionGranted;
//get location for all
  Future getLocation() async {
    loc.Location location = loc.Location.instance;

    geo.Position? currentPos;
    loc.PermissionStatus permissionStatus = await location.hasPermission();
    _permissionGranted = permissionStatus;
    if (_permissionGranted != loc.PermissionStatus.granted) {
      final loc.PermissionStatus permissionStatusReqResult =
      await location.requestPermission();

      _permissionGranted = permissionStatusReqResult;
    }
    loc.LocationData loca = await location.getLocation();
    // loc.Location.instance.onLocationChanged.listen((location) {
    //   print('location ........ listening.......  ${location.longitude}');
    //
    // });
    BackgroundLocation.startLocationService(distanceFilter : 1);

    BackgroundLocation.getLocationUpdates((location) async {

      if (!isLocationUpdated){
        isLocationUpdated =true;
      Timer(Duration(seconds:5), () {
          updateMyLocationInSystem(LocationModel(location.latitude!, location.longitude!));
          isLocationUpdated =false;
      });

      }
      print("location ....... background update ${location.longitude} - ${location.latitude}");
      //audioPlayerService.audio1Play();
    });

    if (loca.latitude != null) {
     changePickUpAddress('Current Location');
      currentPosition = geo.Position(
        latitude: loca.latitude!,
        longitude: loca.longitude!,
        accuracy: loca.accuracy!,
        altitude: loca.altitude!,
        speedAccuracy: loca.speedAccuracy!,
        heading: loca.heading!,
        timestamp: DateTime.now(),
        speed: loca.speed!,
      );
     searchCoordinateAddress(LocationModel(loca.latitude!,loca.longitude!));
      addPickUp.value = true;
    }

    geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high);
    gotMyLocation(true);
    addPickUp.value = true;
    changePickUpAddress('Current Location');

    print("--------------------========== position controller $position");
    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    addPickUp.value = true;
  }

  Future searchCoordinateAddress(LocationModel location) async {
    AssistantMethods assistantMethods = AssistantMethods();
    String address = await assistantMethods.searchCoordinateAddress(currentPosition!, true);
    trip.startPointAddress = address;
    trip.startPoint =
        LocationModel(location.latitude, location.longitude);
    gotMyLocation(true);
    changePickUpAddress(address);
  }

  void changePickUpAddress(String pickUpAddressV) {
    pickUpAddress.value = pickUpAddressV;
    update();
  }

  void changeDropOffAddress(String dropOffAddressV) {
    dropOffAddress.value = dropOffAddressV;
    update();
  }

  void startAddingPickUpStatus(bool status){
    startAddingPickUp.value = status;
    update();
  }
  void startAddingDropOffStatus(bool status){
    startAddingDropOff.value = status;
    update();
  }

  void tripCreatedStatus(bool status){
    tripCreatedDone.value = status;
    update();
  }

  refreshPlacePredictionList(){
    placePredictionList.clear();
    placePredictionList.add(
        PlaceShort(
            placeId: '0',
            mainText: 'set_location_on_map_txt'.tr,
            secondText: 'choose_txt'.tr,
    ));
    //getMyAddresses();
  }
  void updatePickUpLocationAddress( Address pickUpAddress){
    pickUpLocation = pickUpAddress;
    update();
  }

  void updateDropOffLocationAddress( Address dropOffAddress){
    dropOffLocation = dropOffAddress;
    update();
  }
  updateLiveLoc(LatLng latLng){
    liveLocation.value = latLng;
  }
  void findPlace(String placeName) async {
    if (placeName.length > 1) {

      placePredictionList.clear();
      String autoCompleteUrl =
          "https://api.mapbox.com/geocoding/v5/mapbox.places/$placeName.json?worldview=us&country=kw&access_token=$mapbox_token";

      var res = await RequestAssistant.getRequest(autoCompleteUrl);


      if (res == "failed") {
        print('failed');
        return;
      }
      if (res["features"].length <1) {
        print('failed');
        return;
      }
      if (res["features"] != null) {
        print("res features  ===== :: ${res["features"]}");

        print(res['status']);
        var predictions = res["features"];

        var placesList = (predictions as List)
            .map((e) => PlacePredictions.fromJson(e))
            .toList();

        //placePredictionList = placesList;
        placesList.forEach((element) {
          placePredictionList.add(PlaceShort(
              placeId: element.id,
              mainText: element.text,
              secondText: element.place_name,
            lat: element.lat,
            lng: element.lng
          ));
        });
        print(placePredictionList.first);
        update();
      }
    }
  }

  //
  RxBool gotMyLocation = false.obs;
  addMyLocation(bool got){
    gotMyLocation.value = got;
    update();
}

updatePinPos(double lat , double lng){
    latPinLoc.value = lat;
    lngPinLoc.value = lng;
    currentLocationG.value=google_maps.LatLng(lat,lng);
    update();
}
//address
  Future getMyAddresses() async {

    placePredictionList.add(
        PlaceShort(
          placeId: '1',
          mainText: 'Kuwait Salm'.tr,
          secondText: 'Kuwait Salm2'.tr,
          lat:29.297260 ,
          lng:48.023180
        ));
  }
}

class PlaceShort {
  String? placeId;
  String? mainText;
  String? secondText;
  double? lat;
  double? lng;

  PlaceShort({this.mainText, this.placeId, this.secondText,this.lat,this.lng});

}
