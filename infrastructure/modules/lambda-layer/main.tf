# I've left it out as proof of concept but we could use the md5 of the lambda to trigger this only when something changes

# Notes: A complication with building lambda layers is getting to rebuild the image on every apply the suggested base64 method throws
# an error if the file does not exist, which it never will as we are creating it in the shell script.

# The basic setup here is that we generate a unique identifier (timestamp) then run a shell script from the layers/ dir
# containing a docker build script which once completed compresses the output into a zip file in the zips/ dir with a unique timestamp suffix.

# By doing this we don't have to put the base64 method in the layer resource which trys to execute on plan and fails as the file does not exist yet.
# We can instead target a fixed path with the unique suffix which we know will exist by the time we get to apply.

locals {
  file_suffix = timestamp() # unique for every apply
}

resource "null_resource" "build_lambda_layer" {
  # Re-run if the script changes
  triggers = {
    always_on = timestamp() # forces re-run every time
  }

  provisioner "local-exec" {
    command     = "${path.module}/${var.source_path}/${var.layer_name}.sh ${local.file_suffix}"
    working_dir = path.module
    quiet       = false
  }
}

resource "aws_lambda_layer_version" "this" {
  layer_name          = var.layer_name
  description         = var.description
  filename            = "${path.module}/zips/${var.layer_name}-${local.file_suffix}.zip"
  compatible_runtimes = ["python3.12"]
  depends_on          = [null_resource.build_lambda_layer]
}
