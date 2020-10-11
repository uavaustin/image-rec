""" Contains various configuration settings used for unit testing with bazel. """

import pathlib
import re
import yaml

from data_generation.generate_config import *


# This is where we are going to store all the assets.
print(pathlib.Path(__file__).expanduser())
ASSETS_DIR = pathlib.Path("external").expanduser()
BACKGROUNDS_DIRS = [ASSETS_DIR / "backgrounds/backgrounds-v1"]

BASE_SHAPES_VERSION = ["v1"]
BASE_SHAPES_DIRS = [
    ASSETS_DIR / f"base_shapes/base-shapes-{v}" for v in BASE_SHAPES_VERSION
]

FONTS_URL = ASSETS_DIR / "fonts"
DATA_DIR = pathlib.Path(__file__).parent / "data"


ALPHA_FONT_DIR = ASSETS_DIR / "fonts"
ALPHA_FONTS = [
    ALPHA_FONT_DIR / "Rajdhani" / "Rajdhani-Bold.ttf",
    ALPHA_FONT_DIR / "Gudea" / "Gudea-Bold.ttf",
    ALPHA_FONT_DIR / "Inconsolata" / "Inconsolata-Bold.ttf",
    ALPHA_FONT_DIR / "Open_Sans" / "OpenSans-Bold.ttf",
    ALPHA_FONT_DIR / "Open_Sans" / "OpenSans-SemiBold.ttf",
    ALPHA_FONT_DIR / "News_Cycle" / "NewsCycle-Bold.ttf",
]

# Dataset images and splits
EMPTY_TILE_PROB = 0.0
DET_TRAIN_OFFSET = 0
DET_TRAIN_IMAGES = 10
DET_VAL_OFFSET = 0
DET_VAL_IMAGES = 5

CLF_OFFSET = 0
CLF_IMAGES = 10
CLF_VAL_FRACTION = 0.0
