import os
import base64
from services.vlm_extractor import VLMExtractorService
from services.patient_linker import PatientLinkerService
from services.offline_queue import OfflineQueueManager
from schemas.enums import RecordLifecycleState

def encode_image_to_base64(image_path: str) -> str:
    with open(image_path, "rb") as image_file:
        encoded = base64.b64encode(image_file.read()).decode('utf-8')
        return f"data:image/jpeg;base64,{encoded}"

def main():
    api_key = os.getenv("NVIDIA_API_KEY") or os.getenv("OPENAI_API_KEY", "votre-cle-api")
    
    # Initialisation des services avec le bon nom de classe
    extractor = VLMExtractorService(
        api_key=api_key,
        model_name="meta/llama-3.2-11b-vision-instruct",
        base_url="https://integrate.api.nvidia.com/v1"
    )
    linker = PatientLinkerService()
    queue = OfflineQueueManager()

    test_images = [
        "data/1-1.jpg",
        "data/1-2.jpg",
        "data/1-4.jpg",
        "data/1-5.jpg",
        "data/dossiers_specimen_10_patientes-17__1JAXyAcTm1.png",
        "data/dossiers_specimen_10_patientes-18__1baIjVKeMw.png",
        "data/dossiers_specimen_10_patientes-19__1CnJAvJyYe.png",
        "data/dossiers_specimen_10_patientes-20__1Fe9vKiY1J.png",
        "data/dossiers_specimen_10_patientes-21__1uKoGpOPgd.png",
        "data/dossiers_specimen_10_patientes-22.png",
        "data/dossiers_specimen_10_patientes-23__1Ot9b8mqEv.png",
    ]

    for img_path in test_images:
        if not os.path.exists(img_path):
            print(f"[AVERTISSEMENT] Fichier non trouve : {img_path}")
            continue

        print(f"\n--- Traitement du fichier : {img_path} ---")
        
        # 1. Mise en file d'attente hors ligne
        rec_id = queue.enqueue_image(img_path)
        print(f"Enregistrement cree [{rec_id}] - Etat: {RecordLifecycleState.PENDING_AI.value}")

        # 2. Inference VLM via NVIDIA NIM
        try:
            img_b64 = encode_image_to_base64(img_path)
            extraction_result = extractor.process_page_image(img_b64)
            queue.update_state(rec_id, RecordLifecycleState.AI_PROCESSED, extraction_result)
            
            # 3. Liaison de la page au dossier longitudinal
            link_status = linker.link_page_to_profile(extraction_result)
            queue.update_state(rec_id, RecordLifecycleState.PATIENT_MATCHED)
            
            print(f"Statut de liaison : {link_status}")
            print("Extrait JSON partiel :")
            print(extraction_result.model_dump_json(indent=2, exclude_none=True))

        except Exception as e:
            print(f"[ERREUR] Pendant l'extraction de {img_path} : {e}")

if __name__ == "__main__":
    main()