class AnimatedPointMarker extends SimplePointMarker {
 
  PositionRecord head;
  
  AnimatedPointMarker(PositionRecord start){
    super(start.position);
    head = start;
  }
  
  void setToTime(int time){
    // if the time is in the future relative to the current position, move forward
    // through the linked list
    while(time >= head.time && head.next != null){
      if(time < head.next.time){
        setLocation(head.position);
        return; // it's between this point and the next
      }
      head = head.next; // otherwise keep searching
    }
    
    // otherwise, if the time is in the past relative to the current position,
    // move backward through the linked list
    while(time < head.time && head.prev != null){
      if(time > head.prev.time){
         head = head.prev;
         setLocation(head.position);
         return;
      }
      head = head.prev;

    }
    
    // does this happen? Can't imagine that it does unless it's finished moving!!!
    println(time + "\t" + head.time);
  }
}