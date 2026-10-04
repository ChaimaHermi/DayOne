import os
import base64
import mimetypes
from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, Field
import instructor
from openai import OpenAI

# ==========================================
# 1. Définition des Schémas Pydantic
# ==========================================

class FieldStatus(str, Enum):
    CONNU = "CONNU"                   # Texte extrait clairement et sans ambiguïté
    INCONNU = "INCONNU"               # Mention explicite d'ignorance ou "? / Inconnu" sur le formulaire
    NON_FOURNI = "NON_FOURNI"         # Case / Champ complètement vide sur le document
    ILLISIBLE = "ILLISIBLE"           # Écriture manuscrite présente mais impossible à déchiffrer
    NON_APPLICABLE = "NON_APPLICABLE" # Champ biffé, barré ou non concerné

class LanguageDetected(str, Enum):
    FR = "FR"
    AR = "AR"
    EN = "EN"

class ExtractedField(BaseModel):
    field_label: str = Field(description="Nom du champ (ex: N° de la fiche, Nom/Prénom, Tension Artérielle)")
    extracted_text: Optional[str] = Field(
        default=None, 
        description="Valeur exacte lue. Mettre 'None' si le champ est vide (NON_FOURNI) ou totalement illisible (ILLISIBLE)."
    )
    language: LanguageDetected = Field(default=LanguageDetected.FR, description="Langue principale du texte extrait")
    status: FieldStatus = Field(
        default=FieldStatus.NON_FOURNI, 
        description="Statut précis de la donnée sur le document."
    )
    confidence_score: float = Field(
        default=0.0, 
        description="Score de confiance estimé entre 0.0 et 1.0", 
        ge=0.0, 
        le=1.0
    )

class DocumentExtractionResult(BaseModel):
    document_type: str = Field(default="Fiche de surveillance de la grossesse", description="Type de document")
    primary_language: LanguageDetected = Field(default=LanguageDetected.FR)
    number_fiche: Optional[str] = Field(default=None, description="N° de la fiche")
    region: Optional[str] = Field(default=None, description="Région")
    province: Optional[str] = Field(default=None, description="Province")
    etablissement_sanitaire: Optional[str] = Field(default=None, description="Nom de l'établissement")
    nom_parturiente: Optional[str] = Field(default=None, description="Nom et prénom de la parturiente")
    fields: List[ExtractedField] = Field(default_factory=list)


# ==========================================
# 2. Utilitaire Base64 Multiformat
# ==========================================

def encode_image_to_data_uri(image_path: str) -> str:
    """
    Encode l'image en Base64 et génère le Data URI adapté au format (PNG, JPG, WEBP, etc.).
    """
    mime_type, _ = mimetypes.guess_type(image_path)
    if not mime_type:
        # Fallback vers image/jpeg si l'extension est inconnue
        mime_type = "image/jpeg"

    with open(image_path, "rb") as image_file:
        encoded_string = base64.b64encode(image_file.read()).decode('utf-8')

    return f"data:{mime_type};base64,{encoded_string}"


# ==========================================
# 3. Inférence VLM via NVIDIA NIM API
# ==========================================

def extract_with_nvidia_vlm(image_path: str) -> DocumentExtractionResult:
    api_key = os.environ.get("NVIDIA_API_KEY")
    if not api_key:
        raise ValueError("Erreur : La variable d'environnement NVIDIA_API_KEY n'est pas définie.")

    client = instructor.from_openai(
        OpenAI(
            base_url="https://integrate.api.nvidia.com/v1",
            api_key=api_key
        ),
        mode=instructor.Mode.MD_JSON
    )

    image_data_uri = encode_image_to_data_uri(image_path)

    prompt = (
        "Analyse cette fiche de surveillance de la grossesse avec attention, en prêtant une attention particulière à l'écriture manuscrite.\n\n"
        "Pour chaque champ extrait, attribue STRICTEMENT l'un des statuts suivants :\n"
        "- CONNU : Le texte est lisible et extrait avec certitude.\n"
        "- ILLISIBLE : Du texte manuscrit est présent mais impossible à déchiffrer avec certitude.\n"
        "- NON_FOURNI : Le champ ou la case est totalement vide.\n"
        "- INCONNU : Le formulaire indique explicitement une valeur inconnue (ex: '?', 'Inconnu', 'N/S').\n"
        "- NON_APPLICABLE : Le champ a été barré, biffé ou ne s'applique pas au dossier.\n\n"
        "Ne renvoie jamais de valeur 'null' dans les chaînes de texte si un champ est 'NON_FOURNI' ou 'ILLISIBLE' : laisse le champ 'extracted_text' à null ou met 'Illisible'."
    )

    result = client.chat.completions.create(
        model="meta/llama-3.2-90b-vision-instruct",
        response_model=DocumentExtractionResult,
        max_retries=0,
        messages=[
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {
                        "type": "image_url",
                        "image_url": {"url": image_data_uri}
                    }
                ]
            }
        ],
        temperature=0.0
    )
    return result


if __name__ == "__main__":
    # Teste aussi bien sur .png que sur .jpg / .jpeg
    target_image = "data/dossiers_specimen_10_patientes-17__1JAXyAcTm1.png"

    if not os.path.exists(target_image):
        print(f"Erreur : L'image '{target_image}' est introuvable.")
    else:
        print(f"Extraction en cours sur : {target_image}...\n")
        try:
            extraction_result = extract_with_nvidia_vlm(target_image)
            print("================ Résultat Extrait Réel ================")
            print(extraction_result.model_dump_json(indent=2))
        except Exception as e:
            print(f"Erreur durant l'extraction : {e}")