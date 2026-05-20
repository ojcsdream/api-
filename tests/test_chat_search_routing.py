import importlib.util
import sys
import types
import unittest
from unittest.mock import patch

if importlib.util.find_spec("fastapi") is None:
    class _FastAPI:
        def __init__(self, *args, **kwargs):
            pass

        def add_middleware(self, *args, **kwargs):
            pass

        def mount(self, *args, **kwargs):
            pass

        def get(self, *args, **kwargs):
            return lambda fn: fn

        def post(self, *args, **kwargs):
            return lambda fn: fn

        def delete(self, *args, **kwargs):
            return lambda fn: fn

    sys.modules.setdefault(
        "fastapi",
        types.SimpleNamespace(
            FastAPI=_FastAPI,
            UploadFile=object,
            File=lambda *args, **kwargs: None,
            Form=lambda default=None, *args, **kwargs: default,
            Depends=lambda fn=None, *args, **kwargs: fn,
            HTTPException=Exception,
        ),
    )
    sys.modules.setdefault(
        "fastapi.middleware.cors",
        types.SimpleNamespace(CORSMiddleware=object),
    )
    sys.modules.setdefault(
        "fastapi.responses",
        types.SimpleNamespace(
            FileResponse=object,
            StreamingResponse=lambda gen, *args, **kwargs: gen,
        ),
    )
    sys.modules.setdefault(
        "fastapi.staticfiles",
        types.SimpleNamespace(StaticFiles=lambda *args, **kwargs: object()),
    )

for module_name in ("chat_utils", "config", "db", "schemas"):
    module = sys.modules.get(module_name)
    if module is not None and not hasattr(module, "__file__"):
        sys.modules.pop(module_name, None)

import app


class ChatSearchRoutingTest(unittest.TestCase):
    def test_plain_followup_does_not_request_search_planning(self):
        history = [types.SimpleNamespace(role="user", content="介绍一下 Python")]

        with patch.object(app, "looks_like_search_request", return_value=False) as looks_like:
            self.assertFalse(
                app.should_autonomous_search_with_context(
                    "这个怎么用？",
                    history=history,
                    force=False,
                    allow_contextual_search=False,
                )
            )

        looks_like.assert_called_once_with("这个怎么用？")

    def test_explicit_current_followup_can_request_contextual_search(self):
        history = [types.SimpleNamespace(role="user", content="OpenAI")]

        self.assertTrue(
            app.should_autonomous_search_with_context(
                "它最近有什么新闻？",
                history=history,
                force=False,
                allow_contextual_search=True,
            )
        )

    def test_forced_search_still_wins(self):
        self.assertTrue(
            app.should_autonomous_search_with_context(
                "普通问题",
                history=[],
                force=True,
                allow_contextual_search=False,
            )
        )


if __name__ == "__main__":
    unittest.main()
