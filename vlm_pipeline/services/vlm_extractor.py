import os
import instructor
from openai import OpenAI
from schemas.document import DocumentExtractionResult

PROMPT_SYSTEME_VLM = """
Tu es un moteur d'extraction OCR/VLM strict pour registre médical papier.
Ne génère AUCUNE introduction, AUCUN texte explicatif et AUCUN balisage Markdown.
Extrais les champs dans la structure JSON demandée.

Règles de conformité et confidentialité:
1. IGNORER et NE PAS STOCKER les identifiants directs (nom de la femme, nom du conjoint, téléphone, adresse).
2. Pour chaque champ, assigne le statut exact:
   - CONNU : texte lisible et extrait.
   - ILLISIBLE : écriture présente mais incertaine/dégradée.
   - NON_FOURNI : champ/case totalement vide.
   - NON_APPLICABLE : champ barré ou non pertinent.
3. Si le statut est ILLISIBLE ou NON_FOURNI, laisse 'extracted_text' à null.
"""

class VLMExtractorService:
    def __init__(
        self, 
        api_key: str, 
        model_name: str = "meta/llama-3.2-90b-vision-instruct",
        base_url: str = "https://integrate.api.nvidia.com/v1"
    ):
        self.raw_client = OpenAI(api_key=api_key, base_url=base_url)
        # Mode JSON strict pour éliminer le verbiage
        self.instructor_client = instructor.from_openai(
            self.raw_client,
            mode=instructor.Mode.JSON
        )
        self.model_name = model_name

    def process_page_image(self, image_base64_url: str) -> DocumentExtractionResult:
        result = self.instructor_client.chat.completions.create(
            model=self.model_name,
            response_model=DocumentExtractionResult,
            temperature=0.0,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": PROMPT_SYSTEME_VLM},
                        {"type": "image_url", "image_url": {"url": image_base64_url}}
                    ]
                }
            ]
        )
        return result