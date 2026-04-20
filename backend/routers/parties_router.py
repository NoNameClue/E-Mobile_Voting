from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import Party, Candidate
from schemas import PartyCreate

router = APIRouter(tags=["Parties"])

@router.get("/api/parties")
def get_parties(db: Session = Depends(get_db)):
    parties = db.query(Party).all()
    return [{"party_id": p.party_id, "party_name": p.party_name} for p in parties]

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
    if db.query(Party).filter(Party.party_name == party.party_name).first():
        raise HTTPException(status_code=409, detail="Party already exists")
    
    new_party = Party(party_name=party.party_name)
    db.add(new_party)
    db.commit()
    return {"message": "Party created successfully"}

@router.delete("/api/parties/{party_id}")
def delete_party(party_id: int, db: Session = Depends(get_db)):
    party = db.query(Party).filter(Party.party_id == party_id).first()
    if not party:
        raise HTTPException(status_code=404, detail="Party not found")
    if party.party_name == "Independent":
        raise HTTPException(status_code=400, detail="Cannot delete Independent party")
        
    db.delete(party)
    db.commit()
    return {"message": "Party deleted successfully"}