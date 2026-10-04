from enum import Enum

class FieldStatus(str, Enum):
    CONNU = "CONNU"                   # Texte extrait clairement et sans ambiguïté
    INCONNU = "INCONNU"               # Mention explicite d'ignorance (? / Inconnu)
    NON_FOURNI = "NON_FOURNI"         # Case ou champ totalement vide sur le papier
    ILLISIBLE = "ILLISIBLE"           # Texte présent mais impossible à déchiffrer
    NON_APPLICABLE = "NON_APPLICABLE" # Champ biffé, barré ou non concerné

class LanguageDetected(str, Enum):
    FR = "FR"
    AR = "AR"
    EN = "EN"

class RecordLifecycleState(str, Enum):
    CAPTARED = "CAPTURÉ"
    PENDING_AI = "EN_ATTENTE_IA"
    AI_PROCESSED = "TRAITÉ_IA"
    NEEDS_REVIEW = "À_RÉVISER"
    VALIDATED = "VALIDÉ"
    PATIENT_MATCHED = "PATIENTE_LIÉE"
    REGISTERED = "ENREGISTRÉ"
    SYNCED = "SYNCHRONISÉ"