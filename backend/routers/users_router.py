from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from database import get_db
from models import User

router = APIRouter(tags=["Users"])

@router.get("/api/users")
def get_all_users(db: Session = Depends(get_db)):
    users = db.query(User).all()
    return [{**u.__dict__, "full_name": f"{u.first_name} {u.middle_name} {u.last_name}".replace("  ", " ").strip()} for u in users]

@router.get("/api/admin/students")
def get_all_students(db: Session = Depends(get_db)):
    students = db.query(User).filter(User.role == "Student").all()
    return [
        {
            "user_id": s.user_id,
            "first_name": s.first_name,
            "middle_name": s.middle_name,
            "last_name": s.last_name,
            "full_name": f"{s.first_name} {s.middle_name} {s.last_name}".replace("  ", " ").strip(),
            "email": s.email,
            "student_number": s.student_number,
            "course": s.course,
            "is_active": s.is_active,
            "created_at": s.created_at.isoformat() if s.created_at else None,
            "profile_pic_url": s.profile_pic_url
        } for s in students
    ]

@router.put("/api/admin/students/{user_id}/toggle")
async def toggle_student_status(user_id: int, request: Request, db: Session = Depends(get_db)):
    student = db.query(User).filter(User.user_id == user_id, User.role == "Student").first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    try:
        data = await request.json()
        if "is_active" in data:
            student.is_active = bool(data["is_active"])
        elif "status" in data:
            student.is_active = bool(data["status"])
        else:
            student.is_active = not student.is_active
    except Exception:
        student.is_active = not student.is_active

    db.commit()
    return {"message": f"Status updated successfully to {student.is_active}"}