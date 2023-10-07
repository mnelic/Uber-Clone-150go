import 'package:flutter/material.dart';
import 'package:katsitokatsi/AllWidgets/divider.dart';
import 'package:katsitokatsi/AllWidgets/progressDialog.dart';
import 'package:katsitokatsi/Models/address.dart';
import 'package:provider/provider.dart';

import '../Assistant/requestAssistant.dart';
import '../DataHandler/appData.dart';
import '../Models/placePredictions.dart';
import '../configMaps.dart';
class SearchScreen extends StatefulWidget{
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState  extends State<SearchScreen>{
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController dropOffTextEditingController = TextEditingController();

  List<PlacePredictions> placePredictionList  = [];

  @override
  Widget build( BuildContext context)
  {
    String placeAddress = Provider.of<AppData>(context).pickUplocation?.placeName ??"";
    pickUpTextEditingController.text = placeAddress;
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 215.0 ,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 6.0,
                  spreadRadius: 0.5,
                  offset: Offset(0.7,0.7),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 25.0,top: 20.0,right: 25.0,bottom: 20.0),
              child:  Column(
                children: [
                  const SizedBox(height: 5.0,),
                   Stack(
                     children: [

                       GestureDetector(
                         onTap: ()
                        {
                          Navigator.pop(context);
                        },
                         child: Icon(
                             Icons.arrow_back
                         ),
                       ),

                       Center(
                         child: Text("Set Destination Point", style: TextStyle(fontSize: 18.0,fontFamily: "Brand-Bold"),),
                       ),
                     ],
                   ),
                  const SizedBox(height: 16.0,),
                  Row(
                    children: [
                      Image.asset("images/pickicon.png", height: 16.0,width: 16.0,),
                      const SizedBox(width: 18.0,),
                      Expanded(child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child:  Padding(
                          padding: EdgeInsets.all(3.0),
                          child: TextField(
                            controller: pickUpTextEditingController,
                            decoration: InputDecoration(
                              hintText: "PickUp location",
                              fillColor: Colors.grey,
                              filled: true,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.only(left: 11.0,top: 8.0,bottom: 8.0),

                            ),
                          ),
                        ),
                      ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0,),
                  Row(
                    children: [
                      Image.asset("images/desticon.png", height: 16.0,width: 16.0,),
                      const SizedBox(width: 18.0,),
                      Expanded(child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child:  Padding(
                          padding: EdgeInsets.all(3.0),
                          child: TextField(
                            onChanged: (val)
                            {
                              findPlace(val);
                            },
                            controller: dropOffTextEditingController,
                            decoration: InputDecoration(
                              hintText: "Where to?",
                              fillColor: Colors.grey,
                              filled: true,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.only(left: 11.0,top: 8.0,bottom: 8.0),
                            ),
                          ),
                        ),
                      ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          //title for predictions
          SizedBox(height : 10.0,),
            ( placePredictionList.length > 0) ? 
          Padding(padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ListView.separated(
              padding: EdgeInsets.all(
                0.0),

              itemBuilder: (context,index )
              {
                return PredictionTile( placePredictions: placePredictionList[index], );
              }
              , separatorBuilder: (BuildContext context,int index) => DividerWidget(),
              itemCount: placePredictionList.length,
              shrinkWrap: true,
            physics: ClampingScrollPhysics(),
          ),
          )
                : Container(),

        ],
      ),
    );
  }
void findPlace( String placeName) async
{
  if(placeName.length > 1)
  {
    String AutoCompleteUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=1234567890&components=country:za";
       var res  = await RequestAssistant.getRequest(AutoCompleteUrl);
       if(res == "failed")
         {
           return;
         }
        if(res["status"] == "OK")
          {
            var predictions = res["predictions"];
            var placeList = (predictions as List).map((e) => PlacePredictions.fromJson(e)).toList();
            setState(()
            {
              placePredictionList = placeList;
            });
          }
  }
}
}


 class PredictionTile extends  StatelessWidget
 {
  final PlacePredictions placePredictions;

  PredictionTile({ Key? key, required this.placePredictions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return  TextButton(
       style: TextButton.styleFrom(padding: EdgeInsets.all(0.0),

       ),
        onPressed: ()
        {
          getPlaceDetails(placePredictions.place_id, context);
        },

        child: Container(
          child: Column(
            children: [
              SizedBox(width: 8.0,),
              Row(
                children: [
                  Icon(Icons.add_location),
                  SizedBox(width: 14.0,),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.0,),
                      Text(placePredictions.main_text,overflow: TextOverflow.ellipsis, style: TextStyle(fontSize:16.0, color: Colors.black),),
                      SizedBox(height: 2.0,),
                      Text(placePredictions.secondary_text,overflow: TextOverflow.ellipsis , style: TextStyle(fontSize:12.0 , color: Colors.grey),),
                      SizedBox(height: 8.0,),
                    ],
                  ),
                  ),
                ],
              ),
              SizedBox(width: 10.0,),
            ],
          ),
        ),

    );
  }
   void getPlaceDetails( String placeId,context ) async
   {
     showDialog(
         context: context,
         builder: (BuildContext context) => ProgressDialog(message: "Setting Drop off, Please wait ...",)
     );

      String placeDetailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";
      var res = await RequestAssistant.getRequest(placeDetailsUrl);
      Navigator.pop(context);

      if(res == "failed")
        {
          return;
        }

      if(res["status"] == "OK")
        {
          Address address = Address(placeId: placeId, placeName: res["result"]["name"],
              latitude:res["result"]["geometry"]["location"]["lat"] ,
              longitude: res["result"]["geometry"]["location"]["lng"]);
          Provider.of<AppData>(context, listen: false).updateDropOffLocationAddress(address);
          print("mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm This is Drop off location:: ");
          print(address.placeName );
          Navigator.pop(context, "obtainDirection");
          
          
        }
   }
 }



