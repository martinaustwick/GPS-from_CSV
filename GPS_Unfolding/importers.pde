// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords.
AnimatedPointMarker readInFileBasic(String filename, String name, boolean traces) throws FileNotFoundException {

  // open the Driver file and read it into a table
  Table route = loadTable(filename, "header");
  //println((Object[])route.getColumnTitles()); // visualise the names of the columns

  // extract columns of data from the table
  float [] lats = route.getFloatColumn("LATITUDE");
  float [] lons = route.getFloatColumn("LONGITUDE");    
  String [] ew = route.getStringColumn("E/W");
  String [] ns = route.getStringColumn("N/S");
  String [] time = route.getStringColumn("LOCAL TIME");
  //String [] time = route.getStringColumn("MODIFIED TIME");

  PositionRecord prevRecord = null;

  // iterate over the records, clean them accordingly, and store them
  for (int i=1; i<lons.length; i++)
  {
    // adjust for east or west
    if (ew[i].equals("W") && lons[i] > 0) lons[i] *=-1;
    if (ns[i].equals("S") && lats[i] > 0) lats[i] *=-1;

    // extract time information
    String [] timeLine = split(time[i], ":");
    int myTime = 3600*int(timeLine[0]) + 60*int(timeLine[1]) + int(timeLine[2]) - 60;

    // adjust the map to the limits of the area and time
    if (findLimits) checkLimits(lats, lons, i, myTime);

    // save the record as a PositionRecord
    PositionRecord pr = new PositionRecord( myTime, new Location(lats[i], lons[i]));
    pr.setPrev(prevRecord);
    prevRecord = pr;
  }

  // Create the marker
  PositionRecord head = getHead(prevRecord);
  println(head.time);

  return new AnimatedPointMarker(head, name, traces);
} 

// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords. Suitable for a datafile with multiple
// records stored within it
List <AnimatedPointMarker> readInFileInrix(String filename, String name, boolean traces) throws FileNotFoundException {

  List <AnimatedPointMarker> results = new ArrayList <AnimatedPointMarker> ();

  // open the Driver file and read it into a table
  Table route = loadTable(filename, "header");
  //println((Object[])route.getColumnTitles()); // visualise the names of the columns

  // extract columns of data from the table
  float [] lats = route.getFloatColumn("Latitude");
  float [] lons = route.getFloatColumn("Longitude");
  float [] wpSequence = route.getFloatColumn("WaypointSequence");
  String [] time = route.getStringColumn("CaptureDate");

  PositionRecord prevRecord = null;

  // iterate over the records, clean them accordingly, and store them
  for (int i=1; i<lons.length; i++)
  {

    // check to determine if we've started on a new record
    if (wpSequence[i] == 0 && prevRecord != null) {
      PositionRecord head = getHead(prevRecord); // We have: create the new marker
      results.add(new AnimatedPointMarker(head, name, traces));
      prevRecord = null;
    }

    // extract time information
    String fullTimeBit = split(time[i], "T")[1];
    String shortTimeBit = split(fullTimeBit, ".")[0];
    String [] timeLine = split(shortTimeBit, ":");
    int myTime = 3600*int(timeLine[0]) + 60*int(timeLine[1]) + int(timeLine[2]) - 60;

    // adjust the map to the limits of the area and time
    if (findLimits) checkLimits(lats, lons, i, myTime);

    // save the record as a PositionRecord
    PositionRecord pr = new PositionRecord( myTime, new Location(lats[i], lons[i]));
    pr.setPrev(prevRecord);
    prevRecord = pr;
  }

  return results;
}

// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords. In particular, read in the edges 
// defined by the stopping points
AnimatedPointMarker readInFileModes(String filename, color walkColor, color stopColor, color lineColor, 
  MarkerManager manager) throws FileNotFoundException {

  // open the Driver file and read it into a table
  Table route = loadTable(filename, "header,csv");

  // visualise the names of the columns
  println((Object[])route.getColumnTitles());

  // extract columns of data from the table
  float [] lats = route.getFloatColumn("lat");
  float [] lons = route.getFloatColumn("long");
  String [] arrivals = route.getStringColumn("Time");
  String [] modes = route.getStringColumn("Mode");
  // Location stopLocation = null;

  // keeps track of the 
  PositionRecord prevStop = null;
  // PositionRecord prevPr = null;

  // default time if it's missing from the dataset 
  int lastTime = 6*3600; // 6am default

  // iterate over the records, clean them accordingly, and store them
  for (int i=1; i<lons.length; i++)
  {

    // extract time information
    int myTime = lastTime;
    if ((arrivals[i]).length() > 0 && arrivals[i].contains(":")) {
      String [] timeLine = split(arrivals[i], ":");
      myTime = 3600*int(timeLine[0].trim()) + 60*(int(timeLine[1].trim()) - 2) ;
    } else
      myTime = myTime + 1;
    lastTime = myTime;

    // add a TimedPointMarker colored by the type of stop
    // update the newest point in the movement network
    Location myLoc = new Location(lats[i], lons[i]);
    PositionRecord pr = new PositionRecord( myTime, myLoc);

    // adjust the map to the limits of the area
    if (findLimits) checkLimits(lats, lons, i, myTime);

    // handle this point based on the mode of transit involved
    String mode = modes[i];
    color myColor = (mode.equals("Driving") ? walkColor : stopColor);

    // create a point to mark the stop
    TimedPointMarker tpm = new TimedPointMarker(pr, "", myColor);
    manager.addMarker(tpm);

    // if the driver has walked, add a line back to the stop location

    // the vehicle stops: record this and leave a marker
    if (mode.equals("Walking")) {
      PositionRecord walkPr = new PositionRecord( myTime, myLoc);
      walkPr.setPrev(prevStop);
      if (prevStop != null) {
        PositionRecord stopPr = new PositionRecord( myTime + 1, prevStop.getPosition());
        stopPr.setPrev(walkPr);
        prevStop = stopPr;
      } else {
        prevStop = walkPr;
      }
    }

    // otherwise, the vehicle itself has moved. Update the previous stop location
    else { 
      PositionRecord newStop = new PositionRecord( myTime, myLoc);
      newStop.setPrev(prevStop);
      prevStop = newStop;
    }
  }

  // add the information
  println(getHead(prevStop).time);
  return(new AnimatedPointMarker(getHead(prevStop), color(0, 0, 0, 0), lineColor));
}


// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords. In particular, read in the edges 
// defined by the stopping points
void readInFilePointsAsRings_EXPERIMENTAL(String filename, color walkColor, color lineColor, 
  MarkerManager managerLines, MarkerManager managerPoints) throws FileNotFoundException {

  // open the Driver file and read it into a table
  Table route = loadTable(filename, "header,tsv");
  if (((Object[])route.getColumnTitles()).length <= 1)
    route = loadTable(filename, "header,csv");

  // visualise the names of the columns
  //println((Object[])route.getColumnTitles());

  // extract columns of data from the table
  float [] lats = route.getFloatColumn("lat");
  float [] lons = route.getFloatColumn("long");
  String [] arrivals = route.getStringColumn("Time");
  String [] modes = route.getStringColumn("Mode");
  // Location stopLocation = null;

  // keeps track of the beginning of the given ring
  PositionRecord previousStop = null;
  PositionRecord parkingSpace = null;

  int numRings = 0;

  // default time if it's missing from the dataset 
  int lastTime = 6*3600; // 6am default

  // iterate over the records, clean them accordingly, and store them
  for (int i=1; i<lons.length; i++)
  {

    // extract time information
    int myTime = lastTime;
    if ((arrivals[i]).length() > 0 && arrivals[i].contains(":")) {
      String [] timeLine = split(arrivals[i], ":");
      myTime = 3600*int(timeLine[0].trim()) + 60*(int(timeLine[1].trim()) - 2) ;
    } else
      myTime = myTime + 1;
    lastTime = myTime;


    // add a TimedPointMarker colored by the type of stop
    // update the newest point in the movement network
    Location myLoc = new Location(lats[i], lons[i]);

    // adjust the map to the limits of the area
    if (findLimits) checkLimits(lats, lons, i, myTime);

    // handle this point based on the mode of transit involved
    String mode = modes[i].trim();
    //print(mode + " ");

    // if the vehicle has walked, add a line back to the stop location

    // driver moving away from the vehicle
    if (mode.equals("Walking")) {
      PositionRecord walkPr = new PositionRecord( myTime, myLoc);
      walkPr.setPrev(previousStop);
      if (previousStop == null)
        parkingSpace = walkPr;
      previousStop = walkPr;
    }

    // otherwise, the vehicle itself has moved. Create and save any rings which have
    // been in the process of being created!!
    else { 

      // if previous stop is not null, there's stuff in there. Upload it
      if (previousStop != null) {
        PositionRecord walkPr = new PositionRecord( myTime, myLoc);
        walkPr.setPrev(previousStop);      
        /*   if(parkingSpace != null && parkingSpace.position != myLoc){
         PositionRecord completeMe = new PositionRecord(myTime + 1, parkingSpace.position);
         completeMe.setPrev(walkPr);
         walkPr = completeMe;
         }
         */        AnimatedPointMarker apm = new AnimatedPointMarker(getHead(walkPr), walkColor, palette[numRings % palette.length]);
        managerPoints.addMarker(apm);
        managerLines.addMarker(apm.getTail());
        apm.getTail().setStrokeWeight(3);

        print("HELLO THERE I AM A RING\n");
        numRings++;
        print(printOutAll(walkPr));
        print("\n");
      } else {
        print("I am not a ring of any kind\n");
      }

      previousStop = null;
      parkingSpace = null;
    }
  }

  print("WHATTTTT\n");
  // end
}

// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords
void readInFileBlinkingPoints(String filename, color openColor, color closedColor, 
  MarkerManager manager) throws FileNotFoundException {

  // open the Driver file and read it into a table
  Table route = loadTable(filename, "header,csv");

  // visualise the names of the columns
  println((Object[])route.getColumnTitles());

  // extract columns of data from the table
  float [] lats = route.getFloatColumn("lat");//"LATITUDE");
  float [] lons = route.getFloatColumn("long");//"LONGITUDE");    
  String [] modes = route.getStringColumn("Mode");
  //  String [] departures = route.getStringColumn("Leave");
  String [] arrivals = route.getStringColumn("Time");

  int lastTime = 6*3600; // 6am default

  // iterate over the records, clean them accordingly, and store them
  for (int i=0; i<lons.length; i++)
  {


    String mode = modes[i];

    int myTime = lastTime;
    if ((arrivals[i]).length() > 0 && arrivals[i].contains(":")) {
      String [] timeLine = split(arrivals[i], ":");
      myTime = 3600*int(timeLine[0]) + 60*(int(timeLine[1]) -1);
      //      myTime = 3600*int(timeLine[0]) + 60*int(timeLine[1]);
    } else
      myTime = myTime + 1;

    // extract time information
    // adjust the map to the limits of the area
    if (findLimits) checkLimits(lats, lons, i, myTime);

    PositionRecord myPr = new PositionRecord(myTime, new Location(lats[i], lons[i]));
    BlinkingPointMarker sm = new BlinkingPointMarker(myPr, "");
    //  sm.setRadius(mode.equals("W") ? walkingWidth : drivingWidth);
    //   sm.setColor(interpolateColor(((float)i)/lons.length, openColor, closedColor));
    color newColor = (openColor & 0xffffff) | (100 << 24);
    sm.setStrokeColor(openColor);
    sm.setColor(newColor);//closedColor);
    manager.addMarker(sm);
    lastTime = myTime;
  }
}

// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords
void readInFileBlinkingPointsWithAttributes(String filename, HashMap <String, Integer> attributeMapping, 
  String attribute, MarkerManager manager) throws FileNotFoundException {

  // open the Driver file and read it into a table
  Table route = loadTable(filename, "header,tsv");

  // visualise the names of the columns
  //println((Object[])route.getColumnTitles());

  // extract columns of data from the table
  float [] lats = route.getFloatColumn("lat");//"LATITUDE");
  float [] lons = route.getFloatColumn("long");//"LONGITUDE");    
  String [] modes = route.getStringColumn(attribute);

  int lastTime = 6*3600; // 6am default

  // iterate over the records, clean them accordingly, and store them
  for (int i=0; i<lons.length; i++)
  {

    String mode = modes[i];
    if(!attributeMapping.containsKey(mode)) continue;

    // extract time information
    // adjust the map to the limits of the area
    if (findLimits) checkLimits(lats, lons, i, lastTime);

    PositionRecord myPr = new PositionRecord(lastTime, new Location(lats[i], lons[i]));
    BlinkingPointMarker sm = new BlinkingPointMarker(myPr, "");
    color newColor = attributeMapping.get(mode);//(openColor & 0xffffff) | (100 << 24);
    sm.setStrokeColor(color(0,0,0,0));
    sm.setColor(newColor);
    sm.setRadius(15);
    manager.addMarker(sm);
  }
}

// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords
void readInFileTimedPoints(String filename, color myColor, String attribute, MarkerManager manager) throws FileNotFoundException {

  // open the Driver file and read it into a table
  Table route = loadTable(filename, "header,tsv");
  
  //println((Object[])route.getColumnTitles()); // visualise the names of the columns

  // extract columns of data from the table
  float [] lats = route.getFloatColumn("lat");
  float [] lons = route.getFloatColumn("long");    
  String [] times = route.getStringColumn(attribute);

  int lastTime = 6*3600; // 6am default

  // iterate over the records, clean them accordingly, and store them
  for (int i=0; i<lons.length; i++)
  {

    String time = times[i];
    if(time == null || time.length() == 0) continue;

    int myTime = lastTime;
    if (time.contains(":")) {
      String [] timeLine = split(time, ":");
      myTime = 3600*int(timeLine[0].trim()) + 60*(int(timeLine[1].trim()) - 2) ;
    } else
      myTime = myTime + 1;
    lastTime = myTime;

    // extract time information
    // adjust the map to the limits of the area
    if (findLimits) checkLimits(lats, lons, i, lastTime);

    PositionRecord myPr = new PositionRecord(lastTime, new Location(lats[i], lons[i]));
    BlinkingPointMarker sm = new BlinkingPointMarker(myPr, time);
    //  sm.setRadius(mode.equals("W") ? walkingWidth : drivingWidth);
    //   sm.setColor(interpolateColor(((float)i)/lons.length, openColor, closedColor));
    color newColor = myColor;
    sm.setColor(newColor);//closedColor);
    sm.setRadius(1);
    manager.addMarker(sm);
  }
}

// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords. In particular, read in the edges 
// defined by the stopping points
void readInFilePointsMING(String filename, color walkColor, color lineColor, 
  MarkerManager manager, int driveWeight, int walkWeight) throws FileNotFoundException {

  // open the Driver file and read it into a table
  Table route = loadTable(filename, "header,tsv");
  if (((Object[])route.getColumnTitles()).length <= 1)
    route = loadTable(filename, "header,csv");

  // visualise the names of the columns
  println((Object[])route.getColumnTitles());

  // extract columns of data from the table
  float [] lats = route.getFloatColumn("Lat");
  float [] lons = route.getFloatColumn("Long");
  String [] arrivals = route.getStringColumn("Time");
  String [] modes = route.getStringColumn("Mode");
  // Location stopLocation = null;

  // keeps track of the beginning of the given ring
  PositionRecord previousStop = null;
  PositionRecord parkingSpace = null;

  // default time if it's missing from the dataset 
  int lastTime = 6*3600; // 6am default
  print(latLims);
  print(lonLims);
  // iterate over the records, clean them accordingly, and store them
  for (int i=0; i<lons.length; i++)
  {

    // extract time information
    int myTime = lastTime;
    if ((arrivals[i]).length() > 0 && arrivals[i].contains(":")) {
      String [] timeLine = split(arrivals[i], ":");
      myTime = 3600*int(timeLine[0].trim()) + 60*(int(timeLine[1].trim()) - 2) ;
    } else
      myTime = myTime + 1;
    lastTime = myTime;

    // add a TimedPointMarker colored by the type of stop
    // update the newest point in the movement network
    Location myLoc = new Location(lats[i], lons[i]);

    // adjust the map to the limits of the area
    if (findLimits) checkLimits(lats, lons, i, myTime);

    // handle this point based on the mode of transit involved
    String mode = modes[i].trim();
    //print(mode + " ");

    // if the vehicle has walked, add a line back to the stop location
    PositionRecord currentPt = new PositionRecord( myTime, myLoc);      

    // driver moving away from the vehicle
    if (mode.equals("Walking")) {
      if (parkingSpace != null) {
        TimedLineMarker tlm = new TimedLineMarker(currentPt, parkingSpace, "", walkColor);
        tlm.myWeight = walkWeight;
        manager.addMarker(tlm);
      }
      previousStop = currentPt;
    }

    // otherwise, the vehicle itself has moved.
    else if (i < lons.length - 1) { 
      currentPt.setPrev(parkingSpace);
      parkingSpace = currentPt;
    }
  }

  // add the overall trace
  AnimatedPointMarker apm = new AnimatedPointMarker(getHead(parkingSpace), "", true);
  apm.myColor = color(0, 0, 0, 0);
  apm.getTail().setStrokeWeight(driveWeight);
  apm.getTail().setColor(lineColor);
  manager.addMarker(apm);
  manager.addMarker(apm.getTail());

  // end
}