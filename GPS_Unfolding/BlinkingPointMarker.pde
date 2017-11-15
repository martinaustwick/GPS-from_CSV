class BlinkingPointMarker extends FancyPointMarker implements TimedMarker {

  boolean active = false;
  int myTime = -1;

  int blinkCycle = 0;
  float currentSize = 0;
  float shrinkFactor = .95;
  int minSize = 8;
  int maxSize = 11;

  boolean square = false;

  BlinkingPointMarker(PositionRecord start, String name) {
    super(start.position);
    myName = name;
    myTime = start.time;
    currentSize = maxSize;
  }

  BlinkingPointMarker(PositionRecord start) {
    this(start, "");
  }

  // checks to determine whether the time step is beyond the point of completion
  // and the marker is activated
  void setToTime(int mam) {
    if (mam > myTime) {
      active = true;
    } else {
      active = false;
    }
  }

  /* Overrides drawing function to add the label
   */
  @Override
    public void draw(PGraphics pg, float x, float y) {

    if (isHidden())
      return;

    // if the marker has not yet been activated, continue
    if (!active) return;

    // otherwise, set up to draw the marker
    pg.pushStyle();
    pg.strokeWeight(this.strokeWeight);
    pg.fill(myColor);

    // update the size every 5 frames 
    if (frameCount % 15 == 0) {
      currentSize *= shrinkFactor;
      if(currentSize > maxSize || currentSize < minSize){
        currentSize = max(minSize, min(currentSize, maxSize));
        shrinkFactor = 1/shrinkFactor;
      }
    }

    // set up the size of the shape based on the blink cycle
    radius = currentSize;

    // draw the marker
    if (square) {
      pg.rect(x, y, radius, radius);
    } else {
      pg.ellipse((int) x, (int) y, radius, radius);
    }

    // draw the text
    if (font != null) {
      pg.textFont(font);
      pg.fill(textColor);
      pg.text(myName, Math.round(x + space * 0.75f + strokeWeight / 2), 
        Math.round(y + strokeWeight / 2 - space * 0.75f));
    }

    pg.popStyle();
  }
}