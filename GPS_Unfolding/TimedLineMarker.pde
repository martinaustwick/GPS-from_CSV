class TimedLineMarker extends SimpleLinesMarker {

  String myName;
  color myColor;
  boolean paused = false;
  int myTime = -1;

  int myWeight = 10;

  boolean square = false;

  PFont font;
  float fontSize = 12;
  int space = 6;

  TimedLineMarker(PositionRecord start, PositionRecord end, String name, color myColor) {
    super(start.position, end.position);
    //    setColor(palette[int(random(palette.length))]);
    //    setStrokeColor(color(0,0,0,50));//palette[int(random(palette.length))]);
    setColor(myColor);
    setStrokeColor(myColor);
    myName = name;
    myTime = start.time;
  }

  // checks to determine whether the time step is beyond the point of completion
  // and the marker is labeled "fulfilled"

  void checkIfUpdated(int mam) {
    if (mam > myTime) {
      paused = true;
    } else {
      paused = false;
    }
  }

  TimedLineMarker(PositionRecord start, PositionRecord end) {
    this(start, end, "", color(100, 100, 100));
  }

  void setColor(color c) {
    myColor = c;
  }

  /* Overrides drawing function to add the label
   */
  @Override
    public void draw(PGraphics pg, List<MapPosition> mapPositions) {

    if (mapPositions.isEmpty() || isHidden())
      return;

    pg.pushStyle();
    
    pg.noFill();
    if (isSelected() || paused) {
      pg.stroke(myColor);
      pg.strokeWeight(myWeight);
      pg.smooth();

      pg.beginShape(PConstants.LINES);
      MapPosition last = mapPositions.get(0);
      for (int i = 1; i < mapPositions.size(); ++i) {
        MapPosition mp = mapPositions.get(i);
        pg.vertex(last.x, last.y);
        pg.vertex(mp.x, mp.y);

        last = mp;
      }
      pg.endShape();
    }
    
    pg.popStyle();
  }
}