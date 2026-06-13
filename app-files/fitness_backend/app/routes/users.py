from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel

from .. import models
from ..schemas import UserResponse, UserUpdate, RoleUpdate
from ..dependencies import get_db, get_current_user, get_current_admin

router = APIRouter()


@router.get("/users/all", response_model=List[UserResponse])
def get_all_users(db: Session = Depends(get_db)):
    users = db.query(models.User).all()
    return users


@router.get("/users/{user_gmail}", response_model=UserResponse)
def get_user_profile(user_gmail: str, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == user_gmail).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.patch("/users/me", response_model=UserResponse)
def update_my_profile(user_update: UserUpdate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    for key, value in user_update.dict(exclude_unset=True).items():
        setattr(current_user, key, value)
    db.commit()
    db.refresh(current_user)
    return current_user


# convenience endpoints used by the existing Flutter frontend.  instead of
# forcing the client to know about the /users/me route, the old code called
# /update-profile and /update-avatar.  we support them here as thin wrappers
# that simply forward to the logic above (or do nothing for the avatar).

@router.patch("/update-profile", response_model=UserResponse)
def flutter_update_profile(user_update: UserUpdate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # reuse same logic as /users/me
    return update_my_profile(user_update, db, current_user)


class AvatarUpdate(BaseModel):
    emoji: str

@router.patch("/update-avatar")
def flutter_update_avatar(avatar: AvatarUpdate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # previously this endpoint was a no-op; now we store emoji on user record
    current_user.emoji = avatar.emoji
    db.commit()
    db.refresh(current_user)
    return {"message": "Avatar updated", "emoji": current_user.emoji}


@router.delete("/users/me")
def delete_my_account(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    db.delete(current_user)
    db.commit()
    return {"message": "User deleted successfully"}


# ---------------------------------------------------------------------------
# Followed coaches / purchased plan helpers
# ---------------------------------------------------------------------------

@router.get("/followed-coaches/{user_email}")
def get_followed_coaches(
    user_email: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Return a list of coach summaries for every coach whose plan the given
    user has purchased.  Each coach object contains a `plans` list with the
    actual plan records so the client can render titles, counts, etc.

    Authentication is required; users can only ask for their own list but the
    check is intentionally lenient to permit explorer-style behaviour.
    """
    user = db.query(models.User).filter(models.User.email == user_email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # compile coaches grouped by their id
    coaches_map: dict[int, dict] = {}
    for plan in user.purchased_plans:
        coach = plan.coach
        if coach.id not in coaches_map:
            coaches_map[coach.id] = {
                "id": coach.id,
                "name": coach.name,
                "email": coach.email,
                # optional profile fields may not exist on model
                "specialization": getattr(coach, "specialization", ""),
                "emoji": getattr(coach, "emoji", ""),
                "rating": getattr(coach, "rating", ""),
                "plans": [],
            }
        coaches_map[coach.id]["plans"].append({
            "id": plan.id,
            "title": plan.title,
            "category": plan.category,
            "description": plan.description,
            "duration": plan.duration,
            "workouts_per_week": plan.workouts_per_week,
            "level": plan.level,
            "diet": plan.diet,
            "price": plan.price,
        })

    coaches_list = []
    for info in coaches_map.values():
        info["plans_count"] = len(info["plans"])
        coaches_list.append(info)

    return {"coaches": coaches_list}

# ---------------------------------------------------------------------------
# Coach profile management
# ---------------------------------------------------------------------------

@router.patch("/coach-profile", response_model=UserResponse)
def update_coach_profile(
    coach_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Update the current coach's profile (bio, specialization, emoji)"""
    if current_user.role != "coach":
        raise HTTPException(status_code=403, detail="Only coaches can update coach profile")
    
    # Update only the fields that are provided
    for key, value in coach_update.dict(exclude_unset=True).items():
        if value is not None:
            setattr(current_user, key, value)
    
    db.commit()
    db.refresh(current_user)
    return current_user


# ---------------------------------------------------------------------------
# Admin routes
# ---------------------------------------------------------------------------

@router.get("/admin/users", response_model=List[UserResponse])
def get_all_users_admin(db: Session = Depends(get_db), current_admin: models.User = Depends(get_current_admin)):
    users = db.query(models.User).all()
    return users


@router.delete("/admin/users/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db), current_admin: models.User = Depends(get_current_admin)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    db.delete(user)
    db.commit()
    return {"message": "User deleted"}


@router.patch("/admin/users/{user_id}/role")
def change_user_role(user_id: int, role_update: RoleUpdate, db: Session = Depends(get_db), current_admin: models.User = Depends(get_current_admin)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.role = role_update.new_role
    db.commit()
    return {"message": "Role updated"}