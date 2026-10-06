import json
from datetime import datetime, date
from typing import Any


class CustomJSONEncoder(json.JSONEncoder):
    def default(self, obj: Any) -> Any:
        if isinstance(obj, (datetime, date)):
            return obj.isoformat()
        return super().default(obj)


def to_json_serializable(data: Any) -> Any:
    return json.loads(json.dumps(data, cls=CustomJSONEncoder))
