import random
from datetime import datetime, timezone
from database import SessionLocal
from models import User
from auth import pwd_context

# 1. Realistic Name Data
first_names = [
    "Juan", "Maria", "Jose", "Ana", "Pedro", "Lourdes", "Carlos", "Teresa", 
    "Miguel", "Rosa", "Emanuel", "Carmen", "Rafael", "Elena", "Antonio", 
    "Beatriz", "Francisco", "Clara", "Vicente", "Isabel", "Fernando", "Silvia", 
    "Ricardo", "Luisa", "Eduardo", "Valeria", "Roberto", "Camila", "Luis", 
    "Sofia", "Gabriel", "Mariana", "Jorge", "Lucia", "Julio", "Daniela", 
    "Mario", "Valentina", "Oscar", "Victoria", "Marcos", "Martina", "Victor", 
    "Emilia", "Andres", "Juliana", "Diego", "Zoe", "Joaquin", "Micaela"
]

last_names = [
    "Garcia", "Reyes", "Cruz", "Santos", "Bautista", "Ocampo", "Aquino", 
    "Ramos", "Mendoza", "Soriano", "Villanueva", "Diaz", "Flores", "Perez", 
    "Tolentino", "Castillo", "Santiago", "Aguilar", "Navarro", "Torres", 
    "Velasco", "Del Rosario", "Gomez", "Castro", "Rodriguez", "Rivera", 
    "Alvarez", "Romero", "De Leon", "Domingo", "Mercado", "Gonzales", 
    "Lopez", "Gutierrez", "Sison", "Miranda", "Pascual", "Sarmiento", 
    "Valdez", "Ferrer", "Nicolas", "Cordero", "Ignacio", "Guzman", "Ortiz"
]

# 2. Exact Courses from your Flutter App
courses = [
    'Bachelor of Science in Tourism Management',
    'Bachelor of Science in Hospitality Management',
    'Bachelor of Entrepreneurship',
    'Bachelor of Arts in Communication',
    'Bachelor of Arts in Political Science',
    'Bachelor of Arts in English Language',
    'Bachelor of Science in Social Work',
    'Bachelor of Science in Biology',
    'Bachelor of Science in Information Technology',
    'Bachelor of Library and Information Science',
    'Bachelor of Music in Music Education',
    'Bachelor of Early Childhood Education',
    'Bachelor of Elementary Education',
    'Bachelor of Special Needs Education',
    'Bachelor of Physical Education',
    'Bachelor of Technology and Livelihood Education',
    'Bachelor of Secondary Education'
]

def seed_users():
    db = SessionLocal()
    try:
        # We hash the password once to speed up the process
        default_password = "password12345"
        print(f"Hashing password '{default_password}'... Please wait.")
        hashed_pw = pwd_context.hash(default_password)

        users_to_add = []
        base_student_id = 2000000 # Starting 7-digit ID

        for i in range(200):
            fname = random.choice(first_names)
            mname = random.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ") + "."
            lname = random.choice(last_names)
            course = random.choice(courses)

            # Ensure strict 7-digit ID (e.g., 2000000, 2000001, etc.)
            student_id = str(base_student_id + i)
            
            # Ensure unique LNU email (e.g., juan.garcia1@lnu.edu.ph)
            email = f"{fname.lower()}.{lname.lower()}{i}@lnu.edu.ph"

            user = User(
                first_name=fname,
                middle_name=mname,
                last_name=lname,
                email=email,
                student_number=student_id,
                course=course,
                password_hash=hashed_pw,
                role="Student",
                is_active=True,
                created_at=datetime.now(timezone.utc)
            )
            users_to_add.append(user)

        print("Inserting 200 students into the database...")
        db.bulk_save_objects(users_to_add)
        db.commit()
        print("✅ Successfully added 200 students!")
        print("Test them using any generated email and the password: 'password12345'")

    except Exception as e:
        print(f"❌ An error occurred: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_users()