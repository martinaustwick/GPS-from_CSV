// READ IN THE DATA

// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords
AnimatedPointMarker readInFile(String filename, String name, boolean traces) {

  print("READINFILE");
  Table route;
  // open the Driver file and read it into a table
  try {
    route = loadTable(filename, "header");
    // visualise the names of the columns
    //println((Object[])route.getColumnTitles());

    // extract columns of data from the table
    float [] lats = route.getFloatColumn("LATITUDE");
    float [] lons = route.getFloatColumn("LONGITUDE");    
    String [] ew = route.getStringColumn("E/W");
    String [] ns = route.getStringColumn("N/S");
    String [] time = route.getStringColumn("LOCAL TIME");
//    String [] time = route.getStringColumn("MODIFIED TIME");

    PositionRecord prevRecord = null;

    // iterate over the records, clean them accordingly, and store them
    for (int i=1; i<lons.length; i++)
    {
      // adjust for east or west
      if (ew[i].equals("W") && lons[i] > 0) lons[i] *=-1;
      if (ns[i].equals("S") && lats[i] > 0) lats[i] *=-1;

      // extract time information
      String [] timeLine = split(time[i], ":");
      int myTime = 3600*int(timeLine[0]) + 60*int(timeLine[1]) + int(timeLine[2]) + 60;

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

        if (myTime > maxTime) maxTime = myTime;
        if (myTime < minTime) minTime = myTime;
      }

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
  catch (Exception e) {
    return null;
  }
}


// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords. In particular, read in the edges 
// defined by the stopping points
void readInFilePointsMARTIN(String filename, color walkColor, color lineColor, 
  MarkerManager manager, int driveWeight, int walkWeight) throws FileNotFoundException {

  print("READINFILEPOINTSAS MARTIN");

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
  String [] modes = route.getStringColumn("Status");
  String [] times = route.getStringColumn("DeliveryTime");
  // Location stopLocation = null;

  // default time if it's missing from the dataset 
  int lastTime = 6*3600; // 6am default
  int colorIndex = -1;

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

    if (myTime > maxTime) maxTime = myTime;
    if (myTime < minTime) minTime = myTime;


    // add a TimedPointMarker colored by the type of stop
    // update the newest point in the movement network
    Location myLoc = new Location(lats[i], lons[i]);
    String currentName = times[i];

    // handle this point based on the mode of transit involved
    String mode = modes[i].trim();
    print(mode + " ");
    color myColor = -1;
    switch(arrivals[i]){
      case "9AM":
        myColor = color(255,0,0);
        break;
      case "10AM":
        myColor = color(255,255,0);
        break;
      case "12AM":
        myColor = color(0,255,0);
        break;
      default:
        myColor = color(0,0,255);
        break;
    }

    // if the vehicle has walked, add a line back to the stop location
    PositionRecord currentPt = new PositionRecord( myTime, myLoc);      

// check for appropriate colour
    TimedPointMarker spm = new TimedPointMarker(currentPt, myTime);
        spm.setName(currentName);
        spm.setHighlightStrokeColor(myColor);//palette[colorIndex]);
        spm.setColor(myColor);
        spm.setRadius(10);
        manager.addMarker(spm);


  }

  // end
}


// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords. In particular, read in the edges 
// defined by the stopping points
void readInFilePointsMARTINORIGINAL(String filename, color walkColor, color lineColor, 
  MarkerManager manager, int driveWeight, int walkWeight) throws FileNotFoundException {

  print("READINFILEPOINTSAS MARTIN");

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
  String [] modes = route.getStringColumn("Status");
  String [] times = route.getStringColumn("DeliveryTime");
  // Location stopLocation = null;

  // keeps track of the beginning of the given ring
  PositionRecord previousStop = null;
  PositionRecord parkingSpace = null;

  // default time if it's missing from the dataset 
  int lastTime = 6*3600; // 6am default
  int colorIndex = -1;

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

    if (myTime > maxTime) maxTime = myTime;
    if (myTime < minTime) minTime = myTime;


    // add a TimedPointMarker colored by the type of stop
    // update the newest point in the movement network
    Location myLoc = new Location(lats[i], lons[i]);
    String currentName = times[i];

    // handle this point based on the mode of transit involved
    String mode = modes[i].trim();
    //print(mode + " ");

    // if the vehicle has walked, add a line back to the stop location
    PositionRecord currentPt = new PositionRecord( myTime, myLoc);      

    // driver moving away from the vehicle
    if (mode.equals("Walking")) {
      if (parkingSpace != null){
        TimedPointMarker spm = new TimedPointMarker(currentPt, myTime);
        spm.setName(currentName);
        spm.setHighlightStrokeColor(palette[colorIndex]);
        spm.setRadius(15);
        manager.addMarker(spm);
      }
      previousStop = currentPt;
    }

    // otherwise, the vehicle itself has moved.
    else if (i < lons.length - 1){ 
      colorIndex = (colorIndex + 1) % palette.length;
      currentPt.setPrev(parkingSpace);
      parkingSpace = currentPt;
      
      TimedPointMarker spm = new TimedPointMarker(currentPt, myTime);
      spm.setName(currentName);
      spm.setHighlightStrokeColor(palette[colorIndex]);
      spm.setRadius(10);
      spm.square = true;
      manager.addMarker(spm);
    }
  }
  AnimatedPointMarker apm = new AnimatedPointMarker(getHead(parkingSpace), "", true);
  apm.myColor = color(0,0,0,0);
  apm.getTail().setStrokeWeight(driveWeight);
  apm.getTail().setColor(lineColor);
  manager.addMarker(apm);
  manager.addMarker(apm.getTail());

  // end
}

// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords. In particular, read in the edges 
// defined by the stopping points
void readInFilePointsMING(String filename, color walkColor, color lineColor, 
  MarkerManager manager, int driveWeight, int walkWeight) throws FileNotFoundException {

  print("READINFILEPOINTSAS MING");

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

    if (myTime > maxTime) maxTime = myTime;
    if (myTime < minTime) minTime = myTime;


    // add a TimedPointMarker colored by the type of stop
    // update the newest point in the movement network
    Location myLoc = new Location(lats[i], lons[i]);

    // handle this point based on the mode of transit involved
    String mode = modes[i].trim();
    //print(mode + " ");

    // if the vehicle has walked, add a line back to the stop location
    PositionRecord currentPt = new PositionRecord( myTime, myLoc);      

    // driver moving away from the vehicle
    if (mode.equals("Walking")) {
      if (parkingSpace != null){
        TimedLineMarker tlm = new TimedLineMarker(currentPt, parkingSpace, "", walkColor);
        tlm.myWeight = walkWeight;
        manager.addMarker(tlm);
      }
      previousStop = currentPt;
    }

    // otherwise, the vehicle itself has moved.
    else if (i < lons.length - 1){ 
      currentPt.setPrev(parkingSpace);
      parkingSpace = currentPt;
    }
  }
  AnimatedPointMarker apm = new AnimatedPointMarker(getHead(parkingSpace), "", true);
  apm.myColor = color(0,0,0,0);
  apm.getTail().setStrokeWeight(driveWeight);
  apm.getTail().setColor(lineColor);
  manager.addMarker(apm);
  manager.addMarker(apm.getTail());

  // end
}



// OTHER

/*color[] palette = {color(166,206,227), color(31,120,180), 
 color(178,223,138), color(51,160,44), color(251,154,153), 
 color(227,26,28), color(253,191,111), color(255,127,0), 
 color(202,178,214)};
 */
/*
color[] palette = {color(166, 206, 227), color(31, 120, 180), color(178, 223, 138), 
  color(51, 160, 44), color(251, 154, 153), color(227, 26, 28), color(253, 191, 111), 
  color(255, 127, 0), color(202, 178, 214), color(106, 61, 154), color(255, 255, 153), 
  color(177, 89, 40), color(141, 211, 199), color(255, 237, 111)};
*/
/*
color[] palette = {color(166, 206, 227, 200), color(31, 120, 180, 200), color(178, 223, 138, 200), 
  color(51, 160, 44, 200), color(251, 154, 153, 200), color(227, 26, 28, 200), color(253, 191, 111, 200), 
  color(255, 127, 0, 200), color(202, 178, 214, 200), color(106, 61, 154, 200), color(255, 255, 153, 200), 
  color(177, 89, 40, 200), color(141, 211, 199, 200), color(255, 237, 111, 200)};
*/
color[] palette = {color(166,206,227, 200), color(31,120,180, 200), color(178,223,138, 200), color(51,160,44, 200), 
color(251,154,153, 200), color(227,26,28, 200), color(253,191,111, 200), color(255,127,0, 200), color(202,178,214, 200), 
color(106,61,154, 200), color(255,255,153, 200), color(177,89,40, 200)};

PVector bufferVals(PVector maxmin, float percentageBuffer)
{
  float meanVec = 0.5*(maxmin.y + maxmin.x);
  float demiBreadth = 0.5*(maxmin.y - maxmin.x);
  demiBreadth*=(1.0+percentageBuffer);
  return new PVector(meanVec-demiBreadth, meanVec+demiBreadth);
}

void setLimits(float[] ons, float[] ats)
{
  latLims = new PVector(90, -90);
  lonLims = new PVector(180, -180);
  for (int i = 1; i<ons.length; i++)
  {
    if (abs(ons[i]-ons[i-1])<driftLimit)
    {
      if (ons[i]<lonLims.x) lonLims.x=ons[i];
      if (ons[i]>lonLims.y) lonLims.y=ons[i];
    }
    if (abs(ats[i]-ats[i-1])<driftLimit && ats[i]<89)
    {
      if (ats[i]<latLims.x) latLims.x=ats[i];
      if (ats[i]>latLims.y) latLims.y=ats[i];
    }
  }
  lonLims = bufferVals(lonLims, 0.2);
  latLims = bufferVals(latLims, 0.2);
}



// determine whether difference between the given floats exceeds the drift limit
boolean drift(float a, float b)
{
  if (abs(a-b)>driftLimit || abs(a-b)==0) return true;
  else return false;
}

void elClocko()
{
  fill(255);
  stroke(0);
  rect(0, 0, 80, 50);
  fill(0);
  String textor = str(timeIndex/3600) + ":" + nf((timeIndex/60)%60, 2, 0) + ":" + nf(timeIndex%60, 2, 0);
  text(textor, 20, 30);
}

void loadLogos()
{
  //    casa = loadImage("logos/casa_logo.jpg");
  //    casa.resize(90,120);
  //    ftc = loadImage("logos/ftc.png");
  //   ftc.resize(200,120);
}

void drawLogos()
{
  //    image(casa, 10, height-casa.height-10);
  //    image(ftc, 30+casa.width, height-ftc.height-10);
}

// return the header of this object
PositionRecord getHead(PositionRecord pr) {
  if (pr.prev != null) return getHead(pr.prev);
  else return pr;
}

// return the header of this object
String printOutAll(PositionRecord pr) {
  if (pr.prev != null) return printOutAll(pr.prev) + "\t" + pr.position.toString();
  else return "HEADED WITH: " + pr.position.toString();
}


color interpolateColor(float percent, color c1, color c2) {
  float d_r = red(c1) - red(c2);
  float d_g = green(c1) - green(c2);
  float d_b = blue(c1) -  blue(c2);
  float d_a = alpha(c1) - alpha(c2);
  return color(red(c2) + percent * d_r, 
    green(c2) + percent * d_g, 
    blue(c2) + percent * d_b, 
    alpha(c2) + percent * d_a);
}