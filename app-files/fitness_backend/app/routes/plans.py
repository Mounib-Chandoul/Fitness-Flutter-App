from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from .. import models
from ..schemas import PlanCreate, PlanResponse
from ..dependencies import get_db, get_current_user


router = APIRouter(
    prefix="/plans",
    tags=["plans"]
)

@router.post("/", response_model=PlanResponse)
def create_plan(plan_in: PlanCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
   
    new_plan = models.Plan(
        **plan_in.dict(),
        coach_id=current_user.id,
        coach_name=current_user.name
    )
    db.add(new_plan)
    db.commit()
    
   
    db.refresh(new_plan)
    
   
    return new_plan
    

@router.get("/", response_model=List[PlanResponse])
def get_all_plans(db: Session = Depends(get_db)):
    return db.query(models.Plan).all()

@router.get("/my", response_model=List[PlanResponse])
def get_my_plans(current_user: models.User = Depends(get_current_user)):
    return current_user.plans_created

@router.delete("/{plan_id}")
def delete_plan(
    plan_id: int, 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(get_current_user)
):
    db_plan = db.query(models.Plan).filter(
        models.Plan.id == plan_id, 
        models.Plan.coach_id == current_user.id
    ).first()
    
    if not db_plan:
        raise HTTPException(status_code=404, detail="Plan not found or unauthorized")
        
    db.delete(db_plan)
    db.commit()
    return {"message": "Plan deleted successfully"}

@router.post("/{plan_id}/purchase")
def handle_purchase(plan_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    plan = db.query(models.Plan).get(plan_id)
    
    if not plan:
        return {"error": "Plan not found"}

    db_user = db.query(models.User).get(current_user.id)
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    if plan not in db_user.purchased_plans:
        db_user.purchased_plans.append(plan)
        db.commit()
        return {"message": "Purchase successful"}
    
    return {"message": "Already owned"}