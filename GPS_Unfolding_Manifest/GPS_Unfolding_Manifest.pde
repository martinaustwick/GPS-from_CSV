/* 
 Copyright (2017) by Martin Zaltz Austwick, Sarah Wise, and University College London
 Licensed under the Academic Free License version 3.0
 See the file "LICENSE" for more information
 */

import java.util.List;

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

//
// identifying the data to utilise
//
String baseString = "/Users/swise/Projects/FTC/data/"; // prefix for csv files (numbered 0-n)
int selectOneFile = 0;//-1; // -1 to draw all tracks at once, 0+ to draw each track individually
int maxFile = 0;//30;

// world parameters
PVector latLims = new PVector(51.5, 51.6);
PVector lonLims = new PVector(-0.3, 0.05);

float driftLimit = 0.001;

// time parameters
int startMam = 9*3600 + 60 * 20;
int mamChange = 10;

// graphical parameters
float strokoo = 1;
float strokeForTrails = 3;
boolean paused = false;
boolean findLimits = true;


int walkingColor = color(0, 255, 0, 150);
int drivingColor = color(100, 100, 100, 100);
//
// storage for data
//
List<Marker> driverTraces = new ArrayList<Marker>();
List<Marker> pickups = new ArrayList<Marker>();

//
// the physical world
//
UnfoldingMap map;


int mamTime;
int timeIndex;


// images
PImage casa, ftc;


// Initialisation

void setup()
{
  size(1200, 800, P3D);
  smooth();
  frameRate(90);
  mamTime = startMam;

  loadLogos();

  String tilesStr = "jdbc:sqlite:" + sketchPath("./data/tiles/CentralLondon.mbtiles");

  // set up the UnfoldingMap to hold the data

  map = new UnfoldingMap(this, new MBTilesMapProvider(tilesStr));
  //new StamenMapProvider.TonerBackground()); //(alternate tilings)
  //new StamenMapProvider.WaterColor());
  map.zoomToLevel(16);
  map.setZoomRange(14, 18); // prevent zooming too far out
  MapUtils.createDefaultEventDispatcher(this, map);

  if (findLimits)
  {
    latLims = new PVector(90, -90);
    lonLims = new PVector(180, -180);
  }

  for (int f = 0; f<=maxFile; f++)
  {      

    // open each manifest and add blinking points for each point 
    String filename = baseString + str(f) + ".csv";
    List <BlinkingPointMarker> drivers = readInFile(filename, "#" + f, color(255, 0, 0, 50), color(0, 0, 255, 50));

    // other color options
    //palette[int(random(palette.length))];

    // add all of the markers
    pickups.addAll(drivers);
  }

//  map.addMarkers(driverTraces);
  map.addMarkers(pickups);


  strokeWeight(strokoo);
  background(255);
  noStroke();
  colorMode(HSB);

  // defining the limits of the window
  lonLims = bufferVals(lonLims, 0.2);
  latLims = bufferVals(latLims, 0.2);
  println(latLims + "\n" + lonLims);

  // set up the map for visualisation
  Location centrePoint = 
    new Location(0.5 * (latLims.x + latLims.y), 0.5 * (lonLims.x + lonLims.y));
  map.panTo(centrePoint);  
  surface.setResizable(true);
  surface.setSize(1200, 800);
  timeIndex = startMam;
}

List <BlinkingPointMarker> readInFile(String filename, String name, color myColor, color finishedColor) {

  List <BlinkingPointMarker> results = new ArrayList <BlinkingPointMarker> ();

  // open the Driver file and read it into a table
  Table route = loadTable(filename, "header");

  // visualise the names of the columns
  //println((Object[])route.getColumnTitles());

  // extract columns of data from the table
  float [] lats = route.getFloatColumn("LATITUDE");
  float [] lons = route.getFloatColumn("LONGITUDE");    
  String [] ew = route.getStringColumn("E/W");
  String [] ns = route.getStringColumn("N/S");
  String [] time = route.getStringColumn("LOCAL TIME");
  String [] mode = route.getStringColumn("Mode");

  PositionRecord prevRecord = null;
  List<Location> tempPoints = new ArrayList <Location> ();
  String previousMode = mode[1];

  // iterate over the records, clean them accordingly, and store them
  for (int i=0; i<lons.length; i++)
  {
    // adjust for east or west
    if (ew[i].equals("W") && lons[i] > 0) lons[i] *=-1;
    if (ns[i].equals("S") && lats[i] > 0) lats[i] *=-1;

    // adjust the map to the limits of the area
    if (findLimits && i > 0)
    {
      if (abs(lons[i]-lons[i-1])<driftLimit)
      {
        if (lons[i]<lonLims.x) lonLims.x=lons[i];
        if (lons[i]>lonLims.y) lonLims.y=lons[i];
      }
      if (abs(lats[i]-lats[i-1])<driftLimit && lats[i]<89)
      {
        if (lats[i]<latLims.x) latLims.x=lats[i];
        if (lats[i]>latLims.y) latLims.y=lats[i];
      }
    }

    // extract time information
    String [] timeLine = split(time[i], ":");
    int myTime = 3600*int(timeLine[0]) + 60*int(timeLine[1]) + int(timeLine[2]);

    // save the record as a PositionRecord
    PositionRecord pr = new PositionRecord( myTime, new Location(lats[i], lons[i]));
    pr.setPrev(prevRecord);

    // save as a MultiSegmentLineMarker
    if (!mode[i].equals(previousMode)) {

      if(tempPoints.size() > 1)
        driverTraces.add(newManifestTrace(tempPoints, mode[i]));//previousMode));

      tempPoints = new ArrayList <Location>();
      if(prevRecord != null)
        tempPoints.add(prevRecord.position);
      previousMode = mode[i];
    }
    tempPoints.add(pr.position);


    // set up the BlinkingPointMarker
    BlinkingPointMarker bpm = new BlinkingPointMarker(pr, "" + i, myTime);
    bpm.setStrokeColor(myColor);
    bpm.setHighlightStrokeColor(finishedColor);
    bpm.setStrokeWeight((int)strokoo);
    if(mode.equals("Driving"))
      bpm.setHighlightStrokeColor(color(0,255,0,50));

    results.add(bpm);

    prevRecord = pr;
  }


  driverTraces.add(newManifestTrace(tempPoints, previousMode));
  return results;
}

SimpleLinesMarker newManifestTrace(List<Location> positions, String mode) {

  SimpleLinesMarker slm = new SimpleLinesMarker(positions);
  if (mode.equals("Walking")) {
    slm.setColor(walkingColor);
    slm.setHighlightColor(walkingColor);
    slm.setStrokeWeight((int) strokeForTrails);
  } else {
    slm.setColor(drivingColor);
    slm.setStrokeColor(drivingColor);
    slm.setHighlightColor(drivingColor);
    slm.setHighlightStrokeColor(drivingColor);
    slm.setStrokeWeight((int) strokeForTrails * 2);
  }
  return slm;
}

void draw()
{  
  background(0);
  if (! paused) {

    for (int i = 0; i < pickups.size(); i++) {
      ((BlinkingPointMarker)pickups.get(i)).checkIfUpdated(timeIndex);
    }
    timeIndex += mamChange;
  }
  map.draw();
  elClocko();
}


void keyPressed() {
  if (key == ' ') {
    paused = !paused;
  }
  if ( key== 'r') { // reverse the flow of time!
    mamChange *= -1;
  }
  if ( key == 'q') {
    exit();
  }
}