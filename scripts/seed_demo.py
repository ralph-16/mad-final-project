#!/usr/bin/env python3
"""
Seed demo data for an existing Firebase user.

Creates:
  1. A historical event in Firestore (if it doesn't already exist)
  2. A registration for that event linked to the given user UID

Usage:
  1. Download your service account key from Firebase Console:
     Project settings → Service accounts → Generate new private key
  2. Save it as 'service_account.json' in this scripts/ directory
  3. Install dependency: pip install firebase-admin
  4. Run: python3 seed_demo.py <USER_UID>

Example:
  python3 seed_demo.py abc123xyz789
"""

import sys
import json
from datetime import datetime, timezone

import firebase_admin
from firebase_admin import credentials, firestore

SERVICE_ACCOUNT_PATH = "service_account.json"

# The historical event to create (if missing)
HISTORICAL_EVENT = {
    "id": "evt-past-robotics",
    "name": "Robotics Workshop (Past)",
    "category": "Academic",
    "dateTime": datetime(2026, 10, 1, 10, 0, tzinfo=timezone.utc),
    "locationName": "Engineering Lab 3",
    "address": "Main Campus, Engineering Bldg",
    "description": "Hands-on intro to Arduino and line-following robots.",
    "imageUrl": "assets/images/robotics-past.jpg",
}


def init_firebase():
    """Initialize Firebase Admin with the service account."""
    try:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)
        print("✓ Firebase initialized")
    except FileNotFoundError:
        print(f"✗ Service account key not found: {SERVICE_ACCOUNT_PATH}")
        print("  Download it from Firebase Console → Project settings → Service accounts")
        sys.exit(1)
    except ValueError as e:
        print(f"✗ Invalid service account key: {e}")
        sys.exit(1)


def seed(db: firestore.Client, user_uid: str):
    """Create the historical event and registration for the given user."""
    event_ref = db.collection("events").document(HISTORICAL_EVENT["id"])
    reg_ref = db.collection("registrations").document(
        f"{user_uid}_{HISTORICAL_EVENT['id']}"
    )

    # Create event if it doesn't exist
    if not event_ref.get().exists:
        event_data = {k: v for k, v in HISTORICAL_EVENT.items() if k != "id"}
        event_ref.set(event_data)
        print(f"✓ Created event: {HISTORICAL_EVENT['id']}")
    else:
        print(f"• Event already exists: {HISTORICAL_EVENT['id']}")

    # Create registration if it doesn't exist
    if not reg_ref.get().exists:
        reg_data = {
            "studentId": user_uid,
            "eventId": HISTORICAL_EVENT["id"],
            "registeredAt": datetime(2026, 9, 28, 9, 0, tzinfo=timezone.utc),
            "status": "registered",
        }
        reg_ref.set(reg_data)
        print(f"✓ Created registration: {reg_ref.id}")
    else:
        print(f"• Registration already exists: {reg_ref.id}")

    print(f"\nDone! User {user_uid} now has '{HISTORICAL_EVENT['name']}' in History.")


def main():
    if len(sys.argv) != 2:
        print("Usage: python3 seed_demo.py <USER_UID>")
        print("Example: python3 seed_demo.py abc123xyz789")
        sys.exit(1)

    user_uid = sys.argv[1].strip()
    if not user_uid:
        print("✗ UID cannot be empty")
        sys.exit(1)

    init_firebase()
    db = firestore.client()
    seed(db, user_uid)


if __name__ == "__main__":
    main()
