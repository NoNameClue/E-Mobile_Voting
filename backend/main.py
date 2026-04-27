import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from database import Base, engine
from routers import auth_router, users_router, staffs_router, parties_router, polls_router, candidates_router, voting_router, questions_router

# Import all routers
from routers import auth_router, users_router, staffs_router, parties_router, polls_router, candidates_router, voting_router

# Create database tables safely
try:
    Base.metadata.create_all(bind=engine)
except Exception as e:
    print("Warning: Could not connect to MySQL. If running tests, this is expected.")

app = FastAPI()

# Create uploads folder if it doesn't exist
os.makedirs("uploads", exist_ok=True)
# Mount it so images can be accessed publicly via /uploads/filename.jpg
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth_router.router)
app.include_router(users_router.router)
app.include_router(staffs_router.router)
app.include_router(parties_router.router)
app.include_router(polls_router.router)
app.include_router(candidates_router.router)
app.include_router(voting_router.router)
app.include_router(questions_router.router)