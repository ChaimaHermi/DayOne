import os
import glob
import base64
from services.vlm_extractor import VLMExtractorService
from services.review_manager import ReviewManagerService

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

    images = sorted(glob.glob("data/*.jpg") + glob.glob("data/*.jpeg") + glob.glob("data/*.png"))
    
    for img_path in images:
        print("=" * 60)
        print(f"--- Traitement de {img_path} ---")
        img_b64 = encode_image_to_base64(img_path)
        resultat = extractor.process_page_image(img_b64)
        
        recap = ReviewManagerService.generate_interactive_summary(resultat)
        print("\n[Resume UI / Chat] :")
        print(recap["message_text"])