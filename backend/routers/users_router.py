from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from database import get_db
from models import User

router = APIRouter(tags=["Users"])

@router.get("/api/users")
def get_all_users(db: Session = Depends(get_db)):
    return db.query(User).all()

@router.get("/api/admin/students")
def get_all_students(db: Session = Depends(get_db)):
    return db.query(User).filter(User.role == "Student").all()

# 🛠️ BULLETPROOF FIX: Prevent 422 Unprocessable Entity
@router.put("/api/admin/students/{user_id}/toggle")
async def toggle_student_status(user_id: int, request: Request, db: Session = Depends(get_db)):
    student = db.query(User).filter(User.user_id == user_id, User.role == "Student").first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    # Safely catch WHATEVER Flutter sends (or doesn't send) to prevent crashes
    try:
        data = await request.json()
        if "is_active" in data:
            student.is_active = bool(data["is_active"])
        elif "status" in data:
            student.is_active = bool(data["status"])
        else:
            student.is_active = not student.is_active
    except Exception:
        # If Flutter sent NO JSON body at all, just flip the status to the opposite!
        student.is_active = not student.is_active

    db.commit()
    return {"message": f"Status updated successfully to {student.is_active}"}