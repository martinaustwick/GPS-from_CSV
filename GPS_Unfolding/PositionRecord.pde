class PositionRecord {
 
  PositionRecord prev, next;
  int time;
  Location position;

  PositionRecord(int t, Location pos){
    time = t;
    position = pos;
    prev = null;
    next = null;
  }
  
  PositionRecord(int t, Location pos, PositionRecord prevPosition, PositionRecord nextPosition){
    time = t;
    position = pos;
    prev = prevPosition;
    next = nextPosition;
  }
  
  void setNext(PositionRecord pr){
    next = pr;
    if(pr != null) pr.prev = this;
  }
  
  void setPrev(PositionRecord pr){
    prev = pr;
    if(pr != null) pr.next = this;
  }
}