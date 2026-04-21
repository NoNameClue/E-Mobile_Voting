from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timezone

from database import get_db
from models import Party, Candidate, Poll  # 🛠️ Added Poll here
from schemas import PartyCreate

router = APIRouter(tags=["Parties"])

# 🛠️ CHANGED: Fetch parties ONLY for a specific poll
@router.get("/api/parties/{poll_id}")
def get_parties_by_poll(poll_id: int, db: Session = Depends(get_db)):
    parties = db.query(Party).filter(Party.poll_id == poll_id).all()
    return [{"party_id": p.party_id, "name": p.name} for p in parties]

@router.get("/api/parties/lineups")
def get_party_lineups(db: Session = Depends(get_db)):
    candidates = db.query(Candidate).all()
    lineups = {}
    for c in candidates:
        party = c.party_name or "Independent" # (Candidate still uses party_name, leave this alone)
        if party not in lineups:
            lineups[party] = []
            
        full_name = f"{c.first_name} {c.middle_name} {c.last_name}".replace("  ", " ").strip()
        lineups[party].append({
            "candidate_id": c.candidate_id,
            "name": full_name,
            "position": c.position,
            "course_year": c.course_year,
            "photo_url": c.photo_url
        })
    return lineups

@router.post("/api/parties")
def create_party(party: PartyCreate, db: Session = Depends(get_db)):
    # 1. Fetch the target poll
    poll = db.query(Poll).filter(Poll.poll_id == party.poll_id).first()
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found")

    # 2. Rule: Cannot create party if Poll is PUBLISHED
    if poll.is_published:
        raise HTTPException(status_code=400, detail="Cannot create party: This poll is already published and locked.")

    # 3. Rule: Cannot create party if Poll is ENDED/EXPIRED
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    if poll.status == "Ended" or (poll.end_time and now > poll.end_time):
        raise HTTPException(status_code=400, detail="Cannot create party: This poll has already ended.")

    # 4. Check for duplicate party name INSIDE this specific poll
    existing = db.query(Party).filter(Party.poll_id == party.poll_id, Party.name == party.name).first()
    if existing:
        raise HTTPException(status_code=409, detail=f"The party '{party.name}' already exists in this specific poll.")
    
    new_party = Party(poll_id=party.poll_id, name=party.name)
    db.add(new_party)
    db.commit()
    return {"message": "Party created successfully"}

@router.delete("/api/parties/{party_id}")
def delete_party(party_id: int, db: Session = Depends(get_db)):
    party = db.query(Party).filter(Party.party_id == party_id).first()
    if not party:
        raise HTTPException(status_code=404, detail="Party not found")
        
    # 🛠️ CHANGED party.party_name to party.name
    if party.name == "Independent":
        raise HTTPException(status_code=400, detail="Cannot delete the Independent party")
        
    db.delete(party)
    db.commit()
    return {"message": "Party deleted successfully"}