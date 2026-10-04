import os
from openai import OpenAI

api_key = os.environ.get("NVIDIA_API_KEY")
if not api_key:
    print("NVIDIA_API_KEY non trouvée.")
    exit(1)

client = OpenAI(
    base_url="https://integrate.api.nvidia.com/v1",
    api_key=api_key
)

try:
    models = client.models.list()
    print("--- Modèles disponibles pour cette clé ---")
    for m in models.data:
        if any(keyword in m.id.lower() for keyword in ["qwen", "vl", "vision"]):
            print(f"- {m.id}")
except Exception as e:
    print(f"Erreur lors du listing des modèles : {e}")