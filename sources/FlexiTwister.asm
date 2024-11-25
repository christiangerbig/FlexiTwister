; Requirements
; CPU:		68020+
; Fast-Memory:	-
; Chipset:	AGA PAL
; OS:		3.0+


; History/Changes

; V.1.0 beta
; - first release

; V.1.1 beta
; - direction change of the striped bar triggered by module
; - horizontal movement of the logo triggered by module
; - fading out improved

; V.1.2 beta
; - logo replaced with Optic's logo
; - all palettes changed
; - scroll text changed

; V.1.3 beta
; - Convert-Color-Table of the bar is already called at the inits, so that
;   the color values of the bar are displayed correctly at the beginning
; - background color is now 100% global and changed
; - code optimized
; - mouse handler: out-fader stops in-fader if necessary
; - bars equalizer is now more sensitive and reacts faster
; - with revised module

; V.1.4 beta
; - logo scroller optimized
; - fader optimized
; - init copper lists revised
; - with revised include files

; V.1.5 beta
; - with revised module
; - bugfix: Now the logo scrolls down when the scrolltext is inactive
; - CWAIT for BPL1DAT adapted
; - with Optic's logo, bar color of the 1st bar adjusted

; V.1.6 beta
; - with revised module
; - with revised Optic's logo
; - scroll text changes its color 4x
; - wait-Command for scrolltext
; - all color gradients adapted to 1st bar

; V.1.7 beta
; - scroll text colors changed
; - module revised
; - smaller font used

; V.1.8 beta
; - fx commands 861->870, 870->880
; - new Fx command 89n to select the audio channel (n=0..3) for the twister
; - scroll text now starts earlier together with the music
; - fx commands in module changed


; PT 8xy command
; 810	start Bar-Fader-In
; 820	start scroll text
; 830	start Scroll-Logo-Bottom-In
; 840	start Chunky-Columns-Fader-In
; 850	toggle Stripes Y-Movement
; 860	start Horiz-Logo-Scroll
; 870	stop Horiz-Logo-Scroll
; 880	restart scroll text
; 89n	select audio channel for twister

; COLOR00: 3 x 16 = 48 colors: bars, sprites (2nd color bank)
; COLOR00: 2 x 40 = 80 colors: striped bar
; COLOR01: 3 x 16 = 48 colors: bars, sprites (2nd color bank)
; COLOR01: 1 x 16 = 16 colors: color gradient scroll text centered

; Execution time 68020: ? raster lines


	SECTION code_and_variables,CODE

	MC68040


	INCDIR "Daten:include3.5/"

	INCLUDE "exec/exec.i"
	INCLUDE "exec/exec_lib.i"

	INCLUDE "dos/dos.i"
	INCLUDE "dos/dos_lib.i"
	INCLUDE "dos/dosextens.i"

	INCLUDE "graphics/gfxbase.i"
	INCLUDE "graphics/graphics_lib.i"
	INCLUDE "graphics/videocontrol.i"

	INCLUDE "intuition/intuition.i"
	INCLUDE "intuition/intuition_lib.i"

	INCLUDE "libraries/any_lib.i"

	INCLUDE "resources/cia_lib.i"

	INCLUDE "hardware/adkbits.i"
	INCLUDE "hardware/blit.i"
	INCLUDE "hardware/cia.i"
	INCLUDE "hardware/custom.i"
	INCLUDE "hardware/dmabits.i"
	INCLUDE "hardware/intbits.i"

	INCDIR "Daten:Asm-Sources.AGA/custom-includes/"


PROTRACKER_VERSION_3.0B	SET 1


	INCLUDE "macros.i"


	INCLUDE "equals.i"

requires_030_cpu		EQU FALSE
requires_040_cpu		EQU FALSE
requires_060_cpu		EQU FALSE
requires_fast_memory		EQU FALSE
requires_multiscan_monitor	EQU FALSE

workbench_start_enabled		EQU FALSE
screen_fader_enabled		EQU FALSE
text_output_enabled		EQU FALSE

open_border_enabled		EQU TRUE

pt_ciatiming_enabled		EQU TRUE
pt_finetune_enabled		EQU FALSE
pt_metronome_enabled		EQU FALSE
pt_mute_enabled			EQU FALSE
pt_track_volumes_enabled	EQU TRUE
pt_track_periods_enabled	EQU FALSE
pt_music_fader_enabled		EQU TRUE
pt_split_module_enabled		EQU TRUE
pt_usedfx			EQU %1111110100001000
pt_usedefx			EQU %0000100000000000

tb_quick_clear_enabled		EQU FALSE
tb_restore_cl_cpu_enabled	EQU TRUE
tb_restore_cl_blitter_enabled	EQU FALSE

cfc_rgb8_prefade_enabled	EQU TRUE

dma_bits			EQU DMAF_SPRITE|DMAF_BLITTER|DMAF_COPPER|DMAF_RASTER|DMAF_MASTER|DMAF_SETCLR

	IFEQ pt_ciatiming_enabled
intena_bits			EQU INTF_EXTER|INTF_INTEN|INTF_SETCLR
	ELSE
intena_bits			EQU INTF_VERTB|INTF_EXTER|INTF_INTEN|INTF_SETCLR
	ENDC

ciaa_icr_bits			EQU CIAICRF_SETCLR
	IFEQ pt_ciatiming_enabled
ciab_icr_bits			EQU CIAICRF_TA|CIAICRF_TB|CIAICRF_SETCLR
	ELSE
ciab_icr_bits			EQU CIAICRF_TB|CIAICRF_SETCLR
	ENDC

copcon_bits			EQU 0

pf1_x_size1			EQU 512
pf1_y_size1			EQU 256+112
pf1_depth1			EQU 1
pf1_x_size2			EQU 512
pf1_y_size2			EQU 256+112
pf1_depth2			EQU 1
pf1_x_size3			EQU 512
pf1_y_size3			EQU 256+112
pf1_depth3			EQU 1
pf1_colors_number		EQU 256

pf2_x_size1			EQU 0
pf2_y_size1			EQU 0
pf2_depth1			EQU 0
pf2_x_size2			EQU 0
pf2_y_size2			EQU 0
pf2_depth2			EQU 0
pf2_x_size3			EQU 0
pf2_y_size3			EQU 0
pf2_depth3			EQU 0
pf2_colors_number		EQU 0
pf_colors_number		EQU pf1_colors_number+pf2_colors_number
pf_depth			EQU pf1_depth3+pf2_depth3

pf_extra_number			EQU 0

spr_number			EQU 8
spr_x_size1			EQU 0
spr_x_size2			EQU 64
spr_depth			EQU 2
spr_colors_number		EQU 0	; 16
spr_odd_color_table_select	EQU 1
spr_even_color_table_select	EQU 1
spr_used_number			EQU 8

	IFD PROTRACKER_VERSION_2.3A 
audio_memory_size		EQU 0
	ENDC
	IFD PROTRACKER_VERSION_3.0B
audio_memory_size		EQU 2
	ENDC

disk_memory_size		EQU 0

chip_memory_size		EQU 0
	IFEQ pt_ciatiming_enabled
ciab_cra_bits			EQU CIACRBF_LOAD
	ENDC
ciab_crb_bits			EQU CIACRBF_LOAD|CIACRBF_RUNMODE ; Oneshot mode
ciaa_ta_time			EQU 0
ciaa_tb_time			EQU 0
	IFEQ pt_ciatiming_enabled
ciab_ta_time			EQU 14187 ; = 0.709379 MHz * [20000 µs = 50 Hz duration for one frame on a PAL machine]
;ciab_ta_time			EQU 14318 ; = 0.715909 MHz * [20000 µs = 50 Hz duration for one frame on a NTSC machine]
	ELSE
ciab_ta_time			EQU 0
	ENDC
ciab_tb_time			EQU 362 ; = 0.709379 MHz * [511.43 µs = Lowest note period C1 with Tuning=-8 * 2 / PAL clock constant = 907*2/3546895 ticks per second]
					; = 0.715909 MHz * [506.76 µs = Lowest note period C1 with Tuning=-8 * 2 / NTSC clock constant = 907*2/3579545 ticks per second]
ciaa_ta_continuous_enabled	EQU FALSE
ciaa_tb_continuous_enabled	EQU FALSE
	IFEQ pt_ciatiming_enabled
ciab_ta_continuous_enabled	EQU TRUE
	ELSE
ciab_ta_continuous_enabled	EQU FALSE
	ENDC
ciab_tb_continuous_enabled	EQU FALSE

beam_position			EQU $133 ; Wegen Module-Fader

pixel_per_line			EQU 336
visible_pixels_number		EQU 352
visible_lines_number		EQU 256
MINROW				EQU VSTART_256_LINES

pf_pixel_per_datafetch		EQU 16	; 1x
spr_pixel_per_datafetch		EQU 64	; 4x

display_window_hstart		EQU HSTART_44_CHUNKY_PIXEL
display_window_vstart		EQU MINROW
display_window_hstop		EQU HSTOP_352_pixel
display_window_vstop		EQU VSTOP_256_LINES

pf1_plane_width			EQU pf1_x_size3/8
data_fetch_width		EQU pixel_per_line/8
pf1_plane_moduli		EQU (pf1_plane_width*(pf1_depth3-1))+pf1_plane_width-data_fetch_width

diwstrt_bits			EQU ((display_window_vstart&$ff)*DIWSTRTF_V0)|(display_window_hstart&$ff)
diwstop_bits			EQU ((display_window_vstop&$ff)*DIWSTOPF_V0)|(display_window_hstop&$ff)
ddfstrt_bits			EQU DDFSTART_320_PIXEL
ddfstop_bits			EQU DDFSTOP_OVERSCAN_16_PIXEL
bplcon0_bits			EQU BPLCON0F_ECSENA|((pf_depth>>3)*BPLCON0F_BPU3)|(BPLCON0F_COLOR)|((pf_depth&$07)*BPLCON0F_BPU0)
bplcon1_bits			EQU 0
bplcon2_bits			EQU 0
bplcon3_bits1			EQU 0
bplcon3_bits2			EQU bplcon3_bits1|BPLCON3F_LOCT
bplcon4_bits			EQU (BPLCON4F_OSPRM4*spr_odd_color_table_select)|(BPLCON4F_ESPRM4*spr_even_color_table_select)
diwhigh_bits			EQU (((display_window_hstop&$100)>>8)*DIWHIGHF_HSTOP8)|(((display_window_vstop&$700)>>8)*DIWHIGHF_VSTOP8)|(((display_window_hstart&$100)>>8)*DIWHIGHF_HSTART8)|((display_window_vstart&$700)>>8)
fmode_bits			EQU FMODEF_SPR32|FMODEF_SPAGEM
color00_bits			EQU $000011
color255_bits			EQU color00_bits

cl2_display_x_size		EQU 352+8 ; 45 Spalten
cl2_display_width		EQU cl2_display_x_size/8
cl2_display_y_size		EQU visible_lines_number
	IFEQ open_border_enabled
cl2_hstart1			EQU (ddfstrt_bits*2)-(pf1_depth3*CMOVE_SLOT_PERIOD)
	ELSE
cl2_hstart1			EQU display_window_hstart-4
	ENDC
cl2_vstart1			EQU MINROW
cl2_hstart2			EQU $00
cl2_vstart2			EQU beam_position&$ff

sine_table_length		EQU 256

; Logo
lg_image_x_size			EQU 256
lg_image_plane_width		EQU lg_image_x_size/8
lg_image_y_size			EQU 54
lg_image_depth			EQU 4
lg_image_x_centre		EQU (visible_pixels_number-lg_image_x_size)/2

lg_image_x_position		EQU display_window_hstart+lg_image_x_centre+14
lg_image_y_position		EQU MINROW

; PT-Replay
pt_fade_out_delay		EQU 1	; Tick

; Volume-Meter
vm_period_divider		EQU 30
vm_max_period_step		EQU 4

; Twisted-Bars
tb_bars_number			EQU 3
tb_bar_height			EQU 32
tb_y_radius			EQU (visible_lines_number-tb_bar_height)/2
tb_y_centre			EQU (cl2_display_y_size-tb_bar_height)/2
tb_y_angle_step_radius		EQU 6
tb_y_angle_step_centre		EQU 3
tb_y_angle_step_step		EQU 1
tb_y_distance			EQU sine_table_length/tb_bars_number

; Clear-Blit
tb_clear_blit_x_size		EQU 16
	IFEQ open_border_enabled
tb_clear_blit_y_size		EQU cl2_display_y_size*(cl2_display_width+2)
	ELSE
tb_clear_blit_y_size		EQU cl2_display_y_size*(cl2_display_width+1)
	ENDC

; Restore-Blit
tb_restore_blit_x_size		EQU 16
tb_restore_blit_width		EQU tb_restore_blit_x_size/8
tb_restore_blit_y_size		EQU cl2_display_y_size

; Sine-Striped-Bar
ssb_bar_height			EQU 80
ssb_y_radius			EQU 112
ssb_y_center			EQU (cl2_display_y_size-ssb_bar_height+ssb_y_radius)/2
ssb_y_angle_speed		EQU 3

; Stripes-Pattern
sp_stripes_y_radius		EQU ssb_bar_height/2
sp_stripes_y_center		EQU ssb_bar_height/2
sp_stripes_y_angle_step		EQU 1
sp_stripes_y_angle_speed1	EQU 1
sp_stripes_number		EQU 16
sp_stripe_height		EQU 8

; Horiz-Scrolltext
hst_image_x_size		EQU 320
hst_image_plane_width		EQU hst_image_x_size/8
hst_image_depth			EQU 1
hst_origin_character_x_size	EQU 16
hst_origin_character_y_size	EQU 16

hst_text_character_x_size	EQU 16
hst_text_character_width	EQU hst_text_character_x_size/8
hst_text_character_y_size	EQU hst_origin_character_y_size
hst_text_character_depth	EQU hst_image_depth

hst_horiz_scroll_window_x_size 	EQU visible_pixels_number+hst_text_character_x_size
hst_horiz_scroll_window_width	EQU hst_horiz_scroll_window_x_size/8
hst_horiz_scroll_window_y_size 	EQU hst_text_character_y_size
hst_horiz_scroll_window_depth	EQU hst_image_depth
hst_horiz_scroll_speed1		EQU 2
hst_horiz_scroll_speed2		EQU 6

hst_text_character_x_restart	EQU hst_horiz_scroll_window_x_size
hst_text_characters_number	EQU hst_horiz_scroll_window_x_size/hst_text_character_x_size

hst_text_x_position		EQU 0
hst_text_y_position		EQU (pf1_y_size3-hst_text_character_y_size)/2

hst_color_gradient_height	EQU hst_text_character_y_size
hst_color_gradient_y_pos	EQU (ssb_bar_height-hst_text_character_y_size)/2

hst_copy_blit_x_size		EQU hst_text_character_x_size
hst_copy_blit_y_size		EQU hst_text_character_y_size*hst_text_character_depth

hst_horiz_scroll_blit_x_size	EQU hst_horiz_scroll_window_x_size
hst_horiz_scroll_blit_y_size	EQU hst_horiz_scroll_window_y_size*hst_horiz_scroll_window_depth

hst_text_delay			EQU 3*PAL_FPS

; Horiz-Scroll-Logo
hsl_x_center			EQU display_window_hstart+((visible_pixels_number-lg_image_x_size)/2)+14
hsl_x_angle_speed		EQU 4

hsl_start_x_radius		EQU (visible_pixels_number-lg_image_x_size)/2
hsl_start_x_center		EQU (visible_pixels_number-lg_image_x_size)/2
hsl_start_x_angle_speed		EQU 1

hsl_stop_x_radius		EQU (visible_pixels_number-lg_image_x_size)/2
hsl_stop_x_center		EQU (visible_pixels_number-lg_image_x_size)/2
hsl_stop_x_angle_speed		EQU 1

; Colors-Fader-Cross
cfc_rgb8_start_color		EQU 1
cfc_rgb8_color_table_offset	EQU 0
cfc_rgb8_colors_number		EQU hst_color_gradient_height
cfc_rgb8_color_tables_number	EQU 4
cfc_rgb8_fader_speed_max	EQU 3
cfc_rgb8_fader_radius		EQU cfc_rgb8_fader_speed_max
cfc_rgb8_fader_center		EQU cfc_rgb8_fader_speed_max+1
cfc_rgb8_fader_angle_speed	EQU 1
cfc_rgb8_fader_delay		EQU 10*PAL_FPS
cfc_rgb8_colors_per_bank	EQU 32

; Bar-Fader
bf_color_table_offset		EQU 0
bf_colors_number		EQU ssb_bar_height

; Bar-Fader-In
bfi_fader_speed_max		EQU 16
bfi_fader_radius		EQU bfi_fader_speed_max
bfi_fader_center		EQU bfi_fader_speed_max+1
bfi_fader_angle_speed		EQU 6

; Bar-Fader-Out
bfo_fader_speed_max		EQU 8
bfo_fader_radius		EQU bfo_fader_speed_max
bfo_fader_center		EQU bfo_fader_speed_max+1
bfo_fader_angle_speed		EQU 2

; Scroll-Logo-Bottom
slb_y_radius			EQU visible_lines_number
slb_y_center			EQU visible_lines_number

; Scroll-Logo-Bottom-In
slbi_y_angle_speed		EQU 2

; Scroll-Logo-Bottom-Out
slbo_y_angle_speed		EQU 1

; Chunky-Columns-Fader-In
ccfi_mode1			EQU 0
ccfi_mode2			EQU 1
ccfi_mode3			EQU 2
ccfi_mode4			EQU 3
ccfi_delay_speed		EQU 1
ccfi_delay			EQU 1

; Chunky-Columns-Fader-Out
ccfo_mode1			EQU 0
ccfo_mode2			EQU 1
ccfo_mode3			EQU 2
ccfo_mode4			EQU 3
ccfo_delay_speed		EQU 1
ccfo_delay			EQU 1

; Main
quit_delay			EQU (hst_origin_character_x_size*(((hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size))+1))/hst_horiz_scroll_speed2


color_step1			EQU 256/(tb_bar_height/2)
color_step2.1			EQU 256/(ssb_bar_height/2)
color_step2.2			EQU 128/(ssb_bar_height/2)
color_step3			EQU 256/hst_color_gradient_height
color_values_number1		EQU tb_bar_height/2
color_values_number2		EQU ssb_bar_height/2
color_values_number3		EQU hst_color_gradient_height
segments_number1		EQU tb_bars_number
segments_number2		EQU 4
segments_number3		EQU 1

ct_size1			EQU color_values_number1*segments_number1
ct_size2			EQU color_values_number2*segments_number2
ct_size3			EQU color_values_number3*segments_number3

tb_bplam_table_size		EQU ct_size1*2
ssb_bplam_table_size		EQU ct_size2


pf1_planes_x_offset		EQU 16+32
pf1_bpl1dat_x_offset		EQU pf1_planes_x_offset-pf_pixel_per_datafetch


	INCLUDE "except-vectors-offsets.i"


	INCLUDE "extra-pf-attributes.i"


	INCLUDE "sprite-attributes.i"


	RSRESET

cl1_begin			RS.B 0

	INCLUDE "copperlist1-offsets.i"

cl1_COPJMP2			RS.L 1

copperlist1_size 		RS.B 0


	RSRESET

cl2_extension1			RS.B 0

cl2_ext1_WAIT			RS.L 1
	IFEQ open_border_enabled
cl2_ext1_BPL1DAT		RS.L 1
	ENDC
cl2_ext1_BPLCON4_1		RS.L 1
cl2_ext1_BPLCON4_2		RS.L 1
cl2_ext1_BPLCON4_3		RS.L 1
cl2_ext1_BPLCON4_4		RS.L 1
cl2_ext1_BPLCON4_5		RS.L 1
cl2_ext1_BPLCON4_6		RS.L 1
cl2_ext1_BPLCON4_7		RS.L 1
cl2_ext1_BPLCON4_8		RS.L 1
cl2_ext1_BPLCON4_9		RS.L 1
cl2_ext1_BPLCON4_10 		RS.L 1
cl2_ext1_BPLCON4_11		RS.L 1
cl2_ext1_BPLCON4_12		RS.L 1
cl2_ext1_BPLCON4_13		RS.L 1
cl2_ext1_BPLCON4_14		RS.L 1
cl2_ext1_BPLCON4_15		RS.L 1
cl2_ext1_BPLCON4_16		RS.L 1
cl2_ext1_BPLCON4_17		RS.L 1
cl2_ext1_BPLCON4_18		RS.L 1
cl2_ext1_BPLCON4_19		RS.L 1
cl2_ext1_BPLCON4_20		RS.L 1
cl2_ext1_BPLCON4_21		RS.L 1
cl2_ext1_BPLCON4_22		RS.L 1
cl2_ext1_BPLCON4_23		RS.L 1
cl2_ext1_BPLCON4_24		RS.L 1
cl2_ext1_BPLCON4_25		RS.L 1
cl2_ext1_BPLCON4_26		RS.L 1
cl2_ext1_BPLCON4_27		RS.L 1
cl2_ext1_BPLCON4_28		RS.L 1
cl2_ext1_BPLCON4_29		RS.L 1
cl2_ext1_BPLCON4_30		RS.L 1
cl2_ext1_BPLCON4_31		RS.L 1
cl2_ext1_BPLCON4_32		RS.L 1
cl2_ext1_BPLCON4_33		RS.L 1
cl2_ext1_BPLCON4_34		RS.L 1
cl2_ext1_BPLCON4_35		RS.L 1
cl2_ext1_BPLCON4_36		RS.L 1
cl2_ext1_BPLCON4_37		RS.L 1
cl2_ext1_BPLCON4_38		RS.L 1
cl2_ext1_BPLCON4_39		RS.L 1
cl2_ext1_BPLCON4_40		RS.L 1
cl2_ext1_BPLCON4_41		RS.L 1
cl2_ext1_BPLCON4_42		RS.L 1
cl2_ext1_BPLCON4_43		RS.L 1
cl2_ext1_BPLCON4_44		RS.L 1
cl2_ext1_BPLCON4_45		RS.L 1

cl2_extension1_size		RS.B 0


	RSRESET

cl2_begin			RS.B 0

cl2_extension1_entry		RS.B cl2_extension1_size*cl2_display_y_size

cl2_WAIT			RS.L 1
cl2_INTREQ			RS.L 1

cl2_end				RS.L 1

copperlist2_size		RS.B 0


cl1_size1			EQU 0
cl1_size2			EQU copperlist1_size
cl1_size3			EQU copperlist1_size

cl2_size1			EQU copperlist2_size
cl2_size2			EQU copperlist2_size
cl2_size3			EQU copperlist2_size


; sprite0 additional structure
	RSRESET

spr0_extension1			RS.B 0

spr0_ext1_header		RS.L 1*(spr_pixel_per_datafetch/16)
spr0_ext1_planedata		RS.L (spr_pixel_per_datafetch/16)*lg_image_y_size

spr0_extension1_size		RS.B 0

; sprite0 main structure
	RSRESET

spr0_begin			RS.B 0

spr0_extension1_entry		RS.B spr0_extension1_size

spr0_end			RS.L 1*(spr_pixel_per_datafetch/16)

sprite0_size			RS.B 0

; sprite1 additional structure
	RSRESET

spr1_extension1			RS.B 0

spr1_ext1_header		RS.L 1*(spr_pixel_per_datafetch/16)
spr1_ext1_planedata		RS.L (spr_pixel_per_datafetch/16)*lg_image_y_size

spr1_extension1_size		RS.B 0

; sprite1 main structure
	RSRESET

spr1_begin			RS.B 0

spr1_extension1_entry		RS.B spr1_extension1_size

spr1_end			RS.L 1*(spr_pixel_per_datafetch/16)

sprite1_size			RS.B 0

; sprite2 additional structure
	RSRESET

spr2_extension1	RS.B 0

spr2_ext1_header		RS.L 1*(spr_pixel_per_datafetch/16)
spr2_ext1_planedata		RS.L (spr_pixel_per_datafetch/16)*lg_image_y_size

spr2_extension1_size		RS.B 0

; sprite2 main structure
	RSRESET

spr2_begin			RS.B 0

spr2_extension1_entry		RS.B spr2_extension1_size

spr2_end			RS.L 1*(spr_pixel_per_datafetch/16)

sprite2_size			RS.B 0

; sprite3 additional structure
	RSRESET

spr3_extension1	RS.B 0

spr3_ext1_header		RS.L 1*(spr_pixel_per_datafetch/16)
spr3_ext1_planedata		RS.L (spr_pixel_per_datafetch/16)*lg_image_y_size

spr3_extension1_size		RS.B 0

; sprite3 main structure
	RSRESET

spr3_begin			RS.B 0

spr3_extension1_entry 		RS.B spr3_extension1_size

spr3_end			RS.L 1*(spr_pixel_per_datafetch/16)

sprite3_size			RS.B 0

; sprite4 additional structure
	RSRESET

spr4_extension1			RS.B 0

spr4_ext1_header		RS.L 1*(spr_pixel_per_datafetch/16)
spr4_ext1_planedata		RS.L (spr_pixel_per_datafetch/16)*lg_image_y_size

spr4_extension1_size		RS.B 0

; sprite4 main structure
	RSRESET

spr4_begin			RS.B 0

spr4_extension1_entry		RS.B spr4_extension1_size

spr4_end			RS.L 1*(spr_pixel_per_datafetch/16)

sprite4_size			RS.B 0

; sprite5 additional structure
	RSRESET

spr5_extension1	RS.B 0

spr5_ext1_header		RS.L 1*(spr_pixel_per_datafetch/16)
spr5_ext1_planedata		RS.L (spr_pixel_per_datafetch/16)*lg_image_y_size

spr5_extension1_size		RS.B 0

; sprite5 main structure
	RSRESET

spr5_begin			RS.B 0

spr5_extension1_entry		RS.B spr5_extension1_size

spr5_end			RS.L 1*(spr_pixel_per_datafetch/16)

sprite5_size			RS.B 0

; sprite6 additional structure
	RSRESET

spr6_extension1			RS.B 0

spr6_ext1_header		RS.L 1*(spr_pixel_per_datafetch/16)
spr6_ext1_planedata		RS.L (spr_pixel_per_datafetch/16)*lg_image_y_size

spr6_extension1_size		RS.B 0

; sprite6 main structure
	RSRESET

spr6_begin			RS.B 0

spr6_extension1_entry		RS.B spr6_extension1_size

spr6_end			RS.L 1*(spr_pixel_per_datafetch/16)

sprite6_size			RS.B 0

; sprite7 additional structure
	RSRESET

spr7_extension1	RS.B 0

spr7_ext1_header		RS.L 1*(spr_pixel_per_datafetch/16)
spr7_ext1_planedata		RS.L (spr_pixel_per_datafetch/16)*lg_image_y_size

spr7_extension1_size		RS.B 0

; sprite7 main structure
	RSRESET

spr7_begin			RS.B 0

spr7_extension1_entry		RS.B spr7_extension1_size

spr7_end			RS.L 1*(spr_pixel_per_datafetch/16)

sprite7_size			RS.B 0


spr0_x_size1			EQU spr_x_size1
spr0_y_size1			EQU 0
spr1_x_size1			EQU spr_x_size1
spr1_y_size1			EQU 0
spr2_x_size1			EQU spr_x_size1
spr2_y_size1			EQU 0
spr3_x_size1			EQU spr_x_size1
spr3_y_size1			EQU 0
spr4_x_size1			EQU spr_x_size1
spr4_y_size1			EQU 0
spr5_x_size1			EQU spr_x_size1
spr5_y_size1			EQU 0
spr6_x_size1			EQU spr_x_size1
spr6_y_size1			EQU 0
spr7_x_size1			EQU spr_x_size1
spr7_y_size1			EQU 0

spr0_x_size2			EQU spr_x_size2
spr0_y_size2			EQU sprite0_size/(spr_pixel_per_datafetch/4)
spr1_x_size2			EQU spr_x_size2
spr1_y_size2			EQU sprite1_size/(spr_pixel_per_datafetch/4)
spr2_x_size2			EQU spr_x_size2
spr2_y_size2			EQU sprite2_size/(spr_pixel_per_datafetch/4)
spr3_x_size2			EQU spr_x_size2
spr3_y_size2			EQU sprite3_size/(spr_pixel_per_datafetch/4)
spr4_x_size2			EQU spr_x_size2
spr4_y_size2			EQU sprite4_size/(spr_pixel_per_datafetch/4)
spr5_x_size2			EQU spr_x_size2
spr5_y_size2			EQU sprite5_size/(spr_pixel_per_datafetch/4)
spr6_x_size2			EQU spr_x_size2
spr6_y_size2			EQU sprite6_size/(spr_pixel_per_datafetch/4)
spr7_x_size2			EQU spr_x_size2
spr7_y_size2			EQU sprite7_size/(spr_pixel_per_datafetch/4)


	RSRESET

em_bplam_table1			RS.B tb_bplam_table_size
em_bplam_table2			RS.B ssb_bplam_table_size
	RS_ALIGN_LONGWORD
em_color_table			RS.L ct_size2
extra_memory_size		RS.B 0


	RSRESET

	INCLUDE "variables-offsets.i"

; PT-Replay
	IFD PROTRACKER_VERSION_2.3A 
		INCLUDE "music-tracker/pt2-variables-offsets.i"
	ENDC
	IFD PROTRACKER_VERSION_3.0B
		INCLUDE "music-tracker/pt3-variables-offsets.i"
	ENDC

pt_effects_handler_active	RS.W 1

; Volume-Meter
vm_audio_channel		RS.W 1

; Twisted-Bars
tb_y_angle			RS.W 1
tb_y_angle_step_angle		RS.W 1

; Sine-Striped-Bar
ssb_y_angle			RS.W 1

; Striped-Pattern
sp_stripes_y_angle		RS.W 1
sp_stripes_y_angle_speed 	RS.W 1

; Horiz-Scrolltext
	RS_ALIGN_LONGWORD
hst_image			RS.L 1
hst_enabled			RS.W 1
hst_text_table_start		RS.W 1
hst_text_BLTCON0_bits		RS.W 1
hst_character_toggle_image	RS.W 1
hst_text_y_offset		RS.W 1
hst_horiz_scroll_speed		RS.W 1
hst_pause_horiz_scroll_enabled	RS.W 1
hst_text_delay_counter		RS.W 1

; Horiz-Scroll-Logo
hsl_active			RS.W 1
hsl_variable_x_radius		RS.W 1
hsl_x_angle			RS.W 1

hsl_start_active		RS.W 1
hsl_start_x_angle		RS.W 1

hsl_stop_active			RS.W 1
hsl_stop_x_angle		RS.W 1

; Colors-Fader-Cross
cfc_rgb8_active			RS.W 1
cfc_rgb8_fader_angle		RS.W 1
cfc_rgb8_fader_delay_counter	RS.W 1
cfc_rgb8_color_table_start	RS.W 1
cfc_rgb8_colors_counter		RS.W 1
cfc_rgb8_copy_colors_active	RS.W 1

; Bar-Fader
bf_colors_counter		RS.W 1
bf_convert_colors_active	RS.W 1

; Bar-Fader-In
bfi_active			RS.W 1
bfi_fader_angle			RS.W 1

; Bar-Fader-Out
bfo_active			RS.W 1
bfo_fader_angle			RS.W 1

; Scroll-Logo-Bottom-In
slbi_active			RS.W 1
slbi_y_angle			RS.W 1

; Scroll-Logo-Bottom-Out
slbo_active			RS.W 1
slbo_y_angle			RS.W 1

; Chunky-Columns-Fader-In
ccfi_active			RS.W 1
ccfi_current_mode		RS.W 1
ccfi_start			RS.W 1
ccfi_delay_counter		RS.W 1

; Chunky-Columns-Fader-Out
ccfo_active			RS.W 1
ccfo_current_mode		RS.W 1
ccfo_start			RS.W 1
ccfo_delay_counter		RS.W 1

; Main
logo_enabled			RS.W 1
stop_fx_active			RS.W 1
quit_active			RS.W 1
quit_delay_counter		RS.W 1

variables_size			RS.B 0


; PT-Replay
	INCLUDE "music-tracker/pt-song.i"

	INCLUDE "music-tracker/pt-temp-channel.i"


	RSRESET

audio_channel_info		RS.B 0

aci_yanglespeed			RS.W 1
aci_yanglestep			RS.W 1

audio_channel_info_size		RS.B 0


	INCLUDE "sys-wrapper.i"


	CNOP 0,4
init_main_variables

; PT-Replay
	IFD PROTRACKER_VERSION_2.3A 
		PT2_INIT_VARIABLES
	ENDC

	IFD PROTRACKER_VERSION_3.0B
		PT3_INIT_VARIABLES
	ENDC

	moveq	#TRUE,d0
	move.w	d0,pt_effects_handler_active(a3)

; Volume-Meter
	move.w	d0,vm_audio_channel(a3)

; Twisted-Bars
	move.w	d0,tb_y_angle(a3)	; 0°
	move.w	d0,tb_y_angle_step_angle(a3) ; 0°

; Sine-Striped-Bar
	move.w	d0,ssb_y_angle(a3)	; 0°

; Stripes-Pattern
	move.w	d0,sp_stripes_y_angle(a3) ; 0°
	move.w	#sp_stripes_y_angle_speed1,sp_stripes_y_angle_speed(a3)

; Horiz-Scrolltext
	lea	hst_image_data,a0
	move.l	a0,hst_image(a3)
	moveq	#FALSE,d1
	move.w	d1,hst_enabled(a3)
	move.w	d0,hst_text_table_start(a3)
	move.w	d0,hst_text_bltcon0_bits(a3)
	move.w	d0,hst_character_toggle_image(a3)
	move.w	d0,hst_text_y_offset(a3)
	moveq	#hst_horiz_scroll_speed1,d2
	move.w	d2,hst_horiz_scroll_speed(a3)
	move.w	d1,hst_pause_horiz_scroll_enabled(a3)
	move.w	d1,hst_text_delay_counter(a3)

; Horiz-Scroll-Logo
	move.w	d1,hsl_active(a3)
	move.w	d0,hsl_variable_x_radius(a3)
	move.w	d0,hsl_x_angle(a3) ;0°

	move.w	d1,hsl_start_active(a3)
	move.w	#sine_table_length/4,hsl_start_x_angle(a3) ; 90°

	move.w	d1,hsl_stop_active(a3)
	move.w	#sine_table_length/2,hsl_stop_x_angle(a3) ; 180°

	move.w	d1,hst_text_delay_counter(a3) ; delay counter inactive

; Colors-Fader-Cross
	IFEQ cfc_rgb8_prefade_enabled
		move.w	d0,cfc_rgb8_active(a3)
		move.w	#cfc_rgb8_colors_number*3,cfc_rgb8_colors_counter(a3)
		move.w	d0,cfc_rgb8_copy_colors_active(a3)
	ELSE
		move.w	d1,cfc_rgb8_active(a3)
		move.w	d0,cfc_rgb8_colors_counter(a3)
		move.w	d1,cfc_rgb8_copy_colors_active(a3)
	ENDC
	move.w	#sine_table_length/4,cfc_rgb8_fader_angle(a3) ; 90°
	move.w	d1,cfc_rgb8_fader_delay_counter(a3)
	move.w	d0,cfc_rgb8_color_table_start(a3)

; Bar-Fader
	move.w	d0,bf_colors_counter(a3)
	move.w	d1,bf_convert_colors_active(a3)

; Bar-Fader-In
	move.w	d1,bfi_active(a3)
	moveq	#sine_table_length/4,d2
	move.w	#sine_table_length/4,bfi_fader_angle(a3) ; 90°

; Bar-Fader-Out
	move.w	d1,bfo_active(a3)
	move.w	#sine_table_length/4,bfo_fader_angle(a3) ; 90°

; Scroll-Logo-Bottom-In
	move.w	d1,slbi_active(a3)
	move.w	d0,slbi_y_angle(a3)	; 0°

; Scroll-Logo-Bottom-Out
	move.w	d1,slbo_active(a3)
	move.w	#sine_table_length/4,slbo_y_angle(a3) ; 90°

; Chunky-Columns-Fader-In
	move.w	d1,ccfi_active(a3)
	move.w	#ccfi_mode1,ccfi_current_mode(a3)
	move.w	d0,ccfi_start(a3)
	move.w	d0,ccfi_delay_counter(a3)

; Chunky-Columns-Fader-Out
	move.w	d1,ccfo_active(a3)
	move.w	#ccfo_mode1,ccfo_current_mode(a3)
	move.w	d0,ccfo_start(a3)
	move.w	d0,ccfo_delay_counter(a3)

; Main
	move.w	d1,logo_enabled(a3)
	move.w	d1,stop_fx_active(a3)
	move.w	d1,quit_active(a3)
	move.w	d1,quit_delay_counter(a3)
	rts


	CNOP 0,4
init_main
	bsr.s	pt_DetectSysFrequ
	bsr	pt_InitRegisters
	bsr	pt_InitAudTempStrucs
	bsr	pt_ExamineSongStruc
	IFEQ pt_finetune_enabled
		bsr	pt_InitFtuPeriodTableStarts
	ENDC
	bsr	vm_init_audio_channel_info
	bsr	tb_init_color_table
	bsr	ssb_init_color_table
	bsr	tb_init_mirror_bplam_table
	bsr	get_channels_amplitudes
	bsr	ssb_init_bplam_table
	bsr	hst_init_characters_offsets
	bsr	hst_init_characters_x_positions
	bsr	hst_init_characters_images
	bsr	bf_init_color_table
	bsr	init_sprites
	bsr	init_CIA_timers
	bsr	init_first_copperlist
	bra	init_second_copperlist

; PT-Replay
	PT_DETECT_SYS_FREQUENCY

	PT_INIT_REGISTERS

	PT_INIT_AUDIO_TEMP_STRUCTURES

	PT_EXAMINE_SONG_STRUCTURE

	IFEQ pt_finetune_enabled
		PT_INIT_FINETUNE_TABLE_STARTS
	ENDC

; Volume-Meter
	CNOP 0,4
vm_init_audio_channel_info
	lea	vm_audio_channel1_info(pc),a0
	moveq	#0,d0
	move.w	d0,aci_yanglespeed(a0)
	move.w	d0,aci_yanglestep(a0)
	lea	vm_audio_channel2_info(pc),a0
	move.w	d0,aci_yanglespeed(a0)
	move.w	d0,aci_yanglestep(a0)
	lea	vm_audio_channel3_info(pc),a0
	move.w	d0,aci_yanglespeed(a0)
	move.w	d0,aci_yanglestep(a0)
	lea	vm_audio_channel4_info(pc),a0
	move.w	d0,aci_yanglespeed(a0)
	move.w	d0,aci_yanglestep(a0)
	rts

; Sine-Striped-Bar
	CNOP 0,4
ssb_init_color_table
	move.l	#color00_bits,d0
	move.l	extra_memory(a3),a0
	ADDF.L	em_color_table,a0
	moveq	#(color_values_number2*2)-1,d7
ssb_init_color_table_loop
	move.l	d0,(a0)+		; light color values
	move.l	d0,(a0)+		; dark color values
	dbf	d7,ssb_init_color_table_loop
	rts

; Twisted-Bars
	CNOP 0,4
tb_init_color_table
	lea	tb_colorfradients(pc),a0
	lea	pf1_rgb8_color_table(pc),a1
	moveq	#(color_values_number1*segments_number1)-1,d7
tb_init_color_table_loop
	move.l	(a0)+,d0
	move.l	d0,(a1)+		; COLOR00
	move.l	d0,(a1)+		; COLOR01
	dbf	d7,tb_init_color_table_loop
	rts

	INIT_MIRROR_bplam_table.B tb,0,2,segments_number1,color_values_number1,extra_memory,a3

; Sine-Striped-Bar / Horiz-Scrolltext
	INIT_bplam_table.B ssb,color_values_number1*segments_number1*2,2,color_values_number2*2,extra_memory,a3,em_bplam_table2

; Horiz-Scrolltext
	INIT_CHARACTERS_OFFSETS.W hst

	INIT_CHARACTERS_X_POSITIONS hst,LORES

	INIT_CHARACTERS_IMAGES hst

; Bar-Fader
	CNOP 0,4
bf_init_color_table
	clr.w	bf_convert_colors_active(a3)
	bra	bf_convert_colors


	CNOP 0,4
init_sprites
	bsr.s	spr_init_ptrs_table
	bra.s	lg_init_attached_sprites_cluster

	INIT_SPRITE_POINTERS_TABLE

	INIT_ATTACHED_SPRITES_CLUSTER lg,spr_ptrs_display,,,spr_x_size2,lg_image_y_size,NOHEADER

	CNOP 0,4
init_CIA_timers

; PT-Replay
	PT_INIT_TIMERS
	rts


	CNOP 0,4
init_first_copperlist
	move.l	cl1_construction2(a3),a0 
	bsr.s	cl1_init_playfield_props
	bsr.s	cl1_init_sprite_ptrs
	bsr	cl1_init_colors
	bsr	cl1_init_plane_ptrs
	COP_MOVEQ 0,COPJMP2
	bsr	cl1_set_sprite_ptrs
	bsr	cl1_set_plane_ptrs
	bra	copy_first_copperlist

	COP_INIT_PLAYFIELD_REGISTERS cl1

	COP_INIT_SPRITE_POINTERS cl1

	CNOP 0,4
cl1_init_colors
	COP_INIT_COLOR_HIGH COLOR00,32,pf1_rgb8_color_table
	COP_SELECT_COLOR_HIGH_BANK 1
	COP_INIT_COLOR_HIGH COLOR00,32
	COP_SELECT_COLOR_HIGH_BANK 2
	COP_INIT_COLOR_HIGH COLOR00,32
	COP_SELECT_COLOR_HIGH_BANK 3
	COP_INIT_COLOR_HIGH COLOR00,32
	COP_SELECT_COLOR_HIGH_BANK 4
	COP_INIT_COLOR_HIGH COLOR00,32
	COP_SELECT_COLOR_HIGH_BANK 5
	COP_INIT_COLOR_HIGH COLOR00,32
	COP_SELECT_COLOR_HIGH_BANK 6
	COP_INIT_COLOR_HIGH COLOR00,32
	COP_SELECT_COLOR_HIGH_BANK 7
	COP_INIT_COLOR_HIGH COLOR00,32

	COP_SELECT_COLOR_LOW_BANK 0
	COP_INIT_COLOR_LOW COLOR00,32,pf1_rgb8_color_table
	COP_SELECT_COLOR_LOW_BANK 1
	COP_INIT_COLOR_LOW COLOR00,32
	COP_SELECT_COLOR_LOW_BANK 2
	COP_INIT_COLOR_LOW COLOR00,32
	COP_SELECT_COLOR_LOW_BANK 3
	COP_INIT_COLOR_LOW COLOR00,32
	COP_SELECT_COLOR_LOW_BANK 4
	COP_INIT_COLOR_LOW COLOR00,32
	COP_SELECT_COLOR_LOW_BANK 5
	COP_INIT_COLOR_LOW COLOR00,32
	COP_SELECT_COLOR_LOW_BANK 6
	COP_INIT_COLOR_LOW COLOR00,32
	COP_SELECT_COLOR_LOW_BANK 7
	COP_INIT_COLOR_LOW COLOR00,32
	rts

	COP_INIT_BITPLANE_POINTERS cl1

	COP_SET_SPRITE_POINTERS cl1,construction2,spr_number

	COP_SET_BITPLANE_POINTERS cl1,display,pf1_depth3

	COPY_COPPERLIST cl1,2

	CNOP 0,4
init_second_copperlist
	move.l	cl2_construction1(a3),a0 
	bsr.s	cl2_init_bplcon4
	bsr.s	cl2_init_copper_interrupt
	COP_LISTEND
	bsr	copy_second_copperlist
	bra	swap_second_copperlist

	COP_INIT_BPLCON4_CHUNKY_SCREEN cl2,cl2_hstart1,cl2_vstart1,cl2_display_x_size,cl2_display_y_size,open_border_enabled,tb_quick_clear_enabled,FALSE

	COP_INIT_COPINT cl2,cl2_hstart2,cl2_vstart2

	COPY_COPPERLIST cl2,3


	CNOP 0,4
main
	bsr.s	no_sync_routines
	bra.s	beam_routines


	CNOP 0,4
no_sync_routines
	IFEQ cfc_rgb8_prefade_enabled
		bsr	cfc_rgb8_init_start_colors
	ENDC
	rts

	IFEQ cfc_rgb8_prefade_enabled
		CNOP 0,4
cfc_rgb8_init_start_colors
		bsr	cfc_rgb8_copy_color_table
		bsr	rgb8_colors_fader_cross
		tst.w	cfc_rgb8_copy_colors_active(a3)
		beq.s	cfc_rgb8_init_start_colors
		move.w	#FALSE,cfc_rgb8_copy_colors_active(a3) ; delay counter inactive
		rts
	ENDC


	CNOP 0,4
beam_routines
	bsr	wait_copint
	bsr	swap_first_copperlist
	bsr	swap_second_copperlist
	bsr	swap_playfield1
	bsr	set_playfield1
	bsr	horiz_scrolltext
	bsr	hst_horiz_scroll
	bsr	horiz_scroll_logo_start
	bsr	horiz_scroll_logo_stop
	bsr	horiz_scroll_logo
	bsr	tb_clear_second_copperlist
	bsr	cl2_update_bpl1dat
	bsr	bf_convert_colors
	bsr	sp_get_stripes_y_coords
	bsr	sp_make_color_offsets_table
	bsr	sp_make_pattern
	bsr	get_channels_amplitudes
	bsr	tb_get_yz_coords
	bsr	tb_set_background_bars
	bsr	make_striped_bar
	bsr	tb_set_foreground_bars
	IFNE tb_quick_clear_enabled
		bsr	restore_second_copperlist
	ENDC
	bsr	bar_fader_in
	bsr	bar_fader_out
	bsr	scroll_logo_bottom_in
	bsr	scroll_logo_bottom_out
	bsr	chunky_columns_fader_in
	bsr	chunky_columns_fader_out
	bsr	rgb8_colors_fader_cross
	bsr	cfc_rgb8_copy_color_table
	bsr	control_counters
	bsr	mouse_handler
	tst.w	stop_fx_active(a3)
	bne	beam_routines
	rts


	SWAP_COPPERLIST cl1,2

	SWAP_COPPERLIST cl2,3

	SWAP_PLAYFIELD pf1,3

	CNOP 0,4
set_playfield1
	moveq	#ssb_y_radius,d1	
	sub.w	hst_text_y_offset(a3),d1 ; vertical centering
	MULUF.W pf1_plane_width*pf1_depth3,d1,d0 ; y offset
	ADDF.W	pf1_planes_x_offset/8,d1
	move.l	cl1_display(a3),a0
	ADDF.W	cl1_BPL1PTH+WORD_SIZE,a0
	move.l	pf1_display(a3),a1
	moveq	#pf1_depth3-1,d7
set_playfield1_loop
	move.l	(a1)+,d0
	add.l	d1,d0			; bitplane offset
	move.w	d0,4(a0)		; BPLxPTL
	swap	d0
	move.w	d0,(a0)			; BPLxPTH
	addq.w	#8,a0
	dbf	d7,set_playfield1_loop
	rts


; calculate x radius for Horiz-Scroll-Logo
	CNOP 0,4
horiz_scroll_logo_start
	tst.w	hsl_start_active(a3)
	bne.s	horiz_scroll_logo_start_quit
	move.w	hsl_start_x_angle(a3),d2
	cmp.w	#sine_table_length/2,d2	; 180° reached ?
	ble.s	horiz_scroll_logo_start_skip
	move.w	#FALSE,hsl_start_active(a3)
	rts
	CNOP 0,4
horiz_scroll_logo_start_skip
	lea	sine_table(pc),a0
	move.l	(a0,d2.w*4),d0		; cos(w)
	MULUF.L hsl_start_x_radius*SHIRES_PIXEL_FACTOR*2*2,d0,d1 ; xr'=xr*cos(w)/2^16
	swap	d0
	add.w	#hsl_start_x_center*SHIRES_PIXEL_FACTOR*2,d0
	move.w	d0,hsl_variable_x_radius(a3)
	addq.w	#hsl_start_x_angle_speed,d2 ; next x angle
	move.w	d2,hsl_start_x_angle(a3) 
horiz_scroll_logo_start_quit
	rts

	CNOP 0,4
horiz_scroll_logo_stop
	tst.w	hsl_stop_active(a3)
	bne.s	horiz_scroll_logo_stop_quit
	move.w	hsl_stop_x_angle(a3),d2
	cmp.w	#sine_table_length/4,d2 ; 90° reached ?
	bgt.s   horiz_scroll_logo_stop_skip
	move.w	#FALSE,hsl_stop_active(a3)
	move.w	#FALSE,hsl_active(a3)	; stop logo movement
	rts
	CNOP 0,4
horiz_scroll_logo_stop_skip
	lea	sine_table(pc),a0
	move.l	(a0,d2.w*4),d0		; cos(w)
	MULUF.L hsl_stop_x_radius*SHIRES_PIXEL_FACTOR*2*2,d0,d1 ; x'=xr*cos(w)/2^16
	swap	d0
	add.w	#hsl_stop_x_center*SHIRES_PIXEL_FACTOR*2,d0
	move.w	d0,hsl_variable_x_radius(a3)
	subq.w	#hsl_stop_x_angle_speed,d2 ; next x angle
	move.w	d2,hsl_stop_x_angle(a3) 
horiz_scroll_logo_stop_quit
	rts

	CNOP 0,4
horiz_scroll_logo
	tst.w	hsl_active(a3)
	bne.s	horiz_scroll_logo_quit
	move.w	hsl_x_angle(a3),d1
	lea	sine_table(pc),a0
	move.w	2(a0,d1.w*4),d3		; sin(w)
	muls.w	hsl_variable_x_radius(a3),d3 ; x'=xrsin(w)/2^16
	swap	d3
	add.w	#hsl_x_center*SHIRES_PIXEL_FACTOR,d3
	addq.b	#hsl_x_angle_speed,d1 	; next x angle
	move.w	d1,hsl_x_angle(a3)	
	moveq	#lg_image_y_position,d4
	MOVEF.W lg_image_y_size,d5
	add.w	d4,d5			; VSTOP
	MOVEF.W spr_x_size2*SHIRES_PIXEL_FACTOR,d6
	lea	spr_ptrs_display(pc),a2
	moveq	#(spr_used_number/2)-1,d7
horiz_scroll_logo_loop
	move.w	d3,d0			; HSTART
	move.w	d4,d1			; VSTART
	move.w	d5,d2			; VSTOP
	move.l	(a2)+,a0		; first sprite structure
	move.l	(a2)+,a1		; second sprite structure
	SET_SPRITE_POSITION d0,d1,d2
	move.w	d1,(a0)			; SPRPOS
	move.w	d1,(a1)			; SPRPOS
	add.w	d6,d3			; next dprite x position
	move.w	d2,spr_pixel_per_datafetch/8(a0) ; SPRCTL
	or.b	#SPRCTLF_ATT,d2
	move.w	d2,spr_pixel_per_datafetch/8(a1) ; SPRCTL
	dbf	d7,horiz_scroll_logo_loop
horiz_scroll_logo_quit
	rts

	CLEAR_BPLCON4_CHUNKY_SCREEN tb,cl2,construction1,extension1,quick_clear_enabled

	CNOP 0,4
cl2_update_bpl1dat
	moveq	#ssb_y_radius,d0
	sub.w	hst_text_y_offset(a3),d0 ; vertical centering
	MULUF.W pf1_plane_width*pf1_depth3,d0,d1 ; y offset
	addq.w	#pf1_bpl1dat_x_offset/8,d0
	moveq	#pf1_plane_width*pf1_depth3,d1
	MOVEF.L cl2_extension1_size,d2
	move.l	pf1_display(a3),a0
	move.l	(a0),a0
	add.l	d0,a0			; + xy offset
	move.l	cl2_display(a3),a1
	ADDF.W	cl2_extension1_entry+cl2_ext1_BPL1DAT+WORD_SIZE,a1
	MOVEF.W (visible_lines_number/32)-1,d7
cl2_update_bpl1dat_loop
	REPT 32
		move.w	(a0),(a1)	; copy 16 pixel
		add.l	d1,a0		; next line in playfield
		add.l	d2,a1		; next line in cl
	ENDR
	dbf	d7,cl2_update_bpl1dat_loop
	rts

	CNOP 0,4
get_channels_amplitudes
	moveq	#vm_period_divider,d2
	lea	pt_audchan1temp(pc),a0
	lea	vm_audio_channel1_info(pc),a1
	bsr.s	get_channel_amplitude
	lea	pt_audchan2temp(pc),a0
	lea	vm_audio_channel2_info(pc),a1
	bsr.s	get_channel_amplitude
	lea	pt_audchan3temp(pc),a0
	lea	vm_audio_channel3_info(pc),a1
	bsr.s	get_channel_amplitude
	lea	pt_audchan4temp(pc),a0
	lea	vm_audio_channel4_info(pc),a1
	bsr.s	get_channel_amplitude
	rts

	CNOP 0,4
get_channel_amplitude
; Input
; d2.w	... Skalierung
; a0	... Temporäre Struktur des Audiokanals
; a1	... Zeiger auf Kanalinfo-Struktur
; Result
; d0.l	... Kein Rückgabewert
	tst.b	n_notetrigger(a0)	; new note played ?
	bne.s	get_channel_amplitude_quit
	move.b	#FALSE,n_notetrigger(a0)
	move.w	n_period(a0),d0
	DIVUF.W d2,d0,d1
	moveq	#vm_max_period_step,d0
	sub.w	d1,d0			; maxperstep - perstep
	lsr.w	#1,d0
	move.w	d0,(a1)+		; y angle speed
	lsr.w	#1,d0
	move.w	d0,(a1)			; y angle step
get_channel_amplitude_quit
	rts

	CNOP 0,4
tb_get_yz_coords
	move.l	a4,-(a7)
	move.w	vm_audio_channel(a3),d1
	MULUF.W audio_channel_info_size/WORD_SIZE,d1,d0
	moveq	#tb_y_distance,d3
	move.w	tb_y_angle(a3),d4
	move.w	d4,d0		
	move.w	tb_y_angle_step_angle(a3),d5
	add.b	(vm_audio_channel1_info+aci_yanglespeed+1,pc,d1.w*2),d0 ; next y angle
	move.w	d0,tb_y_angle(a3) 
	move.w	d5,d0
	add.b	(vm_audio_channel1_info+aci_yanglestep+1,pc,d1.w*2),d0 ; next y angle step
	move.w	d0,tb_y_angle_step_angle(a3) 
	lea	sine_table(pc),a0	
	lea	tb_yz_coords(pc),a1
	move.w	#tb_y_centre,a2
	move.w	#tb_y_angle_step_centre,a4
	moveq	#(cl2_display_width-1)-1,d7 ; number of columns
tb_get_yz_coords_loop1
	move.l	(a0,d5.w*4),d0		; sin(w)
	MULUF.L tb_y_angle_step_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	add.w	a4,d0			; y' + y step center
	move.w	d4,d2			; y angle
	add.b	d0,d4			; next y angle
	moveq	#tb_bars_number-1,d6
tb_get_yz_coords_loop2
	moveq	#-(sine_table_length/4),d1 ; - 90°
	move.l	(a0,d2.w*4),d0		; sin(w)
	add.w	d2,d1			; y angle - 90°
	ext.w	d1
	move.w	d1,(a1)+		; z vector
	MULUF.L tb_y_radius*2,d0,d1	; y'=(yr*sin(w))/2^15
	swap	d0
	add.w	a2,d0			; y' + y center
	MULUF.W cl2_extension1_size/LONGWORD_SIZE,d0,d1 ; y offset in cl
	move.w	d0,(a1)+		; y position
	add.b	d3,d2			; y distance to next bar
	dbf	d6,tb_get_yz_coords_loop2
	addq.b	#tb_y_angle_step_step,d5 ; next y step angle
	dbf	d7,tb_get_yz_coords_loop1
	move.l	(a7)+,a4
	rts

	CNOP 0,4
sp_get_stripes_y_coords
	move.w	sp_stripes_y_angle(a3),d2
	move.w	d2,d0
	MOVEF.W (sine_table_length/2)-1,d5 ; overflow
	add.w	sp_stripes_y_angle_speed(a3),d0 ; next y angle
	and.w	d5,d0			; remove overflow
	move.w	d0,sp_stripes_y_angle(a3) 
	;moveq	#sp_stripes_y_radius*2,d3
	moveq	#sp_stripes_y_center,d4
	lea	sine_table+((sine_table_length/4)*LONGWORD_SIZE)(pc),a0 
	lea	sp_stripes_y_coords(pc),a1
	moveq	#(sp_stripes_number*sp_stripe_height)-1,d7 ; number of lines
sp_get_stripes_y_coords_loop
	move.l	(a0,d2.w*4),d0		; cos(w)
	MULUF.L SP_stripes_y_radius*2,d0,d1 ; y'=(yr*cos(w))/2^15
	swap	d0
	add.w	d4,d0			; y' + y center
	move.w	d0,(a1)+		; y position
	addq.w	#sp_stripes_y_angle_step,d2 ; next y angle
	and.w	d5,d2			; remove overflow
	dbf	d7,sp_get_stripes_y_coords_loop
	rts

	CNOP 0,4
tb_set_background_bars
	movem.l	a4-a6,-(a7)
	moveq	#tb_bar_height,d4
	lea	tb_yz_coords(pc),a0
	move.l	cl2_construction2(a3),a2
	ADDF.W	cl2_extension1_entry+cl2_ext1_BPLCON4_1+WORD_SIZE,a2
	move.l	extra_memory(a3),a5	; pointer BPLCON4 switch values table
	lea	ccf_columns_mask(pc),a6
	moveq	#(cl2_display_width-1)-1,d7
tb_set_background_bars_loop1
	tst.b	(a6)+			; display column ?
	beq.s	tb_set_background_bars_skip1
	ADDF.W	tb_bars_number*LONGWORD_SIZE,a0 ; skip z vector and y position
	bra	tb_set_background_bars_skip4
	CNOP 0,4
tb_set_background_bars_skip1
	move.l	a5,a1			; pointer BPLCON4 switch values table
	moveq	#tb_bars_number-1,d6
tb_set_background_bars_loop2
	move.l	(a0)+,d0		; bits 0-15: y position, bits 16-31: z vector
	bpl.s	tb_set_background_bars_skip2
	add.l	d4,a1			; skip switch values
	bra	tb_set_background_bars_skip3
	CNOP 0,4
tb_set_background_bars_skip2
	lea	(a2,d0.w*4),a4		; y offset in cl
	COPY_TWISTED_BAR.B tb,cl2,extension1,bar_height
tb_set_background_bars_skip3
	dbf	d6,tb_set_background_bars_loop2
tb_set_background_bars_skip4
	addq.w	#LONGWORD_SIZE,a2	; next column in cl
	dbf	d7,tb_set_background_bars_loop1
	movem.l	(a7)+,a4-a6
	rts

	CNOP 0,4
make_striped_bar
	move.w	ssb_y_angle(a3),d1
	move.w	d1,d0		
	addq.w	#ssb_y_angle_speed,d0	; next y angle
	and.w	#(sine_table_length/2)-1,d0 ; remove overflow
	move.w	d0,ssb_y_angle(a3) 
	lea	sine_table(pc),a0	
	move.l	(a0,d1.w*4),d0		; sin(w)
	MULUF.L ssb_y_radius*2,d0,d1	; y'=(yr*sin(w))/2^15
	swap	d0
	move.w	d0,d1		
	add.w	#ssb_y_radius,d0	; y' + y radius
	move.w	d0,hst_text_y_offset(a3) 
	add.w	#ssb_y_center,d1	; y' + y y center
	MULUF.W cl2_extension1_size/LONGWORD_SIZE,d1,d0 ; y offset in cl
	move.l	extra_memory(a3),a0
	add.l	#em_bplam_table2,a0
	move.l	cl2_construction2(a3),a1 
	ADDF.W	(cl2_extension1_entry+cl2_ext1_BPLCON4_1+WORD_SIZE),a1
	lea	(a1,d1.w*4),a1		; + y offset
	move.w	#cl2_extension1_size,a2
	moveq	#(ssb_bar_height)-1,d7
make_striped_bar_loop
	move.b	(a0)+,d0		; BPLCON4 switch value
	move.b	d0,(a1)			; first column in cl
	move.b	d0,4(a1)		; second column in cl
	move.b	d0,8(a1)		; ...
	move.b	d0,12(a1)
	move.b	d0,16(a1)
	move.b	d0,20(a1)
	move.b	d0,24(a1)
	move.b	d0,28(a1)
	move.b	d0,32(a1)
	move.b	d0,36(a1)
	move.b	d0,40(a1)
	move.b	d0,44(a1)
	move.b	d0,48(a1)
	move.b	d0,52(a1)
	move.b	d0,56(a1)
	move.b	d0,60(a1)
	move.b	d0,64(a1)
	move.b	d0,68(a1)
	move.b	d0,72(a1)
	move.b	d0,76(a1)
	move.b	d0,80(a1)
	move.b	d0,84(a1)
	move.b	d0,88(a1)
	move.b	d0,92(a1)
	move.b	d0,96(a1)
	move.b	d0,100(a1)
	move.b	d0,104(a1)
	move.b	d0,108(a1)
	move.b	d0,112(a1)
	move.b	d0,116(a1)
	move.b	d0,120(a1)
	move.b	d0,124(a1)
	move.b	d0,128(a1)
	move.b	d0,132(a1)
	move.b	d0,136(a1)
	move.b	d0,140(a1)
	move.b	d0,144(a1)
	move.b	d0,148(a1)
	move.b	d0,152(a1)
	move.b	d0,156(a1)
	move.b	d0,160(a1)
	move.b	d0,164(a1)
	move.b	d0,168(a1)
	add.l	a2,a1			; next line in cl
	move.b	d0,172-cl2_extension1_size(a1)
	dbf	d7,make_striped_bar_loop
	rts

	CNOP 0,4
tb_set_foreground_bars
	movem.l	a4-a6,-(a7)
	moveq	#tb_bar_height,d4
	lea	tb_yz_coords(pc),a0
	move.l	cl2_construction2(a3),a2
	ADDF.W	cl2_extension1_entry+cl2_ext1_BPLCON4_1+WORD_SIZE,a2
	move.l	extra_memory(a3),a5	; pointer BPLCON4 switch values table
	lea	ccf_columns_mask(pc),a6
	moveq	#(cl2_display_width-1)-1,d7
tb_set_foreground_bars_loop1
	tst.b	(a6)+			; display column ?
	beq.s	tb_set_foreground_bars_skip1
	ADDF.W	tb_bars_number*LONGWORD_SIZE,a0 ; skip y position and z vector
	bra	tb_set_foreground_bars_skip4
	CNOP 0,4
tb_set_foreground_bars_skip1
	move.l	a5,a1			; pointer BPLCON4 switch values table
	moveq	#tb_bars_number-1,d6
tb_set_foreground_bars_loop2
	move.l	(a0)+,d0		; bits 0-15: y positions, bits 16-31: z vector
	bmi.s	tb_set_foreground_bars_skip2
	add.l	d4,a1			; skip switch values
	bra	tb_set_foreground_bars_skip3
	CNOP 0,4
tb_set_foreground_bars_skip2
	lea	(a2,d0.w*4),a4		; + y offset
	COPY_TWISTED_BAR.B tb,cl2,extension1,bar_height
tb_set_foreground_bars_skip3
	dbf	d6,tb_set_foreground_bars_loop2
tb_set_foreground_bars_skip4
	addq.w	#LONGWORD_SIZE,a2	; next column in cl
	dbf	d7,tb_set_foreground_bars_loop1
	movem.l	(a7)+,a4-a6
	rts

	CNOP 0,4
sp_make_color_offsets_table
	moveq	#$00000001,d1		; color offset 1st & 2nd stripe
	lea	sp_stripes_y_coords(pc),a0
	lea	sp_color_offsets_table(pc),a1
	moveq	#sp_stripes_number-1,d7
sp_make_color_offsets_table_loop1
	moveq	#sp_stripe_height-1,d6
sp_make_color_offsets_table_loop2
	move.w	(a0)+,d0		; color offset
	move.w	d1,(a1,d0.w*2)
	dbf	d6,sp_make_color_offsets_table_loop2
	swap	d1			; swap color offsets
	dbf	d7,sp_make_color_offsets_table_loop1
	rts

	CNOP 0,4
sp_make_pattern
	move.w	#RB_NIBBLES_MASK,d3
	moveq	#0,d4			; color registers counter
	moveq	#2<<3,d5
	lea	sp_color_offsets_table(pc),a0
	move.l	extra_memory(a3),a1
	add.l	#em_color_table,a1
	move.l	cl1_construction2(a3),a2
	ADDF.W	cl1_COLOR00_high4+WORD_SIZE,a2
	moveq	#ssb_bar_height-1,d7
sp_make_pattern_loop
	move.w	(a0)+,d0		; color offset
	move.w	(a1,d0.w*4),(a2)	; COLOR00 high bits
	addq.w	#QUADWORD_SIZE,a1	; next color value
	move.w	WORD_SIZE-QUADWORD_SIZE(a1,d0.w*4),cl1_COLOR00_low1-cl1_COLOR00_high1(a2) ; COLOR00 low bits
	addq.w	#QUADWORD_SIZE,a2	; next line in cl
	add.b	d5,d4			; increment color registers counter
	bne.s	sp_make_pattern_skip
	addq.w	#LONGWORD_SIZE,a2	; skip CMOVE
sp_make_pattern_skip
	dbf	d7,sp_make_pattern_loop
	rts

	CNOP 0,4
horiz_scrolltext
	movem.l a4-a5,-(a7)
	tst.w	hst_enabled(a3)
	bne.s	horiz_scrolltext_quit
	bsr.s	horiz_scrolltext_init
	move.w	#(hst_copy_blit_y_size*64)+(hst_copy_blit_x_size/16),d4 ; BLTSIZE
	move.w	#hst_text_character_x_restart,d5
	lea	hst_characters_x_positions(pc),a0
	lea	hst_characters_image_ptrs(pc),a1
	move.l	pf1_construction1(a3),a2
	move.l	(a2),d3
	add.l	#(hst_text_x_position/8)+(hst_text_y_position*pf1_plane_width*pf1_depth3),d3 ; vertical centering
	lea	BLTAPT-DMACONR(a6),a2
	lea	BLTDPT-DMACONR(a6),a4
	lea	BLTSIZE-DMACONR(a6),a5
	bsr.s	hst_get_text_softscroll
	moveq	#hst_text_characters_number-1,d7
horiz_scrolltext_loop
	moveq	#0,d0
	move.w	(a0),d0			; x
	move.w	d0,d2		
	lsr.w	#3,d0			; x/8
	add.l	d3,d0			; x offset
	WAITBLIT
	move.l	(a1)+,(a2)		; character image
	move.l	d0,(a4)			; playfield
	move.w	d4,(a5)			; start blit
	sub.w	hst_horiz_scroll_speed(a3),d2 ; decrease x position
	bpl.s	horiz_scrolltext_skip1
	move.l	a0,-(a7)
	bsr.s	hst_get_new_character_image
	move.l	d0,-4(a1)		; new character image
	add.w	d5,d2			; restart x position
	move.l	(a7)+,a0
horiz_scrolltext_skip1
	move.w	d2,(a0)+		
	dbf	d7,horiz_scrolltext_loop
	tst.w	hst_pause_horiz_scroll_enabled(a3)
	bne.s	horiz_scrolltext_skip2
	move.w	#FALSE,hst_pause_horiz_scroll_enabled(a3)
	clr.w	hst_horiz_scroll_speed(a3)
horiz_scrolltext_skip2
	move.w	#DMAF_BLITHOG,DMACON-DMACONR(a6)
horiz_scrolltext_quit
	movem.l (a7)+,a4-a5
	rts
	CNOP 0,4
horiz_scrolltext_init
	move.w	#DMAF_BLITHOG+DMAF_SETCLR,DMACON-DMACONR(a6)
	WAITBLIT
	move.l	#(BC0F_SRCA+BC0F_DEST+ANBNC+ANBC+ABNC+ABC)<<16,BLTCON0-DMACONR(a6) ; minterm D=A
	moveq	#FALSE,d0
	move.l	d0,BLTAFWM-DMACONR(a6) 	; no mask
	move.l	#((hst_image_plane_width-hst_text_character_width)<<16)+(pf1_plane_width-hst_text_character_width),BLTAMOD-DMACONR(a6) ; A&D moduli
	rts

	CNOP 0,4
hst_get_text_softscroll
	moveq	#hst_text_character_x_size-1,d0
	and.w	(a0),d0			; x position & $f
	ror.w	#4,d0			; adjust bits
	or.w	#BC0F_SRCA+BC0F_DEST+ANBNC+ANBC+ABNC+ABC,d0 ; minterm D=A
	move.w	d0,hst_text_bltcon0_bits(a3) 
	rts

	GET_NEW_CHARACTER_IMAGE.W hst,hst_check_control_codes,NORESTART

	CNOP 0,4
hst_check_control_codes
; Input
; d0.b	... ascii code
; Result
; d0.l	... return value: return code
	cmp.b	#ASCII_CTRL_P,d0
	beq.s	hst_pause_scrolltext
	cmp.b	#ASCII_CTRL_S,d0
	beq.s	hst_stop_scrolltext
	rts
	CNOP 0,4
hst_pause_scrolltext
	clr.w	hst_pause_horiz_scroll_enabled(a3)
	move.w	#hst_text_delay,hst_text_delay_counter(a3) ; start delay counter
	moveq	#RETURN_OK,d0
	rts
	CNOP 0,4
hst_stop_scrolltext
	move.w	#FALSE,hst_enabled(a3)	; stop text
	tst.w	quit_active(a3)		; quit intro ?
	bne.s	hst_stop_scrolltext_quit
	clr.w	pt_music_fader_active(a3)
	tst.w	logo_enabled(a3)
	bne.s	hst_stop_scrolltext_skip
	clr.w	slbo_active(a3)
hst_stop_scrolltext_skip
	clr.w	ccfo_active(a3)
	move.w	#1,ccfo_delay_counter(a3) ; activate delay counter
	move.w	#bf_colors_number*3,bf_colors_counter(a3)
	clr.w	bf_convert_colors_active(a3)
	clr.w	bfo_active(a3)
hst_stop_scrolltext_quit
	moveq	#RETURN_OK,d0
	rts

	CNOP 0,4
hst_horiz_scroll
	tst.w	hst_enabled(a3)
	bne.s	hst_horiz_scroll_quit
	move.l	pf1_construction1(a3),a0
	move.l	(a0),a0
	ADDF.L	(hst_text_x_position/8)+(hst_text_y_position*pf1_plane_width*pf1_depth3),a0 ; y centering
	WAITBLIT
	move.w	hst_text_bltcon0_bits(a3),BLTCON0-DMACONR(a6)
	move.l	a0,BLTAPT-DMACONR(a6)	; source
	addq.w	#WORD_SIZE,a0		; skip 16 pixel
	move.l	a0,BLTDPT-DMACONR(a6) 	; target
	move.l	#((pf1_plane_width-hst_horiz_scroll_window_width)<<16)+(pf1_plane_width-hst_horiz_scroll_window_width),BLTAMOD-DMACONR(a6) ; A&D moduli
	move.w	#(hst_horiz_scroll_blit_y_size*64)+(hst_horiz_scroll_blit_x_size/16),BLTSIZE-DMACONR(a6) ; start blit
hst_horiz_scroll_quit
	rts

	IFNE tb_quick_clear_enabled
		RESTORE_BLCON4_CHUNKY_SCREEN tb,cl2,construction2,extension1,32
	ENDC


	CNOP 0,4
bar_fader_in
	movem.l a4-a6,-(a7)
	tst.w	bfi_active(a3)
	bne.s	bar_fader_in_quit
	move.w	bfi_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	bfi_fader_angle_speed,d0 ; next angle
	cmp.w	#sine_table_length/2,d0	; angle <= 180° ?
	ble.s	bar_fader_in_skip
	MOVEF.W sine_table_length/2,d0	; 180°
bar_fader_in_skip
	move.w	d0,bfi_fader_angle(a3) 
	MOVEF.W bf_colors_number*3,d6	; RGB counter
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L bfi_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	bfi_fader_center,d0
	lea	bf_color_cache+(bf_color_table_offset*LONGWORD_SIZE)(pc),a0 ; color values buffer
	lea	bfi_color_table+(bf_color_table_offset*LONGWORD_SIZE)(pc),a1 ; target color values
	move.w	d0,a5			; increment/decrement blue
	swap	d0
	clr.w	d0
	move.l	d0,a2			; increment/decrement red
	lsr.l	#8,d0
	move.l	d0,a4			; increment/decrement green
	MOVEF.W bf_colors_number-1,d7
	bsr	bf_rgb8_fader_loop
	move.w	d6,bf_colors_counter(a3) ; fading finished ?
	bne.s	bar_fader_in_quit
	move.w	#FALSE,bfi_active(a3)
bar_fader_in_quit
	movem.l (a7)+,a4-a6
	rts

	CNOP 0,4
bar_fader_out
	movem.l a4-a6,-(a7)
	tst.w	bfo_active(a3)
	bne.s	bar_fader_out_quit
	move.w	bfo_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	bfo_fader_angle_speed,d0 ; next angle
	cmp.w	#sine_table_length/2,d0	; angle <= 180° ?
	ble.s	bar_fader_out_skip
	MOVEF.W sine_table_length/2,d0	; 180°
bar_fader_out_skip
	move.w	d0,bfo_fader_angle(a3) 
	MOVEF.W bf_colors_number*3,d6	; RGB counter
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L bfo_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	bfo_fader_center,d0
	lea	bf_color_cache+(bf_color_table_offset*LONGWORD_SIZE)(pc),a0 ; color values buffer
	lea	bfo_color_table+(bf_color_table_offset*LONGWORD_SIZE)(pc),a1 ; target color values
	move.w	d0,a5			; increment/decrement blue
	swap	d0
	clr.w	d0
	move.l	d0,a2			; increment/decrement red
	lsr.l	#8,d0
	move.l	d0,a4			; increment/decrement green
	MOVEF.W bf_colors_number-1,d7
	bsr	bf_rgb8_fader_loop
	move.w	d6,bf_colors_counter(a3) ; fading finished ?
	bne.s	bar_fader_out_quit
	move.w	#FALSE,bfo_active(a3)
bar_fader_out_quit
	movem.l (a7)+,a4-a6
	rts

	RGB8_COLOR_FADER bf

	CNOP 0,4
bf_convert_colors
	move.l	a4,-(a7)
	tst.w	bf_convert_colors_active(a3)
	bne.s	bf_convert_colors_quit
	move.w	#RB_NIBBLES_MASK,d5
	lea	bf_color_cache+(bf_color_table_offset*LONGWORD_SIZE)(pc),a0 ; light color values buffer
	lea	(bf_color_table_offset*LONGWORD_SIZE)+((bf_colors_number/2)*LONGWORD_SIZE)(a0),a1 ; dark color values buffer
	move.l	extra_memory(a3),a2
	add.l	#em_color_table,a2
	lea	bf_colors_number*QUADWORD_SIZE(a2),a4 ; end of color table
	MOVEF.W (bf_colors_number/2)-1,d7
bf_convert_colors_loop
; helle Streifen
	move.l	(a0)+,d0		; RGB8 value
	move.l	d0,d2		
	RGB8_TO_RGB4_HIGH d0,d1,d5
	move.w	d0,(a2)+		; COLORxx high bits
	RGB8_TO_RGB4_LOW d2,d1,d5
	move.w	d2,(a2)+		; COLORxx low bits
; dunkle Streifen
	move.l	(a1)+,d3		; RGB8 value
	move.l	d3,d4		
	RGB8_TO_RGB4_HIGH d3,d1,d5
	move.w	d3,(a2)+		; COLORxx high bits
	RGB8_TO_RGB4_LOW d4,d1,d5
	move.w	d4,(a2)+		; COLORxx low bits
; 2. Hälfte der Bar rückwärts
	move.w	d4,-(a4)		; COLORxx low bits
	move.w	d3,-(a4)		; COLORxx high bits
	move.w	d2,-(a4)		; COLORxx low bits
	move.w	d0,-(a4)		; COLORxx high bits
	dbf	d7,bf_convert_colors_loop
	tst.w	bf_colors_counter(a3)	; fading finished ?
	bne.s	bf_convert_colors_quit
	move.w	#FALSE,bf_convert_colors_active(a3)
bf_convert_colors_quit
	move.l	(a7)+,a4
	rts

	CNOP 0,4
scroll_logo_bottom_in
	move.l	a4,-(a7)
	tst.w	slbi_active(a3)
	bne.s	scroll_logo_bottom_in_quit
	move.w	slbi_y_angle(a3),d2
	cmp.w	#sine_table_length/4,d2	; 90° reached ?
	ble.s	scroll_logo_bottom_in_skip
	move.w	#FALSE,slbi_active(a3)
	clr.w	logo_enabled(a3)
	bra.s	scroll_logo_bottom_in_quit
	CNOP 0,4
scroll_logo_bottom_in_skip
	lea	sine_table,a0
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L slb_y_radius*2,d0,d1 	; y'=yr*cos(w)/2^16
	swap	d0
	add.w	#slb_y_center,d0
	MOVEF.W lg_image_y_position,d5
	add.w	d0,d5			; vertical centering
	addq.w	#slbi_y_angle_speed,d2	; next y angle
	move.w	d2,slbi_y_angle(a3)
	bsr.s	slb_scroll_logo
scroll_logo_bottom_in_quit
	move.l	(a7)+,a4
	rts

	CNOP 0,4
scroll_logo_bottom_out
	move.l	a4,-(a7)
	tst.w	slbo_active(a3)
	bne.s	scroll_logo_bottom_out_quit
	move.w	slbo_y_angle(a3),d2
	cmp.w	#sine_table_length/2,d2 ; 180° reached ?
	ble.s	scroll_logo_bottom_out_skip
	move.w	#FALSE,slbo_active(a3)
	bra.s	scroll_logo_bottom_out_quit
	CNOP 0,4
scroll_logo_bottom_out_skip
	lea	sine_table,a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L slb_y_radius*2,d0,d1	; y'=yr*cos(w)/2^16
	swap	d0
	add.w	#slb_y_center,d0
	MOVEF.W lg_image_y_position,d5
	add.w	d0,d5			; vertical centering
	addq.w	#slbi_y_angle_speed,d2	; next y angle
	move.w	d2,slbo_y_angle(a3)
	bsr.s	slb_scroll_logo
scroll_logo_bottom_out_quit
	move.l	(a7)+,a4
	rts

	CNOP 0,4
slb_scroll_logo
	MOVEF.W lg_image_x_position*SHIRES_PIXEL_FACTOR,d4
	MOVEF.W lg_image_y_size,d6
	add.w	d5,d6			; VSTOP
	lea	spr_ptrs_display(pc),a2
	move.w	#spr_x_size2*SHIRES_PIXEL_FACTOR,a4 ; X
	moveq	#(spr_used_number/2)-1,d7
slb_scroll_logo_loop
	move.w	d4,d0			; HSTART
	move.w	d5,d1			; VSTART
	move.w	d6,d2			; VSTOP
	move.l	(a2)+,a0		; 1st sprite structure
	move.l	(a2)+,a1		; 2nd sprite structure
	SET_SPRITE_POSITION_V9 d0,d1,d2,d3
	move.w	d1,(a0)			; SPRPOS
	move.w	d1,(a1)			; SPRPOS
	add.w	a4,d4			; next x position
	move.w	d2,spr_pixel_per_datafetch/8(a0) ; SPRCTL
	or.b	#SPRCTLF_ATT,d2
	move.w	d2,spr_pixel_per_datafetch/8(a1) ; SPRCTL
	dbf	d7,slb_scroll_logo_loop
	rts

	CNOP 0,4
chunky_columns_fader_in
	tst.w	ccfi_active(a3)
	bne.s	chunky_columns_fader_in_quit
	subq.w	#ccfi_delay_speed,ccfi_delay_counter(a3)
	bne.s	chunky_columns_fader_in_quit
	move.w	#ccfi_delay,ccfi_delay_counter(a3) ; reset delay counter
	move.w	ccfi_start(a3),d1
	moveq	#(cl2_display_width-1)-1,d2
	lea	ccf_columns_mask(pc),a0
	move.w	ccfi_current_mode(a3),d0
	beq.s	ccfi_fader_mode_1
	subq.w	#1,d0			; mode2 ?
	beq.s	ccfi_fader_mode_2
	subq.w	#1,d0			; mode3 ?
	beq.s	ccfi_fader_mode_3
	subq.w	#1,d0			; mode4 ?
	beq.s	ccfi_fader_mode_4
chunky_columns_fader_in_quit
	rts
; fade in from left to right
	CNOP 0,4
ccfi_fader_mode_1
	clr.b	(a0,d1.w)		; state fade in
	addq.w	#BYTE_SIZE,d1		; bext column
	cmp.w	d2,d1			; columns faded in ?
	bgt.s	ccfi_fader_mode_skip
	move.w	d1,ccfi_start(a3)
	rts
; fade in from right to left
	CNOP 0,4
ccfi_fader_mode_2
	move.w	d1,d0			; start value
	neg.w	d0
	addq.w	#BYTE_SIZE,d1		; next column
	clr.b	(cl2_display_width-1)-1(a0,d0.w) ; state fade in
	cmp.w	d2,d1			; columns faded in ?
	bgt.s	ccfi_fader_mode_skip
	move.w	d1,ccfi_start(a3)
	rts
; fade in from left and right simutanleously
	CNOP 0,4
ccfi_fader_mode_3
	clr.b	(a0,d1.w)		; state fade in
	move.w	d1,d0			; start value
	neg.w	d0
	addq.w	#BYTE_SIZE,d1		; next column
	lsr.w	#1,d2			; columns center
	clr.b	(cl2_display_width-1)-1(a0,d0.w) ; state fade in
	cmp.w	d2,d1			; columns faded in ?
	bgt.s	ccfi_fader_mode_skip
	move.w	d1,ccfi_start(a3)
	rts
; fade in from left and right every second column simutanleously
	CNOP 0,4
ccfi_fader_mode_4
	clr.b	(a0,d1.w)		; state fade in
	move.w	d1,d0			; start value
	neg.w	d0
	addq.w	#WORD_SIZE,d1		; column after next
	clr.b	(cl2_display_width-1)-1(a0,d0.w) ; state fade in
	cmp.w	d2,d1			; columns faded in ?
	bgt.s	ccfi_fader_mode_skip
	move.w	d1,ccfi_start(a3)
	rts
	CNOP 0,4
ccfi_fader_mode_skip
	move.w	#FALSE,ccfi_active(a3)
	rts

	CNOP 0,4
chunky_columns_fader_out
	tst.w	ccfo_active(a3)
	bne.s	chunky_columns_fader_out_quit
	subq.w	#ccfo_delay_speed,ccfo_delay_counter(a3)
	bne.s	chunky_columns_fader_out_quit
	move.w	#ccfo_delay,ccfo_delay_counter(a3) ; reset delay counter
	move.w	ccfo_start(a3),d1
	moveq	#(cl2_display_width-1)-1,d2
	lea	ccf_columns_mask(pc),a0
	move.w	ccfo_current_mode(a3),d0
	beq.s	ccfo_fader_mode_1
	subq.w	#1,d0			; mode2 ?
	beq.s	ccfo_fader_mode_2
	subq.w	#1,d0			; mode3 ?
	beq.s	ccfo_fader_mode_3
	subq.w	#1,d0			; mode4 ?
	beq.s	ccfo_fader_mode_4
chunky_columns_fader_out_quit
	rts
; fade out from left to right
	CNOP 0,4
ccfo_fader_mode_1
	move.b	#FALSE,(a0,d1.w)	; state fade out
	addq.w	#BYTE_SIZE,d1		; next column
	cmp.w	d2,d1			; columns faded out ?
	bgt.s	ccfo_fader_mode_skip
	move.w	d1,ccfo_start(a3)
	rts
; fade out from right to left
	CNOP 0,4
ccfo_fader_mode_2
	move.w	d1,d0			; start value
	neg.w	d0
	addq.w	#BYTE_SIZE,d1		; next column
	move.b	#FALSE,(cl2_display_width-1)-1(a0,d0.w) ; state fade out
	cmp.w	d2,d1			; columns faded out ?
	bgt.s	ccfo_fader_mode_skip
	move.w	d1,ccfo_start(a3)
	rts
; fade out from left to right simutaneously
	CNOP 0,4
ccfo_fader_mode_3
	move.b	#FALSE,(a0,d1.w)	; state fade out
	move.w	d1,d0			; start value
	neg.w	d0
	addq.w	#BYTE_SIZE,d1		; next column
	lsr.w	#1,d2			; columns center
	move.b	#FALSE,(cl2_display_width-1)-1(a0,d0.w) ; state fade out
	cmp.w	d2,d1			; columns faded out ?
	bgt.s	ccfo_fader_mode_skip
	move.w	d1,ccfo_start(a3)
	rts
; fade in from left and right every second column simutanleously
	CNOP 0,4
ccfo_fader_mode_4
	move.b	#FALSE,(a0,d1.w)	; state fade out
	move.w	d1,d0			; start value
	neg.w	d0
	addq.w	#WORD_SIZE,d1		; übernächste Spalte
	move.b	#FALSE,(cl2_display_width-1)-1(a0,d0.w) ; state fade out
	cmp.w	d2,d1			; columns faded out ?
	bgt.s	ccfo_fader_mode_skip
	move.w	d1,ccfo_start(a3)
	rts
	CNOP 0,4
ccfo_fader_mode_skip
	move.w	#FALSE,ccfo_active(a3)
	rts

	CNOP 0,4
rgb8_colors_fader_cross
	movem.l a4-a6,-(a7)
	tst.w	cfc_rgb8_active(a3)
	bne.s	rgb8_colors_fader_cross_quit
	move.w	cfc_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	cfc_rgb8_fader_angle_speed,d0 ; next angle
	cmp.w	#sine_table_length/2,d0	; angle <= 180° ?
	ble.s	rgb8_colors_fader_cross_skip
	MOVEF.W sine_table_length/2,d0	; 180°
rgb8_colors_fader_cross_skip
	move.w	d0,cfc_rgb8_fader_angle(a3) 
	MOVEF.W cfc_rgb8_colors_number*3,d6 ; RGB counter
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L cfc_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	cfc_rgb8_fader_center,d0
	lea	pf1_rgb8_color_table+(1+(((color_values_number1*segments_number1)+hst_color_gradient_y_pos)*2))*LONGWORD_SIZE(pc),a0 ; color values buffer
	lea	cfc_rgb8_color_table(pc),a1 ; target color values
	move.w	cfc_rgb8_color_table_start(a3),d1
	MULUF.W 8,d1			; * 64 = offset in color table
	lea	(a1,d1.w*8),a1
	move.w	d0,a5			; increment/decrement blue
	swap	d0
	clr.w	d0
	move.l	d0,a2			; increment/decrement red
	lsr.l	#8,d0
	move.l	d0,a4			; increment/decrement green
	MOVEF.W cfc_rgb8_colors_number-1,d7
	bsr	cfc_rgb8_fader_loop
	move.w	d6,cfc_rgb8_colors_counter(a3) ; fading finished ?
	bne.s	rgb8_colors_fader_cross_quit
	move.w	#FALSE,cfc_rgb8_active(a3)
rgb8_colors_fader_cross_quit
	movem.l (a7)+,a4-a6
	rts

	RGB8_COLOR_FADER cfc

	CNOP 0,4
cfc_rgb8_copy_color_table
	IFNE cl1_size2
		move.l	a4,-(a7)
	ENDC
	tst.w	cfc_rgb8_copy_colors_active(a3)
	bne	cfc_rgb8_copy_color_table_quit
	move.w	#RB_NIBBLES_MASK,d3
	moveq	#cfc_rgb8_start_color,d4 ; color registers counter
	lea	pf1_rgb8_color_table+(1+(((color_values_number1*segments_number1)+hst_color_gradient_y_pos)*2))*LONGWORD_SIZE(pc),a0 ; color values buffer
	move.l	cl1_display(a3),a1 
	ADDF.W	cl1_COLOR01_high6+WORD_SIZE,a1
	IFNE cl1_size1
		move.l	cl1_construction1(a3),a2 
		ADDF.W	cl1_COLOR01_high6+WORD_SIZE,a2
	ENDC
	IFNE cl1_size2
		move.l	cl1_construction2(a3),a4 
		ADDF.W	cl1_COLOR01_high6+WORD_SIZE,a4
	ENDC
	MOVEF.W cfc_rgb8_colors_number-1,d7
cfc_rgb8_copy_color_table_loop
	move.l	(a0)+,d0		; RGB8 value
	move.l	d0,d2	
	RGB8_TO_RGB4_HIGH d0,d1,d3
	move.w	d0,(a1)			; COLORxx high bits
	IFNE cl1_size1
		move.w	d0,(a2)		; COLORxx high bits
	ENDC
	IFNE cl1_size2
		move.w	d0,(a4)		; COLORxx high bits
	ENDC
	RGB8_TO_RGB4_LOW d2,d1,d3
	move.w	d2,cl1_COLOR01_low6-cl1_COLOR01_high6(a1) ; COLORxx low bits
	addq.w	#QUADWORD_SIZE,a1	; next color register
	IFNE cl1_size1
		move.w	d2,cl1_COLOR01_low6-cl1_COLOR01_high6(a2) ; COLORxx low bits
		addq.w	#QUADWORD_SIZE,a2 ; next color register
	ENDC
	IFNE cl1_size2
		move.w	d2,cl1_COLOR01_low6-cl1_COLOR01_high6(a4) ; COLORxx low bits
		addq.w	#QUADWORD_SIZE,a4 ; next color register
	ENDC
	addq.b	#2,d4			; increment color registers counter
	cmp.b	#cfc_rgb8_colors_per_bank-1,d4
	ble.s	cfc_rgb8_copy_color_table_skip
	and.b	#cfc_rgb8_colors_per_bank-1,d4
	addq.w	#LONGWORD_SIZE,a1 	; skip CMOVE
	IFNE cl1_size1
		addq.w	#LONGWORD_SIZE,a2 ; skip CMOVE
	ENDC
	IFNE cl1_size2
		addq.w	#LONGWORD_SIZE,a4 ; skip CMOVE
	ENDC
cfc_rgb8_copy_color_table_skip
	dbf	d7,cfc_rgb8_copy_color_table_loop
	tst.w	cfc_rgb8_colors_counter(a3) ; fading finished ?
	bne.s	cfc_rgb8_copy_color_table_quit
	move.w	#FALSE,cfc_rgb8_copy_colors_active(a3)
	move.w	#cfc_rgb8_fader_delay,cfc_rgb8_fader_delay_counter(a3)
	move.w	cfc_rgb8_color_table_start(a3),d0
	addq.w	#1,d0			; next color table
	and.w	#cfc_rgb8_color_tables_number-1,d0 ; remove overflow
	move.w	d0,cfc_rgb8_color_table_start(a3)
cfc_rgb8_copy_color_table_quit
	IFNE cl1_size2
		move.l	(a7)+,a4
	ENDC
	rts

	CNOP 0,4
control_counters
	move.w	cfc_rgb8_fader_delay_counter(a3),d0
	bmi.s	control_counters_skip2
	subq.w	#1,d0
	bpl.s	control_counters_skip1
	move.w	#cfc_rgb8_colors_number*3,cfc_rgb8_colors_counter(a3)
	clr.w	cfc_rgb8_copy_colors_active(a3)
	clr.w	cfc_rgb8_active(a3)
	move.w	#sine_table_length/4,cfc_rgb8_fader_angle(a3) ; 90°
control_counters_skip1
	move.w	d0,cfc_rgb8_fader_delay_counter(a3) 
control_counters_skip2
	move.w	hst_text_delay_counter(a3),d0
	bmi.s	control_counters_skip4
	subq.w	#1,d0
	bpl.s	control_counters_skip3
	move.w	#hst_horiz_scroll_speed1,hst_horiz_scroll_speed(a3)
	moveq	#FALSE,d0		; stop counter
control_counters_skip3
	move.w	d0,hst_text_delay_counter(a3) 
control_counters_skip4
	move.w	quit_delay_counter(a3),d0
	bmi.s	control_counters_quit
	subq.w	#1,d0
	bpl.s	control_counters_skip7
	clr.w	pt_music_fader_active(a3)
	tst.w	logo_enabled(a3)
	bne.s	control_counters_skip5
	clr.w	slbo_active(a3)
control_counters_skip5
	clr.w	ccfo_active(a3)
	move.w	#1,ccfo_delay_counter(a3) ; deactivate counter
	tst.w	ccfi_active(a3)
	bne.s	control_counters_skip6
	move.w	#FALSE,ccfi_active(a3)
control_counters_skip6
	clr.w	bfo_active(a3)
	clr.w	bf_convert_colors_active(a3)
	move.w	#bf_colors_number*3,bf_colors_counter(a3)
	tst.w	bfi_active(a3)
	bne.s	control_counters_skip7
	move.w	#FALSE,bfi_active(a3)
control_counters_skip7
	move.w	d0,quit_delay_counter(a3)
control_counters_quit
	rts

	CNOP 0,4
mouse_handler
	btst	#CIAB_GAMEPORT0,CIAPRA(a4) ; LMB pressed ?
	beq.s	mh_exit_demo
	rts
	CNOP 0,4
mh_exit_demo
	move.w	#FALSE,pt_effects_handler_active(a3)
	tst.w	hst_enabled(a3)
	bne.s	mh_exit_demo_skip2
	tst.w	hsl_active(a3)
	bne.s	mh_exit_demo_skip1
	clr.w	hsl_stop_active(a3)
	move.w	#sine_table_length/2,hsl_stop_x_angle(a3) ; 180°
mh_exit_demo_skip1
	move.w	#hst_horiz_scroll_speed2,hst_horiz_scroll_speed(a3) ; scrolltext double speed
	move.w	#hst_stop_text-hst_text,hst_text_table_start(a3) ; no characters
	clr.w	quit_active(a3)		; stop intro after scrolltext stop
	bra.s	mh_exit_demo_quit
	CNOP 0,4
mh_exit_demo_skip2
	tst.w	hsl_active(a3)
	bne.s	mh_exit_demo_skip3
	clr.w	hsl_stop_active(a3)
	move.w	#sine_table_length/2,hsl_stop_x_angle(a3) ; 180°
mh_exit_demo_skip3
	move.w	#quit_delay,quit_delay_counter(a3)
mh_exit_demo_quit
	rts


	INCLUDE "int-autovectors-handlers.i"

	IFEQ pt_ciatiming_enabled
		CNOP 0,4
ciab_ta_int_server
	ENDC

	IFNE pt_ciatiming_enabled
		CNOP 0,4
VERTB_int_server
	ENDC

; PT-Replay
	IFEQ pt_music_fader_enabled
		bsr.s	pt_music_fader
		bra.s	pt_PlayMusic

		PT_FADE_OUT_VOLUME stop_fx_active

		CNOP 0,4
	ENDC

	IFD PROTRACKER_VERSION_2.3A 
		PT2_REPLAY pt_effects_handler
	ENDC

	IFD PROTRACKER_VERSION_3.0B
		PT3_REPLAY pt_effects_handler
	ENDC

	CNOP 0,4
pt_effects_handler
	tst.w	pt_effects_handler_active(a3)
	bne.s	pt_effects_handler_quit
	move.b	n_cmdlo(a2),d0
	lsr.b	#4,d0
	cmp.b	#$1,d0
	beq.s	pt_start_bar_fader_in
	cmp.b	#$2,d0
	beq.s	pt_start_scrolltext
	cmp.b	#$3,d0
	beq.s	pt_start_scroll_logo_bottom_in
	cmp.b	#$4,d0
	beq.s	pt_start_chunky_columns_fader_in
	cmp.b	#$5,d0
	beq.s	pt_toggle_stripes_y_movement
	cmp.b	#$6,d0
	beq.s	pt_start_horiz_logo_scroll
	cmp.b	#$7,d0
	beq.s	pt_stop_horiz_logo_scroll
	cmp.b	#$8,d0
	beq.s	pt_restart_scrolltext
	cmp.b	#$9,d0
	beq.s	pt_select_channel
pt_effects_handler_quit
	rts
	CNOP 0,4
pt_start_bar_fader_in
	clr.w	bfi_active(a3)
	move.w	#bf_colors_number*3,bf_colors_counter(a3)
	clr.w	bf_convert_colors_active(a3)
	rts
	CNOP 0,4
pt_start_scrolltext
	clr.w	hst_enabled(a3)
	rts
	CNOP 0,4
pt_start_scroll_logo_bottom_in
	clr.w	slbi_active(a3)
	rts
	CNOP 0,4
pt_start_chunky_columns_fader_in
	clr.w	ccfi_active(a3)
	move.w	#1,ccfi_delay_counter(a3) ; deactivate delay counter
	rts
	CNOP 0,4
pt_toggle_stripes_y_movement
	neg.w	sp_stripes_y_angle_speed(a3) ; reverse direction
	rts
	CNOP 0,4
pt_start_horiz_logo_scroll
	clr.w	hsl_active(a3)
	clr.w	hsl_start_active(a3)
	move.w	#sine_table_length/4,hsl_start_x_angle(a3) ; 90°
	rts
	CNOP 0,4
pt_stop_horiz_logo_scroll
	clr.w	hsl_stop_active(a3)
	move.w	#sine_table_length/2,hsl_stop_x_angle(a3) ; 180°
	rts
	CNOP 0,4
pt_restart_scrolltext
	clr.w	hst_enabled(a3)
	move.w	#hst_restart_text-hst_text,hst_text_table_start(a3) ; skip countdown text
	rts
	CNOP 0,4
pt_select_channel
	moveq	#NIBBLE_MASK_LOW,d0
	and.b	n_cmdlo(a2),d0
        move.w	d0,vm_audio_channel(a3)
	rts

	CNOP 0,4
ciab_tb_int_server
	PT_TIMER_INTERRUPT_SERVER

	CNOP 0,4
EXTER_int_server
	rts

	CNOP 0,4
nmi_int_server
	rts


	INCLUDE "help-routines.i"


	INCLUDE "sys-structures.i"

	CNOP 0,4
pf1_rgb8_color_table
	DC.L color00_bits
	DS.L pf1_colors_number-2
	DC.L color255_bits

	CNOP 0,4
spr_ptrs_display
	DS.L spr_number

	CNOP 0,4
sine_table
	INCLUDE "sine-table-256x32.i"

; PT-Replay
	INCLUDE "music-tracker/pt-invert-table.i"

	INCLUDE "music-tracker/pt-vibrato-tremolo-table.i"

	IFD PROTRACKER_VERSION_2.3A 
		INCLUDE "music-tracker/pt2-period-table.i"
	ENDC

	IFD PROTRACKER_VERSION_3.0B
		INCLUDE "music-tracker/pt3-period-table.i"
	ENDC

	INCLUDE "music-tracker/pt-temp-channel-data-tables.i"

	INCLUDE "music-tracker/pt-sample-starts-table.i"

	INCLUDE "music-tracker/pt-finetune-starts-table.i"

; Volume-Meter
	CNOP 0,2
vm_audio_channel1_info
	DS.B audio_channel_info_size

	CNOP 0,2
vm_audio_channel2_info
	DS.B audio_channel_info_size

	CNOP 0,2
vm_audio_channel3_info
	DS.B audio_channel_info_size

	CNOP 0,2
vm_audio_channel4_info
	DS.B audio_channel_info_size

; Twisted-Bars
	CNOP 0,4
tb_colorfradients
	INCLUDE "Daten:Asm-Sources.AGA/projects/FlexiTwister/colortables/Bars-Colorgradient3.ct"

	CNOP 0,4
tb_yz_coords
	DS.W tb_bars_number*(cl2_display_width-1)*2

; Striped-Pattern
	CNOP 0,2
sp_stripes_y_coords
	DS.W sp_stripe_height*sp_stripes_number

	CNOP 0,2
sp_color_offsets_table
	DS.W sp_stripe_height*sp_stripes_number

; Horiz-Scrolltext
hst_ascii
	DC.B "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.!?-'():\/#*>< "
hst_ascii_end
	EVEN

	CNOP 0,2
hst_characters_offsets
	DS.W hst_ascii_end-hst_ascii

	CNOP 0,2
hst_characters_x_positions
	DS.W hst_text_characters_number

	CNOP 0,4
hst_characters_image_ptrs
	DS.L hst_text_characters_number

; Bar-Fader
	CNOP 0,4
bfi_color_table
	INCLUDE "Daten:Asm-Sources.AGA/projects/FlexiTwister/colortables/Striped-Bar-Colorgradient3.ct"

	CNOP 0,4
bfo_color_table
	REPT ssb_bar_height
		DC.L color00_bits
	ENDR

	CNOP 0,4
bf_color_cache
	REPT ssb_bar_height
		DC.L color00_bits
	ENDR

; Columns_fader
ccf_columns_mask
	REPT cl2_display_width-1
		DC.B FALSE
	ENDR

; Color-Fader-Cross
	CNOP 0,4
cfc_rgb8_color_table
	INCLUDE "Daten:Asm-Sources.AGA/projects/FlexiTwister/colortables/Font-Colorgradient5.ct"


	INCLUDE "sys-variables.i"


	INCLUDE "sys-names.i"


	INCLUDE "error-texts.i"


; Horiz-Scrolltext
hst_text
	REPT hst_text_characters_number/(hst_origin_character_x_size/hst_text_character_x_size)
		DC.B " "
	ENDR
	DC.B " 3             2              1                            "
hst_restart_text
	DC.B " RESISTANCE PRESENTS THEIR CONTRIBUTION TO        GERP 2025      ",ASCII_CTRL_P,"   >FLEXI TWISTER<   ",ASCII_CTRL_P,"          "

	DC.B "AGA POWER WITH A 8 SPRITES-LOGO IN OVERSCAN!!!           "

	REPT (hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size)
		DC.B " "
	ENDR

	DC.B "GREETINGS      ",ASCII_CTRL_P,"         "
	DC.B ">TO ALL ON GERP 2025<         "
	DC.B ">DESIRE<         "
	DC.B ">EPHIDRENA<         "
	DC.B ">FOCUS DESIGN<         "
	DC.B ">GHOSTOWN<         "
	DC.B ">NAH-KOLOR<         "
	DC.B ">PLANET JAZZ<         "
	DC.B ">SOFTWARE FAILURE<         "
	DC.B ">TEK<         "
	DC.B ">WANTED TEAM<         "

	DC.B "         "
	DC.B "CREDITS       ",ASCII_CTRL_P,"       "
	DC.B "CODING AND MUSIC       DISSIDENT      ",ASCII_CTRL_P,"    "
	DC.B "GRAPHICS          OPTIC        ",ASCII_CTRL_P,"           "

	REPT (hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size)
		DC.B " "
	ENDR
	REPT (hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size)
		DC.B "*"
	ENDR
	REPT (hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size)
		DC.B "*"
	ENDR
	REPT (hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size)
		DC.B "*"
	ENDR

	DC.B "SEE YOU IN ANOTHER PRODUCTION..."
hst_stop_text
	REPT ((hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size))+1
		DC.B " "
	ENDR
	DC.B ASCII_CTRL_S," "

	EVEN


	DC.B "$VER: "
	DC.B "RSE-FlexiTwister "
	DC.B "1.7 beta "
	DC.B "(17.11.24)"
	DC.B "© 2024 by Resistance",0
	EVEN


; audio data

; PT-Replay
	IFEQ pt_split_module_enabled
pt_auddata SECTION pt_audio,DATA
		INCBIN "Daten:Asm-Sources.AGA/projects/FlexiTwister/modules/MOD.CatchyTune2ReRemix.song"
pt_audsmps SECTION pt_audio2,DATA_C
		INCBIN "Daten:Asm-Sources.AGA/projects/FlexiTwister/modules/MOD.CatchyTune2ReRemix.smps"
	ELSE
pt_auddata SECTION pt_audio,DATA_C
		INCBIN "Daten:Asm-Sources.AGA/projects/FlexiTwister/modules/mod.CatchyTune2ReRemix"
	ENDC


; graphics data

; Horiz-Scrolltext
hst_image_data SECTION hst_gfx,DATA_C
	INCBIN "Daten:Asm-Sources.AGA/projects/FlexiTwister/fonts/16x16x2-Font.rawblit"

; Logo
lg_image_data SECTION lg_gfx,DATA
	INCBIN "Daten:Asm-Sources.AGA/projects/FlexiTwister/graphics/RSE_FT_Logo_WIP03e-b2.rawblit"

	END
