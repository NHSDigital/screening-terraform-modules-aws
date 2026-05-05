variable "name_prefix" {
  description = "the prefix standard"
  type        = string

}

variable "layer_name" {
  description = "The name of the Lambda layer"
  type        = string
}

variable "compatible_runtimes" {
  description = "Compatible Python runtimes for the Lambda layer"
  type        = list(string)
  default     = ["python3.12"]
}


variable "description" {
  description = "The description for the Lambda layer"
  type        = string
}

variable "source_path" {
  description = "The path of the stored layer zip file"
  type        = string
  default     = "../../layers"
}
