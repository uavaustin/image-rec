# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Repository rule for pulling a file from GCS bucket.
The rule uses gsutil tool installed in the system to download a file from a GCS bucket,
and make it available for other rules to use (e.g. container_image rule).
To install gsutil, please refer to:
  https://cloud.google.com/storage/docs/gsutil
You need to have read access to the GCS bucket.

# Extended by UAV for further usability.
"""

_GCS_FILE_BUILD = """
package(default_visibility = ["//visibility:public"])
filegroup(
    name = "file",
    srcs = glob(["**/*"]),
)
"""


def download_gcs_object(
    ctx,
    bucket,
    download_path,
    file,
    sha256,
    strip_prefix,
    output_dir,
    build_file_content = None
):
    if not build_file_content:
        build_file_content = _GCS_FILE_BUILD

    # Add a top-level BUILD file to export all the downloaded files.
    ctx.file("BUILD", build_file_content.format(download_path))

    # Create a bash script from a template.
    ctx.template(
        "gsutil_cp_and_validate.sh",
        Label("//third_party:gsutil_cp_and_validate.sh.tpl"),
        {
            "%{BUCKET}": bucket,
            "%{DOWNLOAD_PATH}": download_path,
            "%{FILE}": file,
            "%{SHA256}": sha256,
        },
    )

    gsutil_cp_and_validate_result = ctx.execute(["bash", "gsutil_cp_and_validate.sh"])
    if gsutil_cp_and_validate_result.return_code == 255:
        fail("SHA256 of file {} from bucket {} does not match given SHA256: {} {}".format(
            file,
            bucket,
            gsutil_cp_and_validate_result.stdout,
            gsutil_cp_and_validate_result.stderr,
        ))
    elif gsutil_cp_and_validate_result.return_code != 0:
        fail("gsutil cp command failed: %s" % (gsutil_cp_and_validate_result.stderr))

    rm_result = ctx.execute(["rm", "gsutil_cp_and_validate.sh"])

    if rm_result.return_code:
        fail("Failed to remove temporary file: %s" % rm_result.stderr)

    # Extract the downloaded archive.
    ctx.extract(download_path, output = output_dir, stripPrefix = strip_prefix)

def _gcs_file_impl(ctx):
    """Implementation of the gcs_file rule."""

    repo_root = ctx.path(".")
    forbidden_files = [
        repo_root,
        ctx.path("WORKSPACE"),
        ctx.path("BUILD"),
        ctx.path("BUILD.bazel"),
    ]
    downloaded_file_path = ctx.attr.downloaded_file_path or ctx.attr.file
    download_path = ctx.path(downloaded_file_path)
    if download_path in forbidden_files or not str(download_path).startswith(str(repo_root)):
        fail("'%s' cannot be used as downloaded_file_path in gcs_file" % ctx.attr.downloaded_file_path)

    download_gcs_object(
        ctx,
        ctx.attr.bucket,
        str(download_path),
        ctx.attr.file,
        ctx.attr.sha256,
        ctx.attr.strip_prefix,
        ctx.attr.output_dir,
    )


gcs_file = repository_rule(
    attrs = {
        "bucket": attr.string(
            mandatory = True,
            doc = "The GCS bucket which contains the file.",
        ),
        "downloaded_file_path": attr.string(
            doc = "Path assigned to the file downloaded.",
        ),
        "file": attr.string(
            mandatory = True,
            doc = "The file which we are downloading.",
        ),
        "sha256": attr.string(
            mandatory = True,
            doc = "The expected SHA-256 of the file downloaded.",
        ),
        "strip_prefix": attr.string(doc = "The contents of the build file for the target"),
        "output_dir": attr.string(doc = "Where to extract to."),
    },
    implementation = _gcs_file_impl,
)
