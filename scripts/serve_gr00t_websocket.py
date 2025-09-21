"""Serve a GR00T policy over the vla-client websocket interface."""

from __future__ import annotations

import logging
import socket
from dataclasses import dataclass
from typing import Literal

import tyro

from gr00t.data.embodiment_tags import EMBODIMENT_TAG_MAPPING
from gr00t.data.schema import DatasetMetadata
from gr00t.eval.gr00t_policy_adapter import Gr00tPolicyAdapter
from gr00t.eval.websocket_policy_server import WebsocketPolicyServer
from gr00t.experiment.data_config import load_data_config
from gr00t.model.policy import Gr00tPolicy


@dataclass
class Args:
    """Command line arguments for serving a GR00T policy over websockets."""

    model_path: str = "nvidia/GR00T-N1.5-3B"
    """Path or HuggingFace ID for the GR00T model checkpoint."""

    embodiment_tag: Literal[tuple(EMBODIMENT_TAG_MAPPING.keys())] = "gr1"
    """Embodiment tag to select the correct metadata and transforms."""

    data_config: str = "fourier_gr1_arms_waist"
    """Data config name or import path used to build modality config and transforms."""

    denoising_steps: int | None = 4
    """Number of denoising steps for the action head. Use None to leave the default."""

    host: str = "0.0.0.0"
    """Interface to bind the websocket server to."""

    port: int = 8000
    """Port for the websocket server."""

    log_level: str = "INFO"
    """Logging level (e.g. INFO, DEBUG)."""


def _build_policy(args: Args) -> Gr00tPolicy:
    data_config = load_data_config(args.data_config)
    modality_config = data_config.modality_config()
    modality_transform = data_config.transform()

    return Gr00tPolicy(
        model_path=args.model_path,
        modality_config=modality_config,
        modality_transform=modality_transform,
        embodiment_tag=args.embodiment_tag,
        denoising_steps=args.denoising_steps,
    )


def _prepare_metadata(policy: Gr00tPolicy, args: Args) -> dict:
    metadata: dict[str, object] = {
        "model_path": args.model_path,
        "embodiment_tag": args.embodiment_tag,
        "modality_config": {
            name: config.model_dump(mode="json")
            for name, config in policy.get_modality_config().items()
        },
    }

    dataset_metadata = getattr(policy, "metadata", None)
    if isinstance(dataset_metadata, DatasetMetadata):
        metadata["dataset_metadata"] = dataset_metadata.model_dump(mode="json")

    return metadata


def main(args: Args) -> None:
    level = getattr(logging, args.log_level.upper(), logging.INFO)
    logging.basicConfig(level=level)

    policy = _build_policy(args)
    adapter = Gr00tPolicyAdapter(policy)

    policy_metadata = _prepare_metadata(policy, args)

    hostname = socket.gethostname()
    local_ip = socket.gethostbyname(hostname)
    logging.info("Starting websocket server (host: %s, ip: %s)", hostname, local_ip)

    server = WebsocketPolicyServer(
        policy=adapter,
        host=args.host,
        port=args.port,
        metadata=policy_metadata,
    )
    server.serve_forever()


if __name__ == "__main__":
    main(tyro.cli(Args))
