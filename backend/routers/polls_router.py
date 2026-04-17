from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timezone # <-- Added timezone here
from database import get_db
from models import Poll
from schemas import PollCreate, PollUpdate

router = APIRouter(tags=["Polls"])

@router.post("/api/polls")
def create_poll(poll: PollCreate, db: Session = Depends(get_db)):
    # 🛠️ FIX 1: Pydantic v2 replaces .dict() with .model_dump()
    new_poll = Poll(**poll.model_dump())
    db.add(new_poll)
    db.commit()
    return {"message": "Poll created successfully"}

@router.get("/api/polls")
def get_polls(db: Session = Depends(get_db)):
    polls = db.query(Poll).all()
    # 🛠️ FIX 2: Updated to the modern timezone-aware UTC datetime
    now = datetime.now(timezone.utc).replace(tzinfo=None) # Keep naive to match DB
    result = []
    for p in polls:
        status = "Active"
        if not p.is_published:
            status = "Draft"
        elif p.start_time and now < p.start_time:
            status = "Upcoming"
        elif p.end_time and now > p.end_time:
            status = "Ended"
            
        result.append({
            "poll_id": p.poll_id,
            "title": p.title,
            "description": getattr(p, "description", ""), 
            "start_time": p.start_time.isoformat() if p.start_time else None,
            "end_time": p.end_time.isoformat() if p.end_time else None,
            "is_published": p.is_published,
            "is_archived": p.is_archived,
            "status": status
        })
    return result

@router.put("/api/polls/{poll_id}")
def update_poll(poll_id: int, poll: PollUpdate, db: Session = Depends(get_db)):
    db_poll = db.query(Poll).filter(Poll.poll_id == poll_id).first()
    if not db_poll:
        raise HTTPException(status_code=404, detail="Poll not found")
    
    # 🛠️ FIX 1: Pydantic v2 replaces .dict() with .model_dump()
    for key, value in poll.model_dump().items():
        setattr(db_poll, key, value)
    db.commit()
    return {"message": "Poll updated successfully"}

@router.put("/api/polls/{poll_id}/archive")
def archive_poll(poll_id: int, is_archived: bool, db: Session = Depends(get_db)):
    db_poll = db.query(Poll).filter(Poll.poll_id == poll_id).first()
    if not db_poll:
        raise HTTPException(status_code=404, detail="Poll not found")
    if not db_poll.is_published and is_archived:
        raise HTTPException(status_code=400, detail="Cannot archive an unpublished poll")
    
    db_poll.is_archived = is_archived
    db.commit()
    return {"message": "Poll archive status updated"}

@router.put("/api/polls/{poll_id}/unarchive")
def unarchive_poll(poll_id: int, db: Session = Depends(get_db)):
    db_poll = db.query(Poll).filter(Poll.poll_id == poll_id).first()
    if not db_poll:
        raise HTTPException(status_code=404, detail="Poll not found")
    db_poll.is_archived = False
    db.commit()
    return {"message": "Poll unarchived successfully"}

@router.delete("/api/polls/{poll_id}")
def delete_poll(poll_id: int, db: Session = Depends(get_db)):
    db_poll = db.query(Poll).filter(Poll.poll_id == poll_id).first()
    if not db_poll:
        raise HTTPException(status_code=404, detail="Poll not found")
    db.delete(db_poll)
    db.commit()
    return {"message": "Poll deleted successfully"}