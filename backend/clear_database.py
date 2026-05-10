from database import SessionLocal
from models import User, Poll, Party, Candidate, Vote

def clear_database():
    db = SessionLocal()
    try:
        print("⚠️ WARNING: You are about to wipe the election database.")
        print("This will delete ALL Votes, Candidates, Parties, Polls, and Student accounts.")
        print("Admin and Staff accounts will NOT be deleted.\n")
        
        # Safety check to prevent accidental wipes
        confirm = input("Type 'DELETE' to confirm: ")
        if confirm != 'DELETE':
            print("Operation cancelled. Nothing was deleted.")
            return

        print("\n🧹 1. Deleting all Votes...")
        db.query(Vote).delete()

        print("🧹 2. Deleting all Candidates...")
        db.query(Candidate).delete()

        print("🧹 3. Deleting all Parties...")
        db.query(Party).delete()

        print("🧹 4. Deleting all Polls...")
        db.query(Poll).delete()

        print("🧹 5. Deleting all Student accounts...")
        # synchronize_session=False is used for faster bulk deletes
        db.query(User).filter(User.role == 'Student').delete(synchronize_session=False)

        # Commit the changes to the database
        db.commit()
        print("\n✅ Success! The database has been successfully cleared.")

    except Exception as e:
        print(f"\n❌ An error occurred: {e}")
        db.rollback() # Undo any partial deletions if something fails
    finally:
        db.close()

if __name__ == "__main__":
    clear_database()