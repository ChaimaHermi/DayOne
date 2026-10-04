import uuid
from typing import List, Dict
from schemas.enums import RecordLifecycleState

class OfflineQueueManager:
    def __init__(self):
        self.queue: List[Dict] = []

    def enqueue_image(self, image_path: str) -> str:
        record_id = str(uuid.uuid4())
        record = {
            "record_id": record_id,
            "image_path": image_path,
            "state": RecordLifecycleState.PENDING_AI,
            "extracted_data": None
        }
        self.queue.append(record)
        return record_id

    def update_state(self, record_id: str, new_state: RecordLifecycleState, data=None):
        for record in self.queue:
            if record["record_id"] == record_id:
                record["state"] = new_state
                if data:
                    record["extracted_data"] = data
                break