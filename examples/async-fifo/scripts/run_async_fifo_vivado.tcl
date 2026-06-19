set script_dir [file dirname [file normalize [info script]]]
set demo_dir [file normalize [file join $script_dir ..]]
set run_dir [file normalize [file join $demo_dir build]]
set reports_dir [file join $run_dir reports]
file mkdir $reports_dir

set status_file [file join $reports_dir run_status.txt]
set status_fp [open $status_file w]
puts $status_fp "vivado_version: [version -short]"

set target_part "xc7a35tcsg324-1"
if {[llength [get_parts -quiet $target_part]] == 0} {
  set candidates [get_parts -quiet "xc7a35t*"]
  if {[llength $candidates] == 0} {
    puts $status_fp "target_part: unavailable"
    puts $status_fp "fatal: no xc7a35t candidate parts found"
    close $status_fp
    exit 1
  }
  set target_part [lindex $candidates 0]
}
puts $status_fp "target_part: $target_part"

create_project async_fifo_vivado [file join $run_dir project async_fifo_vivado] -part $target_part -force

add_files -fileset sources_1 [file join $demo_dir rtl async_fifo.v]
read_xdc [file join $demo_dir constraints async_fifo.xdc]
set_property top async_fifo [get_filesets sources_1]
update_compile_order -fileset sources_1

add_files -fileset sim_1 [file join $demo_dir tb tb_async_fifo.v]
set_property top tb_async_fifo [get_filesets sim_1]
set_property SOURCE_SET sources_1 [get_filesets sim_1]
set_property -name xsim.simulate.runtime -value all -objects [get_filesets sim_1]
update_compile_order -fileset sim_1

set sim_status "not-run"
if {[catch {
  launch_simulation -simset sim_1 -mode behavioral
  close_sim
  set sim_status "passed"
} sim_error]} {
  set sim_status "failed"
  puts $status_fp "simulation_error: $sim_error"
}
puts $status_fp "behavioral_simulation: $sim_status"

set synth_status "not-run"
if {[catch {
  synth_design -top async_fifo -part $target_part
  report_utilization -file [file join $reports_dir post_synth_utilization.rpt]
  report_timing_summary -file [file join $reports_dir post_synth_timing_summary.rpt]
  report_clocks -file [file join $reports_dir clocks.rpt]
  report_clock_interaction -file [file join $reports_dir clock_interaction.rpt]
  report_exceptions -file [file join $reports_dir exceptions.rpt]
  report_methodology -file [file join $reports_dir methodology.rpt]
  report_drc -file [file join $reports_dir drc.rpt]
  catch {report_cdc -file [file join $reports_dir cdc.rpt]} cdc_error
  if {[info exists cdc_error] && $cdc_error ne ""} {
    puts $status_fp "cdc_report_note: $cdc_error"
  }
  write_checkpoint -force [file join $reports_dir post_synth.dcp]
  set synth_status "passed"
} synth_error]} {
  set synth_status "failed"
  puts $status_fp "synthesis_error: $synth_error"
}
puts $status_fp "synthesis: $synth_status"

set implementation_status "not-run"
if {$synth_status eq "passed"} {
  if {[catch {
    opt_design
    place_design
    route_design
    report_route_status -file [file join $reports_dir route_status.rpt]
    report_timing_summary -file [file join $reports_dir post_route_timing_summary.rpt]
    report_utilization -file [file join $reports_dir post_route_utilization.rpt]
    report_methodology -file [file join $reports_dir post_route_methodology.rpt]
    report_drc -file [file join $reports_dir post_route_drc.rpt]
    report_clock_interaction -file [file join $reports_dir post_route_clock_interaction.rpt]
    write_checkpoint -force [file join $reports_dir post_route.dcp]
    set implementation_status "passed"
  } impl_error]} {
    set implementation_status "failed"
    puts $status_fp "implementation_error: $impl_error"
  }
}
puts $status_fp "implementation: $implementation_status"

close_project
close $status_fp

if {$sim_status ne "passed" || $synth_status ne "passed" || $implementation_status ne "passed"} {
  exit 1
}
exit 0
