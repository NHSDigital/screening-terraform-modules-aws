locals {
  single_alarm_name          = format("%s-alarm", module.this.id)
  multi_dimension_alarm_name = format("%s-multi-alarm", module.this.id)
}
