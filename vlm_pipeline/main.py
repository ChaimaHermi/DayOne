import os
import base64
from typing import Optional
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from schemas.document import DocumentExtractionResult
from schemas.verification import (
    ActionUtilisateur, 
    ExtractionResponse, 
    VerificationRequest, 
    VerificationResponse
)
from services.vlm_extractor import VLMExtractorService
from services.verification_service import VerificationService

app = FastAPI(title="API Pipeline VLM - Backend Mobile")

# Configuration CORS pour autoriser les requetes depuis Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

API_KEY = os.getenv("NVIDIA_API_KEY")
vlm_service = VLMExtractorService(api_key=API_KEY) if API_KEY else None


def extract_patient_id(extraction_result: DocumentExtractionResult) -> Optional[str]:
    if getattr(extraction_result, "cin", None):
        return extraction_result.cin

    if getattr(extraction_result, "number_fiche", None):
        return extraction_result.number_fiche

    if hasattr(extraction_result, "fields") and extraction_result.fields:
        labels = ["cni", "cin", "n° de la fiche", "numéro de suivi", "identifiant", "n° fiche", "numero fiche"]
        for field in extraction_result.fields:
            label = getattr(field, "field_label", "") or ""
            if any(term in label.lower() for term in labels):
                extracted_text = getattr(field, "extracted_text", None)
                if extracted_text and getattr(field, "status", "") == "CONNU":
                    return extracted_text

    return None


@app.post("/api/extract", response_model=ExtractionResponse)
async def extract_document(file: UploadFile = File(...)):
    if not vlm_service:
        return VerificationService.preparer_reponse_extraction(
            result=None, ia_disponible=False
        )

    try:
        contents = await file.read()
        encoded_string = base64.b64encode(contents).decode("utf-8")
        mime_type = file.content_type or "image/jpeg"
        image_b64 = f"data:{mime_type};base64,{encoded_string}"

        extraction_result = vlm_service.process_page_image(image_b64)
        patient_id = extract_patient_id(extraction_result)

        return VerificationService.preparer_reponse_extraction(
            result=extraction_result,
            patient_id=patient_id,
            ia_disponible=True
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur d'extraction: {str(e)}")


@app.post("/api/verify", response_model=VerificationResponse)
async def verify_document(payload: VerificationRequest):
    action = payload.action

    if action == ActionUtilisateur.CONFIRMER:
        return VerificationResponse(
            status="CONFIRME",
            message="Document valide et prêt pour le stockage.",
            final_data=payload.extraction_data
        )

    elif action == ActionUtilisateur.CORRIGER:
        data_corrigee = VerificationService.appliquer_corrections(
            payload.extraction_data, payload.corrections or []
        )
        return VerificationResponse(
            status="CORRIGE",
            message="Corrections appliquees avec succes.",
            final_data=data_corrigee
        )

    elif action == ActionUtilisateur.REPRENDRE_PHOTO:
        return VerificationResponse(
            status="REJETEE",
            message="Reprise de photo requise."
        )

    elif action == ActionUtilisateur.SAISIE_MANUELLE:
        return VerificationResponse(
            status="MANUEL",
            message="Basculement en saisie manuelle."
        )

if __name__ == "__main__":
    import uvicorn
    # Le port 8000 sur 0.0.0.0 rend le serveur accessible au reseau local et aux emulateurs
    uvicorn.run(app, host="0.0.0.0", port=8000)