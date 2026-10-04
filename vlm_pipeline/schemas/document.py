from enum import Enum
from typing import Optional, List
from pydantic import BaseModel, Field

class FieldStatus(str, Enum):
    CONNU = "CONNU"
    INCONNU = "INCONNU"
    NON_FOURNI = "NON_FOURNI"
    ILLISIBLE = "ILLISIBLE"
    NON_APPLICABLE = "NON_APPLICABLE"
    A_REVISER = "A_REVISER"

class ExtractedField(BaseModel):
    field_label: str = Field(description="Nom du champ (ex: N° de la fiche, Tension, etc.)")
    extracted_text: Optional[str] = Field(
        default=None, 
        description="Texte extrait. Laisser à null si NON_FOURNI ou ILLISIBLE."
    )
    status: FieldStatus = Field(default=FieldStatus.NON_FOURNI)
    confidence_score: float = Field(default=1.0, ge=0.0, le=1.0)

class DocumentExtractionResult(BaseModel):
    document_type: str = Field(default="Fiche de surveillance de la grossesse")
    number_fiche: Optional[str] = Field(default=None, description="Code/Numéro attribué par la sage-femme")
    region: Optional[str] = Field(default=None)
    province: Optional[str] = Field(default=None)
    etablissement_sanitaire: Optional[str] = Field(default=None)
    fields: List[ExtractedField] = Field(default_factory=list)

# Retrait strict des PI/PII : Les noms ne sont JAMAIS stockés (consignes du défi)