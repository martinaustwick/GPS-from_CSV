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
String baseString = "/Users/swise/Projects/FTC/CSV/"; // prefix for csv files (numbered 0-n)
int selectOneFile = -1; // -1 to draw all tracks at once, 0+ to draw each track individually
int maxFile = 30;

// world parameters
PVector latLims = new PVector(51.5, 51.6);
PVector lonLims = new PVector(-0.3, 0.05);

float driftLimit = 0.001;

// time parameters
int startMam = 6*3600;// + 60 * 20;
int mamChange = 10;

// graphical parameters
float trackAlpha = 50;
float strokoo = 5;
boolean paused = false;
boolean findLimits = true;

//
// storage for data
//
List<Marker> driverTraces = new ArrayList<Marker>();
List<Marker> vehicleTraces = new ArrayList<Marker>();
List<Marker> tails = new ArrayList<Marker>();

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

  String tilesStr = "jdbc:sqlite:" + sketchPath("./data/tiles/LondonDemo_noRed.mbtiles");

  // set up the UnfoldingMap to hold the data

  map = new UnfoldingMap(this, new MBTilesMapProvider(tilesStr));
  //new StamenMapProvider.TonerBackground()); //(alternate tilings)
  //new StamenMapProvider.WaterColor());
  map.zoomToLevel(14);
  map.setZoomRange(12, 17); // prevent zooming too far out
  MapUtils.createDefaultEventDispatcher(this, map);

  if (findLimits)
  {
    latLims = new PVector(90, -90);
    lonLims = new PVector(180, -180);
  }

  for (int f = 0; f<=maxFile; f++)
  {      

    // first process the driver

    String filename = baseString + str(f) + "-D.csv";
    AnimatedPointMarker driver = readInFile(filename, "#" + f);
    color myColor = palette[int(random(palette.length))];
    driver.setColor(myColor);
    driver.setStrokeWeight(2);
    driver.setStrokeColor(color(0,0,0));
    driverTraces.add(driver);
    tails.add(driver.getTail());
    
    // next the vehicle
    filename = baseString + str(f) + "-V.csv";
    AnimatedPointMarker vehicle = readInFile(filename, "");
    vehicle.square = true;
    vehicle.setColor(myColor);
    vehicle.setStrokeColor(color(0,0,0));
    vehicle.setStrokeWeight(0);
    vehicleTraces.add(vehicle);
  }

  map.addMarkers(vehicleTraces);
  map.addMarkers(driverTraces);
  map.addMarkers(tails);

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

AnimatedPointMarker readInFile(String filename, String name) {

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

  PositionRecord prevRecord = null;

  // iterate over the records, clean them accordingly, and store them
  for (int i=1; i<lons.length; i++)
  {
    // adjust for east or west
    if (ew[i].equals("W") && lons[i] > 0) lons[i] *=-1;
    if (ns[i].equals("S") && lats[i] > 0) lats[i] *=-1;

    // adjust the map to the limits of the area
    if (findLimits)
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
    prevRecord = pr;

    // save the record as a LinesMarker object!
    //traceLocations.add(new Location(lats[i], lons[i]));
  }

  // 
  PositionRecord head = getHead(prevRecord);
  return new AnimatedPointMarker(head, name);
}

void draw()
{  
  background(0);
  if (! paused) {

    for (int i = 0; i < driverTraces.size(); i++) {
      ((AnimatedPointMarker)driverTraces.get(i)).setToTime(timeIndex);
      ((AnimatedPointMarker)vehicleTraces.get(i)).setToTime(timeIndex);
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