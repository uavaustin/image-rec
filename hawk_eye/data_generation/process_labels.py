#!/usr/bin/env python3

import argparse
import csv
import pathlib
import json
import shutil
import tempfile

from hawk_eye.data_generation import generate_config
from hawk_eye.data_generation import create_detection_data


def parse_labels(
    image_dir: pathlib.Path,
    save_dir: pathlib.Path,
    csv_path: pathlib.Path,
    val_percent: int,
):
    save_dir = save_dir / "images"
    save_dir.mkdir(exist_ok=True, parents=True)
    with open(csv_path, newline="") as csvfile:
        spamreader = csv.reader(csvfile, delimiter=" ", quotechar="|")
        # First get a list of all the images
        images = []
        for row in spamreader:
            vals = row[0].split(",")
            images.append(vals[-3])
        images = sorted(images)

    with open(csv_path, newline="") as csvfile:
        spamreader = csv.reader(csvfile, delimiter=" ", quotechar="|")

        for row in spamreader:
            vals = row[0].split(",")
            original_tile_path = image_dir / vals[-3]
            tile_save_path = save_dir / vals[-3]
            tile_json = (tile_save_path).with_suffix(".json")
            class_name = vals[0]
            x1, y1, w, h = vals[1:5]
            img_w, img_h = vals[-2], vals[-1]
            label = {
                "bboxes": [
                    {
                        "class_id": generate_config.SHAPE_TYPES.index(class_name),
                        "x1": float(x1) / float(img_w),
                        "y1": float(y1) / float(img_h),
                        "w": float(w) / float(img_w),
                        "h": float(h) / float(img_h),
                    },
                ],
                "image_id": images.index(original_tile_path.name),
            }
            tile_json.write_text(json.dumps(label, indent=2))
            shutil.copy2(original_tile_path, tile_save_path)

    # Split the data into the proper split.
    with tempfile.TemporaryDirectory() as d:
        tmp_train = pathlib.Path(d) / "train"
        tmp_train.mkdir()
        tmp_val = pathlib.Path(d) / "val"
        tmp_val.mkdir()
        val_num = int(len(images) * val_percent / 100)
        val_imgs = images[:val_num]
        train_imgs = images[val_num:]
        for img in val_imgs:
            shutil.copy2(image_dir / img, tmp_val / img)
            shutil.copy2(
                (image_dir / img).with_suffix(".json"),
                (tmp_val / img).with_suffix(".json"),
            )
            print(img)

        for img in train_imgs:
            shutil.copy2(image_dir / img, tmp_train / img)
            shutil.copy2(
                (image_dir / img).with_suffix(".json"),
                (tmp_train / img).with_suffix(".json"),
            )

        create_detection_data.create_coco_metadata(
            tmp_train, save_dir.parent / "train_coco.json", img_ext=".JPG"
        )
        create_detection_data.create_coco_metadata(
            tmp_val, save_dir.parent / "val_coco.json", img_ext=".JPG"
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--image_dir",
        type=pathlib.Path,
        required=False,
        help="Path to directory of tiles that were labeled.",
    )
    parser.add_argument(
        "--save_dir",
        type=pathlib.Path,
        required=True,
        help="Path to directory in which to store sliced images.",
    )
    parser.add_argument(
        "--csv_path",
        type=pathlib.Path,
        required=True,
        help="Path to the csv outputted from labeling app.",
    )
    parser.add_argument(
        "--val_percent",
        type=int,
        help="Fraction of data to use for validation.",
        default=20,
    )
    args = parser.parse_args()

    parse_labels(args.image_dir, args.save_dir, args.csv_path, args.val_percent)
