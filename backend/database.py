from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

DATABASE_URL = "mysql+pymysql://root:@localhost/emobile_voting"
engine = create_engine(
    DATABASE_URL,
    pool_size=50,       # Handle 50 concurrent DB connections
    max_overflow=100,   # Allow up to 100 extra during absolute peak times
    pool_timeout=30,    # Wait 30 seconds before giving up on a connection
    pool_recycle=1800   # Refresh connections every 30 minutes to prevent staleness
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()