# Demo Seed Script

Creates a historical event + registration for an existing Firebase user so you can demo the History tab.

## Setup

1. **Download your service account key:**
   - Firebase Console → Project settings → Service accounts → Generate new private key
   - Save as `scripts/service_account.json`

2. **Install dependency:**
   ```bash
   pip install firebase-admin
   ```

3. **Run the script:**
   ```bash
   cd scripts
   python3 seed_demo.py <USER_UID>
   ```

   Replace `<USER_UID>` with the Firebase Auth UID of your demo user.

## What it does

- Creates `events/evt-past-robotics` (a past event) if it doesn't exist
- Creates `registrations/<UID>_evt-past-robotics` linked to that user
- Idempotent — safe to run multiple times

## Finding the User's UID

Firebase Console → Authentication → Users → copy the UID column.
