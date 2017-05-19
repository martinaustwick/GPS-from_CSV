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

//
// identifying the data to utilise
//
int selectOneFile = 13;//-1; // -1 to draw all tracks at once, 0+ to draw each track individually
int maxFile = 13;//7;
int minManifest = 13;
int maxManifest = 13;

// world parameters
PVector latLims = new PVector(51.5, 51.6);
PVector lonLims = new PVector(-0.3, 0.05);
int minTime = 0, maxTime = 24*3600;
float driftLimit = 0.001;

// time parameters
int startMam = 9*3600; // CHANGE THIS to change the start time!
int mamChange = 15; // CHANGE THIS to make time run faster or slower
int timeIndex;

// graphical parameters
float trackAlpha = 50;
float strokoo = 5;
boolean findLimits = true;
int colorIndex = 0;

int walkingWidth = 20;//15;
int drivingWidth = 12;//7;

//
// the physical world
//
UnfoldingMap map;
MarkerManager mm_agents;
MarkerManager mm_heatmap;
MarkerManager mm_deliveries;
MarkerManager mm_invisible;



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
    "./data/tiles/LondonSmokeAndStars3.mbtiles");//LondonDemo_noRed.mbtiles");

  // set up the UnfoldingMap to hold the data
  map = new UnfoldingMap(this, new MBTilesMapProvider(tilesStr));
  //new StamenMapProvider.WaterColor());
  mm_agents = new MarkerManager<Marker>();
  mm_heatmap = new MarkerManager<Marker>();
  mm_deliveries = new MarkerManager<Marker>();
  mm_invisible = new MarkerManager<Marker>();

  // set
  map.zoomToLevel(14);
  map.setZoomRange(12, 17); // prevent zooming too far out
  MapUtils.createDefaultEventDispatcher(this, map);

  if (findLimits)
  {
    latLims = new PVector(90, -90);
    lonLims = new PVector(180, -180);
    minTime = Integer.MAX_VALUE;
    maxTime = -1;
  }

  readInDir("/Users/swise/Projects/FTC/data/TNT_CSV/TNT_", "_271016.csv", 
    "/Users/swise/Projects/FTC/data/ThuBa/slide", ".csv", color(220,220,100));
    /*readInDir("/Users/swise/Projects/FTC/data/TNT_CSV/TNT_", "_251016.csv", 
    "/Users/swise/Projects/FTC/data/DetailedSurveyRoutesCSV/261016_", "_TNT.csv");
  readInDir("/Users/swise/Projects/FTC/data/TNT_CSV/TNT_", "_271016.csv", 
    "/Users/swise/Projects/FTC/data/DetailedSurveyRoutesCSV/261016_", "_TNT.csv");

  readInDir("/Users/swise/Projects/FTC/data/GnewtN_251016/GnewtN_", "_251016.csv", 
    "/Users/swise/Projects/FTC/data/DetailedSurveyRoutesCSV/251016_", "_GnewtN.csv",color(50,220,150));
*//*
readInDir("/Users/swise/Projects/FTC/data/GnewtS_251016/GnewtS_", "_251016.csv", 
    "/Users/swise/Projects/FTC/data/DetailedSurveyRoutesCSV/251016_", "_GnewtS.csv", color(50,150,220));

/*readInDir("/Users/swise/Projects/FTC/data/TNT_CSV/TNT_", "_261016.csv", 
    "/Users/swise/Projects/FTC/data/DetailedSurveyRoutesCSV/261016_", "_TNT.csv", color(50,150,220));
/*readInDir("/Users/swise/Projects/FTC/data/GnewtN_251016/GnewtN_", "_251016.csv", 
    "/Users/swise/Projects/FTC/data/DetailedSurveyRoutesCSV/251016_", "_GnewtN.csv", color(50,150,220));
  /*readInDir("/Users/swise/Projects/FTC/data/TNT_CSV/TNT_", "_251016.csv", 
    "/Users/swise/Projects/FTC/data/DetailedSurveyRoutesCSV/261016_", "_TNT.csv", color(220,220,100));

/*  readInDir("/Users/swise/Projects/FTC/data/TNT_CSV/TNT_", "_261016.csv", 
    "/Users/swise/Projects/FTC/data/DetailedSurveyRoutesCSV/261016_", "_TNT.csv", color(220,220,100));
  /*
   readInDir("/Users/swise/Projects/FTC/data/GnewtN_271016/GnewtN_", "_271016.csv", 
    "/Users/swise/Projects/FTC/data/DetailedSurveyRoutesCSV/271016_", "_GnewtN.csv",color(220,50,150));
*/
//readInDir("/Users/swise/Projects/FTC/data/GnewtN_271016/GnewtN_", "_271016.csv", 
//    "/Users/swise/Projects/FTC/data/ThuBa/slide", ".csv",color(50,220,150));
  
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

void readInDir(String dirTrace, String dirTraceSuffix, 
  String dirManifest, String dirManifestSuffix, color myAssignedColor) {
  // go through the files and read in the driver/vehicle pairs
  for (int f = max(1, selectOneFile); f<=maxFile; f++)
  {      
    // first process the driver
    String filename = dirTrace + str(f) + "D" + dirTraceSuffix;
    color myColor = palette[colorIndex];//myAssignedColor;//

    if (f > 0 ) {

      AnimatedPointMarker driver = readInFile(filename, "" + f, true);
      if (driver != null) {
        driver.setColor(myColor);
        driver.setStrokeWeight(2);
        driver.setStrokeColor(color(0, 0, 0));
        color newColor = (myColor & 0xffffff) | (50 << 24);
        driver.getTail().setColor(newColor);
  //      mm_agents.addMarker(driver);
  //      mm_heatmap.addMarker(driver.getTail());
        colorIndex = colorIndex + 1; // only increase index if it's successfully read in
        if(colorIndex > palette.length)
          colorIndex = 0;
      }

      // next the vehicle
/*
      filename = dirTrace + str(f) + "V" + dirTraceSuffix;
      AnimatedPointMarker vehicle = readInFile(filename, "", false);
      if (vehicle != null) {
        vehicle.square = true;
        vehicle.setColor(myColor);
        vehicle.setStrokeColor(color(0, 0, 0));
        vehicle.setStrokeWeight(0);
        mm_agents.addMarker(vehicle);
      } */
    }
    // finally, an associated manifest
    if (f >= minManifest && f <= maxManifest) {
      
      filename = dirManifest + str(f) + dirManifestSuffix;
      
      // taken from https://processing.org/discourse/beta/num_1261125421.html
      color newColor = (myColor & 0xffffff) | (100 << 24); 
      try {

        readInFilePointsMING(filename, color(200,200,0), color(250,0,0), //newColor, 
        mm_deliveries, 3, 2);
/*
RUBBISH CUT IT OFF
        AnimatedPointMarker manifest = readInFilePoints(filename, myColor, 
          newColor, color(220, 220, 220, 100), mm_deliveries);
        if(manifest != null){
    
          mm_deliveries.addMarker(manifest);
          SimpleLinesMarker manifestTail = manifest.getTail();
          manifestTail.setStrokeWeight(1);
          mm_deliveries.addMarker(manifest.getTail());
        }
  */    } 
      catch (FileNotFoundException e) {
      }
    }


  }

  // add the MarkerManagers to the map itself
  map.addMarkerManager(mm_agents);
  map.addMarkerManager(mm_deliveries);
  map.addMarkerManager(mm_heatmap);

  // defining the limits of the window
  lonLims = bufferVals(lonLims, 0.2);
  latLims = bufferVals(latLims, 0.2);
  println(latLims + "\n" + lonLims);
}


void draw()
{  
  background(0);

  if (! paused) {

    // only proceed if the time is within the bounds
    if (timeIndex <= maxTime && timeIndex >=minTime){
      for (Object o : mm_agents.getMarkers())
        ((AnimatedPointMarker) o).setToTime(timeIndex);
      List<Object> myPickups = mm_deliveries.getMarkers(); 
      for (int i = 0; i < myPickups.size(); i++) {
        Object o = myPickups.get(i);
        if(o instanceof AnimatedPointMarker)
          ((AnimatedPointMarker)o).setToTime(timeIndex);
          else if(o instanceof TimedLineMarker)
          ((TimedLineMarker)o).checkIfUpdated(timeIndex);
      }

      myPickups = mm_invisible.getMarkers(); 
      for (int i = 0; i < myPickups.size(); i++) {
        Object o = myPickups.get(i);
        if(o instanceof AnimatedPointMarker)
          ((AnimatedPointMarker)o).setToTime(timeIndex);
          else if(o instanceof TimedLineMarker)
          ((TimedLineMarker)o).checkIfUpdated(timeIndex);
      }

    }

    // update the time index
    timeIndex += mamChange; // ...but don't exceed the temporal boundaries
    timeIndex = min(max(timeIndex, minTime), maxTime);
  }
  map.draw();
  elClocko(); // visualise the time
}

// control the visualisation
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
  if ( key =='h') { // flip the visibility of the heatmap
    enable_heatmap = !enable_heatmap;
    if (enable_heatmap) mm_heatmap.enableDrawing();
    else mm_heatmap.disableDrawing();
  }
  if ( key == 'a') { // flip the visibility of the agents
    enable_agents = !enable_agents;
    if (enable_agents) mm_agents.enableDrawing();
    else mm_agents.disableDrawing();
  }
  if( key == 'm') { // flip the visibility of the manifest
    enable_manifest = !enable_manifest;
    if(enable_manifest) mm_deliveries.enableDrawing();
    else mm_deliveries.disableDrawing();
  }
}