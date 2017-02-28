class MultiSegmentLineMarker extends AbstractMarker {

  protected List<List<Location>> segments;
  protected List<Integer> colors;
  
  public MultiSegmentLineMarker(List<List<Location>> segs, List<Integer> cols){
    super();
    segments = segs;
    colors = cols;
  }
  
  @Override
  public boolean isInside(float checkX, float checkY, float posx, float posy) {
    return false;
  }
  
  @Override
  public void draw(PGraphics pg, float x, float y){
    
    if (segments.isEmpty() || isHidden())
      return;

    pg.pushStyle();
    pg.noFill();
    pg.strokeWeight(strokeWeight);
    pg.smooth();

    pg.beginShape(PConstants.LINES);
    for (int i = 1; i < segments.size(); ++i) {
      pg.stroke(colors.get(i));
      List<Location> segment = segments.get(i);
      if(!segment.isEmpty()){
        for(Location l: segment)
          pg.vertex(l.x, l.y);
      }
    }
    pg.endShape();
    pg.popStyle();
    
  }
  
}