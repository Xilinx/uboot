#
# EDK BSP board generation for U-boot supporting Microblaze and PPC
#
# (C) Copyright 2007-2008 Michal Simek
#
# Michal SIMEK <monstr@monstr.eu>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307 USA
#
# Project description at http://www.monstr.eu/uboot/
#

# Globals variable
set version "U-BOOT v4.00.c"
set cpunumber 0
set periphery_array ""

proc uboot_drc {os_handle} {
	puts "\#--------------------------------------"
	puts "\# uboot BSP DRC...!"
	puts "\#--------------------------------------"
}

proc generate {os_handle} {
	generate_uboot $os_handle
}

# procedure post_generate
# This generates the drivers directory for uboot
# and runs the ltypes script

proc post_generate {lib_handle} {
}

proc generate_uboot {os_handle} {
	puts "\#--------------------------------------"
	puts "\# uboot BSP generate..."
	puts "\#--------------------------------------"

	# Open files and print GPL licence
	set config_file2 [open "config.mk" w]
	headerm $config_file2
	set config_file [open "xparameters.h" w]
	headerc $config_file

	set folder "[exec pwd]"
	set folder [string range $folder 0 [expr [string last "/" $folder] - 1]]
	set folder [string range $folder 0 [expr [string last "/" $folder] - 1]]
	set folder [string range $folder 0 [expr [string last "/" $folder] - 1]]
	set folder [exec basename $folder]
	puts $config_file "#define XILINX_BOARD_NAME\t$folder\n"

	# ******************************************************************************
	# print system clock
	set proc_handle [xget_libgen_proc_handle]
	set hwproc_handle [xget_handle $proc_handle "IPINST"]
	puts $config_file "/* System Clock Frequency */"
	puts $config_file "#define XILINX_CLOCK_FREQ\t[clock_val $hwproc_handle]\n"

	# Microblaze
	set hwproc_handle [xget_handle $proc_handle "IPINST"]
	set args [xget_hw_parameter_handle $hwproc_handle "*"]
	set proctype [xget_value $hwproc_handle "OPTION" "IPNAME"]
	switch $proctype {
		"microblaze" {
			# write only name of instance
			puts $config_file "/* Microblaze is [xget_hw_parameter_value $hwproc_handle "INSTANCE"] */"

			foreach arg $args {
				set arg_name [xget_value $arg "NAME"]
				set arg_name [string map -nocase {C_ ""} $arg_name]
				set arg_value [xget_value $arg "VALUE"]
				#	puts $config_file "DEBUG $arg_name $arg_value"
				switch $arg_name {
					USE_MSR_INSTR {
						puts $config_file "#define XILINX_USE_MSR_INSTR\t$arg_value"
					}
					FSL_LINKS {
						puts $config_file "#define XILINX_FSL_NUMBER\t$arg_value"
					}
					USE_ICACHE {
						if {[string match $arg_value "1"]} {
							puts $config_file "#define XILINX_USE_ICACHE\t$arg_value"
						}
					}
					#ICACHE_BASEADDR {
					#	puts $config_file "#define XILINX_ICACHE_BASEADDR\t$arg_value"
					#}
					#ICACHE_HIGHADDR {
					#	puts $config_file "#define XILINX_ICACHE_HIGHADDR\t$arg_value"
					#}
					USE_DCACHE {
						if {[string match $arg_value "1"]} {
							puts $config_file "#define XILINX_USE_DCACHE\t$arg_value"
						}
					}
					#DCACHE_BASEADDR {
					#	puts $config_file "#define XILINX_DCACHE_BASEADDR\t$arg_value"
					#}
					#DCACHE_HIGHADDR {
					#	puts $config_file "#define XILINX_DCACHE_HIGHADDR\t$arg_value"
					#}
					HW_VER {
						puts $config_file2 "PLATFORM_CPPFLAGS += -mcpu=v$arg_value"
					}
					USE_BARREL {
						if {[string match $arg_value "1"]} {
							puts $config_file2 "PLATFORM_CPPFLAGS += -mxl-barrel-shift"
						}
					}
					USE_DIV {
						if {[string match $arg_value "1"]} {
							puts $config_file2 "PLATFORM_CPPFLAGS += -mno-xl-soft-div"
						}
						#FIXME What is -mno-xl-hard-div
					}
					USE_HW_MUL {
						if {[string match $arg_value "1"]} {
							puts $config_file2 "PLATFORM_CPPFLAGS += -mno-xl-soft-mul"
						} else {
							puts $config_file2 "PLATFORM_CPPFLAGS += -mxl-soft-mul"
						}
						#FIXME What is -mxl-multiply-high???
					}
					USE_PCMP_INSTR {
						if {[string match $arg_value "1"]} {
							puts $config_file2 "PLATFORM_CPPFLAGS += -mxl-pattern-compare"
						}
					}
					USE_FPU {
						if {[string match $arg_value "1"]} {
							puts $config_file2 "PLATFORM_CPPFLAGS += -mhard-float"
						}
					}
					PVR {
						puts $config_file "#define XILINX_PVR\t\t$arg_value"
					}
					FAMILY {
					}
					default {}
				}
			}

			# OPB bus resolve
			set dopb [xget_handle $hwproc_handle "BUS_INTERFACE" "DOPB"]
			set dopb [xget_value $dopb "VALUE"]
			set iopb [xget_handle $hwproc_handle "BUS_INTERFACE" "IOPB"]
			set iopb [xget_value $iopb "VALUE"]
			if { $dopb == $iopb } {
				set system_bus "$dopb"
				puts "System bus for instruction and data $dopb"
				#testing
				#	set bus [xget_sw_parameter_value $os_handle "opb_v20"]
				##	set bus_handle [xget_sw_ipinst_handle_from_processor $proc_handle $bus]
				##	set hodn [xget_sw_parameter_value $bus_handle "C_EXT_RESET_HIGH"]
				#	puts "fdf $bus fds"
				#	set clk [xget_handle $dopb "PORT" "OPB_Clk"]
				#	puts "$clk"
				#	set clk [xget_value $clk "VALUE"]
				#	error "$clk"
				#end testing
			} else {
				error "different microblaze architecture - dual busses $iopb $dopb"
			}
			puts $config_file ""
			uboot_intc $os_handle $proc_handle $config_file $config_file2 $system_bus
		}
		"ppc405" -
		"ppc405_virtex4" -
		"ppc440_virtex5" {
			puts "unsupported processor type $proctype\n"
#			error "ERROR $proctype not supported by U-BOOT yet"
		}
		default {
			error "This type of CPU is not supported by U-BOOT yet"
		}
	}
	close $config_file
	close $config_file2
}

#function for handling adress
proc uboot_addr_hex {handle name} {
	return [format "0x%08x" [uboot_value $handle $name]]
}

proc uboot_value {handle name} {
	set addr [xget_sw_parameter_value "$handle" "$name"]
	if {![llength $addr]} {
		error "Request for undefined value [xget_hw_name $handle]:$name"
	}
	return $addr
}


proc uboot_intc {os_handle proc_handle config_file config_file2 system_bus} {
# ******************************************************************************
# Interrupt controler
	set intc_handle [get_handle_to_intc $proc_handle "Interrupt"]
	if {[string match "" $intc_handle] || [string match -nocase "none" $intc_handle]} {
		puts $config_file "/* Interrupt controller not defined */"
	} else {
		puts $config_file "/* Interrupt controller is [xget_hw_name $intc_handle] */"
#FIXME redesign test_buses - give name of buses from IP
		test_buses $system_bus $intc_handle "SOPB"
#		Interrupt controller address
		puts $config_file "#define XILINX_INTC_BASEADDR\t\t[uboot_addr_hex $intc_handle "C_BASEADDR"]"

		set intc_value [uboot_value $intc_handle "C_NUM_INTR_INPUTS"]
		puts $config_file "#define XILINX_INTC_NUM_INTR_INPUTS\t$intc_value"
		set intc_value [expr $intc_value - 1]

		set port_list [xget_port_by_subtype $intc_handle "*"]
		foreach port $port_list {
			set name [xget_value $port "NAME"]
			if {[string match -nocase $name "intr"]} {
				set intc_irq [xget_value $port "VALUE"]
#DEBUG				puts $config_file "/* pripojene interrupty $name=$intc_irq */"
				set intc_signals [split $intc_irq "&"]
#				split the signals
#				DEBUG	puts $config_file "$signals"
			}
		}
		puts $config_file ""
# ****************************************************************************
# Timer part
# handle timer if exists intc
		set timer [xget_sw_parameter_value $os_handle "timer"]
		if {[string match "" $timer] || [string match -nocase "none" $timer]} {
			puts $config_file "/* Timer not defined */"
		} else {
			set timer_handle [xget_sw_ipinst_handle_from_processor $proc_handle $timer]
			#test for correct system bus
			test_buses $system_bus $timer_handle "SOPB"
#			set timer_base [xget_sw_parameter_value $timer_handle "C_BASEADDR"]
#			set timer_end [xget_sw_parameter_value $timer_handle "C_HIGHADDR"]
#			set timer_base [format "0x%08x" $timer_base]
			puts $config_file "/* Timer pheriphery is $timer */"
			puts $config_file "#define XILINX_TIMER_BASEADDR\t[uboot_addr_hex $timer_handle "C_BASEADDR"]"

#			puts "$timer_handle $intc $intc_value $intc_signals Interrupt"
			set intr [get_intr $timer_handle $intc_handle $intc_value "Interrupt"]
			puts $config_file "#define XILINX_TIMER_IRQ\t$intr"
		}
		puts $config_file ""
	}
# ******************************************************************************
# UartLite driver - I suppose, only uartlite driver
	set uart [xget_sw_parameter_value $os_handle "stdout"]
	if {[string match "" $uart] || [string match -nocase "none" $uart]} {
		puts $config_file "/* Uart not defined */"
		puts "ERROR Uart not specified. Please specific console"
	} else {
		set uart_handle [xget_sw_ipinst_handle_from_processor $proc_handle $uart]
		puts $config_file "/* Uart pheriphery is $uart */"
		set type [xget_value $uart_handle "VALUE"]
		switch $type {
			"opb_uart16550" -
			"xps_uart16550" {
				puts $config_file "#define XILINX_UART16550"
				puts $config_file "#define XILINX_UART16550_BASEADDR\t[uboot_addr_hex $uart_handle "C_BASEADDR"]"
# find correct uart16550 frequency
				puts $config_file "#define XILINX_UART16550_CLOCK_HZ\t[clock_val $uart_handle]"
			}
			"opb_uartlite" -
			"xps_uartlite" -
			"opb_mdm" -
			"xps_mdm" {
				set args [xget_sw_parameter_handle $uart_handle "*"]
				foreach arg $args {
					set arg_name [xget_value $arg "NAME"]
					set arg_value [xget_value $arg "VALUE"]
					set arg_name [string map -nocase {C_ ""} $arg_name]
					case $arg_name in {
						"BASEADDR" {
							puts $config_file "#define XILINX_UARTLITE_${arg_name}\t$arg_value"
							set uart_base $arg_value
						}
						"BAUDRATE" {
							puts $config_file "#define XILINX_UARTLITE_${arg_name}\t$arg_value"
						}
						"HIGHADDR" {
							set uart_end $arg_value
						}
						default	{}
					}
				}
			}
			default {
				error "Unsupported type of console - $type"
			}
		}
	}
	puts $config_file ""
	# ******************************************************************************
	# IIC driver - I suppose, only uartlite driver
	set iic [xget_sw_parameter_value $os_handle "iic"]
	if {[string match "" $iic] || [string match -nocase "none" $iic]} {
		puts $config_file "/* IIC doesn't exist */"
	} else {
		set iic_handle [xget_sw_ipinst_handle_from_processor $proc_handle $iic]
		set iic_baseaddr [xget_sw_parameter_value $iic_handle "C_BASEADDR"]
		set iic_baseaddr [format "0x%08x" $iic_baseaddr]
		set iic_freq [xget_sw_parameter_value $iic_handle "C_IIC_FREQ"]
		set iic_bit [xget_sw_parameter_value $iic_handle "C_TEN_BIT_ADR"]
		puts $config_file "/* IIC pheriphery is $iic */"
		puts $config_file "#define XILINX_IIC_0_BASEADDR\t$iic_baseaddr"
		puts $config_file "#define XILINX_IIC_0_FREQ\t$iic_freq"
		puts $config_file "#define XILINX_IIC_0_BIT\t$iic_bit"
	}
	puts $config_file ""
	# ******************************************************************************
	# GPIO configuration
	set gpio [xget_sw_parameter_value $os_handle "gpio"]
	if {[string match "" $gpio] || [string match "none" $gpio]} {
		puts $config_file "/* GPIO doesn't exist */"
	} else {
		set base_param_name [format "C_BASEADDR" $gpio]
		set gpio_handle [xget_sw_ipinst_handle_from_processor $proc_handle $gpio]
		set gpio_base [xget_sw_parameter_value $gpio_handle $base_param_name]
		set gpio_base [format "0x%08x" $gpio_base]

		set gpio_end [xget_sw_parameter_value $gpio_handle "C_HIGHADDR"]
		set gpio_end [format "0x%08x" $gpio_end]

		puts $config_file "/* GPIO is $gpio*/"
		puts $config_file "#define XILINX_GPIO_BASEADDR\t$gpio_base"
	}
	puts $config_file ""
	# ******************************************************************************
	# System memory
	set main_mem [xget_sw_parameter_value $os_handle "main_memory"]
	if {[string match "" $main_mem] || [string match "none" $main_mem]} {
		puts "ERROR main_memory not specified. Please specific main_memory"
		puts $config_file "/* Main Memory doesn't exist */"
	} else {
		set main_mem_bank [xget_sw_parameter_value $os_handle "main_memory_bank"]
		set main_mem_handle [xget_sw_ipinst_handle_from_processor $proc_handle $main_mem]
		if {[string compare -nocase $main_mem_handle ""] != 0} {
			if {[xget_hw_value $main_mem_handle] == "mpmc"} {
				set base_param_name "C_MPMC_BASEADDR"
				set high_param_name "C_MPMC_HIGHADDR"
			} else {
				set base_param_name [format "C_MEM%i_BASEADDR" $main_mem_bank]
				set high_param_name [format "C_MEM%i_HIGHADDR" $main_mem_bank]
			}
			set eram_base [xget_sw_parameter_value $main_mem_handle $base_param_name]
			set eram_end [xget_sw_parameter_value $main_mem_handle $high_param_name]
			set eram_size [expr $eram_end - $eram_base + 1]
			set eram_base [format "0x%08x" $eram_base]
			set eram_size [format "0x%08x" $eram_size]
			set eram_high [expr $eram_base + $eram_size]
			set eram_high [format "0x%08x" $eram_high]
			puts $config_file "/* Main Memory is $main_mem */"
			puts $config_file "#define XILINX_RAM_START\t$eram_base"
			puts $config_file "#define XILINX_RAM_SIZE\t\t$eram_size"
		}
	}
	puts $config_file ""
	# ******************************************************************************
	# Flash memory
	set flash_mem [xget_sw_parameter_value $os_handle "flash_memory"]
	if {[string match "" $flash_mem] || [string match "none" $flash_mem]} {
		puts $config_file "/* FLASH doesn't exist $flash_mem */"
		puts "FLASH doesn't exists"
	} else {
		set flash_mem_handle [xget_sw_ipinst_handle_from_processor $proc_handle $flash_mem]
		set flash_mem_bank [xget_sw_parameter_value $os_handle "flash_memory_bank"]
		set flash_type [xget_hw_value $flash_mem_handle];
		puts $config_file "/* Flash Memory is $flash_mem */"

		# Handle different FLASHs differently
		switch -exact $flash_type {
			"xps_spi" {
				# SPI FLASH
				# Set the SPI FLASH's SPI controller's base address.
				set spi_start [xget_sw_parameter_value $flash_mem_handle "C_BASEADDR"]
				puts $config_file "#define XILINX_SPI_FLASH_BASEADDR\t$spi_start"
				# Set the SPI FLASH clock frequency
				set sys_clk [get_clock_frequency $flash_mem_handle "SPLB_CLK"]
				set sck_ratio [xget_sw_parameter_value $flash_mem_handle "C_SCK_RATIO"]
				set sck [expr { $sys_clk / $sck_ratio }]
				puts $config_file "#define XILINX_SPI_FLASH_MAX_FREQ\t$sck"
				# Set the SPI FLASH chip select
				global flash_memory_bank
				puts $config_file "#define XILINX_SPI_FLASH_CS\t$flash_memory_bank"
			}
			default {
				# Parallel Flash
				set base_param_name [format "C_MEM%i_BASEADDR" $flash_mem_bank]
				set high_param_name [format "C_MEM%i_HIGHADDR" $flash_mem_bank]
				set flash_start [xget_sw_parameter_value $flash_mem_handle $base_param_name]
				set flash_end [xget_sw_parameter_value $flash_mem_handle $high_param_name]
				set flash_size [expr $flash_end - $flash_start + 1]
				set flash_start [format "0x%08x" $flash_start]
				set flash_size [format "0x%08x" $flash_size]
				if {$eram_base < $flash_start} {
					puts $config_file "#define XILINX_FLASH_START\t$flash_start"
					puts $config_file "#define XILINX_FLASH_SIZE\t$flash_size"
				} else {
					error "Flash base address must be on higher address than ram memory"
				}
			}
		}
	}
	puts $config_file ""
	# ******************************************************************************
	# Sysace
	set sysace [xget_sw_parameter_value $os_handle "sysace"]
	if {[string match "" $sysace] || [string match "none" $sysace]} {
		puts $config_file "/* Sysace doesn't exist */"
	} else {
		puts $config_file "/* Sysace Controller is $sysace */"
		set sysace_handle [xget_sw_ipinst_handle_from_processor $proc_handle $sysace]
		set args [xget_sw_parameter_handle $sysace_handle "*"]
		foreach arg $args {
			set arg_name [xget_value $arg "NAME"]
			set arg_name [string map -nocase {C_ ""} $arg_name]
			set arg_value [xget_value $arg "VALUE"]
			switch $arg_name {
				"BASEADDR" {
					puts $config_file "#define XILINX_SYSACE_${arg_name}\t$arg_value"
					set sysace_base $arg_value
				}
				"MEM_WIDTH" {
					puts $config_file "#define XILINX_SYSACE_${arg_name}\t$arg_value"
				}
				"HIGHADDR" {
					set sysace_end $arg_value
				}
				"HW_VER" {
				}
				default {}
			}
		}
	}
	puts $config_file ""
	# ******************************************************************************
	# Ethernet
	set ethernet [xget_sw_parameter_value $os_handle "ethernet"]
	if {[string match "" $ethernet] || [string match -nocase "none" $ethernet]} {
		puts $config_file "/* Ethernet doesn't exist */"
	} else {
		set ethernet_handle [xget_sw_ipinst_handle_from_processor $proc_handle $ethernet]
		set ethernet_name [xget_value $ethernet_handle "VALUE"]
		puts $config_file "/* Ethernet controller is $ethernet */"

		switch $ethernet_name {
			"opb_ethernet" -
			"xps_ethernet" {
				set args [xget_sw_parameter_handle $ethernet_handle "*"]
				foreach arg $args {
					set arg_name [xget_value $arg "NAME"]
					set arg_value [xget_value $arg "VALUE"]
					set arg_name [string map -nocase {C_ ""} $arg_name]
#						{"MII_EXIST" "DMA_PRESENT" "HALF_DUPLEX_EXIST"} {
#							puts $config_file "#define XILINX_EMAC_${arg_name}\t$arg_value"
#						}
					case $arg_name in {
						"BASEADDR" {
							puts $config_file "#define XILINX_EMAC_${arg_name}\t$arg_value"
							set ethernet_base $arg_value
						}
#						"HIGHADDR" {
#							set ethernet_end $arg_value
#						}
						default {}
					}
				}
			}
			"xps_ll_temac" {
				puts $config_file "#define XILINX_LLTEMAC_BASEADDR\t\t\t[uboot_addr_hex $ethernet_handle "C_BASEADDR"]"
#get mhs_handle
				set mhs_handle [xget_hw_parent_handle $ethernet_handle]

				set bus_handle [xget_handle $ethernet_handle "BUS_INTERFACE" "LLINK0"]
				set bus_type [xget_hw_value $bus_handle]
				debug 8 "$bus_handle --$bus_type "
#initiator is ll_temac
#				set slave_ips [xget_hw_connected_busifs_handle $mhs_handle $bus_type "INITIATOR"]
#				puts "$slave_ips"
#target is mpmc
				set llink_bus [xget_hw_connected_busifs_handle $mhs_handle $bus_type "TARGET"]
				debug 8 "handle of mpmc bus is $llink_bus"
#name of bus interface
				set llink_name [xget_hw_name $llink_bus]
				debug 8 "Name of mpmc interface: $llink_name"
#get mpmc handle
				set llink_handle [xget_hw_parent_handle $llink_bus]

				set sdma [xget_sw_parameter_handle $llink_handle "C_SDMA_CTRL_BASEADDR"]
				if {[llength $sdma] != 0 } {
					set mpmc [xget_hw_name $llink_handle]
					debug 8 "mpmc is $mpmc"
#I need to separate number of interface
					set sdma_channel [string index "$llink_name" [expr [string length $llink_name] - 1]]
					set sdma_name [xget_value $sdma "NAME"]
					set sdma_name [string map -nocase {C_ ""} $sdma_name]
					set sdma_base [xget_value $sdma "VALUE"]
					debug 8 "$sdma_name $sdma_base"
#channel count
					set sdma_base [expr $sdma_base + [expr $sdma_channel * 0x80]]
					set sdma_base [format "0x%08x" $sdma_base] 
					puts $config_file "#define XILINX_LLTEMAC_${sdma_name}\t${sdma_base}"
				} else {
					set fifo [xget_sw_parameter_handle $llink_handle "C_BASEADDR"]
					if {[llength $fifo] != 0 } {
						set ll_fifo [xget_hw_name $llink_handle]
						debug 8 "ll_fifo is $ll_fifo, $fifo"
						set fifo_name [xget_value $fifo "NAME"]
						set fifo_name [string map -nocase {C_ ""} $fifo_name]
						set fifo_base [xget_value $fifo "VALUE"]
						debug 8 "$fifo_name $fifo_base"
						puts $config_file "#define XILINX_LLTEMAC_FIFO_${fifo_name}\t${fifo_base}"
					} else {
						error "your ll_temac is no connected properly"
					}
				}
			}
			"opb_ethernetlite" -
			"xps_ethernetlite" {
				set args [xget_sw_parameter_handle $ethernet_handle "*"]
				foreach arg $args {
					set arg_name [xget_value $arg "NAME"]
					set arg_value [xget_value $arg "VALUE"]
					set arg_name [string map -nocase {C_ ""} $arg_name]
					case $arg_name in {
						"BASEADDR" {
							puts $config_file "#define XILINX_EMACLITE_${arg_name}\t$arg_value"
						}
						{"TX_PING_PONG" "RX_PING_PONG"} {
							if { "$arg_value" == "1" } {
								puts $config_file "#define CONFIG_XILINX_EMACLITE_${arg_name}\t$arg_value"
							}
						}
						default {}
					}
				}
			}
			default {
				error "Unsupported ethernet periphery - $ethernet_name"
			}
		}
	}

	#*******************************************************************************
	# U-BOOT position in memory
# FIXME I think that generation via setting don't work corectly
	set text_base [xget_sw_parameter_value $os_handle "uboot_position"]
	set text_base [format "0x%08x" $text_base]
	puts $config_file2 ""
	if {$text_base == 0} {
		if {[llength $eram_base] != 0 } {
			set half [format "0x%08x" [expr $eram_high - 0x100000 ]]
			puts $config_file2 "TEXT_BASE = $half"
			puts "INFO automatic U-BOOT position = $half"
		} else {
			error "Main memory is not defined"
		}
	} else {
		if {$eram_base < $text_base && $eram_high > $text_base} {
			#			puts $config_file2 "# TEXT BASE "
			puts $config_file2 "TEXT_BASE = $text_base"
			puts $config_file2 ""
			# print system clock
			#	set sw [xget_sw_parameter_value $proc_handle "HW_INSTANCE"]
			# FIXME Parameters for Microblaze from MHS files
			# look at Microblaze SW manual
			# print microblaze params
			#	set hwproc_handle [xget_handle $proc_handle "IPINST"]
			#	set args [xget_hw_parameter_handle $hwproc_handle "*"]
			#	set proctype [xget_value $hwproc_handle "OPTION" "IPNAME"]
		} else {
			error "ERROR u-boot position is out of range $eram_base - $eram_high"
		}
	}
}

proc headerm {ufile} {
	variable version
	puts $ufile "\#"
	puts $ufile "\# (C) Copyright 2007-2008 Michal Simek"
	puts $ufile "\#"
	puts $ufile "\# Michal SIMEK <monstr@monstr.eu>"
	puts $ufile "\#"
	puts $ufile "\# This program is free software; you can redistribute it and/or"
	puts $ufile "\# modify it under the terms of the GNU General Public License as"
	puts $ufile "\# published by the Free Software Foundation; either version 2 of"
	puts $ufile "\# the License, or (at your option) any later version."
	puts $ufile "\#"
	puts $ufile "\# This program is distributed in the hope that it will be useful,"
	puts $ufile "\# but WITHOUT ANY WARRANTY; without even the implied warranty of"
	puts $ufile "\# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the"
	puts $ufile "\# GNU General Public License for more details."
	puts $ufile "\#"
	puts $ufile "\# You should have received a copy of the GNU General Public License"
	puts $ufile "\# along with this program; if not, write to the Free Software"
	puts $ufile "\# Foundation, Inc., 59 Temple Place, Suite 330, Boston,"
	puts $ufile "\# MA 02111-1307 USA"
	puts $ufile "\#"
	puts $ufile "\# CAUTION: This file is automatically generated by libgen."
	puts $ufile "\# Version: [xget_swverandbld]"
	puts $ufile "\# Generate by $version"
	puts $ufile "\# Project description at http://www.monstr.eu/uboot/"
	puts $ufile "\#"
	puts $ufile ""
}

proc headerc {ufile} {
	variable version
	puts $ufile "/*"
	puts $ufile " * (C) Copyright 2007-2008 Michal Simek"
	puts $ufile " *"
	puts $ufile " * Michal SIMEK <monstr@monstr.eu>"
	puts $ufile " *"
	puts $ufile " * This program is free software; you can redistribute it and/or"
	puts $ufile " * modify it under the terms of the GNU General Public License as"
	puts $ufile " * published by the Free Software Foundation; either version 2 of"
	puts $ufile " * the License, or (at your option) any later version."
	puts $ufile " *"
	puts $ufile " * This program is distributed in the hope that it will be useful,"
	puts $ufile " * but WITHOUT ANY WARRANTY; without even the implied warranty of"
	puts $ufile " * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the"
	puts $ufile " * GNU General Public License for more details."
	puts $ufile " *"
	puts $ufile " * You should have received a copy of the GNU General Public License"
	puts $ufile " * along with this program; if not, write to the Free Software"
	puts $ufile " * Foundation, Inc., 59 Temple Place, Suite 330, Boston,"
	puts $ufile " * MA 02111-1307 USA"
	puts $ufile " *"
	puts $ufile " * CAUTION: This file is automatically generated by libgen."
	puts $ufile " * Version: [xget_swverandbld]"
	puts $ufile " * Generate by $version"
	puts $ufile " * Project description at http://www.monstr.eu/uboot/"
	puts $ufile " */"
	puts $ufile ""
}


#test for peripheral - if is correct setting system bus
proc test_buses {system_bus handle bus_type} {
	set bus [xget_handle $handle "BUS_INTERFACE" $bus_type]
	if { [llength $bus] == 0 } {
		return 1
	}
	set bus [xget_value $bus "VALUE"]
	if { $bus != $system_bus} {
		error "Periphery $handle is connected to another system bus $bus ----"
		return 0
	} else {
		set name [xget_value $handle "NAME"]
		puts "$name has correct system_bus $system_bus"
	}
	return 1
}

proc get_intc_signals {intc} {
	set signals [split [xget_hw_port_value $intc "intr"] "&"]
	set intc_signals {}
	foreach signal $signals {
		lappend intc_signals [string trim $signal]
	}
	return $intc_signals
}

# Get interrupt number
proc get_intr {per_handle intc intc_value port_name} {
	if {![string match "" $intc] && ![string match -nocase "none" $intc]} {
		set intc_signals [get_intc_signals $intc]
		set port_handle [xget_hw_port_handle $per_handle "$port_name"]
		set interrupt_signal [xget_value $port_handle "VALUE"]
		set index [lsearch $intc_signals $interrupt_signal]
		if {$index == -1} {
			return -1
		} else {
			# interrupt 0 is last in list.
			return [expr [llength $intc_signals] - $index - 1]
		}
	} else {
		return -1
	}
}

proc clock_val {hw_handle} {
	set ipname [xget_hw_name $hw_handle]
	set ports [xget_hw_port_handle $hw_handle "*"]
	foreach port $ports {
		set sigis [xget_hw_subproperty_value $port "SIGIS"]
		if {[string toupper $sigis] == "CLK"} {
			set portname [xget_hw_name $port]
			# EDK doesn't compute clocks for ports that aren't connected.
			set connected_port [xget_hw_port_value $hw_handle $portname]
			if {[llength $connected_port] != 0} {
				set frequency [get_clock_frequency $hw_handle $portname]
				return "$frequency"
			}
		}
	}
	puts "Not find correct clock frequency"
}

#
#get handle to interrupt controller from CPU handle
#
proc get_handle_to_intc {proc_handle port_name} {
	#one CPU handle
	set hwproc_handle [xget_handle $proc_handle "IPINST"]
	#hangle to mhs file
	set mhs_handle [xget_hw_parent_handle $hwproc_handle]
	#get handle to interrupt port on Microblaze
	set intr_port [xget_value $hwproc_handle "PORT" $port_name]
	if { [llength $intr_port] == 0 } {
		puts "CPU has no connection to Interrupt controller"
		return
	}
	#	set sink_port [xget_hw_connected_ports_handle $mhs_handle $intr_port "sink"]
	#	set sink_name [xget_hw_name $sink_port]
	#get source port periphery handle - on interrupt controller
	set source_port [xget_hw_connected_ports_handle $mhs_handle $intr_port "source"]
	#get interrupt controller handle
	set intc [xget_hw_parent_handle $source_port]
	#	set name [xget_hw_name $intc]
	#	puts "$intc $name"
	return $intc
}


proc debug {level message} {
#	puts "$message"
}
