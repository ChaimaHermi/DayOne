import base64
import mimetypes

def encode_image_to_data_uri(image_path: str) -> str:
    """Encode l'image en Base64 et construit le Data URI (PNG, JPG, WEBP)."""
    mime_type, _ = mimetypes.guess_type(image_path)
    if not mime_type:
        mime_type = "image/jpeg"

    with open(image_path, "rb") as image_file:
        encoded_string = base64.b64encode(image_file.read()).decode('utf-8')

    return f"data:{mime_type};base64,{encoded_string}"