  import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:katsitokatsi/AllScreens/loginScreen.dart';
import 'package:katsitokatsi/AllWidgets/progressDialog.dart';
import 'package:katsitokatsi/configMaps.dart';
import 'package:provider/provider.dart';
import '../AllWidgets/divider.dart';
  import '../Assistant/assistantMethods.dart';
import '../Assistant/geoFileAssistant.dart';
import '../DataHandler/appData.dart';
import 'package:katsitokatsi/AllScreens/searchScreen.dart';

import '../Models/directionDetails.dart';
import '../Models/nearbyAvailableDrivers.dart';


class MainScreen extends StatefulWidget
{
  static const String idScreen = "mainscreen";
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  late GoogleMapController newGoogleMapController;
  GlobalKey<ScaffoldState> scaffoldkey = new GlobalKey<ScaffoldState>();
  DirectionDetails? tripDirectionDetails;

  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polyLineSet = {};

  late Position currentPosition;

  var geolocator = Geolocator();
  double bottomPaddingOfMap = 0;

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};


  double rideDetailsContainerHeight = 0;
  double requestRideContainerHeight = 0;
  double searchContainerHeight = 300.0;
  bool drawerOpen = true;
  bool  isNearbyAvailableDriverKeyLoaded = false;
  late DatabaseReference rideRequestRef;
  BitmapDescriptor? nearByIcon ;
  

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    AssistantMethods.getCurrentOnlineUserInfo();
  }

  void saveRideRequest() {
    rideRequestRef =
        FirebaseDatabase.instance.ref().child("Ride Requests").push();
    var pickUp = Provider
        .of<AppData>(context, listen: false)
        .pickUplocation;
    var dropOff = Provider
        .of<AppData>(context, listen: false)
        .dropOffLocation;

    Map pickUplocMap =
    {
      "latitude": pickUp!.latitude.toString(),
      "longitude": pickUp!.longitude.toString(),
    };

    Map dropOfflocMap =
    {
      "latitude": dropOff!.latitude.toString(),
      "longitude": dropOff!.longitude.toString(),
    };
    Map rideInforMap =
    {
      "driver_id": "waiting",
      "payment_method": "cash",
      "pickup": pickUplocMap,
      "dropoff": dropOfflocMap,
      "created_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo!.name,
      "rider_phone": userCurrentInfo!.phone,
      "pickup_address": pickUp.placeName,
      "dropoff_address": dropOff.placeName,

    };
    rideRequestRef.set(rideInforMap);
  }

  void cancelRideRequest() {
    rideRequestRef.remove();
  }

  void displayRequestRideContainer() {
    setState(() {
      requestRideContainerHeight = 250.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = true;
    });
    saveRideRequest();
  }

  resetApp() {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 300.0;
      rideDetailsContainerHeight = 0;
      requestRideContainerHeight = 0;
      bottomPaddingOfMap = 230.0;
      polyLineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
    });

    locatePosition();
  }


  void displayRideDetailsContainer() async
  {
    await getPlaceDirection();

    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 240.0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = false;
    });
  }

  void locatePosition() async
  {

    Position position = await _determinePosition();
    currentPosition = position;
    LatLng latlngthPosition = LatLng(position.latitude, position.longitude);
    CameraPosition cameraPosition = new CameraPosition (
        target: latlngthPosition, zoom: 14);
    newGoogleMapController.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition));

    String address = await AssistantMethods.searchCoOrdinateAddress(
        position, context);
    print("This is your address::" + address);

    unitGeoFireListner();

  }

  Future<Position> _determinePosition() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("You denied Location permission");
      }
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );


  @override
  Widget build(BuildContext context) {
    createIconMaker();
    return Scaffold(
      key: scaffoldkey,
      appBar: AppBar(
        title: const Text("Main Screen of katsi"),
      ),
      drawer: Container(
        color: Colors.white,
        width: 255.0,
        child: Drawer(
          child: ListView(
            children: [
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Image.asset(
                        "images/user_icon.png", height: 65.0, width: 65.0,),
                      SizedBox(width: 16.0,),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Profile Name", style: TextStyle(
                              fontSize: 14.0, fontFamily: "Brand Bold"),),
                          SizedBox(height: 6.0,),
                          Text("Visit Profile"),

                        ],
                      )

                    ],
                  ),
                ),
              ),
              DividerWidget(),
              SizedBox(height: 12.0,),

              //Drawer Body

              ListTile(
                leading: Icon(Icons.history),
                title: Text("History", style: TextStyle(fontSize: 15.0,),),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text(
                  "Visit Profile", style: TextStyle(fontSize: 15.0,),),
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text("About", style: TextStyle(fontSize: 15.0,),),
              ),
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.idScreen, (route) => false);
                },
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text("Sign out", style: TextStyle(fontSize: 15.0,),),
                ),
              )

            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polyLineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;
              setState(() {
                bottomPaddingOfMap = 290.0;
              }
              );
              locatePosition();
            },
          ),

          //HamburgerButton for Drawer
          Positioned(
            top: 38.0,
            left: 22.0,
            child: GestureDetector(

              onTap: () {
                if (drawerOpen) {
                  scaffoldkey.currentState?.openDrawer();
                }
                else {
                  resetApp();
                }
              },

              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 6.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7,
                      ),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon((drawerOpen) ? Icons.menu : Icons.close,
                    color: Colors.black,),
                  radius: 20.0,

                ),
              ),
            ),

          ),

          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              // ignore: deprecated_member_use
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(microseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18.0),
                      topRight: Radius.circular(18.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 6.0),
                      const Text(
                        "Hi there,", style: TextStyle(fontSize: 12.0),),
                      const Text("Where to?", style: TextStyle(
                          fontSize: 20.0, fontFamily: "Brand-Bold"),),
                      const SizedBox(height: 20.0),
                      GestureDetector(
                        onTap: () async
                        {
                          var res = await Navigator.push((context),
                              MaterialPageRoute(
                                  builder: (context) => SearchScreen()));
                          if (res == "obtainDirection") {
                            displayRideDetailsContainer();
                          }
                        },

                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 6.0,
                                spreadRadius: 0.5,
                                offset: Offset(0.7, 0.7),
                              ),
                            ],

                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: Colors.blueAccent,),
                                SizedBox(width: 10.0),
                                Text("Search Destination Point"),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      Row(
                        children: [
                          Icon(Icons.home, color: Colors.grey,),
                          SizedBox(width: 12.0,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(overflow: TextOverflow.ellipsis,
                                Provider
                                    .of<AppData>(context)
                                    .pickUplocation != null ?
                                Provider
                                    .of<AppData>(context)
                                    .pickUplocation!
                                    .placeName :
                                "Add Home",
                              ),
                              SizedBox(height: 4.0,),
                              Text("You living home adress", style: TextStyle(
                                  color: Colors.black54, fontSize: 12.0),),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10.0),
                      DividerWidget(),
                      SizedBox(height: 16.0,),
                      Row(
                        children: [
                          Icon(Icons.work, color: Colors.grey,),
                          SizedBox(width: 12.0,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4.0,),
                              Text(
                                  "Add Work"

                              ),
                              SizedBox(height: 4.0,),
                              Text("Your office adress", style: TextStyle(
                                  color: Colors.black54, fontSize: 12.0),),

                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,

            child: AnimatedSize(
              // ignore: deprecated_member_use
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(microseconds: 160),
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black,
                        blurRadius: 16.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7)
                    ),
                  ],

                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 17.0),

                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.tealAccent[100],
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Image.asset(
                                "images/taxi.png", height: 70.0, width: 30.0,),
                              SizedBox(width: 16.0,),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Car", style: TextStyle(
                                    fontSize: 18.0, fontFamily: "Brand-Bold",),
                                  ),
                                  Text(
                                    ((tripDirectionDetails != null)
                                        ? tripDirectionDetails!.distanceText
                                        : ''), style: TextStyle(
                                    fontSize: 18.0, color: Colors.grey,),
                                  ),
                                ],
                              ),
                              Expanded(child: Container()),
                              Text(
                                ((tripDirectionDetails != null
                                    ? '\R${AssistantMethods.calculateFares(
                                    tripDirectionDetails!)}'
                                    : '')),
                                style: TextStyle(fontFamily: "Brand-Bold",),
                              ),
                            ],
                          ),
                        ),

                      ),
                      SizedBox(height: 20.0,),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            Icon(FontAwesomeIcons.moneyCheck, size: 18.0,
                              color: Colors.black54,),
                            SizedBox(width: 16.0,),
                            Text("Cash"),
                            SizedBox(width: 6.0,),
                            Icon(
                              Icons.keyboard_arrow_down, color: Colors.black54,
                              size: 16.0,),

                          ],
                        ),
                      ),

                      SizedBox(height: 24.0,),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: ElevatedButton(

                          onPressed: () {
                            displayRequestRideContainer();
                          },
                          style: ElevatedButton.styleFrom(
                              onPrimary: Theme
                                  .of(context)
                                  .colorScheme
                                  .secondary
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(5.0, 0.0, 5.0, 0.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Request", style: TextStyle(fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),),
                                Icon(FontAwesomeIcons.taxi, color: Colors.white,
                                  size: 26.0,),
                              ],
                            ),
                          ),

                        ),

                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,

            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black54,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: requestRideContainerHeight,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    SizedBox(height: 12.0),

                    SizedBox(
                      width: double.infinity,

                      // ignore: deprecated_member_use
                      child: ColorizeAnimatedTextKit(
                        onTap: () {
                          print("Tab Event");
                        },
                        text: [
                          "Requesting a Ride...",
                          "Please wait...",
                          "Finding a Driver..."
                        ],
                        textStyle: TextStyle(
                            fontSize: 55.0,
                            fontFamily: "Signatra"
                        ),
                        colors: [
                          Colors.green,
                          Colors.purple,
                          Colors.pink,
                          Colors.blue,
                          Colors.yellow,
                          Colors.red,
                        ],
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 22.0),
                    GestureDetector(
                      onTap: () {
                        cancelRideRequest();
                        resetApp();
                      },

                      child: Container(
                        height: 60.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26.0),
                          border: Border.all(width: 2.0, color: Colors.grey),
                        ),
                        child: Icon(Icons.close, size: 26.0,),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    Container(
                      width: double.infinity,
                      child: Text("Cancel Ride", textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.0),),
                    )
                  ],
                ),
              ),

            ),
          ),
        ],
      ),
    );
  }

  Future<void> getPlaceDirection() async
  {
    var initialPos = Provider
        .of<AppData>(context, listen: false)
        .pickUplocation;
    var finalPos = Provider
        .of<AppData>(context, listen: false)
        .dropOffLocation;
    var pickUpLatLgn = LatLng(initialPos!.latitude, initialPos!.longitude);
    var droOffLatLng = LatLng(finalPos!.latitude, finalPos!.longitude);

    showDialog(context: context,
        builder: (BuildContext context) =>
            ProgressDialog(message: "Please wait...",)
    );

    var details = await AssistantMethods.obtainPlaceDirectionDetails(
        pickUpLatLgn, droOffLatLng);

    setState(() {
      tripDirectionDetails = details!;
    });


    Navigator.pop(context);

    print("This is Encoded Points:: ");
    print(details!.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolylinePointsResult = polylinePoints
        .decodePolyline(details.encodedPoints);

    pLineCoordinates.clear();
    if (decodedPolylinePointsResult.isNotEmpty) {
      decodedPolylinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates.add(
            LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    polyLineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        color: Colors.pink,
        polylineId: PolylineId("polylineId"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      polyLineSet.add(polyline);
    });
    LatLngBounds latLngBounds;
    if (pickUpLatLgn.latitude > droOffLatLng.latitude &&
        pickUpLatLgn.longitude > droOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: droOffLatLng, northeast: pickUpLatLgn);
    }
    else if (pickUpLatLgn.longitude > droOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatLgn.latitude, droOffLatLng.longitude),
          northeast: LatLng(droOffLatLng.latitude, pickUpLatLgn.longitude));
    }
    else if (pickUpLatLgn.latitude > droOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(droOffLatLng.latitude, pickUpLatLgn.longitude),
          northeast: LatLng(pickUpLatLgn.latitude, droOffLatLng.longitude));
    }
    else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLgn, northeast: droOffLatLng);
    }

    newGoogleMapController.animateCamera(
        CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: InfoWindow(
          title: initialPos.placeName, snippet: "My location"),
      position: pickUpLatLgn,
      markerId: MarkerId("pickUpId"),
    );

    Marker dropOffLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
          title: finalPos.placeName, snippet: "Drop off location"),
      position: droOffLatLng,
      markerId: MarkerId("dropOffId"),
    );

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropOffLocMarker);
    });

    Circle pickUpLocCircle = Circle(
        fillColor: Colors.blueAccent,
        center: pickUpLatLgn,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.blueAccent,
        circleId: CircleId("pickUpId"));

    Circle dropOffLocCircle = Circle(
        fillColor: Colors.deepPurple,
        center: droOffLatLng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.deepPurple,
        circleId: CircleId("dropOffId"));

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }

  void unitGeoFireListner()
  {
    Geofire.initialize("availableDrivers");

    Geofire.queryAtLocation(
        currentPosition!.latitude, currentPosition!.longitude, 15)!.listen((map)
    {

      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyAvailableDrivers nearbyavailavledrivers = NearbyAvailableDrivers(
                key: map['key'], latitude: map['latitude'], longitude: map['longitude']);
            GeoFireAssisant.nearByAvailavleDriverslist.add(nearbyavailavledrivers);

            if(isNearbyAvailableDriverKeyLoaded == true)
            {
              updateAvailableDriverOnMap();
            }

            break;

          case Geofire.onKeyExited:
            GeoFireAssisant.removeDriverFromlist(map['key']);
            updateAvailableDriverOnMap();
            break;

          case Geofire.onKeyMoved:
            NearbyAvailableDrivers nearbyavailabledrivers = NearbyAvailableDrivers(
                key: map['key'], latitude: map['latitude'], longitude: map['longitude']);
            GeoFireAssisant.updateDrivernearbylocation(nearbyavailabledrivers);
            updateAvailableDriverOnMap();
            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriverOnMap();
            break;
        }
      }

      setState(()
      {});
    });
  }

  void updateAvailableDriverOnMap()
  {
    setState(() {
      markersSet.clear();
    });


    Set<Marker> tMakers = Set<Marker>();

    for (NearbyAvailableDrivers driver in GeoFireAssisant.nearByAvailavleDriverslist)
    {
      LatLng driverAvailablePosition = LatLng(driver.latitude, driver.longitude);
      Marker marker = Marker(markerId: MarkerId('driver${driver.key}'),
          position: driverAvailablePosition,
          icon: nearByIcon!,
          rotation: AssistantMethods.createRandomNumber(360),
      );

      tMakers.add(marker);
    }
    setState(() {
      markersSet = tMakers;
    });
  }
  void createIconMaker()
  {

    if( nearByIcon == null)
      {
        ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(2,2));
        BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car_ios.png").then((value){
          nearByIcon = value;
        });
      }
}     

}
