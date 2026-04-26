from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from pydantic import BaseModel
from typing import Optional
from database import get_db
from models import Party, Candidate, Poll

router = APIRouter(tags=["Parties"])

# --- Pydantic Validation Schemas ---
class PartyCreate(BaseModel):
    poll_id: int
    name: str
    platform_bio: Optional[str] = None  # 🛠️ ADDED: Platform Bio

class PartyUpdate(BaseModel):
    name: Optional[str] = None
    platform_bio: Optional[str] = None  # 🛠️ ADDED: Platform Bio

# --- Endpoints ---

@router.get("/api/parties/{poll_id}")
def get_parties_by_poll(poll_id: int, db: Session = Depends(get_db)):
    parties = db.query(Party).filter(Party.poll_id == poll_id).all()
    # 🛠️ ADDED: Include platform_bio in the response so Flutter can display it
    return [
        {
            "party_id": p.party_id, 
            "name": p.name, 
            "platform_bio": p.platform_bio
        } 
        for p in parties
    ]

@router.get("/api/parties/lineups")
def get_party_lineups(db: Session = Depends(get_db)):
    candidates = db.query(Candidate).all()
    lineups = {}
    for c in candidates:
        party = c.party_name or "Independent" 
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

    # 2. 🛠️ SECURITY CHECK: Cannot create party if Poll is PUBLISHED
    if poll.is_published:
        raise HTTPException(status_code=400, detail="Cannot create party: This poll is already published and locked.")

    # 3. 🛠️ SECURITY CHECK: Cannot create party if Poll is ENDED/EXPIRED
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    if poll.status == "Ended" or (poll.end_time and now > poll.end_time):
        raise HTTPException(status_code=400, detail="Cannot create party: This poll has already ended.")

    # 4. Check for duplicate party name INSIDE this specific poll
    existing = db.query(Party).filter(Party.poll_id == party.poll_id, Party.name == party.name).first()
    if existing:
        raise HTTPException(status_code=409, detail=f"The party '{party.name}' already exists in this specific poll.")
    
    # 5. Save to database including bio
    new_party = Party(
        poll_id=party.poll_id, 
        name=party.name,
        platform_bio=party.platform_bio  # 🛠️ ADDED: Map the bio
    )
    db.add(new_party)
    db.commit()
    db.refresh(new_party)
    return new_party

# 🛠️ ADDED: New PUT endpoint so you can edit the name and bio later
@router.put("/api/parties/{party_id}")
def update_party(party_id: int, party_data: PartyUpdate, db: Session = Depends(get_db)):
    db_party = db.query(Party).filter(Party.party_id == party_id).first()
    if not db_party:
        raise HTTPException(status_code=404, detail="Party not found.")

    # 1. 🛠️ SECURITY CHECK: Is the Poll already published?
    poll = db.query(Poll).filter(Poll.poll_id == db_party.poll_id).first()
    if poll and poll.is_published:
        raise HTTPException(status_code=400, detail="Cannot edit parties. This poll is already published and locked.")

    # Update fields
    if party_data.name:
        existing = db.query(Party).filter(Party.name.ilike(party_data.name), Party.party_id != party_id).first()
        if existing:
            raise HTTPException(status_code=400, detail="Another party already uses this name.")
        db_party.name = party_data.name
        
    if party_data.platform_bio is not None:
        db_party.platform_bio = party_data.platform_bio  # 🛠️ ADDED: Update Bio

    db.commit()
    return {"message": "Party updated successfully"}

@router.delete("/api/parties/{party_id}")
def delete_party(party_id: int, db: Session = Depends(get_db)):
    db_party = db.query(Party).filter(Party.party_id == party_id).first()
    if not db_party:
        raise HTTPException(status_code=404, detail="Party not found")
        
    if db_party.name.lower() == "independent":
        raise HTTPException(status_code=400, detail="Cannot delete the Independent party")
        
    # 1. 🛠️ SECURITY CHECK: Is the Poll already published?
    poll = db.query(Poll).filter(Poll.poll_id == db_party.poll_id).first()
    if poll and poll.is_published:
        raise HTTPException(status_code=400, detail="Cannot delete parties. This poll is already published and locked.")

    party_name = db_party.name

    # 2. Reassign candidates to Independent so they aren't deleted
    candidates = db.query(Candidate).filter(Candidate.party_name == party_name).all()
    for cand in candidates:
        cand.party_name = "Independent"

    db.delete(db_party)
    db.commit()
    return {"message": f"Party '{party_name}' deleted successfully"}