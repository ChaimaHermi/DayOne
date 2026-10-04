from enum import Enum
from typing import List, Optional
from pydantic import BaseModel
from schemas.document import DocumentExtractionResult

class ActionUtilisateur(str, Enum):
    CONFIRMER = "CONFIRMER"
    CORRIGER = "CORRIGER"
    REPRENDRE_PHOTO = "REPRENDRE_PHOTO"
    SAISIE_MANUELLE = "SAISIE_MANUELLE"

class QuestionSuivi(BaseModel):
    field_label: str
    message: str
    valeur_suggeree: Optional[str] = None

class ExtractionResponse(BaseModel):
    patient_id: Optional[str] = None
    extraction_data: Optional[DocumentExtractionResult] = None
    doute_detecte: bool = False
    questions: List[QuestionSuivi] = []
    champs_a_verifier: List[str] = []

class CorrectionChamp(BaseModel):
    field_label: str
    nouvelle_valeur: str

class VerificationRequest(BaseModel):
    action: ActionUtilisateur
    extraction_data: DocumentExtractionResult
    corrections: Optional[List[CorrectionChamp]] = []

class VerificationResponse(BaseModel):
    status: str
    message: str
    final_data: Optional[DocumentExtractionResult] = None