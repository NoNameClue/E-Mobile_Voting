from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from pydantic import BaseModel
from typing import Optional, List
import json
import shutil
import os
from database import get_db
from models import Party, Candidate, Poll, PartyApplication, CandidateQA

router = APIRouter(tags=["Parties"])

class PartyCreate(BaseModel):
    poll_id: int
    name: str
    platform_bio: Optional[str] = None

class PartyUpdate(BaseModel):
    name: Optional[str] = None
    platform_bio: Optional[str] = None

class ApplicationApproveData(BaseModel):
    # Allows admin to fix typos before approving, but Q&A remains locked in backend
    party_name: str
    candidates: List[dict]

# 1. STANDARD PARTY ENDPOINTS

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

@router.get("/api/parties/{poll_id}")
def get_parties_by_poll(poll_id: int, db: Session = Depends(get_db)):
    parties = db.query(Party).filter(Party.poll_id == poll_id).all()
    return [{"party_id": p.party_id, "name": p.name, "platform_bio": p.platform_bio} for p in parties]

@router.post("/api/parties")
def create_party(party: PartyCreate, db: Session = Depends(get_db)):
    poll = db.query(Poll).filter(Poll.poll_id == party.poll_id).first()
    if not poll: raise HTTPException(status_code=404, detail="Poll not found")
    if poll.is_published: raise HTTPException(status_code=400, detail="Cannot create party: This poll is already published.")
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    if poll.status == "Ended" or (poll.end_time and now > poll.end_time):
        raise HTTPException(status_code=400, detail="Cannot create party: This poll has already ended.")

    existing = db.query(Party).filter(Party.poll_id == party.poll_id, Party.name == party.name).first()
    if existing: raise HTTPException(status_code=409, detail="Party already exists.")
    
    new_party = Party(poll_id=party.poll_id, name=party.name, platform_bio=party.platform_bio)
    db.add(new_party)
    db.commit()
    return {"party_id": new_party.party_id, "name": new_party.name, "platform_bio": new_party.platform_bio}

@router.put("/api/parties/{party_id}")
def update_party(party_id: int, party_data: PartyUpdate, db: Session = Depends(get_db)):
    db_party = db.query(Party).filter(Party.party_id == party_id).first()
    if not db_party: raise HTTPException(status_code=404, detail="Party not found.")
    poll = db.query(Poll).filter(Poll.poll_id == db_party.poll_id).first()
    if poll and poll.is_published: raise HTTPException(status_code=400, detail="Poll is published.")

    if party_data.name: db_party.name = party_data.name
    if party_data.platform_bio is not None: db_party.platform_bio = party_data.platform_bio

    db.commit()
    return {"message": "Party updated"}

@router.delete("/api/parties/{party_id}")
def delete_party(party_id: int, db: Session = Depends(get_db)):
    db_party = db.query(Party).filter(Party.party_id == party_id).first()
    if not db_party: raise HTTPException(status_code=404, detail="Party not found")
    if db_party.name.lower() == "independent": raise HTTPException(status_code=400, detail="Cannot delete Independent")
    
    poll = db.query(Poll).filter(Poll.poll_id == db_party.poll_id).first()
    if poll and poll.is_published: raise HTTPException(status_code=400, detail="Poll is published.")

    party_name = db_party.name
    candidates = db.query(Candidate).filter(Candidate.party_name == party_name).all()
    for cand in candidates: cand.party_name = "Independent"

    db.delete(db_party)
    db.commit()
    return {"message": "Party deleted"}

# 2. PARTY APPLICATION ENDPOINTS

@router.post("/api/parties/apply")
def submit_party_application(
    poll_id: int = Form(...),
    party_name: str = Form(...),
    platform_bio: str = Form(""),
    candidates_json: str = Form(...), 
    photos: List[UploadFile] = File(None),
    db: Session = Depends(get_db)
):
    poll = db.query(Poll).filter(Poll.poll_id == poll_id).first()
    if not poll or poll.is_published:
        raise HTTPException(status_code=400, detail="No unpublished polls available for application.")
        
    try:
        candidates_data = json.loads(candidates_json)
    except:
        raise HTTPException(status_code=400, detail="Invalid JSON data.")

    # Map uploaded photos to candidates based on position filename prefix
    photo_map = {}
    if photos:
        for photo in photos:
            timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
            safe_filename = photo.filename.replace(" ", "_")
            file_path = f"uploads/app_{timestamp}_{safe_filename}"
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(photo.file, buffer)
            
            # The frontend will prefix the filename with the position (e.g., "President_image.jpg")
            pos_prefix = photo.filename.split("_")[0]
            photo_map[pos_prefix] = file_path

    # Attach photo URLs to the JSON payload
    for cand in candidates_data:
        cand['photo_url'] = photo_map.get(cand['position'], None)

    application = PartyApplication(
        poll_id=poll_id,
        party_name=party_name,
        platform_bio=platform_bio,
        candidates_payload=candidates_data,
        submitted_at=datetime.now().isoformat()
    )
    db.add(application)
    db.commit()
    return {"message": "Application submitted for review."}

@router.get("/api/parties/applications/pending")
def get_pending_applications(db: Session = Depends(get_db)):
    apps = db.query(PartyApplication).filter(PartyApplication.status == "Pending").all()
    return apps

@router.post("/api/parties/applications/{app_id}/approve")
def approve_application(app_id: int, review_data: ApplicationApproveData, db: Session = Depends(get_db)):
    app = db.query(PartyApplication).filter(PartyApplication.application_id == app_id).first()
    if not app: raise HTTPException(status_code=404, detail="Application not found")
    
    # 1. Create the Party
    existing_party = db.query(Party).filter(Party.poll_id == app.poll_id, Party.name == review_data.party_name).first()
    if not existing_party:
        new_party = Party(poll_id=app.poll_id, name=review_data.party_name, platform_bio=app.platform_bio)
        db.add(new_party)
        db.commit()

    # 2. Extract original locked data (Q&A and Photos)
    original_candidates = {c['position']: c for c in app.candidates_payload}

    # 3. Create Candidates using Admin's typo-fixed names, but locked original Q&As
    for reviewed_cand in review_data.candidates:
        pos = reviewed_cand['position']
        orig = original_candidates.get(pos, {})
        
        new_cand = Candidate(
            poll_id=app.poll_id,
            first_name=reviewed_cand['first_name'],
            middle_name=reviewed_cand.get('middle_name', ''),
            last_name=reviewed_cand['last_name'],
            position=pos,
            party_name=review_data.party_name,
            course_year=reviewed_cand['course_year'],
            description_platform=orig.get('description_platform', ''), # Locked
            photo_url=orig.get('photo_url', None), # Locked
            is_withdrawn=False
        )
        db.add(new_cand)
        db.commit()
        db.refresh(new_cand)

        # Process locked Q&A
        if 'qas' in orig:
            for qa in orig['qas']:
                db.add(CandidateQA(candidate_id=new_cand.candidate_id, question=qa['question'], answer=qa['answer']))
            db.commit()

    app.status = "Approved"
    db.commit()
    return {"message": "Application approved and party officially registered."}

@router.delete("/api/parties/applications/{app_id}/reject")
def reject_application(app_id: int, db: Session = Depends(get_db)):
    app = db.query(PartyApplication).filter(PartyApplication.application_id == app_id).first()
    if not app: raise HTTPException(status_code=404, detail="Application not found")
    db.delete(app)
    db.commit()
    return {"message": "Application rejected and deleted."}