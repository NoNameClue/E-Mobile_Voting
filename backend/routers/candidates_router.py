from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.orm import Session
from datetime import datetime
import os, shutil
from database import get_db
from models import Candidate
from schemas import CandidateUpdate

router = APIRouter(tags=["Candidates"])

@router.post("/api/candidates")
def add_candidate(
    poll_id: int = Form(...),
    name: str = Form(...),
    position: str = Form(...),
    party_name: str = Form("Independent"),
    course_year: str = Form(...),
    description_platform: str = Form(""),
    photo: UploadFile = File(None),
    db: Session = Depends(get_db)
):
    existing = db.query(Candidate).filter(
        Candidate.poll_id == poll_id,
        Candidate.position == position,
        Candidate.party_name == party_name
    ).first()
    
    if existing and party_name != "Independent":
        raise HTTPException(status_code=400, detail=f"The {party_name} already has a {position} registered.")

    file_path = None
    if photo and photo.filename:
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        safe_filename = photo.filename.replace(" ", "_")
        file_path = f"uploads/{timestamp}_{safe_filename}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)

    new_candidate = Candidate(
        poll_id=poll_id,
        name=name,
        position=position,
        party_name=party_name,
        course_year=course_year,
        description_platform=description_platform,
        photo_url=file_path
    )
    db.add(new_candidate)
    db.commit()
    return {"message": "Candidate registered successfully"}

@router.get("/api/candidates/{poll_id}")
def get_candidates(poll_id: int, db: Session = Depends(get_db)):
    cands = db.query(Candidate).filter(Candidate.poll_id == poll_id).all()
    # 🛠️ FIX: Safely map data to prevent Dart JSON Decode errors
    return [
        {
            "candidate_id": c.candidate_id,
            "poll_id": c.poll_id,
            "name": c.name,
            "position": c.position,
            "party_name": c.party_name,
            "course_year": c.course_year,
            "description_platform": c.description_platform,
            "photo_url": c.photo_url
        } for c in cands
    ]

@router.put("/api/candidates/{candidate_id}")
def update_candidate(
    candidate_id: int, 
    candidate: CandidateUpdate = Depends(),
    photo: UploadFile = File(None),
    db: Session = Depends(get_db)
):
    db_cand = db.query(Candidate).filter(Candidate.candidate_id == candidate_id).first()
    if not db_cand:
        raise HTTPException(status_code=404, detail="Candidate not found")
        
    if candidate.name:
        db_cand.name = candidate.name
    if candidate.course_year:
        db_cand.course_year = candidate.course_year
    if candidate.description_platform is not None:
        db_cand.description_platform = candidate.description_platform

    if photo and photo.filename:
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        safe_filename = photo.filename.replace(" ", "_")
        file_path = f"uploads/{timestamp}_{safe_filename}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)
        db_cand.photo_url = file_path

    db.commit()
    return {"message": "Candidate updated successfully"}

@router.delete("/api/candidates/{candidate_id}")
def delete_candidate(candidate_id: int, db: Session = Depends(get_db)):
    db_cand = db.query(Candidate).filter(Candidate.candidate_id == candidate_id).first()
    if not db_cand:
        raise HTTPException(status_code=404, detail="Candidate not found")
    db.delete(db_cand)
    db.commit()
    return {"message": "Candidate deleted successfully"}