from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from database import get_db
from models import QuestionBank

router = APIRouter(tags=["Questions"])

class QuestionInput(BaseModel):
    question_text: str

@router.get("/api/questions")
def get_questions(db: Session = Depends(get_db)):
    return db.query(QuestionBank).all()

@router.post("/api/questions")
def add_question(q: QuestionInput, db: Session = Depends(get_db)):
    text = q.question_text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Question cannot be blank.")
        
    existing = db.query(QuestionBank).filter(QuestionBank.question_text == text).first()
    if existing:
        raise HTTPException(status_code=400, detail="This question already exists in the bank.")
        
    new_q = QuestionBank(question_text=text)
    db.add(new_q)
    db.commit()
    return {"message": "Question saved successfully"}

@router.put("/api/questions/{q_id}")
def edit_question(q_id: int, q: QuestionInput, db: Session = Depends(get_db)):
    text = q.question_text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Question cannot be edited to be blank.")
        
    db_q = db.query(QuestionBank).filter(QuestionBank.question_id == q_id).first()
    if not db_q:
        raise HTTPException(status_code=404, detail="Question not found.")
        
    # Check if another question already has this exact text
    existing = db.query(QuestionBank).filter(QuestionBank.question_text == text, QuestionBank.question_id != q_id).first()
    if existing:
        raise HTTPException(status_code=400, detail="Another question with this text already exists.")

    db_q.question_text = text
    db.commit()
    return {"message": "Question updated successfully"}

@router.delete("/api/questions/{q_id}")
def delete_question(q_id: int, db: Session = Depends(get_db)):
    db_q = db.query(QuestionBank).filter(QuestionBank.question_id == q_id).first()
    if db_q:
        db.delete(db_q)
        db.commit()
    return {"message": "Question deleted successfully"}