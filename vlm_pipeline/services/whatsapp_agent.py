from schemas.document import DocumentExtractionResult, FieldStatus


class WhatsAppAgentService:
    @staticmethod
    def render_verification_message(data: DocumentExtractionResult) -> str:
        """Génère le message interactif pour le flux WhatsApp (sans émojis)."""
        msg = "Donnees extraites de la page :\n"
        if data.number_fiche:
            msg += f"- N° Fiche/Code : {data.number_fiche}\n"
        if data.etablissement_sanitaire:
            msg += f"- Établissement : {data.etablissement_sanitaire}\n"

        msg += "\nDétail des champs :\n"
        doubtful_fields = []

        for field in data.fields:
            if field.status == FieldStatus.CONNU:
                msg += f"[VALIDE] {field.field_label} : {field.extracted_text}\n"
            elif field.status in [FieldStatus.ILLISIBLE, FieldStatus.A_REVISER] or field.confidence_score < 0.7:
                msg += f"[A REVISER] {field.field_label} : [Incertain / Illisible]\n"
                doubtful_fields.append(field)
            elif field.status == FieldStatus.NON_FOURNI:
                msg += f"[NON FOURNI] {field.field_label} : Non rempli\n"

        if doubtful_fields:
            msg += "\nL'IA a des doutes sur certains champs :\n"
            for df in doubtful_fields:
                msg += f"-> Pouvez-vous préciser la valeur pour : {df.field_label} ?\n"

        msg += "\n----------------------------------------"
        msg += "\nQue souhaitez-vous faire ?"
        msg += "\n1. Confirmer les données"
        msg += "\n2. Corriger un champ"
        msg += "\n3. Reprendre la photo"
        msg += "\n4. Saisie manuelle complète"

        return msg