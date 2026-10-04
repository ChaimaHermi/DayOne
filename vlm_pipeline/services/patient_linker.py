from typing import Dict, List, Optional
from schemas.document import DocumentExtractionResult

class PatientLinkerService:
    def __init__(self):
        self.patient_records: Dict[str, List[DocumentExtractionResult]] = {}

    def extract_patient_id(self, extraction: DocumentExtractionResult) -> Optional[str]:
        if extraction.number_fiche and extraction.number_fiche.strip():
            return extraction.number_fiche.strip()
        if extraction.cin and extraction.cin.strip():
            return f"CIN_{extraction.cin.strip()}"
        if extraction.nom_parturiente and extraction.nom_parturiente.strip():
            return f"PATIENTE_{extraction.nom_parturiente.strip()}"
        return None

    def link_page_to_profile(self, extraction: DocumentExtractionResult) -> str:
        pid = self.extract_patient_id(extraction)
        
        if not pid:
            pid = "DOSSIER_NON_IDENTIFIE"

        if pid not in self.patient_records:
            self.patient_records[pid] = []
            action_status = f"[NOUVEAU_DOSSIER] Patiente / Fiche : {pid}"
        else:
            action_status = f"[PAGE_AJOUTEE] Dossier {pid} - Total pages : {len(self.patient_records[pid]) + 1}"

        self.patient_records[pid].append(extraction)
        return action_status

    def get_patient_summary(self) -> Dict[str, int]:
        """Renvoie le bilan du nombre de pages par dossier."""
        return {pid: len(docs) for pid, docs in self.patient_records.items()}