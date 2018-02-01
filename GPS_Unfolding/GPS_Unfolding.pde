/* 
 Copyright (2017) by Martin Zaltz Austwick, Sarah Wise, and University College London
 Licensed under the Academic Free License version 3.0
 See the file "LICENSE" for more information
 */

import java.util.List;
import java.io.FileNotFoundException;

import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.core.*;
import de.fhpotsdam.unfolding.data.*;
import de.fhpotsdam.unfolding.events.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.utils.*;

import de.fhpotsdam.unfolding.geo.MercatorProjection;
import de.fhpotsdam.unfolding.mapdisplay.AbstractMapDisplay;
import de.fhpotsdam.unfolding.mapdisplay.MapDisplayFactory;
import de.fhpotsdam.unfolding.tiles.MBTilesLoaderUtils;

// controlling the visualisation
boolean paused = false;
boolean enable_heatmap = false;
boolean enable_agents = true;
boolean enable_manifest = false;
boolean enable_basemap = true;
boolean recordMe = false;
boolean enable_startPoints = false;
boolean enable_endPoints = false;

boolean loaded = false;

//
// identifying the data to utilise
//
int selectOneFile = -1;//-1; // -1 to draw all tracks at once, 0+ to draw each track individually
int maxFile = 5000;//7;
int minManifest = 3;
int maxManifest = 3;

// world parameters
PVector latLims = new PVector(51.5, 51.6);
PVector lonLims = new PVector(-0.3, 0.05);
int minTime = 0, maxTime = 24*3600;
float driftLimit = 0.001;

// time parameters
int startMam = 0*3600; // CHANGE THIS to change the start time!
int mamChange = 4*15; // CHANGE THIS to make time run faster or slower
int timeIndex;

// graphical parameters
float trackAlpha = 50;
float strokoo = 2;
boolean findLimits = false;
int colorIndex = 0;

int driverColour = color(255, 0, 0);
int vehicleColour = color(255, 255, 0);

int walkingWidth = 15;//20;//15;
int drivingWidth = 7;//12;//7;

int percent = 0;

AbstractMapProvider smokeAndStarsProvider;
AbstractMapProvider blankProvider;

//
// the physical world
//
UnfoldingMap map;
MarkerManager mm_agents;
MarkerManager mm_heatmap;
MarkerManager mm_deliveries;
MarkerManager mm_invisible;
MarkerManager mm_start;
MarkerManager mm_end;


// images
PImage casa, ftc;


// Initialisation

void setup()
{
  size(1200, 800, P3D);
  smooth();
  frameRate(90);

  loadLogos();

  String tilesStr = "jdbc:sqlite:" + sketchPath(
    "./data/tiles/LondonSmokeAndStarsBIG.mbtiles");//"./data/tiles/LondonSmokeAndStars3.mbtiles");//LondonDemo_noRed.mbtiles");

  // set up the UnfoldingMap to hold the data

  smokeAndStarsProvider = new MBTilesMapProvider(tilesStr);
  blankProvider = new MBTilesMapProvider();
  map = new UnfoldingMap(this, smokeAndStarsProvider);//new StamenMapProvider.WaterColor());
  mm_agents = new MarkerManager<Marker>();
  mm_heatmap = new MarkerManager<Marker>();
  mm_deliveries = new MarkerManager<Marker>();
  mm_invisible = new MarkerManager<Marker>();
  mm_start = new MarkerManager<Marker>();
  mm_end = new MarkerManager<Marker>();

  // set
  map.zoomToLevel(14);
  map.setZoomRange(10, 17); // prevent zooming too far out
  MapUtils.createDefaultEventDispatcher(this, map);

  if (findLimits)
  {
    latLims = new PVector(90, -90);
    lonLims = new PVector(180, -180);
    minTime = Integer.MAX_VALUE;
    maxTime = -1;
  }

  //thread("readInInfo");
  readInInfo();

  // set up the map for visualisation
  Location centrePoint = new Location(0.5 * (latLims.x + latLims.y), 
    0.5 * (lonLims.x + lonLims.y));
  map.panTo(centrePoint);

  // final settings on the environment
  strokeWeight(strokoo);
  background(255);
  noStroke();
  colorMode(HSB);

  surface.setResizable(true);
  surface.setSize(1200, 800);
  if (findLimits)
    timeIndex = max(startMam, minTime);
  else
    timeIndex = startMam;
}

void readInInfo() {
  percent = 10;
  //  readInDir("/Users/swise/Projects/FTC/data/GnewtN_251016/GnewtN_", "_251016.csv", 
  //    "/Users/swise/Projects/FTC/data/DetailedSurveyRoutesCSV/251016_", "_GnewtN.csv", color(50, 150, 220));
  //readInDir("/Users/swise/Projects/FTC/data/GnewtN_251016/GnewtN_", "_251016.csv", 
  //  "/Users/swise/Projects/FTC/data/ThuBa/FTCPresentationOct2017/", ".csv", color(50, 150, 220));
  percent = 50;
  delay(100);
//  readInInrixDir("/Users/swise/Projects/FTC/data/inrix/partitioned/");
    readInInrix("/Users/swise/Projects/FTC/data/inrix/14thseptinrixwaypoints.csv");//TripRecordsReportWaypoints_Sep2016.csv");
  //readInInrix("/Users/swise/Projects/FTC/data/inrix/testWaypoints.csv");

  synchronized(this) {
    loaded = true;
  }
  percent = 100;
}

synchronized void draw()
{  
  background(color(14,14,14));
  if (! loaded) {
    /*stroke(255);
     noFill();
     rect(width/2-150, height/2, 300, 10);
     fill(255);
     // The size of the rectangle is mapped to the percentage completed
     float w = map(percent, 0, 1, 0, 300);
     rect(width/2-150, height/2, w, 10);
     //   textSize(14);
     //    textAlign(CENTER);
     fill(255);
     text("Loading", width/2, height/2+30);*/
  } else {

    if (! paused) {

      // only proceed if the time is within the bounds
      if (timeIndex <= maxTime && timeIndex >=minTime) {
        MarkerManager [] thingsToUpdate = new MarkerManager [] {mm_invisible, mm_agents, mm_deliveries};
        for (MarkerManager m : thingsToUpdate) {
          List<Object> myPickups = m.getMarkers();  
          for (int i = 0; i < myPickups.size(); i++) {
            Object o = myPickups.get(i);
            if (o instanceof TimedMarker)
              ((TimedMarker)o).setToTime(timeIndex);
          }
        }
      }

      // update the time index
      timeIndex += mamChange; // ...but don't exceed the temporal boundaries
      timeIndex = min(max(timeIndex, minTime), maxTime);
    }
    map.draw();
    elClocko(); // visualise the time

    if (recordMe && frameCount%20==0) saveFrame("images/#####.png");
  }
}

void readInInrix(String filename) {
  try {
    ArrayList <AnimatedPointMarker> myMarkers = new ArrayList <AnimatedPointMarker> (readInFileInrix(filename, "", true));
    mm_agents.addMarkers(myMarkers);
    for (AnimatedPointMarker apm : myMarkers) {
      mm_heatmap.addMarker(apm.getTail());
    }
    map.addMarkerManager(mm_agents);
    map.addMarkerManager(mm_heatmap);
    
    ArrayList <FancyPointMarker> mySEMarkers = 
      new ArrayList <FancyPointMarker> (readInStartAndEndpointsInrix(filename, "", true, color(200,0,0,50), color(0,0,200,50)));
      
   mm_start.addMarkers(mySEMarkers);
   map.addMarkerManager(mm_start);
  } 
  catch (FileNotFoundException e) {
    e.printStackTrace();
  }
}

void readInInrixDir(String dir) {
  String filename;
  try {
    // go through the files and read in the driver/vehicle pairs
    for (int f = max(1, selectOneFile); f<=maxFile; f++)
    {      

      filename = dir + "file" + f + ".txt";

      AnimatedPointMarker myMarker = readInFileInrixParitioned(filename, "", true);
      mm_agents.addMarker(myMarker);
      mm_heatmap.addMarker(myMarker.getTail());
    }

    map.addMarkerManager(mm_agents);
    map.addMarkerManager(mm_heatmap);

    // defining the limits of the window
    if (findLimits) {
      lonLims = bufferVals(lonLims, 0.2);
      latLims = bufferVals(latLims, 0.2);
    }

    println(latLims + "\n" + lonLims);
  } 
  catch (FileNotFoundException e) {
    e.printStackTrace();
  }
}

void readInDir(String dirTrace, String dirTraceSuffix, 
  String dirManifest, String dirManifestSuffix, color myAssignedColor) {

  String filename;

  // go through the files and read in the driver/vehicle pairs
  for (int f = max(1, selectOneFile); f<=maxFile; f++)
  {      

    // first process the driver
    //color myColor = myAssignedColor;//palette[colorIndex];

    if (f > 0 ) {

      // add the driver and vehicle, if desired
      filename = dirTrace + str(f) + "D" + dirTraceSuffix;
      //     try { addDriver(filename, myColor); } catch (FileNotFoundException e){}

      //String inrixFilename = dirTrace + dirTraceSuffix;

      // next the vehicle
      filename = dirTrace + str(f) + "V" + dirTraceSuffix;
      //     try { addVehicle(filename, myColor); } catch (FileNotFoundException e){}
    }

    // add an associated manifest, if desired
    if (f >= minManifest && f <= maxManifest) {

      try {

        // taken from https://processing.org/discourse/beta/num_1261125421.html
        //color newColor = (myColor & 0xffffff) | (100 << 24); 

        filename = dirManifest + "output_case" + str(f) + dirManifestSuffix;
        readInFilePointsMING(filename, color(215, 25, 28, 180), color(255, 255, 191, 180), mm_agents, 3, 3);

        filename = dirManifest + "case" + str(f) + ".txt";
        readInFileTimedPoints(filename, color(255), "DeliveryTime", mm_deliveries);
        readInFileBlinkingPointsWithAttributes(filename, setUpAttributeMapping(), "Time", mm_deliveries);
        //readInFileBlinkingPoints(filename, myColor, newColor, mm_deliveries);
        //readInFilePointsAsRings(filename, myColor, newColor, mm_deliveries, mm_invisible);
      } 
      catch (FileNotFoundException e) {
      }
    }
  }

  // add the MarkerManagers to the map itself
  map.addMarkerManager(mm_heatmap);
  map.addMarkerManager(mm_agents);
  map.addMarkerManager(mm_deliveries);

  // defining the limits of the window
  lonLims = bufferVals(lonLims, 0.2);
  latLims = bufferVals(latLims, 0.2);
  println(latLims + "\n" + lonLims);
}


//////////////////////////////////////////////
// INTERACTIVITY /////////////////////////////
//////////////////////////////////////////////
void keyPressed() {
  if (key == ' ') {
    paused = !paused;
  }
  if ( key== 'r') { // reverse the flow of time!
    mamChange *= -1;
  }
  if ( key == 'q') { // exit the visualisation
    exit();
  }
  else if ( key =='h') { // flip the visibility of the heatmap
    enable_heatmap = !enable_heatmap;
    if (enable_heatmap) mm_heatmap.enableDrawing();
    else mm_heatmap.disableDrawing();
  }
  else if ( key == 'a') { // flip the visibility of the agents
    enable_agents = !enable_agents;
    if (enable_agents) mm_agents.enableDrawing();
    else mm_agents.disableDrawing();
  }
  else if ( key == 'm') { // flip the visibility of the manifest
    enable_manifest = !enable_manifest;
    if (enable_manifest) mm_deliveries.enableDrawing();
    else mm_deliveries.disableDrawing();
  }
  else if ( key == 's') { // flip the visibility of the manifest
    enable_startPoints = !enable_startPoints;
    if (enable_startPoints) mm_start.enableDrawing();
    else mm_start.disableDrawing();
  }
  else if ( key == 'e') { // flip the visibility of the manifest
    enable_endPoints = !enable_endPoints;
    if (enable_endPoints) mm_end.enableDrawing();
    else mm_end.disableDrawing();
  }
  
}