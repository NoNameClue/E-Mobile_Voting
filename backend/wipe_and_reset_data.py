from sqlalchemy import text
from database import SessionLocal

def wipe_and_reset_data():
    db = SessionLocal()
    try:
        print("🧹 Preparing to wipe election data and reset IDs...")
        
        # 1. Temporarily disable foreign key checks to allow truncation
        db.execute(text("SET FOREIGN_KEY_CHECKS = 0;"))
        
        # 2. TRUNCATE tables (Wipes data completely AND resets IDs to 1)
        db.execute(text("TRUNCATE TABLE votes;"))
        db.execute(text("TRUNCATE TABLE candidates;"))
        db.execute(text("TRUNCATE TABLE polls;"))
        db.execute(text("TRUNCATE TABLE parties;"))
        
        # 3. Turn foreign key checks back on for security
        db.execute(text("SET FOREIGN_KEY_CHECKS = 1;"))
        
        # Save all changes
        db.commit()
        
        print("✅ Votes, Candidates, Polls, and Parties wiped. IDs reset to 1.")
        print("🎉 SUCCESS: Election data truncated. Users are safe!")
        
    except Exception as e:
        print(f"❌ Error occurred: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    # Safety confirmation prompt
    confirm = input("WARNING: This will wipe all election data and reset IDs. Keep users? (y/n): ")
    if confirm.lower() == 'y':
        wipe_and_reset_data()
    else:
        print("Operation cancelled.")