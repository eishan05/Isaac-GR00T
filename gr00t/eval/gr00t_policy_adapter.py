"""Server-side adapters for exposing Gr00t policies via the vla-client API."""

from typing import Any, Dict

from gr00t.model.policy import BasePolicy as Gr00tBasePolicy
from vla_client import base_policy as vla_base_policy


class Gr00tPolicyAdapter(vla_base_policy.BasePolicy):
    """Wrap a Gr00t policy instance to expose the vla-client policy API."""

    def __init__(self, policy: Gr00tBasePolicy) -> None:
        self._policy = policy

    def infer(self, obs: Dict[str, Any]) -> Dict[str, Any]:
        return self._policy.get_action(obs)

    def reset(self) -> None:
        reset_fn = getattr(self._policy, "reset", None)
        if callable(reset_fn):
            reset_fn()
