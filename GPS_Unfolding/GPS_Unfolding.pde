/* 
  Copyright (2017) by Martin Zaltz Austwick, Sarah Wise, and University College London
  Licensed under the Academic Free License version 3.0
  See the file "LICENSE" for more information
*/


// imports to include Unfolding library
import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.data.*;
import de.fhpotsdam.unfolding.marker.*;
import java.util.List;
//
//import processing.opengl.*;
import codeanticode.glgraphics.*;
import processing.opengl.*;


import de.fhpotsdam.unfolding.core.*;
import de.fhpotsdam.unfolding.events.*;
import de.fhpotsdam.unfolding.mapdisplay.AbstractMapDisplay;
import de.fhpotsdam.unfolding.tiles.MBTilesLoaderUtils;
import de.fhpotsdam.unfolding.geo.MercatorProjection;


import de.fhpotsdam.unfolding.mapdisplay.MapDisplayFactory;

// handling the data

String baseString = ""; // prefix for csv files (numbered 0-n)
int selectOneFile = -1; // -1 to draw all tracks at once, 0+ to draw each track individually
int maxFile = 13;

//
// the physical world
//
UnfoldingMap map;
UnfoldingMap map2;
UnfoldingMap currentMap;

// world parameters
PVector latLims = new PVector(51.5,51.6);
PVector lonLims = new PVector(-0.3,0.05);

float driftLimit = 0.01;

// storage for data
int count = 0;
ArrayList<float []>allLats, allLons, mams;
ArrayList<Integer> currentTimeIndex;

// time parameters
int startMam = 6*3600+(40*60);
int mamChange = 5;
int mamTime;

// graphical parameters
float trackAlpha = 50;
float strokoo = 5;//2;

// visualising the output
boolean vidoCapture = false;
boolean drawAll = true;
boolean findLimits = true;

// images
PImage casa, ftc;
color[] palette = {color(166,206,227, 100), color(31,120,180, 100), color(178,223,138, 100), color(51,160,44, 100), color(251,154,153, 100), color(227,26,28, 100), color(253,191,111, 100), color(255,127,0, 100), color(202,178,214)};

  // set up a holder for the lines we define here
List<Marker> traces = new ArrayList<Marker>();


// Initialisation

void setup()
{
  size(800, 800, P3D);
  smooth();
  frameRate(90);
  mamTime = startMam;
  
  loadLogos();
  
  // set up the UnfoldingMap to hold the data
  map = new UnfoldingMap(this, new StamenMapProvider.TonerBackground());//WaterColor());//
  map.zoomToLevel(14);
  map.setZoomRange(9, 17); // prevent zooming too far out
  MapUtils.createDefaultEventDispatcher(this, map);
  
  // set up a holder for the lines we define here
  List<Marker> traces = new ArrayList<Marker>();
  
  allLats = new ArrayList<float[]>();
  allLons = new ArrayList<float[]>();
  mams = new ArrayList<float[]>();
  currentTimeIndex =  new ArrayList<Integer>();
  
  if(findLimits)
  {
      latLims = new PVector(90,-90);
      lonLims = new PVector(180,-180);
  }
  
  for(int f = 0; f<=maxFile; f++)
  {
      currentTimeIndex.add(1);
      
      List<Location> traceLocations = new ArrayList<Location>();

      
      String filename = baseString + str(f) + ".csv";
      Table route = loadTable(filename, "header");
      //println((Object[])route.getColumnTitles());
      float [] lats = route.getFloatColumn("LATITUDE");
      float [] lons = route.getFloatColumn("LONGITUDE");
          
    
      
      String [] ew = route.getStringColumn("E/W");
      for (int i=1; i<lons.length; i++)
      {
        if (ew[i].equals("W")) lons[i] *=-1;
        
        if(findLimits)
        {
            if(abs(lons[i]-lons[i-1])<driftLimit)
            {
              if(lons[i]<lonLims.x) lonLims.x=lons[i];
              if(lons[i]>lonLims.y) lonLims.y=lons[i];
            }
            if(abs(lats[i]-lats[i-1])<driftLimit && lats[i]<89)
            {
              if(lats[i]<latLims.x) latLims.x=lats[i];
              if(lats[i]>latLims.y) latLims.y=lats[i];
            }
        }
        traceLocations.add(new Location(lats[i], lons[i]));
      }
//      
      //timings
      String [] time = route.getStringColumn("LOCAL TIME");
      //println(time[0]);
      float [] mam = new float[time.length];
      for (int i=0; i<time.length; i++)
      {
         String [] timeLine = split(time[i],":");
         //println(timeLine);
         mam[i] = 3600*float(timeLine[0]) + 60*float(timeLine[1]) + float(timeLine[2]);
      }
      mams.add(mam);
      allLats.add(lats);
      allLons.add(lons);
      
      SimpleLinesMarker myTrace = new SimpleLinesMarker(traceLocations);
      myTrace.setStrokeWeight((int)strokoo);
      myTrace.setColor(color(255,0,0,75));
      myTrace.setStrokeColor(color(255,0,0,250));
//      myTrace.setColor(palette[int(random(palette.length))]);
      traces.add(myTrace);
  }
  
  count = 1;
  strokeWeight(strokoo);
  
  //you might need to add this in again
  //if(selectOneFile>-1)  background(255);
  //else background(255);
  
  map.addMarkers(traces);
  
  background(255);
  noStroke();
  colorMode(HSB);
  
  lonLims = bufferVals(lonLims, 0.2);
  latLims = bufferVals(latLims, 0.2);
  println(latLims);
  println(lonLims);
  
  Location centrePoint = 
    new Location(0.5 * (latLims.x + latLims.y), 0.5 * (lonLims.x + lonLims.y));
  map.panTo(centrePoint);
  
  //dynamic tweaking of aspect; assume a fixed height for this
  float midLat = 0.5*(latLims.y+latLims.x);
  float dy = (latLims.y-latLims.x);
  float dx = (lonLims.y-lonLims.x);
  int w = int(800*cos(radians(midLat))*dx/dy);
  
//  size(w, 800);
  surface.setResizable(true);
  surface.setSize(800, 800);
}

void draw()
{  
//  println(traces.size());
   map.draw();
 // currentMap.draw();  
}

void keyPressed() {
    if (key == '1') {
        currentMap = map;
    } else if (key == '2') {
        currentMap = map2;
    }
}