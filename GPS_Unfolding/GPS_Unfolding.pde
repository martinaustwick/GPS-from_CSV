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

// controlling the visualisation
boolean paused = false;
boolean enable_heatmap = false;
boolean enable_agents = true;

//
// identifying the data to utilise
//
String baseString = "/Users/swise/Projects/FTC/CSV/"; // prefix for csv files (numbered 0-n)
int selectOneFile = -1; // -1 to draw all tracks at once, 0+ to draw each track individually
int maxFile = 30;

// world parameters
PVector latLims = new PVector(51.5, 51.6);
PVector lonLims = new PVector(-0.3, 0.05);
int minTime = 0, maxTime = 24*3600;
float driftLimit = 0.001;

// time parameters
int startMam = 6*3600; // CHANGE THIS to change the start time!
int mamChange = 10; // CHANGE THIS to make time run faster or slower
int timeIndex;

// graphical parameters
float trackAlpha = 50;
float strokoo = 5;
boolean findLimits = true;

/*// storage for data
//
List<Marker> driverTraces = new ArrayList<Marker>();
List<Marker> vehicleTraces = new ArrayList<Marker>();
List<Marker> tails = new ArrayList<Marker>();
*/
//
// the physical world
//
UnfoldingMap map;
MarkerManager mm_agents;
MarkerManager mm_heatmap;




// images
PImage casa, ftc;


// Initialisation

void setup()
{
  size(1200, 800, P3D);
  smooth();
  frameRate(90);

  loadLogos();

  String tilesStr = "jdbc:sqlite:" + sketchPath("./data/tiles/LondonSmokeAndStars2.mbtiles");

  // set up the UnfoldingMap to hold the data
  map = new UnfoldingMap(this, new MBTilesMapProvider(tilesStr));
            //new StamenMapProvider.WaterColor());
  mm_agents = new MarkerManager<Marker>();
  mm_heatmap = new MarkerManager<Marker>();
  
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

  // go through the files and read in the driver/vehicle pairs
  for (int f = 0; f<=maxFile; f++)
  {      

    // first process the driver
    String filename = baseString + str(f) + "-D.csv";
    AnimatedPointMarker driver = readInFile(filename, "#" + f, true);
    color myColor = palette[int(random(palette.length))];
    driver.setColor(myColor);
    driver.setStrokeWeight(2);
    driver.setStrokeColor(color(0,0,0));
    mm_agents.addMarker(driver);
    mm_heatmap.addMarker(driver.getTail());
    
    // next the vehicle
    filename = baseString + str(f) + "-V.csv";
    AnimatedPointMarker vehicle = readInFile(filename, "", false);
    vehicle.square = true;
    vehicle.setColor(myColor);
    vehicle.setStrokeColor(color(0,0,0));
    vehicle.setStrokeWeight(0);
    mm_agents.addMarker(vehicle);
  }

  // add the MarkerManagers to the map itself
  map.addMarkerManager(mm_agents);
  map.addMarkerManager(mm_heatmap);

  // defining the limits of the window
  lonLims = bufferVals(lonLims, 0.2);
  latLims = bufferVals(latLims, 0.2);
  println(latLims + "\n" + lonLims);

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
  timeIndex = min(startMam, minTime);
}

// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords
AnimatedPointMarker readInFile(String filename, String name, boolean traces) {

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

    // extract time information
    String [] timeLine = split(time[i], ":");
    int myTime = 3600*int(timeLine[0]) + 60*int(timeLine[1]) + int(timeLine[2]);

    // adjust the map to the limits of the area and time
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
      
      if(myTime > maxTime) maxTime = myTime;
      if(myTime < minTime) minTime = myTime;
    }

    // save the record as a PositionRecord
    PositionRecord pr = new PositionRecord( myTime, new Location(lats[i], lons[i]));
    pr.setPrev(prevRecord);
    prevRecord = pr;
  }

  // Create the marker
  PositionRecord head = getHead(prevRecord);
  return new AnimatedPointMarker(head, name, traces);
}

void draw()
{  
  background(0);
  if (! paused) {

    // only proceed if the time is within the bounds
    if(timeIndex <= maxTime && timeIndex >=minTime)
      for (Object o: mm_agents.getMarkers())
        ((AnimatedPointMarker) o).setToTime(timeIndex);

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
    if(enable_heatmap) mm_heatmap.enableDrawing();
    else mm_heatmap.disableDrawing();
  }
  if ( key == 'a'){ // flip the visibility of the agents
    enable_agents = !enable_agents;
    if(enable_agents) mm_agents.enableDrawing();
    else mm_agents.disableDrawing();
  }
}