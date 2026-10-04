from schemas.document import ExtractedDocumentData

class ReviewManagerService:
    @staticmethod
    def generate_interactive_summary(extracted_data: ExtractedDocumentData) -> dict:
        summary_text = f"Page detectee : {extracted_data.page_type.value}\n"
        summary_text += f"Confiance : {int(extracted_data.confidence_score * 100)}%\n\n"
        
        needs_review_questions = []

        if extracted_data.couverture:
            cov = extracted_data.couverture
            summary_text += f"- N° Fiche : {cov.num_fiche or 'Non fourni'}\n"
            summary_text += f"- Etablissement : {cov.nom_etablissement or 'Non fourni'}\n"
            summary_text += f"- Type : {cov.type_etablissement.value}\n"
            summary_text += f"- Mode couverture : {cov.mode_couverture.value}\n"
            summary_text += f"- Grossesse a risque : {'Oui' if cov.grossesse_classee_a_risque else 'Non'}\n"
            
            if cov.grossesse_classee_a_risque and cov.types_risque:
                summary_text += f"  Risques : {', '.join([r.value for r in cov.types_risque])}\n"

        elif extracted_data.antecedents:
            ant = extracted_data.antecedents
            summary_text += f"- Age : {ant.age or 'Non fourni'}\n"
            summary_text += f"- CIN : {ant.cin or 'Non fourni'}\n"
            summary_text += f"- Adresse : {ant.adresse or 'Non fourni'}\n"

        if extracted_data.champs_a_reviser:
            summary_text += "\nChamps a confirmer :\n"
            for champ in extracted_data.champs_a_reviser:
                summary_text += f"- {champ}\n"
                needs_review_questions.append(f"Veuillez valider la valeur pour '{champ}' :")

        return {
            "message_text": summary_text,
            "actions": [
                {"id": "confirm", "label": "Confirmer"},
                {"id": "edit", "label": "Corriger"},
                {"id": "retake", "label": "Reprendre la photo"}
            ],
            "questions": needs_review_questions
        }