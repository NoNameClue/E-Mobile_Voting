from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime
from database import get_db
from models import Vote, Candidate, User
from schemas import VoteSubmit
from auth import get_current_user

router = APIRouter(tags=["Voting"])

@router.get("/api/vote/status/{poll_id}")
def check_vote_status(poll_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    existing_vote = db.query(Vote).filter(
        Vote.user_id == current_user.user_id,
        Vote.poll_id == poll_id
    ).first()
    return {"has_voted": existing_vote is not None}

@router.post("/api/vote")
def submit_vote(vote: VoteSubmit, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    existing_vote = db.query(Vote).filter(
        Vote.user_id == current_user.user_id,
        Vote.poll_id == vote.poll_id
    ).first()
    
    if existing_vote:
        raise HTTPException(status_code=400, detail="You have already voted in this poll")

    for cand_id in vote.candidate_ids:
        new_vote = Vote(
            user_id=current_user.user_id,
            poll_id=vote.poll_id,
            candidate_id=cand_id
        )
        db.add(new_vote)
    
    db.commit()
    return {"message": "Vote submitted successfully"}

@router.get("/api/users/me/votes")
def get_my_votes(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    user_votes = db.query(Vote).filter(Vote.user_id == current_user.user_id).all()
    poll_groups = {}

    for vote in user_votes:
        if vote.poll_id not in poll_groups:
            poll_groups[vote.poll_id] = []
        
        candidate = db.query(Candidate).filter(Candidate.candidate_id == vote.candidate_id).first()
        if candidate:
            poll_groups[vote.poll_id].append({
                "candidate_id": candidate.candidate_id,
                "name": candidate.name,
                "position": candidate.position,
                "party": candidate.party_name,
                "photo": candidate.photo_url
            })

    result = [{"poll_id": pid, "candidates": cands} for pid, cands in poll_groups.items()]
    return result

@router.get("/api/polls/{poll_id}/results")
def get_poll_results(poll_id: int, db: Session = Depends(get_db)):
    candidates = db.query(Candidate).filter(Candidate.poll_id == poll_id).all()
    
    position_totals = db.query(Candidate.position, func.count(Vote.vote_id).label("total"))\
        .outerjoin(Vote, Candidate.candidate_id == Vote.candidate_id)\
        .filter(Candidate.poll_id == poll_id)\
        .group_by(Candidate.position).all()
        
    pos_map = {row[0]: row[1] for row in position_totals}

    results = []
    for c in candidates:
        votes = db.query(Vote).filter(Vote.candidate_id == c.candidate_id).count()
        total_for_pos = pos_map.get(c.position, 0)
        percentage = (votes / total_for_pos * 100) if total_for_pos > 0 else 0.0
        
        results.append({
            "candidate_id": c.candidate_id,
            "name": c.name,
            "position": c.position,
            "party_name": c.party_name,
            "photo_url": c.photo_url,
            "votes": votes,
            "percentage": round(percentage, 2)
        })
    return results

# 🛠️ THE FIX: This now returns exactly the advanced data your Dart file expects!
@router.get("/api/polls/{poll_id}/report")
def get_poll_report(poll_id: int, db: Session = Depends(get_db)):
    # 1. GENERATE SUMMARY DATA
    total_active_students = db.query(User).filter(User.role == "Student", User.is_active == True).count()
    total_voters = db.query(func.count(func.distinct(Vote.user_id))).filter(Vote.poll_id == poll_id).scalar() or 0
    
    turnout = 0.0
    if total_active_students > 0:
        turnout = round((total_voters / total_active_students) * 100, 2)
        
    summary = {
        "total_active_students": total_active_students,
        "total_voters": total_voters,
        "turnout_percentage": turnout
    }
    
    # 2. GENERATE RESULTS DATA
    candidates = db.query(Candidate).filter(Candidate.poll_id == poll_id).all()
    
    positions = {}
    for c in candidates:
        if c.position not in positions:
            positions[c.position] = []
        
        votes = db.query(Vote).filter(Vote.candidate_id == c.candidate_id).count()
        positions[c.position].append({
            "candidate_id": c.candidate_id,
            "name": c.name,
            "party_name": c.party_name or "Independent",
            "votes": votes
        })
        
    results = []
    for pos, cands in positions.items():
        total_votes_pos = sum(c["votes"] for c in cands)
        
        # Sort candidates by votes highest to lowest
        cands.sort(key=lambda x: x["votes"], reverse=True)
        
        formatted_cands = []
        for i, c in enumerate(cands):
            pct = round((c["votes"] / total_votes_pos * 100), 2) if total_votes_pos > 0 else 0.0
            
            # Calculate Margin (+X% over the person below them)
            margin = None
            if i < len(cands) - 1:
                next_pct = round((cands[i+1]["votes"] / total_votes_pos * 100), 2) if total_votes_pos > 0 else 0.0
                margin = round(pct - next_pct, 2)
                
            formatted_cands.append({
                "rank": i + 1,
                "name": c["name"],
                "party_name": c["party_name"],
                "votes": c["votes"],
                "percentage": pct,
                "margin": margin,
                "is_winner": (i == 0 and c["votes"] > 0) # Top rank is the winner
            })
            
        results.append({
            "position": pos,
            "total_votes": total_votes_pos,
            "candidates": formatted_cands
        })
        
    return {
        "summary": summary,
        "results": results
    }