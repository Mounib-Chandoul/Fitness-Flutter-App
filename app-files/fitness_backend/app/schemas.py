from pydantic import BaseModel, field_validator,ConfigDict
from typing import Optional, List


class UserUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    password: Optional[str] = None
    bio: Optional[str] = None
    specialization: Optional[str] = None
    emoji: Optional[str] = None


class RoleUpdate(BaseModel):
    new_role: str


class UserCreate(BaseModel):
    email: str
    password: str
    name: str
    role: str


class UserResponse(BaseModel):
    id: int
    email: str
    name: str
    role: str
    bio: Optional[str] = ""
    specialization: Optional[str] = ""
    emoji: Optional[str] = "⚡"
    # include plans the user has purchased (populated from relationship)
    # PlanResponse is declared later, so use a forward-reference string to avoid
    # NameError at import time.
    purchased_plans: Optional["List[PlanResponse]"] = []

    model_config = ConfigDict(from_attributes=True)


class PlanBase(BaseModel):
    title: str
    category: str
    description: Optional[str] = None
    duration: int
    workouts_per_week: int
    level: str
    exercises: List[str] # Matches your Dynamic Exercise list in Flutter
    diet: Optional[str] = None
    price: float


class PlanCreate(PlanBase):
    # we are intentionally permissive here so that clients can send extra
    # keys (such as `creator_name` or card details) without triggering a
    # validation error.  the router still only uses the fields defined on
    # PlanBase and the authenticated user information, so extra data is
    # harmlessly ignored.
    model_config = ConfigDict(extra="ignore")

class PlanResponse(PlanBase):
    id: int
    coach_id: int
    coach_name: str = ""

    model_config = ConfigDict(from_attributes=True)