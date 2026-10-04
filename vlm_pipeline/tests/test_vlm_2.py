import os
import json
from enum import Enum
from io import BytesIO
from typing import List, Optional
from pydantic import BaseModel, Field
from PIL import Image
import ollama

# ==========================================
# 1. Définition des Schémas Pydantic
# ==========================================

class FieldStatus(str, Enum):
    VALID = "VALID"          
    UNCERTAIN = "UNCERTAIN"  
    MISSING = "MISSING"      

class LanguageDetected(str, Enum):
    FR = "FR"
    EN = "EN"
    AR = "AR"
    MIXED = "MIXED"

class ExtractedField(BaseModel):
    field_label: str = Field(description="Nom du champ (ex: N° de la fiche, Région, Province, Établissement)")
    extracted_text: Optional[str] = Field(description="Valeur lue sur le document")
    language: LanguageDetected = Field(description="Langue du texte extrait")
    status: FieldStatus = Field(description="Lisibilité du texte")
    confidence_score: float = Field(description="Confiance estimée entre 0.0 et 1.0", ge=0.0, le=1.0)

class DocumentExtractionResult(BaseModel):
    document_type: str = Field(description="Type de document (ex: Fiche de surveillance de la grossesse)")
    primary_language: LanguageDetected
    fields: List[ExtractedField]


# ==========================================
# 2. Utilitaire d'image
# ==========================================

def prepare_image_bytes(image_path: str, max_size=(1536, 1536)) -> bytes:
    with Image.open(image_path) as img:
        ##img.thumbnail(max_size, Image.Resampling.LANCZOS)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        buffered = BytesIO()
        img.save(buffered, format="JPEG", quality=95)
        return buffered.getvalue()


# ==========================================
# 3. Pipeline à Deux Étapes
# ==========================================

def step1_ocr_vlm(image_bytes: bytes) -> str:

    prompt = """
Observe cette fiche médicale.

Lis uniquement les champs suivants :
- numéro de fiche
- région
- province
- établissement sanitaire
- type d'établissement
- mode de couverture

Pour chaque champ :
- recopie uniquement ce qui est réellement visible ;
- si la valeur est absente, écris VIDE ;
- si tu ne peux pas la lire avec certitude, écris ILLISIBLE ;
- n'invente aucune valeur.

Ne transcris pas le reste de la page.
"""

    response = ollama.chat(
        model="qwen2.5vl:3b",
        messages=[
            {
                "role": "user",
                "content": prompt,
                "images": [image_bytes],
            }
        ],
        options={
            "temperature": 0,
            "num_predict": 128,
            "num_ctx": 4096,
        },
    )

    return response["message"]["content"].strip()


def step2_structure_json(raw_ocr_text: str) -> DocumentExtractionResult:
    """
    Étape 2 : Un SLM texte convertit la transcription brute en JSON Pydantic valide.
    """
    prompt = f"""Tu es un assistant d'extraction de données médicales.
À partir de la transcription brute suivante d'une fiche de surveillance de grossesse, extrais les informations et réponds UNIQUEMENT avec un objet JSON structuré respectant le schéma Pydantic fourni.

Transcription brute :
\"\"\"
{raw_ocr_text}
\"\"\"

Schéma JSON attendu :
{json.dumps(DocumentExtractionResult.model_json_schema(), indent=2)}
"""

    response = ollama.chat(
        model="qwen2.5:1.5b",  # Modèle texte rapide et stable pour le JSON
        messages=[{
            "role": "user",
            "content": prompt
        }],
        format="json",  # Imposition du format JSON sur le modèle texte
        options={
            "temperature": 0.0
        }
    )

    json_output = response['message']['content']
    return DocumentExtractionResult.model_validate_json(json_output)


def process_document(image_path: str) -> DocumentExtractionResult:
    print("-> [Étape 1/2] Extraction du texte brut via Qwen2.5-VL 3B...")
    img_bytes = prepare_image_bytes(image_path)
    raw_text = step1_ocr_vlm(img_bytes)
    print(f"\n--- Texte OCR brut extrait ---\n{raw_text}\n-------------------------------\n")

    print("-> [Étape 2/2] Structuration JSON via Qwen2.5 1.5B...")
    result = step2_structure_json(raw_text)
    return result


# ==========================================
# 4. Point d'entrée
# ==========================================

if __name__ == "__main__":
    target_image = "data/dossiers_specimen_10_patientes-17__1JAXyAcTm1.png"

    if not os.path.exists(target_image):
        print(f"Erreur : L'image '{target_image}' est introuvable.")
    else:
        print(f"Début de l'analyse du document : {target_image}\n")
        try:
            extraction_result = process_document(target_image)
            print("\n================ Résultat Structuré Final ================")
            print(extraction_result.model_dump_json(indent=2))
        except Exception as e:
            print(f"\nErreur durant le traitement : {e}")