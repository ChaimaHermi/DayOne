from typing import List, Optional
from schemas.document import DocumentExtractionResult
from schemas.verification import ExtractionResponse, QuestionSuivi, CorrectionChamp

class VerificationService:
    SEUIL_CONFIANCE_MIN: float = 0.85

    @classmethod
    def preparer_reponse_extraction(
        cls, 
        result: Optional[DocumentExtractionResult], 
        patient_id: Optional[str] = None,
        ia_disponible: bool = True
    ) -> ExtractionResponse:
        if not ia_disponible or result is None:
            return ExtractionResponse(
                patient_id=None,
                extraction_data=None,
                doute_detecte=True,
                questions=[
                    QuestionSuivi(
                        field_label="SYSTEME",
                        message="Service d'extraction IA indisponible. Veuillez utiliser le formulaire manuel."
                    )
                ],
                champs_a_verifier=[]
            )

        questions: List[QuestionSuivi] = []
        champs_a_verifier: List[str] = []

        if hasattr(result, "fields") and result.fields:
            for field in result.fields:
                label = field.field_label
                status = field.status
                score = field.confidence_score
                value = field.extracted_text

                if status == "ILLISIBLE":
                    questions.append(
                        QuestionSuivi(
                            field_label=label,
                            message=f"Le champ '{label}' est illisible."
                        )
                    )
                    champs_a_verifier.append(label)

                elif status == "CONNU" and score < cls.SEUIL_CONFIANCE_MIN:
                    questions.append(
                        QuestionSuivi(
                            field_label=label,
                            message=f"Incertitude sur le champ '{label}'.",
                            valeur_suggeree=value
                        )
                    )
                    champs_a_verifier.append(label)

                elif status == "NON_FOURNI":
                    champs_a_verifier.append(label)

        doute_present = len(questions) > 0 or len(champs_a_verifier) > 0

        return ExtractionResponse(
            patient_id=patient_id,
            extraction_data=result,
            doute_detecte=doute_present,
            questions=questions,
            champs_a_verifier=champs_a_verifier
        )

    @classmethod
    def appliquer_corrections(
        cls, 
        result: DocumentExtractionResult, 
        corrections: List[CorrectionChamp]
    ) -> DocumentExtractionResult:
        dict_corrections = {c.field_label.lower(): c.nouvelle_valeur for c in corrections}

        if hasattr(result, "fields") and result.fields:
            for field in result.fields:
                if field.field_label.lower() in dict_corrections:
                    field.extracted_text = dict_corrections[field.field_label.lower()]
                    field.status = "CONNU"
                    field.confidence_score = 1.0

        return result