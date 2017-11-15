class TimedPointMarker extends FancyPointMarker implements TimedMarker {

  boolean paused = false;
  int myTime = -1;

  int defaultSize = 10;

  boolean square = false;

  PFont font;
  float fontSize = 12;
  int space = 6;

  TimedPointMarker(PositionRecord start, String name, color myColor) {
    super(start.position);
    setColor(myColor);
    setStrokeColor(myColor);
    myName = name;
    myTime = start.time;
  }

  TimedPointMarker(PositionRecord start) {
    this(start, "", color(100, 100, 100));
  }

  // checks to determine whether the time step is beyond the point of completion
  // and the marker is labeled "fulfilled"

  void setToTime(int mam) {
    if (mam > myTime) {
      paused = true;
    } else {
      paused = false;
    }
  }


  /* Overrides drawing function to add the label
   */
  @Override
    public void draw(PGraphics pg, float x, float y) {

    if (isHidden())
      return;

    pg.pushStyle();
    pg.strokeWeight(this.strokeWeight);

    if (paused) { // it's not blinking
      pg.fill(myColor);
      radius = defaultSize;

      if (square) {
        pg.rect(x, y, radius, radius);
      } else {
        pg.ellipse((int) x, (int) y, radius, radius);
      }

      if (font != null) {
        pg.textFont(font);
      }
      pg.fill(textColor);
      pg.text(myName, Math.round(x + space * 0.75f + strokeWeight / 2), 
        Math.round(y + strokeWeight / 2 - space * 0.75f));
    }

    pg.popStyle();
  }
}