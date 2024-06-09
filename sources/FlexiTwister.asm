; ##############################
; # Programm: FlexiTwister.asm #
; # Autor:    Christian Gerbig #
; # Datum:    02.06.2024       #
; # Version:  1.4 Beta         #
; # CPU:      68020+           #
; # FASTMEM:  -                #
; # Chipset:  AGA              #
; # OS:       3.0+             #
; ##############################

; V.1.0 Beta
; Ertes Release

; V.1.1 Beta
; - Richtungsändrung der gestreiften Bar durch Modul getriggert
; - Horizontale Bewegung des Logos durch Modul getriggert
; - Ausfaden verbessert

; V.1.2 Beta
; - Logo gegen Resistance-Logo ausgetauscht
; - Alle Paletten geändert
; - Scrolltext geändert

; V.1.3 Beta
; - Convert-Color-Table der Bar wird schon bei den Inits aufgerufen, damit schon
;   zu Beginn die Farbwerte der Bar richtig dargestellt werden.
; - Hintergrundfarbe ist jetzt 100% global und geändert
; - Code optimiert
; - Mouse-Handler: Out-Fader stoppen ggf. In-Fader
; - Bars-Equalizer ist nun empfindlicher und reagiert schneller
; - Mit überarbeitetem Modul

; V.1.4 Beta
; - Logo-Scroller optimiert
; - Fader optimiert
; - Init Copperlisten überarbeitet
; - Mit überarbeiteten Include-Files


; PT 8xy-Befehl
; 810 Start Bar-Fader-In
; 820 Start Scrolltext
; 830 Start Scroll-Logo-Bottom-In
; 840 Start Chunky-Columns-Fader-In
; 850 Toggle Stripes Y-Movement
; 860 Start Horiz-Logo-Scroll
; 861 Stop Horiz-Logo-Scroll
; 870 Restart Scrolltext

; Ausführungszeit 68020: 253 Rasterzeilen

  SECTION code_and_variables,CODE

  MC68040


; ** Library-Includes V.3.x nachladen **
; --------------------------------------
  ;INCDIR  "OMA:include/"
  INCDIR "Daten:include3.5/"

  INCLUDE "dos/dos.i"
  INCLUDE "dos/dosextens.i"
  INCLUDE "libraries/dos_lib.i"

  INCLUDE "exec/exec.i"
  INCLUDE "exec/exec_lib.i"

  INCLUDE "graphics/GFXBase.i"
  INCLUDE "graphics/videocontrol.i"
  INCLUDE "graphics/graphics_lib.i"

  INCLUDE "intuition/intuition.i"
  INCLUDE "intuition/intuition_lib.i"

  INCLUDE "resources/cia_lib.i"

  INCLUDE "hardware/adkbits.i"
  INCLUDE "hardware/blit.i"
  INCLUDE "hardware/cia.i"
  INCLUDE "hardware/custom.i"
  INCLUDE "hardware/dmabits.i"
  INCLUDE "hardware/intbits.i"

  INCDIR "Daten:Asm-Sources.AGA/normsource-includes/"


; ** Konstanten **
; ----------------

  INCLUDE "equals.i"

requires_68030                 EQU FALSE  
requires_68040                 EQU FALSE
requires_68060                 EQU FALSE
requires_fast_memory           EQU FALSE
requires_multiscan_monitor     EQU FALSE

workbench_start                EQU FALSE
workbench_fade                 EQU FALSE
text_output                    EQU FALSE

open_border                    EQU TRUE

pt_v3.0b
  IFD pt_v2.3a
    INCLUDE "music-tracker/pt2-equals.i"
  ENDC
  IFD pt_v3.0b
    INCLUDE "music-tracker/pt3-equals.i"
  ENDC
pt_ciatiming                   EQU TRUE
pt_usedfx                      EQU %1111110100001000
pt_usedefx                     EQU %0000100000000000
pt_finetune                    EQU FALSE
  IFD pt_v3.0b
pt_metronome                   EQU FALSE
  ENDC
pt_track_channel_volumes       EQU TRUE
pt_track_channel_periods       EQU FALSE
pt_music_fader                 EQU TRUE
pt_split_module                EQU TRUE

tb_quick_clear                 EQU FALSE
tb_restore_cl_by_cpu           EQU TRUE
tb_restore_cl_by_blitter       EQU FALSE

DMABITS                        EQU DMAF_SPRITE+DMAF_BLITTER+DMAF_COPPER+DMAF_RASTER+DMAF_MASTER+DMAF_SETCLR

  IFEQ pt_ciatiming
INTENABITS                     EQU INTF_EXTER+INTF_INTEN+INTF_SETCLR
  ELSE
INTENABITS                     EQU INTF_VERTB+INTF_EXTER+INTF_INTEN+INTF_SETCLR
  ENDC

CIAAICRBITS                    EQU CIAICRF_SETCLR
  IFEQ pt_ciatiming
CIABICRBITS                    EQU CIAICRF_TA+CIAICRF_TB+CIAICRF_SETCLR
  ELSE
CIABICRBITS                    EQU CIAICRF_TB+CIAICRF_SETCLR
  ENDC

COPCONBITS                     EQU TRUE

pf1_x_size1                    EQU 512
pf1_y_size1                    EQU 256+112
pf1_depth1                     EQU 1
pf1_x_size2                    EQU 512
pf1_y_size2                    EQU 256+112
pf1_depth2                     EQU 1
pf1_x_size3                    EQU 512
pf1_y_size3                    EQU 256+112
pf1_depth3                     EQU 1
pf1_colors_number              EQU 256

pf2_x_size1                    EQU 0
pf2_y_size1                    EQU 0
pf2_depth1                     EQU 0
pf2_x_size2                    EQU 0
pf2_y_size2                    EQU 0
pf2_depth2                     EQU 0
pf2_x_size3                    EQU 0
pf2_y_size3                    EQU 0
pf2_depth3                     EQU 0
pf2_colors_number              EQU 0
pf_colors_number               EQU pf1_colors_number+pf2_colors_number
pf_depth                       EQU pf1_depth3+pf2_depth3

extra_pf_number                EQU 0

spr_number                     EQU 8
spr_x_size1                    EQU 0
spr_x_size2                    EQU 64
spr_depth                      EQU 2
spr_colors_number              EQU 0 ;16
spr_odd_color_table_select     EQU 0
spr_even_color_table_select    EQU 0
spr_used_number                EQU 8

  IFD pt_v2.3a
audio_memory_size              EQU 0
  ENDC
  IFD pt_v3.0b
audio_memory_size              EQU 2
  ENDC

disk_memory_size               EQU 0

chip_memory_size               EQU 0

AGA_OS_Version                 EQU 39

  IFEQ pt_ciatiming
CIABCRABITS                    EQU CIACRBF_LOAD
  ENDC
CIABCRBBITS                    EQU CIACRBF_LOAD+CIACRBF_RUNMODE ;Oneshot mode
CIAA_TA_value                  EQU 0
CIAA_TB_value                  EQU 0
  IFEQ pt_ciatiming
CIAB_TA_value                  EQU 14187 ;= 0.709379 MHz * [20000 µs = 50 Hz duration for one frame on a PAL machine]
;CIAB_TA_value                  EQU 14318 ;= 0.715909 MHz * [20000 µs = 50 Hz duration for one frame on a NTSC machine]
  ELSE
CIAB_TA_value                  EQU 0
  ENDC
CIAB_TB_value                  EQU 362 ;= 0.709379 MHz * [511.43 µs = Lowest note period C1 with Tuning=-8 * 2 / PAL clock constant = 907*2/3546895 ticks per second]
                                 ;= 0.715909 MHz * [506.76 µs = Lowest note period C1 with Tuning=-8 * 2 / NTSC clock constant = 907*2/3579545 ticks per second]
CIAA_TA_continuous             EQU FALSE
CIAA_TB_continuous             EQU FALSE
  IFEQ pt_ciatiming
CIAB_TA_continuous             EQU TRUE
  ELSE
CIAB_TA_continuous             EQU FALSE
  ENDC
CIAB_TB_continuous             EQU FALSE

beam_position                  EQU $133 ;Wegen Music-Fader

pixel_per_line                 EQU 336
visible_pixels_number          EQU 352
visible_lines_number           EQU 256
MINROW                         EQU VSTART_256_lines

pf_pixel_per_datafetch         EQU 16 ;1x
DDFSTRTBITS                    EQU DDFSTART_320_pixel
DDFSTOPBITS                    EQU DDFSTOP_overscan_16_pixel
spr_pixel_per_datafetch        EQU 64 ;4x

display_window_HSTART          EQU HSTART_352_pixel
display_window_VSTART          EQU MINROW
DIWSTRTBITS                    EQU ((display_window_VSTART&$ff)*DIWSTRTF_V0)+(display_window_HSTART&$ff)
display_window_HSTOP           EQU HSTOP_352_pixel
display_window_VSTOP           EQU VSTOP_256_lines
DIWSTOPBITS                    EQU ((display_window_VSTOP&$ff)*DIWSTOPF_V0)+(display_window_HSTOP&$ff)

pf1_plane_width                EQU pf1_x_size3/8
data_fetch_width               EQU pixel_per_line/8
pf1_plane_moduli               EQU (pf1_plane_width*(pf1_depth3-1))+pf1_plane_width-data_fetch_width

BPLCON0BITS                    EQU BPLCON0F_ECSENA+((pf_depth>>3)*BPLCON0F_BPU3)+(BPLCON0F_COLOR)+((pf_depth&$07)*BPLCON0F_BPU0) ;lores
BPLCON1BITS                    EQU TRUE
BPLCON2BITS                    EQU BPLCON2F_PF2P2
BPLCON3BITS1                   EQU TRUE
BPLCON3BITS2                   EQU BPLCON3BITS1+BPLCON3F_LOCT
BPLCON4BITS                    EQU (BPLCON4F_OSPRM4*spr_odd_color_table_select)+(BPLCON4F_ESPRM4*spr_even_color_table_select)
DIWHIGHBITS                    EQU (((display_window_HSTOP&$100)>>8)*DIWHIGHF_HSTOP8)+(((display_window_VSTOP&$700)>>8)*DIWHIGHF_VSTOP8)+(((display_window_HSTART&$100)>>8)*DIWHIGHF_HSTART8)+((display_window_VSTART&$700)>>8)
FMODEBITS                      EQU FMODEF_SPR32+FMODEF_SPAGEM
COLOR00BITS                    EQU $001429
COLOR255BITS                   EQU COLOR00BITS

cl2_display_x_size             EQU 352+8 ;45 Spalten
cl2_display_width              EQU cl2_display_x_size/8
cl2_display_y_size             EQU visible_lines_number
  IFEQ open_border
cl2_HSTART1                    EQU display_window_HSTART-(1*CMOVE_slot_period)-4
  ELSE
cl2_HSTART1                    EQU display_window_HSTART-4
  ENDC
cl2_VSTART1                    EQU MINROW
cl2_HSTART2                    EQU $00
cl2_VSTART2                    EQU beam_position&$ff

sine_table_length              EQU 256

; **** Logo ****
lg_image_x_size                EQU 256
lg_image_plane_width           EQU lg_image_x_size/8
lg_image_y_size                EQU 54
lg_image_depth                 EQU 4
lg_image_x_centre              EQU (visible_pixels_number-lg_image_x_size)/2

lg_image_x_position            EQU display_window_HSTART+lg_image_x_centre
lg_image_y_position            EQU MINROW

; **** PT-Replay ****
pt_fade_out_delay              EQU 1 ;Tick

; **** Volume-Meter ****
vm_source_channel              EQU 2 ;Nr. 0..3
vm_period_div                  EQU 26
vm_max_period_step             EQU 16

; **** Twisted-Bars ****
tb_bars_number                 EQU 3
tb_bar_height                  EQU 32
tb_y_radius                    EQU (visible_lines_number-tb_bar_height)/2
tb_y_centre                    EQU (cl2_display_y_size-tb_bar_height)/2
tb_y_angle_step_radius         EQU 6
tb_y_angle_step_centre         EQU 3
tb_y_angle_step_step           EQU 1
tb_y_distance                  EQU sine_table_length/tb_bars_number

; **** Clear-Blit ****
tb_clear_blit_x_size           EQU 16
  IFEQ open_border
tb_clear_blit_y_size           EQU cl2_display_y_size*(cl2_display_width+2)
  ELSE
tb_clear_blit_y_size           EQU cl2_display_y_size*(cl2_display_width+1)
  ENDC

; **** Restore-Blit ****
tb_restore_blit_x_size         EQU 16
tb_restore_blit_width          EQU tb_restore_blit_x_size/8
tb_restore_blit_y_size         EQU cl2_display_y_size

; **** Sine-Striped-Bar ****
ssb_bar_height                 EQU 80
ssb_y_radius                   EQU 112
ssb_y_center                   EQU (cl2_display_y_size-ssb_bar_height+ssb_y_radius)/2
ssb_y_angle_speed              EQU 3

; **** Stripes-Pattern ****
sp_stripes_y_radius            EQU ssb_bar_height/2
sp_stripes_y_center            EQU ssb_bar_height/2
sp_stripes_y_angle_step        EQU 1
sp_stripes_y_angle_speed       EQU 2
sp_stripes_number              EQU 8
sp_stripe_height               EQU 16

; **** Horiz-Scrolltext ****
hst_chear_image_x_size         EQU 320
hst_image_plane_width          EQU hst_chear_image_x_size/8
hst_image_depth                EQU 1
hst_origin_character_x_size    EQU 32
hst_origin_character_y_size    EQU 32

hst_text_character_x_size      EQU 16
hst_text_character_width       EQU hst_text_character_x_size/8
hst_text_character_y_size      EQU hst_origin_character_y_size
hst_text_character_depth       EQU hst_image_depth

hst_horiz_scroll_window_x_size EQU visible_pixels_number+hst_text_character_x_size
hst_horiz_scroll_window_width  EQU hst_horiz_scroll_window_x_size/8
hst_horiz_scroll_window_y_size EQU hst_text_character_y_size
hst_horiz_scroll_window_depth  EQU hst_image_depth
hst_horiz_scroll_speed1        EQU 3
hst_horiz_scroll_speed2        EQU 6

hst_text_character_x_restart   EQU hst_horiz_scroll_window_x_size
hst_text_characters_number     EQU hst_horiz_scroll_window_x_size/hst_text_character_x_size

hst_text_x_position            EQU 0
hst_text_y_position            EQU (pf1_y_size3-hst_text_character_y_size)/2

hst_colorrun_height            EQU hst_text_character_y_size
hst_colorrun_y_pos             EQU (ssb_bar_height-hst_text_character_y_size)/2

hst_copy_blit_x_size           EQU hst_text_character_x_size
hst_copy_blit_y_size           EQU hst_text_character_y_size*hst_text_character_depth

hst_horiz_scroll_blit_x_size   EQU hst_horiz_scroll_window_x_size
hst_horiz_scroll_blit_y_size   EQU hst_horiz_scroll_window_y_size*hst_horiz_scroll_window_depth

; **** Bar-Fader ****
bf_color_table_offset          EQU 0
bf_colors_number               EQU ssb_bar_height

; **** Bar-Fader-In ****
bfi_fader_speed_max            EQU 16
bfi_fader_radius               EQU bfi_fader_speed_max
bfi_fader_center               EQU bfi_fader_speed_max+1
bfi_fader_angle_speed          EQU 6

; **** Bar-Fader-Out ****
bfo_fader_speed_max            EQU 8
bfo_fader_radius               EQU bfo_fader_speed_max
bfo_fader_center               EQU bfo_fader_speed_max+1
bfo_fader_angle_speed          EQU 2

; **** Horiz-Scroll-Logo ****
hsl_x_center                   EQU display_window_HSTART+((visible_pixels_number-lg_image_x_size)/2)
hsl_x_angle_speed              EQU 4

hsl_start_x_radius             EQU (visible_pixels_number-lg_image_x_size)/2
hsl_start_x_center             EQU (visible_pixels_number-lg_image_x_size)/2
hsl_start_x_angle_speed        EQU 1

hsl_stop_x_radius              EQU (visible_pixels_number-lg_image_x_size)/2
hsl_stop_x_center              EQU (visible_pixels_number-lg_image_x_size)/2
hsl_stop_x_angle_speed         EQU 1

; **** Scroll-Logo-Bottom ****
slb_y_radius                   EQU visible_lines_number
slb_y_center                   EQU visible_lines_number

; **** Scroll-Logo-Bottom-In ****
slbi_y_angle_speed             EQU 2

; **** Scroll-Logo-Bottom-Out ****
slbo_y_angle_speed             EQU 1

; **** Chunky-Columns-Fader-In ****
ccfi_mode1                     EQU 0
ccfi_mode2                     EQU 1
ccfi_mode3                     EQU 2
ccfi_mode4                     EQU 3
ccfi_delay_speed               EQU 1
ccfi_columns_delay             EQU 1

; **** Chunky-Columns-Fader-Out ****
ccfo_mode1                     EQU 0
ccfo_mode2                     EQU 1
ccfo_mode3                     EQU 2
ccfo_mode4                     EQU 3
ccfo_delay_speed               EQU 1
ccfo_columns_delay             EQU 1


color_step1                    EQU 256/(tb_bar_height/2)
color_step2.1                  EQU 256/(ssb_bar_height/2)
color_step2.2                  EQU 128/(ssb_bar_height/2)
color_step3                    EQU 256/hst_colorrun_height
color_values_number1           EQU tb_bar_height/2
color_values_number2           EQU ssb_bar_height/2
color_values_number3           EQU hst_colorrun_height
segments_number1               EQU tb_bars_number
segments_number2               EQU 4
segments_number3               EQU 1

ct_size1                       EQU color_values_number1*segments_number1
ct_size2                       EQU color_values_number2*segments_number2
ct_size3                       EQU color_values_number3*segments_number3

tb_switch_table_size           EQU ct_size1*2
ssb_switch_table_size          EQU ct_size2

pf1_bitplanes_x_offset         EQU 16+32
pf1_BPL1DAT_x_offset           EQU pf1_bitplanes_x_offset-pf_pixel_per_datafetch


; ## Makrobefehle ##
; ------------------

  INCLUDE "macros.i"


; ** Extra-Memory-Abschnitte **
; ----------------------------
  RSRESET

em_switch_table1 RS.B tb_switch_table_size
em_switch_table2 RS.B ssb_switch_table_size
  RS_ALIGN_LONGWORD
em_color_table   RS.L ct_size2
extra_memory_size RS.B 0


; ** Struktur, die alle Exception-Vektoren-Offsets enthält **
; -----------------------------------------------------------

  INCLUDE "except-vectors-offsets.i"


; ** Struktur, die alle Eigenschaften des Extra-Playfields enthält **
; -------------------------------------------------------------------

  INCLUDE "extra-pf-attributes-structure.i"


; ** Struktur, die alle Eigenschaften der Sprites enthält **
; ----------------------------------------------------------

  INCLUDE "sprite-attributes-structure.i"


; ** Struktur, die alle Registeroffsets der ersten Copperliste enthält **
; -----------------------------------------------------------------------

  RSRESET

cl1_begin        RS.B 0

  INCLUDE "copperlist1-offsets.i"

cl1_COPJMP2      RS.L 1

copperlist1_SIZE RS.B 0


; ** Struktur, die alle Registeroffsets der zweiten Copperliste enthält **
; ------------------------------------------------------------------------

  RSRESET

cl2_extension1      RS.B 0

cl2_ext1_WAIT       RS.L 1
  IFEQ open_border
cl2_ext1_BPL1DAT    RS.L 1
  ENDC
cl2_ext1_BPLCON4_1  RS.L 1
cl2_ext1_BPLCON4_2  RS.L 1
cl2_ext1_BPLCON4_3  RS.L 1
cl2_ext1_BPLCON4_4  RS.L 1
cl2_ext1_BPLCON4_5  RS.L 1
cl2_ext1_BPLCON4_6  RS.L 1
cl2_ext1_BPLCON4_7  RS.L 1
cl2_ext1_BPLCON4_8  RS.L 1
cl2_ext1_BPLCON4_9  RS.L 1
cl2_ext1_BPLCON4_10 RS.L 1
cl2_ext1_BPLCON4_11 RS.L 1
cl2_ext1_BPLCON4_12 RS.L 1
cl2_ext1_BPLCON4_13 RS.L 1
cl2_ext1_BPLCON4_14 RS.L 1
cl2_ext1_BPLCON4_15 RS.L 1
cl2_ext1_BPLCON4_16 RS.L 1
cl2_ext1_BPLCON4_17 RS.L 1
cl2_ext1_BPLCON4_18 RS.L 1
cl2_ext1_BPLCON4_19 RS.L 1
cl2_ext1_BPLCON4_20 RS.L 1
cl2_ext1_BPLCON4_21 RS.L 1
cl2_ext1_BPLCON4_22 RS.L 1
cl2_ext1_BPLCON4_23 RS.L 1
cl2_ext1_BPLCON4_24 RS.L 1
cl2_ext1_BPLCON4_25 RS.L 1
cl2_ext1_BPLCON4_26 RS.L 1
cl2_ext1_BPLCON4_27 RS.L 1
cl2_ext1_BPLCON4_28 RS.L 1
cl2_ext1_BPLCON4_29 RS.L 1
cl2_ext1_BPLCON4_30 RS.L 1
cl2_ext1_BPLCON4_31 RS.L 1
cl2_ext1_BPLCON4_32 RS.L 1
cl2_ext1_BPLCON4_33 RS.L 1
cl2_ext1_BPLCON4_34 RS.L 1
cl2_ext1_BPLCON4_35 RS.L 1
cl2_ext1_BPLCON4_36 RS.L 1
cl2_ext1_BPLCON4_37 RS.L 1
cl2_ext1_BPLCON4_38 RS.L 1
cl2_ext1_BPLCON4_39 RS.L 1
cl2_ext1_BPLCON4_40 RS.L 1
cl2_ext1_BPLCON4_41 RS.L 1
cl2_ext1_BPLCON4_42 RS.L 1
cl2_ext1_BPLCON4_43 RS.L 1
cl2_ext1_BPLCON4_44 RS.L 1
cl2_ext1_BPLCON4_45 RS.L 1

cl2_extension1_SIZE RS.B 0

  RSRESET

cl2_begin            RS.B 0

cl2_extension1_entry RS.B cl2_extension1_SIZE*cl2_display_y_size

cl2_WAIT             RS.L 1
cl2_INTREQ           RS.L 1

cl2_end              RS.L 1

copperlist2_SIZE     RS.B 0


; ** Konstanten für die Größe der Copperlisten **
; -----------------------------------------------
cl1_size1        EQU 0
cl1_size2        EQU copperlist1_SIZE
cl1_size3        EQU copperlist1_SIZE

cl2_size1        EQU copperlist2_SIZE
cl2_size2        EQU copperlist2_SIZE
cl2_size3        EQU copperlist2_SIZE


; ** Sprite0-Zusatzstruktur **
; ----------------------------
  RSRESET

spr0_extension1       RS.B 0

spr0_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr0_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*lg_image_y_size

spr0_extension1_SIZE  RS.B 0

; ** Sprite0-Hauptstruktur **
; ---------------------------
  RSRESET

spr0_begin            RS.B 0

spr0_extension1_entry RS.B spr0_extension1_SIZE

spr0_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite0_SIZE          RS.B 0

; ** Sprite1-Zusatzstruktur **
; ----------------------------
  RSRESET

spr1_extension1       RS.B 0

spr1_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr1_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*lg_image_y_size

spr1_extension1_SIZE  RS.B 0

; ** Sprite1-Hauptstruktur **
; ---------------------------
  RSRESET

spr1_begin            RS.B 0

spr1_extension1_entry RS.B spr1_extension1_SIZE

spr1_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite1_SIZE          RS.B 0

; ** Sprite2-Zusatzstruktur **
; ----------------------------
  RSRESET

spr2_extension1       RS.B 0

spr2_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr2_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*lg_image_y_size

spr2_extension1_SIZE  RS.B 0

; ** Sprite2-Hauptstruktur **
; ---------------------------
  RSRESET

spr2_begin            RS.B 0

spr2_extension1_entry RS.B spr2_extension1_SIZE

spr2_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite2_SIZE          RS.B 0

; ** Sprite3-Zusatzstruktur **
; ----------------------------
  RSRESET

spr3_extension1       RS.B 0

spr3_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr3_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*lg_image_y_size

spr3_extension1_SIZE  RS.B 0

; ** Sprite3-Hauptstruktur **
; ---------------------------
  RSRESET

spr3_begin            RS.B 0

spr3_extension1_entry RS.B spr3_extension1_SIZE

spr3_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite3_SIZE          RS.B 0

; ** Sprite4-Zusatzstruktur **
; ----------------------------
  RSRESET

spr4_extension1       RS.B 0

spr4_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr4_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*lg_image_y_size

spr4_extension1_SIZE  RS.B 0

; ** Sprite4-Hauptstruktur **
; ---------------------------
  RSRESET

spr4_begin            RS.B 0

spr4_extension1_entry RS.B spr4_extension1_SIZE

spr4_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite4_SIZE          RS.B 0

; ** Sprite5-Zusatzstruktur **
; ----------------------------
  RSRESET

spr5_extension1       RS.B 0

spr5_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr5_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*lg_image_y_size

spr5_extension1_SIZE  RS.B 0

; ** Sprite5-Hauptstruktur **
; ---------------------------
  RSRESET

spr5_begin            RS.B 0

spr5_extension1_entry RS.B spr5_extension1_SIZE

spr5_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite5_SIZE          RS.B 0

; ** Sprite6-Zusatzstruktur **
; ----------------------------
  RSRESET

spr6_extension1       RS.B 0

spr6_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr6_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*lg_image_y_size

spr6_extension1_SIZE  RS.B 0

; ** Sprite6-Hauptstruktur **
; ---------------------------
  RSRESET

spr6_begin            RS.B 0

spr6_extension1_entry RS.B spr6_extension1_SIZE

spr6_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite6_SIZE          RS.B 0

; ** Sprite7-Zusatzstruktur **
; ----------------------------
  RSRESET

spr7_extension1       RS.B 0

spr7_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr7_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*lg_image_y_size

spr7_extension1_SIZE  RS.B 0

; ** Sprite7-Hauptstruktur **
; ---------------------------
  RSRESET

spr7_begin            RS.B 0

spr7_extension1_entry RS.B spr7_extension1_SIZE

spr7_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite7_SIZE          RS.B 0


; ** Konstanten für die Größe der Spritestrukturen **
; ---------------------------------------------------
spr0_x_size1    EQU spr_x_size1
spr0_y_size1    EQU 0
spr1_x_size1    EQU spr_x_size1
spr1_y_size1    EQU 0
spr2_x_size1    EQU spr_x_size1
spr2_y_size1    EQU 0
spr3_x_size1    EQU spr_x_size1
spr3_y_size1    EQU 0
spr4_x_size1    EQU spr_x_size1
spr4_y_size1    EQU 0
spr5_x_size1    EQU spr_x_size1
spr5_y_size1    EQU 0
spr6_x_size1    EQU spr_x_size1
spr6_y_size1    EQU 0
spr7_x_size1    EQU spr_x_size1
spr7_y_size1    EQU 0

spr0_x_size2    EQU spr_x_size2
spr0_y_size2    EQU sprite0_SIZE/(spr_pixel_per_datafetch/4)
spr1_x_size2    EQU spr_x_size2
spr1_y_size2    EQU sprite1_SIZE/(spr_pixel_per_datafetch/4)
spr2_x_size2    EQU spr_x_size2
spr2_y_size2    EQU sprite2_SIZE/(spr_pixel_per_datafetch/4)
spr3_x_size2    EQU spr_x_size2
spr3_y_size2    EQU sprite3_SIZE/(spr_pixel_per_datafetch/4)
spr4_x_size2    EQU spr_x_size2
spr4_y_size2    EQU sprite4_SIZE/(spr_pixel_per_datafetch/4)
spr5_x_size2    EQU spr_x_size2
spr5_y_size2    EQU sprite5_SIZE/(spr_pixel_per_datafetch/4)
spr6_x_size2    EQU spr_x_size2
spr6_y_size2    EQU sprite6_SIZE/(spr_pixel_per_datafetch/4)
spr7_x_size2    EQU spr_x_size2
spr7_y_size2    EQU sprite7_SIZE/(spr_pixel_per_datafetch/4)


; ** Struktur, die alle Variablenoffsets enthält **
; -------------------------------------------------

  INCLUDE "variables-offsets.i"

; ** Relative offsets for variables **
; ------------------------------------

; **** PT-Replay ****
  IFD pt_v2.3a
    INCLUDE "music-tracker/pt2-variables-offsets.i"
  ENDC
  IFD pt_v3.0b
    INCLUDE "music-tracker/pt3-variables-offsets.i"
  ENDC

pt_trigger_fx_state               RS.W 1

; **** Horiz-Scrolltext ****
hst_image                         RS.L 1
hst_state                         RS.W 1
hst_text_table_start              RS.W 1
hst_text_BLTCON0BITS              RS.W 1
hst_character_toggle_image        RS.W 1
hst_text_y_offset                 RS.W 1
hst_variable_horiz_scroll_speed   RS.W 1

; **** Twisted-Bars ****
tb_y_angle                        RS.W 1
tb_y_angle_step_angle             RS.W 1

; **** Sine-Striped-Bar ****
ssb_y_angle                       RS.W 1

; **** Striped-Pattern ****
sp_stripes_y_angle                RS.W 1
sp_variable_stripes_y_angle_speed RS.W 1

; **** Horiz-Scroll-Logo ****
hsl_state                         RS.W 1
hsl_variable_x_radius             RS.W 1
hsl_x_angle                       RS.W 1

hsl_start_state                   RS.W 1
hsl_start_x_angle                 RS.W 1

hsl_stop_state                    RS.W 1
hsl_stop_x_angle                  RS.W 1

; **** Bar-Fader ****
bf_colors_counter                 RS.W 1
bf_convert_colors_state           RS.W 1

; **** Bar-Fader-In ****
bfi_state                         RS.W 1
bfi_fader_angle                   RS.W 1

; **** Bar-Fader-Out ****
bfo_state                         RS.W 1
bfo_fader_angle                   RS.W 1

; **** Scroll-Logo-Bottom-In ****
slbi_state                        RS.W 1
slbi_y_angle                      RS.W 1

; **** Scroll-Logo-Bottom-Out ****
slbo_state                        RS.W 1
slbo_y_angle                      RS.W 1

; **** Chunky-Columns-Fader-In ****
ccfi_state                        RS.W 1
ccfi_current_mode                 RS.W 1
ccfi_start                        RS.W 1
ccfi_columns_delay_counter        RS.W 1

; **** Chunky-Columns-Fader-Out ****
ccfo_state                        RS.W 1
ccfo_current_mode                 RS.W 1
ccfo_start                        RS.W 1
ccfo_columns_delay_counter        RS.W 1

; **** Main ****
fx_state                          RS.W 1
quit_state                        RS.W 1

variables_SIZE                    RS.B 0


; **** PT-Replay ****
; ** PT-Song-Structure **
; -----------------------
  INCLUDE "music-tracker/pt-song-structure.i"

; ** Temporary channel structure **
; ---------------------------------
  INCLUDE "music-tracker/pt-temp-channel-structure.i"

; **** Volume-Meter ****
; ** Structure for channel info **
; --------------------------------
  RSRESET

vm_audchaninfo      RS.B 0

vm_aci_yanglespeed  RS.W 1
vm_aci_yanglestep   RS.W 1

vm_audchaninfo_SIZE RS.B 0


; ## Beginn des Initialisierungsprogramms ##
; ------------------------------------------

  INCLUDE "sys-init.i"

; ** Eigene Variablen initialisieren **
; -------------------------------------
  CNOP 0,4
init_own_variables

; **** PT-Replay ****
  IFD pt_v2.3a
    PT2_INIT_VARIABLES
  ENDC
  IFD pt_v3.0b
    PT3_INIT_VARIABLES
  ENDC

  moveq   #TRUE,d0
  move.w  d0,pt_trigger_fx_state(a3)

; **** Horiz-Scrolltext ****
  lea     hst_image_data,a0
  move.l  a0,hst_image(a3)
  moveq   #FALSE,d1
  move.w  d1,hst_state(a3)
  move.w  d0,hst_text_table_start(a3)
  move.w  d0,hst_text_BLTCON0BITS(a3)
  move.w  d0,hst_character_toggle_image(a3)
  move.w  d0,hst_text_y_offset(a3)
  moveq   #hst_horiz_scroll_speed1,d2
  move.w  d2,hst_variable_horiz_scroll_speed(a3)

; **** Twisted-Bars ****
  move.w  d0,tb_y_angle(a3)  ;0 Grad
  move.w  d0,tb_y_angle_step_angle(a3) ;0 Grad

; **** Sine-Striped-Bar ****
  move.w  d0,ssb_y_angle(a3) ;0 Grad

; **** Stripes-Pattern ****
  move.w  d0,sp_stripes_y_angle(a3) ;0 Grad
  moveq   #sp_stripes_y_angle_speed,d2
  move.w  d2,sp_variable_stripes_y_angle_speed(a3)

; **** Horiz-Scroll-Logo ****
  move.w  d1,hsl_state(a3)
  move.w  d0,hsl_variable_x_radius(a3)
  move.w  d0,hsl_x_angle(a3) ;0 Grad

  move.w  d1,hsl_start_state(a3)
  MOVEF.W sine_table_length/4,d2
  move.w  d2,hsl_start_x_angle(a3) ;90 Grad

  move.w  d1,hsl_stop_state(a3)
  move.w  #sine_table_length/2,hsl_stop_x_angle(a3) ;180 Grad

; **** Bar-Fader ****
  move.w  d0,bf_colors_counter(a3)
  move.w  d1,bf_convert_colors_state(a3)

; **** Bar-Fader-In ****
  move.w  d1,bfi_state(a3)
  moveq   #sine_table_length/4,d2
  move.w  d2,bfi_fader_angle(a3) ;90 Grad

; **** Bar-Fader-Out ****
  move.w  d1,bfo_state(a3)
  move.w  d2,bfo_fader_angle(a3) ;90 Grad

; **** Scroll-Logo-Bottom-In ****
  move.w  d1,slbi_state(a3)
  move.w  d0,slbi_y_angle(a3) ;0 Grad

; **** Scroll-Logo-Bottom-Out ****
  move.w  d1,slbo_state(a3)
  MOVEF.W sine_table_length/4,d2
  move.w  d2,slbo_y_angle(a3) ;90 Grad

; **** Chunky-Columns-Fader-In ****
  move.w  d1,ccfi_state(a3)
  moveq   #ccfi_mode1,d2
  move.w  d2,ccfi_current_mode(a3)
  move.w  d0,ccfi_start(a3)
  move.w  d0,ccfi_columns_delay_counter(a3)

; **** Chunky-Columns-Fader-Out ****
  move.w  d1,ccfo_state(a3)
  moveq   #ccfo_mode1,d2
  move.w  d2,ccfo_current_mode(a3)
  move.w  d0,ccfo_start(a3)
  move.w  d0,ccfo_columns_delay_counter(a3)

; **** Main ****
  move.w  d1,fx_state(a3)
  move.w  d1,quit_state(a3)
  rts

; ** Alle Initialisierungsroutinen ausführen **
; ---------------------------------------------
  CNOP 0,4
init_all
  bsr.s   pt_DetectSysFrequ
  bsr     init_CIA_timers
  bsr     pt_InitRegisters
  bsr     pt_InitAudTempStrucs
  bsr     pt_ExamineSongStruc
  IFEQ pt_finetune
    bsr     pt_InitFtuPeriodTableStarts
  ENDC
  bsr     init_sprites
  bsr     vm_init_audio_channel_info_structures
  bsr     tb_init_color_table
  bsr     ssb_init_color_table
  bsr     hst_init_color_table
  bsr     tb_init_mirror_switch_table
  bsr     get_channels_amplitudes
  bsr     ssb_init_switch_table
  bsr     hst_init_characters_offsets
  bsr     hst_init_characters_x_positions
  bsr     hst_init_characters_images
  bsr     bf_convert_color_table2
  bsr     init_first_copperlist
  bra     init_second_copperlist

; ** Detect system frequency NTSC/PAL **
; --------------------------------------
  PT_DETECT_SYS_FREQUENCY

; ** CIA-Timer initialisieren **
; ------------------------------
  CNOP 0,4
init_CIA_timers

; **** PT-Replay ****
  PT_INIT_TIMERS
  rts

; **** PT-Replay ****
; ** Audioregister initialisieren **
; ----------------------------------
   PT_INIT_REGISTERS

; ** Temporäre Audio-Kanal-Struktur initialisieren **
; ---------------------------------------------------
   PT_INIT_AUDIO_TEMP_STRUCTURES

; ** Höchstes Pattern ermitteln und Tabelle mit Zeigern auf Samples initialisieren **
; -----------------------------------------------------------------------------------
   PT_EXAMINE_SONG_STRUCTURE

  IFEQ pt_finetune
; ** FineTuning-Offset-Tabelle initialisieren **
; ----------------------------------------------
    PT_INIT_FINETUNING_PERIOD_TABLE_STARTS
  ENDC

; **** Volume-Meter ****
; ** Audiochandata-Strukturen initialisieren **
; ---------------------------------------------
  CNOP 0,4
vm_init_audio_channel_info_structures
  lea     vm_audio_channel1_info(pc),a0
  moveq   #TRUE,d0           
  move.w  d0,(a0)+           ;Y-Winkel Geschwindigkeit
  move.w  d0,(a0)+           ;Y-Winkel Schrittweite
  move.w  d0,(a0)+           ;Y-Winkel Geschwindigkeit
  move.w  d0,(a0)+           ;Y-Winkel Schrittweite
  move.w  d0,(a0)+           ;Y-Winkel Geschwindigkeit
  move.w  d0,(a0)+           ;Y-Winkel Schrittweite
  move.w  d0,(a0)+           ;Y-Winkel Geschwindigkeit
  move.w  d0,(a0)            ;Y-Winkel Schrittweite
  rts

; ** Sprites initialisieren **
; ----------------------------
  CNOP 0,4
init_sprites
  bsr.s   spr_init_pointers_table
  bra.s   lg_init_attached_sprites_cluster

; ** Tabelle mit Zeigern auf Sprites initialisieren **
; ----------------------------------------------------
  INIT_SPRITE_POINTERS_TABLE

; ** Spritestruktur initialisieren **
; -----------------------------------
  INIT_ATTACHED_SPRITES_CLUSTER lg,spr_pointers_display,,,spr_x_size2,lg_image_y_size,NOHEADER

; **** Sine-Striped-Bar ****
; ** Farbtabelle initialisieren **
; --------------------------------
  CNOP 0,4
ssb_init_color_table
  move.l  #COLOR00BITS,d0
  move.l  extra_memory(a3),a0
  ADDF.L  em_color_table,a0
  moveq   #(color_values_number2*2)-1,d7
ssb_init_color_table_loop
  move.l  d0,(a0)+           ;Helle Farbwerte
  move.l  d0,(a0)+           ;Dunkle Farbwerte
  dbf     d7,ssb_init_color_table_loop
  rts

; **** Twisted-Bars ****
; ** Farbtabelle initialisieren **
; --------------------------------
  CNOP 0,4
tb_init_color_table
  lea     tb_colorfradients(pc),a0
  lea     pf1_color_table(pc),a1
  moveq   #(color_values_number1*segments_number1)-1,d7
tb_init_color_table_loop
  move.l  (a0)+,d0
  move.l  d0,(a1)+           ;COLOR00
  move.l  d0,(a1)+           ;COLOR01
  dbf     d7,tb_init_color_table_loop
  rts

; **** Horiz-Scrolltext ****
; ** Farbtabelle initialisieren **
; --------------------------------
hst_init_color_table
  lea     hst_color_gradient(pc),a0
  lea     pf1_color_table+(1+(((color_values_number1*segments_number1)+hst_colorrun_y_pos)*2))*LONGWORDSIZE(pc),a1
  moveq   #color_values_number3-1,d7
hst_init_color_table_loop
  move.l  (a0)+,(a1)         ;COLOR01
  addq.w  #8,a1
  dbf     d7,hst_init_color_table_loop
  rts

; **** Twisted-Bars ****
; ** Referenz-Switchtabelle initialisieren **
; --------------------------------------------
  INIT_MIRROR_SWITCH_TABLE.B tb,0,2,segments_number1,color_values_number1,extra_memory,a3

; **** Sine-Striped-Bar / Horiz-Scrolltext ****
; ** Referenz-Switchtabelle initialisieren **
; -------------------------------------------
  INIT_SWITCH_TABLE.B ssb,color_values_number1*segments_number1*2,2,color_values_number2*2,extra_memory,a3,em_switch_table2

; **** Horiz-Scrolltext ****
; ** Offsets der Buchstaben im Characters-Pic berechnen **
; --------------------------------------------------------
  INIT_CHARACTERS_OFFSETS.W hst

; ** X-Positionen der Chars berechnen **
; --------------------------------------
  INIT_CHARACTERS_X_POSITIONS hst,LORES

; ** Laufschrift initialisieren **
; --------------------------------
  INIT_CHARACTERS_IMAGES hst


; ** 1. Copperliste initialisieren **
; -----------------------------------
  CNOP 0,4
init_first_copperlist
  move.l  cl1_construction2(a3),a0 ;Aufbau-CL
  bsr.s   cl1_init_playfield_registers
  bsr.s   cl1_init_sprite_pointers
  bsr     cl1_init_color_registers
  bsr     cl1_init_bitplane_pointers
  COPMOVEQ TRUE,COPJMP2
  bsr     cl1_set_sprite_pointers
  bsr     cl1_set_bitplane_pointers
  bra     copy_first_copperlist

  COP_INIT_PLAYFIELD_REGISTERS cl1

  COP_INIT_SPRITE_POINTERS cl1

  CNOP 0,4
cl1_init_color_registers
  COP_INIT_COLORHI COLOR00,32,pf1_color_table
  COP_SELECT_COLORHI_BANK 1
  COP_INIT_COLORHI COLOR00,32
  COP_SELECT_COLORHI_BANK 2
  COP_INIT_COLORHI COLOR00,32
  COP_SELECT_COLORHI_BANK 3
  COP_INIT_COLORHI COLOR00,32
  COP_SELECT_COLORHI_BANK 4
  COP_INIT_COLORHI COLOR00,32
  COP_SELECT_COLORHI_BANK 5
  COP_INIT_COLORHI COLOR00,32
  COP_SELECT_COLORHI_BANK 6
  COP_INIT_COLORHI COLOR00,32
  COP_SELECT_COLORHI_BANK 7
  COP_INIT_COLORHI COLOR00,32

  COP_SELECT_COLORLO_BANK 0
  COP_INIT_COLORLO COLOR00,32,pf1_color_table
  COP_SELECT_COLORLO_BANK 1
  COP_INIT_COLORLO COLOR00,32
  COP_SELECT_COLORLO_BANK 2
  COP_INIT_COLORLO COLOR00,32
  COP_SELECT_COLORLO_BANK 3
  COP_INIT_COLORLO COLOR00,32
  COP_SELECT_COLORLO_BANK 4
  COP_INIT_COLORLO COLOR00,32
  COP_SELECT_COLORLO_BANK 5
  COP_INIT_COLORLO COLOR00,32
  COP_SELECT_COLORLO_BANK 6
  COP_INIT_COLORLO COLOR00,32
  COP_SELECT_COLORLO_BANK 7
  COP_INIT_COLORLO COLOR00,32
  rts

  COP_INIT_BITPLANE_POINTERS cl1

  COP_SET_SPRITE_POINTERS cl1,construction2,spr_number

  COP_SET_BITPLANE_POINTERS cl1,display,pf1_depth3

  COPY_COPPERLIST cl1,2

; ** 2. Copperliste initialisieren **
; -----------------------------------
  CNOP 0,4
init_second_copperlist
  move.l  cl2_construction1(a3),a0 ;Aufbau-CL
  bsr.s   cl2_init_BPLCON4_registers
  bsr.s   cl2_init_copint
  COPLISTEND
  bsr     copy_second_copperlist
  bra     swap_second_copperlist

  COP_INIT_BPLCON4_CHUNKY_SCREEN cl2,cl2_HSTART1,cl2_VSTART1,cl2_display_x_size,cl2_display_y_size,open_border,tb_quick_clear,FALSE

  COP_INIT_COPINT cl2,cl2_HSTART2,cl2_VSTART2

  COPY_COPPERLIST cl2,3


; ** CIA-Timer starten **
; -----------------------

  INCLUDE "continuous-timers-start.i"


; ## Hauptprogramm ##
; -------------------
; a3 ... Basisadresse aller Variablen
; a4 ... CIA-A-Base
; a5 ... CIA-B-Base
; a6 ... DMACONR
  CNOP 0,4
main_routine
  bsr.s   no_sync_routines
  bra.s   beam_routines


; ## Routinen, die nicht mit der Bildwiederholfrequenz gekoppelt sind ##
; ----------------------------------------------------------------------
  CNOP 0,4
no_sync_routines
  rts


; ## Rasterstahl-Routinen ##
; --------------------------
  CNOP 0,4
beam_routines
  bsr     wait_copint
  bsr     swap_first_copperlist
  bsr     swap_second_copperlist
  bsr     swap_playfield1
  bsr     horiz_scrolltext
  bsr     hst_horiz_scroll
  bsr     horiz_scroll_logo_start
  bsr     horiz_scroll_logo_stop
  bsr     horiz_scroll_logo
  bsr     tb_clear_second_copperlist
  bsr     cl2_update_BPL1DAT
  bsr     bf_convert_color_table
  bsr     sp_get_stripes_y_coordinates
  bsr     sp_make_color_offsets_table
  bsr     sp_make_pattern
  bsr     get_channels_amplitudes
  bsr     tb_get_yz_coordinates
  bsr     tb_set_background_bars
  bsr     make_striped_bar
  bsr     tb_set_foreground_bars
  IFNE tb_quick_clear
    bsr     restore_second_copperlist
  ENDC
  bsr     bar_fader_in
  bsr     bar_fader_out
  bsr     scroll_logo_bottom_in
  bsr     scroll_logo_bottom_out
  bsr     chunky_columns_fader_in
  bsr     chunky_columns_fader_out
  bsr     mouse_handler
  tst.w   fx_state(a3)       ;Effekte beendet ?
  bne     beam_routines      ;Nein -> verzweige
  rts


; ** Copperlisten vertauschen **
; ------------------------------
  SWAP_COPPERLIST cl1,2

  SWAP_COPPERLIST cl2,3

; ** Playfields vertauschen **
; ----------------------------
  CNOP 0,4
swap_playfield1
  moveq   #ssb_y_radius,d1   
  sub.w   hst_text_y_offset(a3),d1 ;Playfield vertikal zentrieren
  MULUF.W pf1_plane_width*pf1_depth3,d1 ;Y-Offset in Playfield
  ADDF.W  pf1_bitplanes_x_offset/8,d1
  move.l  cl1_display(a3),a0
  ADDF.W  cl1_BPL1PTH+2,a0
  move.l  pf1_construction1(a3),a2
  move.l  pf1_construction2(a3),a1
  move.l  pf1_display(a3),pf1_construction1(a3)
  move.l  a2,pf1_construction2(a3)
  move.l  a1,pf1_display(a3)
  moveq   #pf1_depth3-1,d7   ;Anzahl der Planes
swap_playfield1_loop
  move.l  (a1)+,d0
  add.l   d1,d0              ;n Zeilen überspringen
  move.w  d0,4(a0)           ;BPLxPTL
  swap    d0
  move.w  d0,(a0)            ;BPLxPTH
  addq.w  #8,a0
  dbf     d7,swap_playfield1_loop
  rts


; ** X-Radius für Horiz-Scroll-Logo berechnen **
; ----------------------------------------------
  CNOP 0,4
horiz_scroll_logo_start
  tst.w   hsl_start_state(a3) ;Berechnung an ?
  bne.s   no_horiz_scroll_logo_start  ;Nein -> verzweige
  move.w  hsl_start_x_angle(a3),d2 ;X-Winkel
  cmp.w   #sine_table_length/2,d2 ;180 Grad erreicht ?
  ble.s   proceed_horiz_scroll_logo_start ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,hsl_start_state(a3) ;Berechnung aus
  rts
  CNOP 0,4
proceed_horiz_scroll_logo_start
  lea     sine_table(pc),a0
  move.l  (a0,d2.w*4),d0    ;cos(w)
  MULUF.L hsl_start_x_radius*4*2*2,d0,d1 ;xr'=xr*cos(w)/2^16
  swap    d0
  add.w   #hsl_start_x_center*4*2,d0  ;+ X-Mittelpunkt
  move.w  d0,hsl_variable_x_radius(a3) ;X-Radius retten
  addq.w  #hsl_start_x_angle_speed,d2 ;nächster X-Winkel
  move.w  d2,hsl_start_x_angle(a3) 
no_horiz_scroll_logo_start
  rts

  CNOP 0,4
horiz_scroll_logo_stop
  tst.w   hsl_stop_state(a3) ;Berechnung an ?
  bne.s   no_horiz_scroll_logo_stop ;Nein -> verzweige
  move.w  hsl_stop_x_angle(a3),d2 ;X-Winkel
  cmp.w   #sine_table_length/4,d2 ;90 Grad erreicht ?
  bgt.s   proceed_horiz_scroll_logo_stop ;Wenn negativ -> verzweige
  moveq   #FALSE,d0
  move.w  d0,hsl_stop_state(a3) ;Berechnung aus
  move.w  d0,hsl_state(a3)   ;Logo nicht mehr bewegen
  rts
  CNOP 0,4
proceed_horiz_scroll_logo_stop
  lea     sine_table(pc),a0
  move.l  (a0,d2.w*4),d0     ;cos(w)
  MULUF.L hsl_stop_x_radius*4*2*2,d0,d1 ;x'=xr*cos(w)/2^16
  swap    d0
  add.w   #hsl_stop_x_center*4*2,d0 ;+ X-Mittelpunkt
  move.w  d0,hsl_variable_x_radius(a3) ;X-Radius retten
  subq.w  #hsl_stop_x_angle_speed,d2 ;nächster X-Winkel
  move.w  d2,hsl_stop_x_angle(a3) 
no_horiz_scroll_logo_stop
  rts

; ** Logo horizontal scrollen **
; ------------------------------
  CNOP 0,4
horiz_scroll_logo
  tst.w   hsl_state(a3)      ;Logo bewegen ?
  bne.s   no_horiz_scroll_logo ;Nein -> verzweige
  move.w  hsl_x_angle(a3),d1 ;X-Winkel
  lea     sine_table(pc),a0
  move.w  2(a0,d1.w*4),d3    ;sin(w)
  muls.w  hsl_variable_x_radius(a3),d3 ;x'=xrsin(w)/2^16
  swap    d3
  add.w   #hsl_x_center*4,d3 ;+ X-Position
  addq.b  #hsl_x_angle_speed,d1 ;nächster X-Winkel
  move.w  d1,hsl_x_angle(a3)  
  moveq   #lg_image_y_position,d4 ;Y-Position
  MOVEF.W lg_image_y_size,d5 ;Höhe
  add.w   d4,d5              ;Höhe dazuaddieren
  MOVEF.W spr_x_size2*4,d6
  lea     spr_pointers_display(pc),a2 ;Zeiger auf Sprites
  moveq   #(spr_used_number/2)-1,d7 ;Anzahl der Attached-Sprites
horiz_scroll_logo_loop
  move.w  d3,d0              ;HSTART
  move.w  d4,d1              ;VSTART
  move.w  d5,d2              ;VSTOP
  move.l  (a2)+,a0           ;1. Sprite-Struktur
  move.l  (a2)+,a1           ;2. Sprite-Struktur
  SET_SPRITE_POSITION d0,d1,d2
  move.w  d1,(a0)            ;SPRPOS
  move.w  d1,(a1)            ;SPRPOS
  add.w   d6,d3              ;nächste Sprite-X-Position
  move.w  d2,spr_pixel_per_datafetch/8(a0) ;SPRCTL
  tas     d2                 ;Attached-Bit setzen
  move.w  d2,spr_pixel_per_datafetch/8(a1) ;SPRCTL
  dbf     d7,horiz_scroll_logo_loop
no_horiz_scroll_logo
  rts

; ** Copperliste löschen **
; -------------------------
  CLEAR_BPLCON4_CHUNKY_SCREEN tb,cl2,construction1,extension1,quick_clear

; ** Linken Overscan-Bereich updaten **
; -------------------------------------
  CNOP 0,4
cl2_update_BPL1DAT
  moveq   #ssb_y_radius,d0
  sub.w   hst_text_y_offset(a3),d0 ;Playfield vertikal zentrieren
  MULUF.W pf1_plane_width*pf1_depth3,d0 ;Y-Offset in Playfield
  addq.w  #pf1_BPL1DAT_x_offset/8,d0 ;X-Offset
  moveq   #pf1_plane_width*pf1_depth3,d1
  MOVEF.L cl2_extension1_SIZE,d2
  move.l  pf1_display(a3),a0
  move.l  (a0),a0
  add.l   d0,a0              ;+ X+Y-Offset
  move.l  cl2_display(a3),a1
  ADDF.W  cl2_extension1_entry+cl2_ext1_BPL1DAT+2,a1
  MOVEF.W visible_lines_number-1,d7 ;Anzahl der Zeilen
cl2_update_BPL1DAT_loop
  move.w  (a0),(a1)          ;16 Pixel kopieren
  add.l   d1,a0              ;nächste Zeile in Playfield
  add.l   d2,a1              ;nächste Zeile in CL
  dbf     d7,cl2_update_BPL1DAT_loop
  rts

; ** Amplituden der einzelnen Kanäle in Erfahrung bringen **
; ----------------------------------------------------------
  CNOP 0,4
get_channels_amplitudes
  moveq   #vm_period_div,d2
  lea	  pt_audchan1temp(pc),a0 ;Zeiger auf temporäre Struktur des 1. Kanals
  lea     vm_audio_channel1_info(pc),a1
  bsr.s   get_channel_amplitude
  lea	  pt_audchan2temp(pc),a0 ;Zeiger auf temporäre Struktur des 2. Kanals
  bsr.s   get_channel_amplitude
  lea	  pt_audchan3temp(pc),a0 ;Zeiger auf temporäre Struktur des 3. Kanals
  bsr.s   get_channel_amplitude
  lea	  pt_audchan4temp(pc),a0 ;Zeiger auf temporäre Struktur des 4. Kanals

; ** Routine get-channel-amplitude **
; d2 ... Skalierung
; a0 ... Temporäre Struktur des Audiokanals
; a1 ... Zeiger auf Amplitudenwert des Kanals
get_channel_amplitude
  tst.b   n_note_trigger(a0) ;Neue Note angespielt ?
  bne.s   no_get_channel_amplitude ;Nein -> verzweige
  moveq   #FALSE,d1          ;Zähler für Ergebnis
  move.b  d1,n_note_trigger(a0) ;Note Trigger Flag zurücksetzen
  move.w  n_period(a0),d0    ;Angespielte Periode 
  DIVUF.W d2,d0,d1
  moveq   #vm_max_period_step,d0
  sub.w   d1,d0              ;maxperstep - perstep
  lsr.w   #1,d0              ;/2
  move.w  d0,(a1)+           ;Y-Winkel Geschwindigkeit
  lsr.w   #1,d0              ;/2
  move.w  d0,(a1)+           ;Y-Winkel Schrittweite
no_get_channel_amplitude
  rts

; ** Y+Z-Koordinaten berechnen **
; -------------------------------
  CNOP 0,4
tb_get_yz_coordinates
  move.l  a4,-(a7)
  moveq   #vm_source_channel,d1
  MULUF.W vm_audchaninfo_SIZE/2,d1,d0
  moveq   #tb_y_distance,d3
  move.w  tb_y_angle(a3),d4 ;1. Y-Winkel
  move.w  d4,d0              
  move.w  tb_y_angle_step_angle(a3),d5 ;1. Y-Step-Winkel
  add.b   (vm_audio_channel1_info+vm_aci_yanglespeed+1,pc,d1.w*2),d0 ;nächster Y-Winkel
  move.w  d0,tb_y_angle(a3) 
  move.w  d5,d0
  add.b   (vm_audio_channel1_info+vm_aci_yanglestep+1,pc,d1.w*2),d0
  move.w  d0,tb_y_angle_step_angle(a3) 
  lea     sine_table(pc),a0    
  lea     tb_yz_coordinates(pc),a1 ;Zeiger auf Y+Z-Koords-Tabelle
  move.w  #tb_y_centre,a2
  move.w  #tb_y_angle_step_centre,a4
  moveq   #(cl2_display_width-1)-1,d7 ;Anzahl der Spalten
tb_get_yz_coordinates_loop1
  move.l  (a0,d5.w*4),d0     ;sin(w)
  MULUF.L tb_y_angle_step_radius*2,d0,d1
  swap    d0
  add.w   a4,d0              ;y' + Y-Step-Mittelpunkt
  move.w  d4,d2              ;Y-Winkel
  add.b   d0,d4              ;nächster Y-Winkel
  moveq   #tb_bars_number-1,d6  ;Anzahl der Stangen
tb_get_yz_coordinates_loop2
  moveq   #-(sine_table_length/4),d1 ;- 90 Grad
  move.l  (a0,d2.w*4),d0     ;sin(w)
  add.w   d2,d1              ;Y-Winkel - 90 Grad
  ext.w   d1                 ;Vorzeichenrichtig auf ein Wort erweitern
  move.w  d1,(a1)+           ;Z-Vektor retten
  MULUF.L tb_y_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  add.w   a2,d0              ;y' + Y-Mittelpunkt
  MULUF.W cl2_extension1_SIZE/4,d0,d1 ;Y-Offset in CL
  move.w  d0,(a1)+           ;Y retten
  add.b   d3,d2              ;Y-Abstand zur nächsten Bar
  dbf     d6,tb_get_yz_coordinates_loop2
  addq.b  #tb_y_angle_step_step,d5 ;nächster Y-Step-Winkel
  dbf     d7,tb_get_yz_coordinates_loop1
  move.l  (a7)+,a4
  rts

; ** Y-Positionen der Streifen berechnen **
; -----------------------------------------
  CNOP 0,4
sp_get_stripes_y_coordinates
  move.w  sp_stripes_y_angle(a3),d2 ;1. Y-Winkel
  move.w  d2,d0
  MOVEF.W (sine_table_length/2)-1,d5 ;Überlauf
  add.w   sp_variable_stripes_y_angle_speed(a3),d0 ;nächster Y-Winkel
  and.w   d5,d0              ;Überlauf entfernen
  move.w  d0,sp_stripes_y_angle(a3) 
  ;moveq   #sp_stripes_y_radius*2,d3
  moveq   #sp_stripes_y_center,d4
  lea     sine_table+((sine_table_length/4)*LONGWORDSIZE)(pc),a0 
  lea     sp_stripes_y_coordinates(pc),a1 ;Zeiger auf Y-Koordinatentabelle
  moveq   #(sp_stripes_number*sp_stripe_height)-1,d7 ;Anzahl der Zeilen
sp_get_stripes_y_coordinates_loop
  move.l  (a0,d2.w*4),d0     ;cos(w)
  MULUF.L SP_stripes_y_radius*2,d0,d1 ;y'=(yr*cos(w))/2^15
  swap    d0
  add.w   d4,d0              ;y' + Y-Mittelpunkt
  move.w  d0,(a1)+           
  addq.w  #sp_stripes_y_angle_step,d2 ;nächster Y-Winkel
  and.w   d5,d2              ;Überlauf entfernen
  dbf     d7,sp_get_stripes_y_coordinates_loop
  rts

; ** Hintere Stangen in Copperliste kopieren **
; ---------------------------------------------
  CNOP 0,4
tb_set_background_bars
  movem.l a4-a6,-(a7)
  moveq   #tb_bar_height,d4
  lea     tb_yz_coordinates(pc),a0 ;Zeiger auf YZ-Koords
  move.l  cl2_construction2(a3),a2 
  ADDF.W  cl2_extension1_entry+cl2_ext1_BPLCON4_1+2,a2
  move.l  extra_memory(a3),a5 ;Zeiger auf Tabelle mit Switchwerten
  lea     tb_fader_columns_mask(pc),a6
  moveq   #(cl2_display_width-1)-1,d7 ;Anzahl der Spalten
tb_set_background_bars_loop1
  tst.b   (a6)+              ;Spalte darstellen ?
  bne     tb_skip_column1    ;Nein -> verzweige
  move.l  a5,a1              ;Zeiger auf Tabelle mit Switchwerten
  moveq   #tb_bars_number-1,d6 ;Anzahl der Stangen
tb_set_background_bars_loop2
  move.l  (a0)+,d0           ;Z + Y lesen
  bmi     tb_skip_background_bar ;Wenn Z negativ -> verzweige
tb_set_background_bar
  lea     (a2,d0.w*4),a4     ;Y-Offset
  COPY_TWISTED_BAR.B tb,cl2,extension1,bar_height
tb_no_background_bar
  dbf     d6,tb_set_background_bars_loop2
tb_no_column1
  addq.w  #4,a2              ;nächste Spalte in CL
  dbf     d7,tb_set_background_bars_loop1
  movem.l (a7)+,a4-a6
  rts
  CNOP 0,4
tb_skip_column1
  ADDF.W  tb_bars_number*LONGWORDSIZE,a0 ;Z + Y überspringen
  bra.s   tb_no_column1
  CNOP 0,4
tb_skip_background_bar
  add.l   d4,a1              ;Switchwerte überspringen
  bra.s   tb_no_background_bar

; ** Hintergrundbar setzen **
; ---------------------------
  CNOP 0,4
make_striped_bar
  move.w  ssb_y_angle(a3),d1 ;Y-Winkel
  move.w  d1,d0              
  addq.w  #ssb_y_angle_speed,d0 ;nächster Y-Winkel
  and.w   #(sine_table_length/2)-1,d0 ;Überlauf entfernen
  move.w  d0,ssb_y_angle(a3) 
  lea     sine_table(pc),a0    
  move.l  (a0,d1.w*4),d0     ;sin(w)
  MULUF.L ssb_y_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  move.w  d0,d1              
  add.w   #ssb_y_radius,d0   ;y' + Y-Radius
  move.w  d0,hst_text_y_offset(a3) 
  add.w   #ssb_y_center,d1   ;y' + Y-Mittelpunkt
  MULUF.W cl2_extension1_SIZE/4,d1,d0 ;Y*cl2_extension1_SIZE
  move.l  extra_memory(a3),a0
  add.l   #em_switch_table2,a0 ;Zeiger auf Tabelle mit Switchwerten
  move.l  cl2_construction2(a3),a1 
  ADDF.W  (cl2_extension1_entry+cl2_ext1_BPLCON4_1+2),a1 
  lea     (a1,d1.w*4),a1     ;Y-Offset in CL
  move.w  #cl2_extension1_SIZE,a2
  moveq   #(ssb_bar_height)-1,d7 ;Höhe der Bar
make_striped_bar_loop
  move.b  (a0)+,d0           ;Switchwert 
  move.b  d0,(a1)            ;1. Spalte in CL
  move.b  d0,4(a1)           ;2. Spalte in CL
  move.b  d0,8(a1)           ;...
  move.b  d0,12(a1)
  move.b  d0,16(a1)
  move.b  d0,20(a1)
  move.b  d0,24(a1)
  move.b  d0,28(a1)
  move.b  d0,32(a1)
  move.b  d0,36(a1)
  move.b  d0,40(a1)
  move.b  d0,44(a1)
  move.b  d0,48(a1)
  move.b  d0,52(a1)
  move.b  d0,56(a1)
  move.b  d0,60(a1)
  move.b  d0,64(a1)
  move.b  d0,68(a1)
  move.b  d0,72(a1)
  move.b  d0,76(a1)
  move.b  d0,80(a1)
  move.b  d0,84(a1)
  move.b  d0,88(a1)
  move.b  d0,92(a1)
  move.b  d0,96(a1)
  move.b  d0,100(a1)
  move.b  d0,104(a1)
  move.b  d0,108(a1)
  move.b  d0,112(a1)
  move.b  d0,116(a1)
  move.b  d0,120(a1)
  move.b  d0,124(a1)
  move.b  d0,128(a1)
  move.b  d0,132(a1)
  move.b  d0,136(a1)
  move.b  d0,140(a1)
  move.b  d0,144(a1)
  move.b  d0,148(a1)
  move.b  d0,152(a1)
  move.b  d0,156(a1)
  move.b  d0,160(a1)
  move.b  d0,164(a1)
  move.b  d0,168(a1)
  add.l   a2,a1              ;nächste Zeile in CL
  move.b  d0,172-cl2_extension1_SIZE(a1) ;44. Spalte in CL
  dbf     d7,make_striped_bar_loop
  rts

; ** Vordere Stangen in Copperliste kopieren **
; ---------------------------------------------
  CNOP 0,4
tb_set_foreground_bars
  movem.l a4-a6,-(a7)
  moveq   #tb_bar_height,d4
  lea     tb_yz_coordinates(pc),a0 ;Zeiger auf YZ-Koords
  move.l  cl2_construction2(a3),a2 
  ADDF.W  cl2_extension1_entry+cl2_ext1_BPLCON4_1+2,a2
  move.l  extra_memory(a3),a5 ;Zeiger auf Tabelle mit Switchwerten
  lea     tb_fader_columns_mask(pc),a6
  moveq   #(cl2_display_width-1)-1,d7 ;Anzahl der Spalten
tb_set_foreround_bars_loop1
  tst.b   (a6)+              ;Spalte darstellen ?
  bne     tb_skip_column2    ;Nein -> verzweige
  move.l  a5,a1              ;Zeiger auf Tabelle mit Switchwerten
  moveq   #tb_bars_number-1,d6  ;Anzahl der Stangen
tb_set_foreround_bars_loop2
  move.l  (a0)+,d0           ;Z + Y lesen
  bpl     tb_skip_foreground_bar ;Wenn Z positiv -> verzweige
tb_set_foreground_bar
  lea     (a2,d0.w*4),a4     ;Y-Offset
  COPY_TWISTED_BAR.B tb,cl2,extension1,bar_height
tb_no_foreground_bar
  dbf     d6,tb_set_foreround_bars_loop2
tb_no_column2
  addq.w  #4,a2              ;nächste Spalte in CL
  dbf     d7,tb_set_foreround_bars_loop1
  movem.l (a7)+,a4-a6
  rts
  CNOP 0,4
tb_skip_column2
  ADDF.W  tb_bars_number*LONGWORDSIZE,a0 ;Z + Y überspringen
  bra.s   tb_no_column2
  CNOP 0,4
tb_skip_foreground_bar
  add.l   d4,a1              ;Switchwerte überspringen
  bra.s   tb_no_foreground_bar

; ** Farboffsettsabelle initialisieren **
; ---------------------------------------
  CNOP 0,4
sp_make_color_offsets_table
  moveq   #$00000001,d1      ;Farboffset des ersten und zweiten Streifens
  lea     sp_stripes_y_coordinates(pc),a0 ;Zeiger auf Y-Koords der Streifen
  lea     sp_color_offsets_table(pc),a1 ;Zeiger auf Farboffsetstabelle
  moveq   #sp_stripes_number-1,d7 ;Anzahl der Streifen
sp_make_color_offsets_table_loop1
  moveq   #sp_stripe_height-1,d6 ;Höhe eines Streifens
sp_make_color_offsets_table_loop2
  move.w  (a0)+,d0           ;Y-Offset 
  move.w  d1,(a1,d0.w*2)     ;Farboffset eintragen
  dbf     d6,sp_make_color_offsets_table_loop2
  swap    d1                 ;Farboffsets vertauschen
  dbf     d7,sp_make_color_offsets_table_loop1
  rts

; ** Farbverlauf in Copperliste kopieren **
; -----------------------------------------
  CNOP 0,4
sp_make_pattern
  move.w  #$0f0f,d3          ;Maske
  moveq   #TRUE,d4           ;Farbregisterzähler
  moveq   #2*8,d5            ;Additionswert für Farbregisterzähler
  lea     sp_color_offsets_table(pc),a0 ;Zeiger auf Farboffsetstabelle
  move.l  extra_memory(a3),a1
  add.l   #em_color_table,a1 ;Zeiger auf Farbtabelle
  move.l  cl1_construction2(a3),a2
  ADDF.W  cl1_COLOR00_high4+2,a2 
  moveq   #ssb_bar_height-1,d7 ;Anzahl der Zeilen
sp_make_stripe_bar_loop
  move.w  (a0)+,d0           ;Farboffset 
  move.w  (a1,d0.w*4),(a2)   ;COLOR00 High-Bits
  move.w  2(a1,d0.w*4),cl1_COLOR00_low1-cl1_COLOR00_high1(a2) ;COLOR00 Low-Bits
  addq.w  #8,a1              ;Nächster Farbwert in Farbtabelle
  addq.w  #8,a2              ;nächste Zeile in CL
  add.b   d5,d4              ;Farbregisterzähler erhöhen
  bne.s   sp_no_restart_registers_counter ;Wenn <> Null -> verzweige
  addq.w  #4,a2              ;CMOVE überspringen
sp_no_restart_registers_counter
  dbf     d7,sp_make_stripe_bar_loop
  rts

; ** Laufschrift **
; -----------------
  CNOP 0,4
horiz_scrolltext
  tst.w   hst_state(a3)      ;Laufschrift an ?
  bne.s   no_horiz_scrolltext ;Nein -> verweige
  movem.l a4-a5,-(a7)
  bsr.s   hst_init_copy_blit
  move.w  #(hst_copy_blit_y_size*64)+(hst_copy_blit_x_size/16),d4 ;BLTSIZE
  move.w  #hst_text_character_x_restart,d5
  lea     hst_characters_x_positions(pc),a0 ;X-Positionen der Chars
  lea     hst_characters_image_pointers(pc),a1 ;Zeiger auf Adressen der Chars-Images
  move.l  pf1_construction1(a3),a2
  move.l  (a2),d3
  add.l   #(hst_text_x_position/8)+(hst_text_y_position*pf1_plane_width*pf1_depth3),d3 ;Y-Zentrierung
  lea     BLTAPT-DMACONR(a6),a2    ;Offset der Blitterregister auf Null setzen
  lea     BLTDPT-DMACONR(a6),a4
  lea     BLTSIZE-DMACONR(a6),a5
  bsr.s   hst_get_text_softscroll
  moveq   #hst_text_characters_number-1,d7 ;Anzahl der Chars
horiz_scrolltext_loop
  moveq   #TRUE,d0           ;Langwort-Zugriff
  move.w  (a0),d0            ;X-Position
  move.w  d0,d2              
  lsr.w   #3,d0              ;X/8
  WAITBLITTER
  move.l  (a1)+,(a2)         ;Char-Image
  add.l   d3,d0              ;X-Offset
  move.l  d0,(a4)            ;Playfield
  move.w  d4,(a5)            ;Blitter starten
  sub.w   hst_variable_horiz_scroll_speed(a3),d2 ;X-Position verringern
  bpl.s   hst_no_new_character_image ;Wenn positiv -> verzweige
hst_new_character_image
  move.l  a0,-(a7)
  bsr.s   hst_get_new_character_image
  move.l  d0,-4(a1)          ;Neues Bild für Character
  add.w   d5,d2              ;X-Pos Neustart
  move.l  (a7)+,a0
hst_no_new_character_image
  move.w  d2,(a0)+           
  dbf     d7,horiz_scrolltext_loop
  movem.l (a7)+,a4-a5
  move.w  #DMAF_BLITHOG,DMACON-DMACONR(a6) ;BLTPRI aus
no_horiz_scrolltext
  rts
  CNOP 0,4
hst_init_copy_blit
  move.w  #DMAF_BLITHOG+DMAF_SETCLR,DMACON-DMACONR(a6) ;BLTPRI an
  WAITBLITTER
  move.l  #(BC0F_SRCA+BC0F_DEST+ANBNC+ANBC+ABNC+ABC)<<16,BLTCON0-DMACONR(a6) ;Minterm D=A
  moveq   #FALSE,d0
  move.l  d0,BLTAFWM-DMACONR(a6) ;keine Ausmaskierung
  move.l  #((hst_image_plane_width-hst_text_character_width)<<16)+(pf1_plane_width-hst_text_character_width),BLTAMOD-DMACONR(a6) ;A-Mod + D-Mod
  rts

; ** Softscrollwert berechen **
; -----------------------------
  CNOP 0,4
hst_get_text_softscroll
  moveq   #hst_text_character_x_size-1,d0
  and.w   (a0),d0            ;X-Pos.&$f
  ror.w   #4,d0              ;Bits in richtige Position bringen
  or.w    #BC0F_SRCA+BC0F_DEST+ANBNC+ANBC+ABNC+ABC,d0 ;Minterm  D=A
  move.w  d0,hst_text_BLTCON0BITS(a3) 
  rts

; ** Neues Image für Character ermitteln **
; -----------------------------------------
  GET_NEW_CHARACTER_IMAGE.W hst,hst_check_control_codes,NORESTART

  CNOP 0,4
hst_check_control_codes
  cmp.b   #ASCII_CTRL_S,d0
  beq.s   hst_stop_scrolltext
  rts
  CNOP 0,4
hst_stop_scrolltext
  moveq   #FALSE,d0
  move.w  d0,hst_state(a3)   ;Text stoppen
  moveq   #TRUE,d0           ;Rückgabewert TRUE = Steuerungscode gefunden
  tst.w   quit_state(a3)     ;Soll Intro beendet werden?
  bne.s   hst_normal_stop_scrolltext ;Nein -> verzweige
hst_quit_and_stop_scrolltext
  move.w  d0,pt_fade_out_music_state(a3) ;Musik ausfaden
  cmp.w   #sine_table_length/4,slbi_y_angle(a3) ;90 Grad erreicht ?
  blt.s   hst_no_scroll_logo_bottom_out  ;Ja -> verzweige
  move.w  d0,slbo_state(a3)  ;Scroll-Logo-Bottom-Out an
hst_no_scroll_logo_bottom_out
  move.w  d0,ccfo_state(a3)  ;Chunky-Columns-Fader-Out an
  moveq   #1,d2
  move.w  d2,ccfo_columns_delay_counter(a3) ;Verzögerungszähler aktivieren
  move.w  #bf_colors_number*3,bf_colors_counter(a3)
  move.w  d0,bf_convert_colors_state(a3) ;Konvertieren der Farben an
  move.w  d0,bfo_state(a3)   ;Bar-Fader-Out an
hst_normal_stop_scrolltext
  rts

; ** Laufschrift bewegen **
; -------------------------
  CNOP 0,4
hst_horiz_scroll
  tst.w   hst_state(a3)      ;Laufschrift an ?
  bne.s   hst_no_horiz_scroll ;Nein -> verweige
  move.l  pf1_construction1(a3),a0
  WAITBLITTER
  move.l  (a0),a0
  move.w  hst_text_BLTCON0BITS(a3),BLTCON0-DMACONR(a6)
  add.l   #(hst_text_x_position/8)+(hst_text_y_position*pf1_plane_width*pf1_depth3),a0 ;Y-Zentrierung
  move.l  a0,BLTAPT-DMACONR(a6) ;Quelle
  addq.w  #2,a0              ;16 Pixel überspringen
  move.l  a0,BLTDPT-DMACONR(a6) ;Ziel
  move.l  #((pf1_plane_width-hst_horiz_scroll_window_width)<<16)+(pf1_plane_width-hst_horiz_scroll_window_width),BLTAMOD-DMACONR(a6) ;A-Mod + D-Mod
  move.w  #(hst_horiz_scroll_blit_y_size*64)+(hst_horiz_scroll_blit_x_size/16),BLTSIZE-DMACONR(a6) ;Blitter starten
hst_no_horiz_scroll
  rts

; ** Copper-WAIT-Befehle wiederherstellen **
; ------------------------------------------
  IFNE tb_quick_clear
    RESTORE_BPLCON4_CHUNKY_SCREEN tb,cl2,construction2,extension1,32
  ENDC


; ** Striped-Bar einblenden **
; ----------------------------
  CNOP 0,4
bar_fader_in
  tst.w   bfi_state(a3)      ;Bar-Fader-In an ?
  bne.s   no_bar_fader_in    ;Nein -> verzweige
  movem.l a4-a6,-(a7)
  move.w  bfi_fader_angle(a3),d2 ;Fader-Winkel 
  move.w  d2,d0
  ADDF.W  bfi_fader_angle_speed,d0 ;nächster Fader-Winkel
  cmp.w   #sine_table_length/2,d0 ;Y-Winkel <= 180 Grad ?
  ble.s   bfi_save_fader_angle ;Ja -> verzweige
  MOVEF.W sine_table_length/2,d0 ;180 Grad
bfi_save_fader_angle
  move.w  d0,bfi_fader_angle(a3) 
  MOVEF.W bf_colors_number*3,d6 ;Zähler
  lea     sine_table(pc),a0  
  move.l  (a0,d2.w*4),d0     ;sin(w)
  MULUF.L bfi_fader_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  ADDF.W  bfi_fader_center,d0 ;+ Fader-Mittelpunkt
  lea     bf_color_cache+(bf_color_table_offset*LONGWORDSIZE)(pc),a0 ;Puffer für Farbwerte
  lea     bfi_color_table+(bf_color_table_offset*LONGWORDSIZE)(pc),a1 ;Sollwerte
  move.w  d0,a5              ;Additions-/Subtraktionswert für Blau
  swap    d0                 ;WORDSHIFT
  clr.w   d0                 ;Bits 0-15 löschen
  move.l  d0,a2              ;Additions-/Subtraktionswert für Rot
  lsr.l   #8,d0              ;BYTESHIFT
  move.l  d0,a4              ;Additions-/Subtraktionswert für Grün
  MOVEF.W bf_colors_number-1,d7 ;Anzahl der Farben
  bsr     bf_fader_loop
  movem.l (a7)+,a4-a6
  move.w  d6,bf_colors_counter(a3) ;Image-Fader-In fertig ?
  bne.s   no_bar_fader_in  ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,bfi_state(a3)   ;Bar-Fader-In aus
no_bar_fader_in
  rts

; ** Striped-Bar ausblenden **
; ----------------------------
  CNOP 0,4
bar_fader_out
  tst.w   bfo_state(a3)      ;Bar-Fader-Out an ?
  bne.s   no_bar_fader_out   ;Nein -> verzweige
  movem.l a4-a6,-(a7)
  move.w  bfo_fader_angle(a3),d2 ;Fader-Winkel 
  move.w  d2,d0
  ADDF.W  bfo_fader_angle_speed,d0 ;nächster Fader-Winkel
  cmp.w   #sine_table_length/2,d0 ;Y-Winkel <= 180 Grad ?
  ble.s   bfo_save_fader_angle ;Ja -> verzweige
  MOVEF.W sine_table_length/2,d0 ;180 Grad
bfo_save_fader_angle
  move.w  d0,bfo_fader_angle(a3) 
  MOVEF.W bf_colors_number*3,d6 ;Zähler
  lea     sine_table(pc),a0  
  move.l  (a0,d2.w*4),d0     ;sin(w)
  MULUF.L bfo_fader_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  ADDF.W  bfo_fader_center,d0 ;+ Fader-Mittelpunkt
  lea     bf_color_cache+(bf_color_table_offset*LONGWORDSIZE)(pc),a0 ;Puffer für Farbwerte
  lea     bfo_color_table+(bf_color_table_offset*LONGWORDSIZE)(pc),a1 ;Sollwerte
  move.w  d0,a5              ;Additions-/Subtraktionswert für Blau
  swap    d0                 ;WORDSHIFT
  clr.w   d0                 ;Bits 0-15 löschen
  move.l  d0,a2              ;Additions-/Subtraktionswert für Rot
  lsr.l   #8,d0              ;BYTESHIFT
  move.l  d0,a4              ;Additions-/Subtraktionswert für Grün
  MOVEF.W bf_colors_number-1,d7 ;Anzahl der Farben
  bsr     bf_fader_loop
  movem.l (a7)+,a4-a6
  move.w  d6,bf_colors_counter(a3) ;Image-Fader-Out fertig ?
  bne.s   no_bar_fader_out   ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,bfo_state(a3)   ;Bar-Fader-Out aus
no_bar_fader_out
  rts

  COLOR_FADER bf

; ** Farbwerte umwandeln **
; -------------------------
  CNOP 0,4
bf_convert_color_table
  tst.w   bf_convert_colors_state(a3)  ;Kopieren der Farbwerte beendet ?
  bne.s   bf_no_convert_color_table ;Ja -> verzweige
bf_convert_color_table2
  move.l  a4,-(a7)
  move.w  #$0f0f,d5          ;Maske für RGB-Nibbles
  lea     bf_color_cache+(bf_color_table_offset*LONGWORDSIZE)(pc),a0 ;Quelle: Puffer für helle Farbwerte
  lea     (bf_color_table_offset*LONGWORDSIZE)+((bf_colors_number/2)*LONGWORDSIZE)(a0),a1 ;Puffer für dunkle Farbwerte
  move.l  extra_memory(a3),a2
  add.l   #em_color_table,a2 ;Zeiger auf Farbtabelle
  lea     bf_colors_number*LONGWORDSIZE*2(a2),a4 ;Ziel: Ende der Bar-Farbtabelle
  MOVEF.W (bf_colors_number/2)-1,d7 ;Anzahl der Farben
bf_convert_color_table_loop
  move.l  (a0)+,d0           ;RGB8-Farbwert
  move.l  d0,d2              
  RGB8_TO_RGB4HI d0,d1,d5
  move.w  d0,(a2)+           ;COLORxx High-Bits
  RGB8_TO_RGB4LO d2,d1,d5
  move.w  d2,(a2)+           ;Low-Bits COLORxx

  move.l  (a1)+,d3           ;RGB8-Farbwert
  move.l  d3,d4              
  RGB8_TO_RGB4HI d3,d1,d5
  move.w  d3,(a2)+           ;COLORxx High-Bits
  RGB8_TO_RGB4LO d4,d1,d5
  move.w  d4,(a2)+           ;Low-Bits COLORxx

  move.w  d4,-(a4)           ;Low-Bits COLORxx
  move.w  d3,-(a4)           ;COLORxx High-Bits
  move.w  d2,-(a4)           ;Low-Bits COLORxx
  move.w  d0,-(a4)           ;COLORxx High-Bits
  dbf     d7,bf_convert_color_table_loop
  tst.w   bf_colors_counter(a3) ;Fading beendet ?
  bne.s   bf_proceed_convert_color_table ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,bf_convert_colors_state(a3) ;Konvertieren beendet
bf_proceed_convert_color_table
  move.l  (a7)+,a4
bf_no_convert_color_table
  rts

; ** Logo von unten einscrollen **
; --------------------------------
  CNOP 0,4
scroll_logo_bottom_in
  tst.w   slbi_state(a3)     ;Scroll-Logo-Bottom-In an ?
  bne.s   no_scroll_logo_bottom_in  ;Nein -> verzweige
  move.w  slbi_y_angle(a3),d2 ;Y-Winkel
  cmp.w   #sine_table_length/4,d2 ;90 Grad erreicht ?
  bgt.s   slbi_finished      ;Ja -> verzweige
  move.l  a4,-(a7)
  lea     sine_table,a0
  move.l  (a0,d2.w*4),d0     ;sin(w)
  MULUF.L slb_y_radius*2,d0,d1 ;y'=yr*cos(w)/2^16
  swap    d0
  add.w   #slb_y_center,d0
  MOVEF.W lg_image_y_position,d5
  add.w   d0,d5              ;Y-Zentrierung
  addq.w  #slbi_y_angle_speed,d2 ;nächster Y-Winkel
  move.w  d2,slbi_y_angle(a3)
  bsr.s   slb_scroll_logo
  move.l  (a7)+,a4
no_scroll_logo_bottom_in
  rts
  CNOP 0,4
slbi_finished
  moveq   #FALSE,d0
  move.w  d0,slbi_state(a3)  ;Scroll-Logo-Bottom-In aus
  rts

; ** Logo nach unten ausscrollen **
; ---------------------------------
  CNOP 0,4
scroll_logo_bottom_out
  tst.w   slbo_state(a3)     ;Scroll-Logo-Bottom-Out an ?
  bne.s   no_scroll_logo_bottom_out ;Nein -> verzweige
  move.w  slbo_y_angle(a3),d2 ;Y-Winkel
  cmp.w   #sine_table_length/2,d2 ;180 Grad erreicht ?
  bgt.s   slbo_finished      ;Ja -> verzweige
  move.l  a4,-(a7)
  lea     sine_table,a0      
  move.l  (a0,d2.w*4),d0     ;sin(w)
  MULUF.L slb_y_radius*2,d0,d1 ;y'=yr*cos(w)/2^16
  swap    d0
  add.w   #slb_y_center,d0
  MOVEF.W lg_image_y_position,d5
  add.w   d0,d5              ;Y-Zentrierung
  addq.w  #slbi_y_angle_speed,d2 ;nächster Y-Winkel
  move.w  d2,slbo_y_angle(a3)
  bsr.s   slb_scroll_logo
  move.l  (a7)+,a4
no_scroll_logo_bottom_out
  rts
  CNOP 0,4
slbo_finished
  moveq   #FALSE,d0
  move.w  d0,slbo_state(a3) ;Scroll-Logo-Bottom-Out aus
  rts

  CNOP 0,4
slb_scroll_logo
  MOVEF.W lg_image_x_position*4,d4 ;X
  MOVEF.W lg_image_y_size,d6 ;Höhe
  add.w   d5,d6              ;Höhe zu Y addieren
  lea     spr_pointers_display(pc),a2 ;Zeiger auf Sprites
  move.w  #spr_x_size2*4,a4
  moveq   #(spr_used_number/2)-1,d7 ;Anzahl der Attached-Sprites
slb_scroll_logo_loop
  move.w  d4,d0              ;HSTART
  move.w  d5,d1              ;VSTART
  move.w  d6,d2              ;VSTOP
  move.l  (a2)+,a0           ;1. Sprite-Struktur
  move.l  (a2)+,a1           ;2. Sprite-Struktur
  SET_SPRITE_POSITION_V9 d0,d1,d2,d3
  move.w  d1,(a0)            ;SPRPOS
  move.w  d1,(a1)            ;SPRPOS
  add.w   a4,d4              ;nächste Sprite-X-Position
  move.w  d2,spr_pixel_per_datafetch/8(a0) ;SPRCTL
  tas     d2                 ;Attached-Bit setzen
  move.w  d2,spr_pixel_per_datafetch/8(a1) ;SPRCTL
  dbf     d7,slb_scroll_logo_loop
  rts

; ** Spalten einblenden **
; ------------------------
  CNOP 0,4
chunky_columns_fader_in
  tst.w   ccfi_state(a3)     ;Chunky-Columns-Fader-In an ?
  bne.s   ccfi_no_chunky_columns_fader_in ;Nein -> verzweige
  subq.w  #ccfi_delay_speed,ccfi_columns_delay_counter(a3) ;Verzögerungszähler herunterzählen
  bne.s   ccfi_no_chunky_columns_fader_in ;Wenn > Null -> verzweige
  moveq   #ccfi_columns_delay,d2
  move.w  d2,ccfi_columns_delay_counter(a3) ;Verzögerungszähler zurücksetzen
  move.w  ccfi_start(a3),d1  ;Startwert in Spalten-Statustabelle
  moveq   #(cl2_display_width-1)-1,d2 ;Anzahl der Spalten
  lea     tb_fader_columns_mask(pc),a0 ;Tabelle mit Status der Spalten
  move.w  ccfi_current_mode(a3),d0 ;Fader-In-Modus 
  beq.s   ccfi_mode1_column_fader_in ;Wenn Fader-In-Modus1 -> verzweige
  subq.w  #1,d0              ;Fader-In-Modus2 ?
  beq.s   ccfi_mode2_column_fader_in ;Ja -> verzweige
  subq.w  #1,d0              ;Fader-In-Modus3 ?
  beq.s   ccfi_mode3_column_fader_in ;Ja -> verzweige
  subq.w  #1,d0              ;Fader-In-Modus4 ?
  beq.s   ccfi_mode4_column_fader_in ;Ja -> verzweige
ccfi_no_chunky_columns_fader_in
  rts
; ** Spalten von links nach rechts einblenden **
  CNOP 0,4
ccfi_mode1_column_fader_in
  clr.b   (a0,d1.w)          ;Spaltenstatus = TRUE (einblenden)
  addq.w  #1,d1              ;nächste Spalte
  cmp.w   d2,d1              ;Alle Spalten eingeblendet ?
  bgt.s   ccfi_finished      ;Ja -> verzweige
  move.w  d1,ccfi_start(a3)  ;neuen Startwert retten
  rts
; ** Spalten von rechts nach links einblenden **
  CNOP 0,4
ccfi_mode2_column_fader_in
  move.w  d1,d0              ;Startwert retten
  neg.w   d0                 ;Vorzeichen umdrehen
  addq.w  #1,d1              ;nächste Spalte
  clr.b   (cl2_display_width-1)-1(a0,d0.w) ;Spaltenstatus = TRUE (einblenden)
  cmp.w   d2,d1              ;Alle Spalten eingeblendet ?
  bgt.s   ccfi_finished      ;Ja -> verzweige
  move.w  d1,ccfi_start(a3)  ;neuen Startwert retten
  rts
; ** Spalten gleichzeitig von links und rechts zur Mitte hin einblenden **
  CNOP 0,4
ccfi_mode3_column_fader_in
  clr.b   (a0,d1.w)          ;Spaltenstatus = TRUE (einblenden)
  move.w  d1,d0              ;Startwert retten
  neg.w   d0                 ;Vorzeichen umdrehen
  addq.w  #1,d1              ;nächste Spalte
  lsr.w   #1,d2              ;Hälfte der Spalten = Mittelpunkt
  clr.b   (cl2_display_width-1)-1(a0,d0.w) ;Spaltenstatus = TRUE (einblenden)
  cmp.w   d2,d1              ;Alle Spalten eingeblendet ?
  bgt.s   ccfi_finished      ;Ja -> verzweige
  move.w  d1,ccfi_start(a3)  ;neuen Startwert retten
  rts
; ** Jede 2. Spalte gleichzeitig von links und rechts einblenden **
  CNOP 0,4
ccfi_mode4_column_fader_in
  clr.b   (a0,d1.w)          ;Spaltenstatus = TRUE (einblenden)
  move.w  d1,d0              ;Startwert retten
  neg.w   d0                 ;Vorzeichen umdrehen
  addq.w  #2,d1              ;übernächste Spalte
  clr.b   (cl2_display_width-1)-1(a0,d0.w) ;Spaltenstatus = TRUE (einblenden)
  cmp.w   d2,d1              ;Alle Spalten eingeblendet ?
  bgt.s   ccfi_finished      ;Ja -> verzweige
  move.w  d1,ccfi_start(a3)  ;neuen Startwert retten
  rts
  CNOP 0,4
ccfi_finished
  moveq   #FALSE,d0
  move.w  d0,ccfi_state(a3)  ;Chunky-Columns-Fader-In aus
  rts

; ** Spalten ausblenden **
; ------------------------
  CNOP 0,4
chunky_columns_fader_out
  tst.w   ccfo_state(a3)     ;Chunky-Columns-Fader-Out an ?
  bne.s   ccfo_no_chunky_columns_fader_out ;Ja -> verzweige
  subq.w  #ccfo_delay_speed,ccfo_columns_delay_counter(a3) ;Verzögerungszähler herunterzählen
  bne.s   ccfo_no_chunky_columns_fader_out ;Wenn > Null -> verzweige
  moveq   #ccfo_columns_delay,d2
  move.w  d2,ccfo_columns_delay_counter(a3) ;Verzögerungszähler zurücksetzen
  move.w  ccfo_start(a3),d1  ;Startwert out Spalten-Statustabelle
  moveq   #(cl2_display_width-1)-1,d2 ;Anzahl der Spalten
  lea     tb_fader_columns_mask(pc),a0 ;Tabelle mit Status der Spalten
  move.w  ccfo_current_mode(a3),d0 ;Fader-Out-Modus 
  beq.s   ccfo_mode1_column_fader_out ;Wenn Fader-Out-Modus1 -> verzweige
  subq.w  #1,d0              ;Fader-Out-Modus2 ?
  beq.s   ccfo_mode2_column_fader_out ;Ja -> verzweige
  subq.w  #1,d0              ;Fader-Out-Modus3 ?
  beq.s   ccfo_mode3_column_fader_out ;Ja -> verzweige
  subq.w  #1,d0              ;Fader-Out-Modus4 ?
  beq.s   ccfo_mode4_column_fader_out ;Ja -> verzweige
ccfo_no_chunky_columns_fader_out
  rts
; ** Spalten von links nach rechts ausblenden **
  CNOP 0,4
ccfo_mode1_column_fader_out
  moveq   #FALSE,d0
  move.b  d0,(a0,d1.w)       ;Spaltenstatus = FALSE (ausblenden)
  addq.w  #1,d1              ;nächste Spalte
  cmp.w   d2,d1              ;Alle Spalten eoutgeblendet ?
  bgt.s   ccfo_finished      ;Ja -> verzweige
  move.w  d1,ccfo_start(a3)  ;neuen Startwert retten
  rts
; ** Spalten von rechts nach links ausblenden **
  CNOP 0,4
ccfo_mode2_column_fader_out
  move.w  d1,d0              ;Startwert retten
  neg.w   d0                 ;Vorzeichen umdrehen
  addq.w  #1,d1              ;nächste Spalte
  moveq   #FALSE,d3
  move.b  d3,(cl2_display_width-1)-1(a0,d0.w) ;Spaltenstatus = FALSE (ausblenden)
  cmp.w   d2,d1              ;Alle Spalten ausgeblendet ?
  bgt.s   ccfo_finished      ;Ja -> verzweige
  move.w  d1,ccfo_start(a3)  ;neuen Startwert retten
  rts
; ** Spalten gleichzeitig von links und rechts zur Mitte hin ausblenden **
  CNOP 0,4
ccfo_mode3_column_fader_out
  not.b   (a0,d1.w)          ;Spaltenstatus = FALSE (ausblenden)
  move.w  d1,d0              ;Startwert retten
  neg.w   d0                 ;Vorzeichen umdrehen
  addq.w  #1,d1              ;nächste Spalte
  lsr.w   #1,d2              ;Hälfte der Spalten = Mittelpunkt
  moveq   #FALSE,d3
  move.b  d3,(cl2_display_width-1)-1(a0,d0.w) ;Spaltenstatus = FALSE (ausblenden)
  cmp.w   d2,d1              ;Alle Spalten eoutgeblendet ?
  bgt.s   ccfo_finished      ;Ja -> verzweige
  move.w  d1,ccfo_start(a3)  ;neuen Startwert retten
  rts
; ** Jede 2. Spalte gleichzeitig von links und rechts ausblenden **
  CNOP 0,4
ccfo_mode4_column_fader_out
  not.b   (a0,d1.w)          ;Spaltenstatus = FALSE (ausblenden)
  move.w  d1,d0              ;Startwert retten
  neg.w   d0                 ;Vorzeichen umdrehen
  addq.w  #2,d1              ;übernächste Spalte
  moveq   #FALSE,d3
  move.b  d3,(cl2_display_width-1)-1(a0,d0.w) ;Spaltenstatus = FALSE (ausblenden)
  cmp.w   d2,d1              ;Alle Spalten eoutgeblendet ?
  bgt.s   ccfo_finished      ;Ja -> verzweige
  move.w  d1,ccfo_start(a3)  ;neuen Startwert retten
  rts
  CNOP 0,4
ccfo_finished
  moveq   #FALSE,d0
  move.w  d0,ccfo_state(a3)  ;Chunky-Columns-Fader-Out aus
  rts


; ** Mouse-Handler **
; -------------------
  CNOP 0,4
mouse_handler
  btst    #CIAB_GAMEPORT0,CIAPRA(a4) ;Linke Maustaste gedrückt ?
  beq.s   mh_quit            ;Ja -> verzweige
  rts
  CNOP 0,4
mh_quit
  moveq   #FALSE,d1
  move.w  d1,pt_trigger_fx_state(a3) ;FX-Abfrage aus
  moveq   #TRUE,d0
  tst.w   hst_state(a3)      ;Scrolltext aktiv ?
  beq.s   mh_quit_with_scrolltext ;Ja -> verzweige
mh_quit_without_scrolltext
  move.w  d0,pt_fade_out_music_state(a3) ;Musik ausfaden
  cmp.w   #sine_table_length/4,slbi_y_angle(a3) ;90 Grad erreicht ?
  blt.s   mh_skip1           ;Ja -> verzweige
  move.w  d0,slbo_state(a3)  ;Scroll-Logo-Bottom-Out an
mh_skip1
  move.w  d0,ccfo_state(a3)  ;Chunky-Columns-Fader-Out an
  moveq   #1,d2
  move.w  d2,ccfo_columns_delay_counter(a3) ;Verzögerungszähler aktivieren
  move.w  #bf_colors_number*3,bf_colors_counter(a3)
  tst.w   ccfi_state(a3)     ;Chunky-Columns_Fader-In aktiv ?
  bne.s   mh_skip2           ;Nein -> verzeige
  move.w  d1,ccfi_state(a3)  ;Chunky-Columns-Fader-In aus
mh_skip2
  move.w  d0,bf_convert_colors_state(a3) ;Konvertieren der Farben an
  move.w  d0,bfo_state(a3)   ;Bar-Fader-Out an
  tst.w   bfi_state(a3)      ;Bar-Fader-In aktiv ?
  bne.s   mh_skip3           ;Nein -> verzeige
  move.w  d1,bfi_state(a3)   ;Bar-Fader-In aus
mh_skip3
  rts
  CNOP 0,4
mh_quit_with_scrolltext
  tst.w   hsl_state(a3)      ;Ist Horiz-Logo-Scroll bereits aktiv ?
  bne.s   mh_no_horiz_scroll_logo_stop ;Nein -> verzweige
  move.w  d0,hsl_stop_state(a3) ;Horiz-Logo-Scroll-Stop an
  move.w  #sine_table_length/2,hsl_stop_x_angle(a3) ;180 Grad
mh_no_horiz_scroll_logo_stop
  moveq   #hst_horiz_scroll_speed2,d2
  move.w  d2,hst_variable_horiz_scroll_speed(a3) ;Doppelte Geschwindigkeit für Laufschrift
  move.w  #hst_stop_text-hst_text,hst_text_table_start(a3) ;Scrolltext beenden
  move.w  d0,quit_state(a3)  ;Intro soll nach Text-Stopp beendet werden
  rts


; ## Interrupt-Routinen ##
; ------------------------
  
  INCLUDE "int-autovectors-handlers.i"

  IFEQ pt_ciatiming
; ** CIA-B timer A interrupt server **
; ------------------------------------
  CNOP 0,4
CIAB_TA_int_server
  ENDC

  IFNE pt_ciatiming
; ** Vertical blank interrupt server **
; -------------------------------------
  CNOP 0,4
VERTB_int_server
  ENDC

  IFEQ pt_music_fader
    bsr.s   pt_fade_out_music
    bra.s   pt_PlayMusic

; ** Musik ausblenden **
; ----------------------
    PT_FADE_OUT fx_state

    CNOP 0,4
  ENDC

; ** PT-replay routine **
; -----------------------
  IFD pt_v2.3a
    PT2_REPLAY pt_trigger_fx
  ENDC
  IFD pt_v3.0b
    PT3_REPLAY pt_trigger_fx
  ENDC

;--> 8xy "Not used/custom" <--
  CNOP 0,4
pt_trigger_fx
  tst.w   pt_trigger_fx_state(a3) ;Check enabled?
  bne.s   pt_no_trigger_fx   ;No -> skip
  move.b  n_cmdlo(a2),d0     ;Get command data x = Effekt y = TRUE/FALSE
  cmp.w   #$10,d0
  beq.s   pt_start_bar_fader_in
  cmp.b   #$20,d0
  beq.s   pt_start_scrolltext
  cmp.b   #$30,d0
  beq.s   pt_start_scroll_logo_bottom_in
  cmp.b   #$40,d0
  beq.s   pt_start_chunky_columns_fader_in
  cmp.b   #$50,d0
  beq.s   pt_toggle_stripes_y_movement
  cmp.b   #$60,d0
  beq.s   pt_start_horiz_logo_scroll
  cmp.b   #$61,d0
  beq.s   pt_stop_horiz_logo_scroll
  cmp.b   #$70,d0
  beq.s   pt_restart_scrolltext
pt_no_trigger_fx
  rts
  CNOP 0,4
pt_start_bar_fader_in
  move.w  #bf_colors_number*3,bf_colors_counter(a3)
  moveq   #TRUE,d0
  move.w  d0,bfi_state(a3)   ;Bar-Fader-In an
  move.w  d0,bf_convert_colors_state(a3) ;Konvertieren der Farben an
  rts
  CNOP 0,4
pt_start_scrolltext
  clr.w   hst_state(a3)      ;Laufschrift an
  rts
  CNOP 0,4
pt_start_scroll_logo_bottom_in
  clr.w   slbi_state(a3)     ;Scroll-Logo-Bottom-In an
  rts
  CNOP 0,4
pt_start_chunky_columns_fader_in
  clr.w   ccfi_state(a3)     ;Columns-Fader-In an
  moveq   #1,d2
  move.w  d2,ccfi_columns_delay_counter(a3) ;Verzögerungszähler aktivieren
  rts
  CNOP 0,4
pt_toggle_stripes_y_movement
  neg.w   sp_variable_stripes_y_angle_speed(a3) ;Richtung umkehren
  rts
  CNOP 0,4
pt_start_horiz_logo_scroll
  moveq   #TRUE,d0
  move.w  d0,hsl_state(a3)   ;log-bewegung an
  move.w  d0,hsl_start_state(a3) ;Horiz-Logo-Scroll an
  moveq   #sine_table_length/4,d2
  move.w  d2,hsl_start_x_angle(a3) ;90 Grad
  rts
  CNOP 0,4
pt_stop_horiz_logo_scroll
  clr.w   hsl_stop_state(a3) ;Horiz-Logo-Scroll beenden
  move.w  #sine_table_length/2,hsl_stop_x_angle(a3) ;180 Grad
  rts
  CNOP 0,4
pt_restart_scrolltext
  clr.w   hst_state(a3)   ;Laufschrift an
  move.w  #hst_restart_text-hst_text,hst_text_table_start(a3) ;Countdown überspringen
  rts

; ** CIA-B Timer B interrupt server **
  CNOP 0,4
CIAB_TB_int_server
  PT_TIMER_INTERRUPT_SERVER

; ** Level-6-Interrupt-Server **
; ------------------------------
  CNOP 0,4
EXTER_int_server
  rts

; ** Level-7-Interrupt-Server **
; ------------------------------
  CNOP 0,4
NMI_int_server
  rts


; ** Timer stoppen **
; -------------------

  INCLUDE "continuous-timers-stop.i"


; ## System wieder in Ausganszustand zurücksetzen ##
; --------------------------------------------------

  INCLUDE "sys-return.i"


; ## Hilfsroutinen ##
; -------------------

  INCLUDE "help-routines.i"


; ## Speicherstellen für Tabellen und Strukturen ##
; -------------------------------------------------

  INCLUDE "sys-structures.i"

; ** Farben des ersten Playfields **
; ----------------------------------
  CNOP 0,4
pf1_color_table
  DC.L COLOR00BITS
  DS.L pf1_colors_number-2
  DC.L COLOR255BITS

; ** Adressen der Sprites **
; --------------------------
spr_pointers_display
  DS.L spr_number

; ** Sinus / Cosinustabelle **
; ----------------------------
sine_table
  INCLUDE "sine-table-256x32.i"

; **** PT-Replay ****
; ** Tables for effect commands **
; --------------------------------
; ** "Invert Loop" **
  INCLUDE "music-tracker/pt-invert-table.i"

; ** "Vibrato/Tremolo" **
  INCLUDE "music-tracker/pt-vibrato-tremolo-table.i"

; ** "Arpeggio/Tone Portamento" **
  IFD pt_v2.3a
    INCLUDE "music-tracker/pt2-period-table.i"
  ENDC
  IFD pt_v3.0b
    INCLUDE "music-tracker/pt3-period-table.i"
  ENDC

; ** Temporary channel structures **
; ----------------------------------
  INCLUDE "music-tracker/pt-temp-channel-data-tables.i"

; ** Pointers to samples **
; -------------------------
  INCLUDE "music-tracker/pt-sample-starts-table.i"

; ** Pointers to priod tables for different tuning **
; ---------------------------------------------------
  INCLUDE "music-tracker/pt-finetune-starts-table.i"

; **** Volume-Meter ****
; Tabelle mit Ausschlägen und Y-Winkeln der einzelnen Kanäle **
; -------------------------------------------------------------
  CNOP 0,2
vm_audio_channel1_info
  DS.B vm_audchaninfo_SIZE

vm_audio_channel2_info
  DS.B vm_audchaninfo_SIZE

vm_audio_channel3_info
  DS.B vm_audchaninfo_SIZE

vm_audio_channel4_info
  DS.B vm_audchaninfo_SIZE

; **** Twisted-Bars ****
  CNOP 0,4
tb_colorfradients
  INCLUDE "Daten:Asm-Sources.AGA/FlexiTwister/colortables/Bars-Colorgradient.ct"

; ** YZ-Koordinatentabelle **
; ---------------------------
tb_yz_coordinates
  DS.W tb_bars_number*(cl2_display_width-1)*2

; ** Maske für die Spalten **
; ---------------------------
tb_fader_columns_mask
  REPT cl2_display_width-1
    DC.B FALSE
  ENDR

; **** Striped-Pattern ****
; ** Y-Koordinaten der Streifen **
; --------------------------------
  CNOP 0,2
sp_stripes_y_coordinates
  DS.W sp_stripe_height*sp_stripes_number

; ** Farboffsets **
; -----------------
sp_color_offsets_table
  DS.W sp_stripe_height*sp_stripes_number

; **** Horiz-Scrolltext ****
  CNOP 0,4
hst_color_gradient
  INCLUDE "Daten:Asm-Sources.AGA/FlexiTwister/colortables/Font-Colorgradient.ct"

; ** ASCII-Buchstaben **
; ----------------------
hst_ASCII
  DC.B "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.!?-'():\/ "
hst_ASCII_end
  EVEN

; ** Offsets der einzelnen Chars **
; ---------------------------------
  CNOP 0,2
hst_characters_offsets
  DS.W hst_ASCII_end-hst_ASCII
  
; ** X-Koordinaten der einzelnen Chars der Laufschrift **
; -------------------------------------------------------
hst_characters_x_positions
  DS.W hst_text_characters_number

; ** Tabelle für Char-Image-Adressen **
; -------------------------------------
  CNOP 0,4
hst_characters_image_pointers
  DS.L hst_text_characters_number

; **** Bar-Fader ****
; ** Zielfarbwerte für Bar-Fader-In **
; ------------------------------------
  CNOP 0,4
bfi_color_table
  INCLUDE "Daten:Asm-Sources.AGA/FlexiTwister/colortables/Striped-Bar-Colorgradient.ct"

; ** Zielfarbwerte für Bar-Fader-Out **
; -------------------------------------
bfo_color_table
  REPT ssb_bar_height
    DC.L COLOR00BITS
  ENDR

; ** Puffer für Farbwerte **
; --------------------------
bf_color_cache
  REPT ssb_bar_height
    DC.L COLOR00BITS
  ENDR


; ## Speicherstellen allgemein ##
; -------------------------------

  INCLUDE "sys-variables.i"


; ## Speicherstellen für Namen ##
; -------------------------------

  INCLUDE "sys-names.i"


; ## Speicherstellen für Texte ##
; -------------------------------

  INCLUDE "error-texts.i"

; **** Horiz-Scrolltext ****
; ** Text für Laufschrift **
; --------------------------
hst_text
  REPT hst_text_characters_number/(hst_origin_character_x_size/hst_text_character_x_size)
    DC.B " "
  ENDR
  DC.B "3     2     1          "

hst_restart_text
  DC.B " RESISTANCE PROUDLY PRESENTS THEIR CONTRIBUTION TO GERP 2025 AS AN INTRO CALLED  -FLEXI TWISTER-           "

  DC.B "YES!  THIS IS PURE RASTER MANIA!  CHECKOUT THE SPRITES!  THE LOGO IS A CLUSTER OF EIGHT ATTACHED SPRITES DISPLAYED ON AN OVERSCAN SCREEN WITHOUT RESTRICSTIONS!           "

  REPT (hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size)
    DC.B " "
  ENDR

  DC.B "GREETINGS GO TO  "
  DC.B "-DESIRE-  "
  DC.B "-EPHIDRENA-  "
  DC.B "-FOCUS DESIGN-  "
  DC.B "-GHOSTOWN-  "
  DC.B "-NAH-KOLOR-  "
  DC.B "-PLANET JAZZ-  "
  DC.B "-SOFTWARE FAILURE-  "
  DC.B "-TEK-  "
  DC.B "-WANTED TEAM-  "

  REPT (hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size)
    DC.B " "
  ENDR

  DC.B "THE CREDITS FOR THIS INTRO           "

  DC.B "CODING AND MUSIC BY  -DISSIDENT-           "
  DC.B "GRAPHICS BY  -NN-           "

  REPT (hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size)
    DC.B " "
  ENDR
  REPT (hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size)
    DC.B " "
  ENDR
  REPT (hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size)
    DC.B " "
  ENDR
  REPT (hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size)
    DC.B " "
  ENDR
  REPT (hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size)
    DC.B " "
  ENDR
  REPT (hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size)
    DC.B " "
  ENDR
  REPT (hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size)
    DC.B " "
  ENDR
  REPT (hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size)
    DC.B " "
  ENDR

  DC.B "SEE YOU IN ANOTHER PRODUCTION..."

hst_stop_text
  REPT ((hst_text_characters_number)/(hst_origin_character_x_size/hst_text_character_x_size))+1
    DC.B " "
  ENDR
  DC.B ASCII_CTRL_S," "
  EVEN


; ** Programmversion für Version-Befehl **
; ----------------------------------------
prg_version DC.B "$VER: RSE-FlexiTwister 1.4 beta (2.6.24)",TRUE
  EVEN


; ## Audiodaten nachladen ##
; --------------------------

; **** PT-Replay ****
  IFEQ pt_split_module
pt_auddata SECTION pt_audio,DATA
    INCBIN "Daten:Asm-Sources.AGA/FlexiTwister/modules/MOD.CatchyTune2ReRemix.song"
pt_audsmps SECTION pt_audio2,DATA_C
    INCBIN "Daten:Asm-Sources.AGA/FlexiTwister/modules/MOD.CatchyTune2ReRemix.smps"
  ELSE
pt_auddata SECTION pt_audio,DATA_C
    INCBIN "Daten:Asm-Sources.AGA/FlexiTwister/modules/mod.CatchyTune2ReRemix"
  ENDC


; ## Grafikdaten nachladen ##
; ---------------------------

; **** Horiz-Scrolltext ****
hst_image_data SECTION hst_gfx,DATA_C
  INCBIN "Daten:Asm-Sources.AGA/FlexiTwister/fonts/32x32x2-Font.rawblit"

; **** Logo *****
lg_image_data SECTION lg_gfx,DATA
  INCBIN "Daten:Asm-Sources.AGA/FlexiTwister/graphics/256x54x8x2-Resistance.rawblit"

  END
