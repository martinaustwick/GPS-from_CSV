class AnimatedPointMarker extends SimplePointMarker {

  String myName;
  PositionRecord head;
  SimpleLinesMarker myTail;
  color myColor;

  boolean square = false;

  PFont font;
  float fontSize = 12;
  int space = 6;

  AnimatedPointMarker(PositionRecord start, String name) {
      super(start.position);
      head = start;
      myTail = new SimpleLinesMarker();
      myTail.setStrokeWeight((int)strokoo);
      myTail.setColor(color(255, 0, 0, 20));//palette[int(random(palette.length))]);//
      setColor(palette[int(random(palette.length))]);
      setStrokeColor(palette[int(random(palette.length))]);
      myName = name;
  }

  AnimatedPointMarker(PositionRecord start) {
      this(start, "Blank");
  }

  void setToTime(int time) {
      // if the time is in the future relative to the current position, move forward
      // through the linked list
      while (time >= head.time && head.next != null) {
        if (time < head.next.time) {
            setLocation(head.position);
            return; // it's between this point and the next
        }
        head = head.next; // otherwise keep searching
        myTail.addLocation(head.position.x, head.position.y);
      }

      // otherwise, if the time is in the past relative to the current position,
      // move backward through the linked list
      while (time < head.time && head.prev != null) {
        myTail.removeLocation(head.position);
        if (time > head.prev.time) {
            head = head.prev;
            setLocation(head.position);
            return;
        }
        head = head.prev;
      }

      // Otherwise, it either hasn't started happening or has finished happening!
  }

  void setColor(color c){
    myColor = c; 
  }

  SimpleLinesMarker getTail() { 
      return myTail;
  }

  /* Overrides drawing function to add the label
  */
  @Override
  public void draw(PGraphics pg, float x, float y) {

      if (isHidden())
           return;

      pg.pushStyle();
      pg.strokeWeight(this.strokeWeight);
      if (isSelected()) {
           pg.stroke(this.highlightStrokeColor);
      } else {
           pg.stroke(this.strokeColor);
      }
      
      pg.fill(myColor);
      // fill in the shape responsibly
      if(square) {
        pg.rect(x, y, radius, radius);
      }
      else {
        pg.ellipse((int) x, (int) y, radius, radius);
      }
        
      if (font != null) {
           pg.textFont(font);
      }
      
      pg.fill(color(0, 0, 0, 255));
      pg.text(myName, Math.round(x + space * 0.75f + strokeWeight / 2), 
          Math.round(y + strokeWeight / 2 - space * 0.75f));

      pg.popStyle();
  }
}