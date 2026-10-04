import os
import glob
import base64
from services.vlm_extractor import VLMExtractorService
from services.review_manager import ReviewManagerService
from services.patient_linker import PatientLinkerService


def encode_image_to_base64(image_path: str) -> str:
    with open(image_path, "rb") as image_file:
        encoded = base64.b64encode(image_file.read()).decode('utf-8')
        return f"data:image/jpeg;base64,{encoded}"


if __name__ == "__main__":
    api_key = os.getenv("NVIDIA_API_KEY") or os.getenv("OPENAI_API_KEY", "votre-cle-api")
    
    extractor = VLMExtractorService(
        api_key=api_key,
        model_name="meta/llama-3.2-11b-vision-instruct",
        base_url="https://integrate.api.nvidia.com/v1"
    )
    linker = PatientLinkerService()

    image_paths = sorted(
        glob.glob("data/*.jpg") + glob.glob("data/*.jpeg") + glob.glob("data/*.png")
    )
    
    if not image_paths:
        print("[AVERTISSEMENT] Aucune image trouvee dans le dossier data/.")
        exit(0)

    print(f"Lancement du test par lot sur {len(image_paths)} image(s)...\n")

    for path in image_paths:
        print("=" * 60)
        print(f"Traitement de : {path}")
        print("=" * 60)
        
        try:
            img_b64 = encode_image_to_base64(path)
            
            resultat = extractor.process_page_image(img_b64)
            
            status_liaison = linker.link_page_to_profile(resultat)
            print(f"\nStatut Liaison : {status_liaison}")

            recap = ReviewManagerService.generate_interactive_summary(resultat)
            print("\n[Resume UI / Chat] :")
            print(recap["message_text"])

        except Exception as e:
            print(f"[ERREUR] Lors du traitement de {path} : {e}")

    print("\n" + "#" * 60)
    print("BILAN LONGITUDINAL DES PATIENTES")
    print("#" * 60)
    summary = linker.get_patient_summary()
    for pid, count in summary.items():
        print(f"- Dossier [{pid}] : {count} page(s) enregistree(s)")