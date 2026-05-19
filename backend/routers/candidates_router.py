from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.orm import Session
from datetime import datetime
import os, shutil
import json
from database import get_db
from models import Candidate, CandidateQA, Poll

router = APIRouter(tags=["Candidates"])

@router.post("/api/candidates")
def add_candidate(
    poll_id: int = Form(...),
    first_name: str = Form(...),
    middle_name: str = Form(""),
    last_name: str = Form(...),
    position: str = Form(...),
    party_name: str = Form("Independent"),
    course_year: str = Form(...),
    description_platform: str = Form(""),
    qa_data: str = Form(None), 
    photo: UploadFile = File(None),
    db: Session = Depends(get_db)
):
    # Check if Poll is already published
    poll = db.query(Poll).filter(Poll.poll_id == poll_id).first()
    if poll and poll.is_published:
        raise HTTPException(status_code=400, detail="Cannot register candidates. This poll is already published and locked.")

    # Prevent duplicate candidates
    if party_name.lower() != "independent":
        existing = db.query(Candidate).filter(
            Candidate.poll_id == poll_id,
            Candidate.party_name == party_name,
            Candidate.position == position
        ).first()
        
        if existing:
            raise HTTPException(
                status_code=400, 
                detail="A candidate is already registered for this party and position."
            )

    file_path = None
    if photo and photo.filename:
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        safe_filename = photo.filename.replace(" ", "_")
        file_path = f"uploads/{timestamp}_{safe_filename}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)

    new_candidate = Candidate(
        poll_id=poll_id,
        first_name=first_name,
        middle_name=middle_name,
        last_name=last_name,
        position=position,
        party_name=party_name,
        course_year=course_year,
        description_platform=description_platform,
        photo_url=file_path,
        is_withdrawn=False # Initialize as active
    )
    db.add(new_candidate)
    db.commit()
    db.refresh(new_candidate)

    # Q&A SAVING LOGIC
    if qa_data:
        try:
            qa_list = json.loads(qa_data)
            for qa in qa_list:
                new_qa = CandidateQA(
                    candidate_id=new_candidate.candidate_id,
                    question=qa["question"],
                    answer=qa["answer"]
                )
                db.add(new_qa)
            db.commit()
        except Exception as e:
            print("Error parsing Q&A Data:", e)

    return {"message": "Candidate registered successfully"}

@router.get("/api/candidates/{poll_id}")
def get_candidates(poll_id: int, db: Session = Depends(get_db)):
    cands = db.query(Candidate).filter(Candidate.poll_id == poll_id).all()
    results = []
    
    for c in cands:
        qas = db.query(CandidateQA).filter(CandidateQA.candidate_id == c.candidate_id).all()
        
        results.append({
            "candidate_id": c.candidate_id,
            "poll_id": c.poll_id,
            "first_name": c.first_name,
            "middle_name": c.middle_name,
            "last_name": c.last_name,
            "name": f"{c.first_name} {c.middle_name} {c.last_name}".replace("  ", " ").strip(),
            "position": c.position,
            "party_name": c.party_name,
            "course_year": c.course_year,
            "description_platform": c.description_platform,
            "photo_url": c.photo_url,
            "is_withdrawn": getattr(c, 'is_withdrawn', False), # 🛠️ Tells Flutter to hide them from the ballot
            "qas": [{"question": qa.question, "answer": qa.answer} for qa in qas]
        })
        
    return results

@router.put("/api/candidates/{candidate_id}")
def update_candidate(
    candidate_id: int, 
    poll_id: int = Form(...),
    first_name: str = Form(...),
    middle_name: str = Form(""),
    last_name: str = Form(...),
    position: str = Form(...),
    party_name: str = Form("Independent"),
    course_year: str = Form(...),
    description_platform: str = Form(""),
    qa_data: str = Form(None), 
    is_withdrawn: str = Form("false"), # 🛠️ FIX: Accept exactly as a string from Flutter
    photo: UploadFile = File(None),
    db: Session = Depends(get_db)
):
    db_cand = db.query(Candidate).filter(Candidate.candidate_id == candidate_id).first()
    if not db_cand:
        raise HTTPException(status_code=404, detail="Candidate not found")
        
    poll = db.query(Poll).filter(Poll.poll_id == poll_id).first()
    
    # 🛠️ FIX: Manually and safely convert the text string to a Python Boolean
    withdrawn_status = str(is_withdrawn).lower() in ['true', '1', 'yes', 'on']
    
    # 🛠️ WITHDRAWAL BYPASS: If poll is published, STRICTLY only allow withdrawal update.
    if poll and poll.is_published:
        db_cand.is_withdrawn = withdrawn_status
        db.commit()
        return {"message": "Poll is published. Core details locked, but withdrawal status was successfully updated."}

    # If NOT published, allow full normal updates
    if party_name.lower() != "independent":
        existing = db.query(Candidate).filter(
            Candidate.poll_id == poll_id,
            Candidate.party_name == party_name,
            Candidate.position == position,
            Candidate.candidate_id != candidate_id 
        ).first()
        if existing:
            raise HTTPException(status_code=400, detail="A candidate is already registered for this party and position.")
            
    db_cand.poll_id = poll_id
    db_cand.first_name = first_name
    db_cand.middle_name = middle_name
    db_cand.last_name = last_name
    db_cand.position = position
    db_cand.party_name = party_name
    db_cand.course_year = course_year
    db_cand.description_platform = description_platform
    db_cand.is_withdrawn = withdrawn_status # Save the boolean

    if photo and photo.filename:
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        safe_filename = photo.filename.replace(" ", "_")
        file_path = f"uploads/{timestamp}_{safe_filename}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)
        db_cand.photo_url = file_path

    if qa_data:
        try:
            qa_list = json.loads(qa_data)
            db.query(CandidateQA).filter(CandidateQA.candidate_id == candidate_id).delete()
            for qa in qa_list:
                new_qa = CandidateQA(candidate_id=candidate_id, question=qa["question"], answer=qa["answer"])
                db.add(new_qa)
        except Exception as e:
            print("Error parsing Q&A Data:", e)

    db.commit()
    return {"message": "Candidate updated successfully"}

@router.delete("/api/candidates/{candidate_id}")
def delete_candidate(candidate_id: int, db: Session = Depends(get_db)):
    db_cand = db.query(Candidate).filter(Candidate.candidate_id == candidate_id).first()
    if not db_cand:
        raise HTTPException(status_code=404, detail="Candidate not found")
        
    poll = db.query(Poll).filter(Poll.poll_id == db_cand.poll_id).first()
    
    # 🛠️ WITHDRAWAL BYPASS: If admin deletes during an active poll, soft-delete instead!
    if poll and poll.is_published:
        db_cand.is_withdrawn = True
        db.commit()
        return {"message": "Poll is active. Candidate has been withdrawn (soft-deleted) to preserve existing vote data."}
        
    # If not published, hard delete normally
    db.delete(db_cand)
    db.commit()
    return {"message": "Candidate deleted successfully"}