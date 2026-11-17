## STAGE 2: REAL HARDWARE. Door reed switch on Servo S3, PIR on Servo S2.
## Boolean Board (xc7s50csga324-1). Pin names taken from the Real Digital master XDC.
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## 100 MHz clock
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

## Buttons: btn[3] = reset, btn[0] = RFID scan
set_property -dict {PACKAGE_PIN J1 IOSTANDARD LVCMOS33} [get_ports rst_btn]
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports rfid_btn]

## Window sensor (simulated by slide switch sw[1]; up = window open)
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports window_sw]

## On-board LEDs: led[0]=lights, led[1]=AC, led[2]=standby warning, led[3]=PIR fault
set_property -dict {PACKAGE_PIN G1 IOSTANDARD LVCMOS33} [get_ports lights_led]
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS33} [get_ports ac_led]
set_property -dict {PACKAGE_PIN F1 IOSTANDARD LVCMOS33} [get_ports warn_led]
set_property -dict {PACKAGE_PIN F2 IOSTANDARD LVCMOS33} [get_ports fault_led]

## Relay outputs on Servo headers S0 and S1 (signal pins)
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports lights_relay]
set_property -dict {PACKAGE_PIN M16 IOSTANDARD LVCMOS33} [get_ports ac_relay]

## 7-segment display 0 (right group). seg[0]=a ... seg[6]=g, seg[7]=decimal point
set_property -dict {PACKAGE_PIN D7 IOSTANDARD LVCMOS33} [get_ports {seg[0]}]
set_property -dict {PACKAGE_PIN C5 IOSTANDARD LVCMOS33} [get_ports {seg[1]}]
set_property -dict {PACKAGE_PIN A5 IOSTANDARD LVCMOS33} [get_ports {seg[2]}]
set_property -dict {PACKAGE_PIN B7 IOSTANDARD LVCMOS33} [get_ports {seg[3]}]
set_property -dict {PACKAGE_PIN A7 IOSTANDARD LVCMOS33} [get_ports {seg[4]}]
set_property -dict {PACKAGE_PIN D6 IOSTANDARD LVCMOS33} [get_ports {seg[5]}]
set_property -dict {PACKAGE_PIN B5 IOSTANDARD LVCMOS33} [get_ports {seg[6]}]
set_property -dict {PACKAGE_PIN A6 IOSTANDARD LVCMOS33} [get_ports {seg[7]}]
set_property -dict {PACKAGE_PIN D5 IOSTANDARD LVCMOS33} [get_ports {an[0]}]
set_property -dict {PACKAGE_PIN C4 IOSTANDARD LVCMOS33} [get_ports {an[1]}]
set_property -dict {PACKAGE_PIN C7 IOSTANDARD LVCMOS33} [get_ports {an[2]}]
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports {an[3]}]

## Door reed switch: signal pin of Servo S3 (+ GND pin). Internal pull-up: open door = 1.
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33 PULLUP true} [get_ports door_sw]
## PIR OUT on the signal pin of Servo S2
set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS33} [get_ports pir_sensor]
