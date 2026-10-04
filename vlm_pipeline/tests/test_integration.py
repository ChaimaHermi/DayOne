from schemas.document import DocumentExtractionResult
from services.patient_linker import PatientLinkerService
from schemas.enums import FieldStatus, LanguageDetected

def test_dynamic_patient_linking():
    linker = PatientLinkerService()

    # Simulation de l'arrivée de pages dans le désordre ou en quantité inconnue
    doc_page_1 = DocumentExtractionResult(patiente_fictive_id="1/10", nom_parturiente="Tazi Meryem")
    doc_page_3 = DocumentExtractionResult(patiente_fictive_id="1/10", document_type="Suivi Grossesse")
    doc_page_8 = DocumentExtractionResult(patiente_fictive_id="1/10", document_type="Post-partum Nouveau-né")
    doc_autre_patiente = DocumentExtractionResult(patiente_fictive_id="2/10", nom_parturiente="Ouazzani Khadjia")

    # Test des liaisons dynamiques
    assert "NOUVEAU" in linker.link_page_to_profile(doc_page_1)
    assert "AJOUTEE" in linker.link_page_to_profile(doc_page_3)
    assert "AJOUTEE" in linker.link_page_to_profile(doc_page_8)
    assert "NOUVEAU" in linker.link_page_to_profile(doc_autre_patiente)

    # Vérification que le dossier regroupe bien toutes les pages sans limite
    profil_meryem = linker.get_full_patient_profile("1/10")
    assert len(profil_meryem) == 3
    print("Test de liaison dynamique validé avec succès !")

if __name__ == "__main__":
    test_dynamic_patient_linking()