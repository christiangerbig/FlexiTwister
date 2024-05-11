; ###############################
; # Programm: flexi-twister.asm #
; # Autor:    Christian Gerbig  #
; # Datum:    29.01.2024        #
; # Version:  1.0 Beta          #
; # CPU:      68020+            #
; # FASTMEM:  -                 #
; # Chipset:  AGA               #
; # OS:       3.0+              #
; ###############################

; V.1.0 beta
; Ertes Release


; Ausführungszeit 68020: n Rasterzeilen

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

color_gradient_rgb8
open_border                    EQU TRUE

pt_v3.0b
pt_ciatiming                   EQU TRUE
pt_usedfx                      EQU %1111010000001000
pt_usedefx                     EQU %0000100000000000
pt_finetune                    EQU FALSE
  IFD pt_v3.0b
pt_metronome                   EQU FALSE
  ENDC
pt_track_channel_volumes                 EQU TRUE
pt_track_channel_periods              EQU FALSE
pt_music_fader                 EQU TRUE
pt_split_module                EQU FALSE

tb_quick_clear                 EQU TRUE
tb_restore_cl_by_cpu           EQU TRUE
tb_restore_cl_by_blitter       EQU FALSE

DMABITS                        EQU DMAF_BLITTER+DMAF_COPPER+DMAF_RASTER+DMAF_MASTER+DMAF_SETCLR

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

spr_number                     EQU 0
spr_x_size1                    EQU 0
spr_y_size1                    EQU 0
spr_x_size2                    EQU 0
spr_y_size2                    EQU 0
spr_depth                      EQU 0
spr_colors_number              EQU 0

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
BPLCON2BITS                    EQU TRUE
BPLCON3BITS1                   EQU TRUE
BPLCON3BITS2                   EQU BPLCON3BITS1+BPLCON3F_LOCT
BPLCON4BITS                    EQU TRUE
DIWHIGHBITS                    EQU (((display_window_HSTOP&$100)>>8)*DIWHIGHF_HSTOP8)+(((display_window_VSTOP&$700)>>8)*DIWHIGHF_VSTOP8)+(((display_window_HSTART&$100)>>8)*DIWHIGHF_HSTART8)+((display_window_VSTART&$700)>>8)
FMODEBITS                      EQU TRUE
COLOR00BITS                    EQU $001122
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

; **** PT-Replay ****
  IFD pt_v2.3a
    INCLUDE "music-tracker/pt2-equals.i"
  ENDC
  IFD pt_v3.0b
    INCLUDE "music-tracker/pt3-equals.i"
  ENDC

  IFEQ pt_music_fader
pt_fade_out_delay              EQU 2 ;Ticks
  ENDC

sine_table_length              EQU 256

; **** Volume-Meter ****
vm_source_channel              EQU 2 ;Nr. 0..3
vm_period_div                  EQU 26
vm_max_period_step             EQU 15

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

hst_horiz_scroll_window_x_size EQU visible_pixels_number+(hst_text_character_x_size*1)
hst_horiz_scroll_window_width  EQU hst_horiz_scroll_window_x_size/8
hst_horiz_scroll_window_y_size EQU hst_text_character_y_size
hst_horiz_scroll_window_depth  EQU hst_image_depth
hst_horiz_scroll_speed         EQU 3

hst_text_character_x_restart   EQU hst_horiz_scroll_window_x_size
hst_text_characters_number     EQU hst_horiz_scroll_window_x_size/hst_text_character_x_size

hst_text_x_position            EQU 0
hst_text_y_position            EQU (pf1_y_size3-hst_text_character_y_size)/2

hst_colorrun_height            EQU hst_text_character_y_size
hst_colorrun_y_pos             EQU (ssb_bar_height-hst_text_character_y_size)/2


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

pf1_bitplanes_x_offset         EQU 48
pf1_BPL1DAT_x_offset           EQU 32


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


; ** Konstanten für die Größe der Spritestrukturen **
; ---------------------------------------------------
spr0_x_size1       EQU spr_x_size1
spr0_y_size1       EQU 0
spr1_x_size1       EQU spr_x_size1
spr1_y_size1       EQU 0
spr2_x_size1       EQU spr_x_size1
spr2_y_size1       EQU 0
spr3_x_size1       EQU spr_x_size1
spr3_y_size1       EQU 0
spr4_x_size1       EQU spr_x_size1
spr4_y_size1       EQU 0
spr5_x_size1       EQU spr_x_size1
spr5_y_size1       EQU 0
spr6_x_size1       EQU spr_x_size1
spr6_y_size1       EQU 0
spr7_x_size1       EQU spr_x_size1
spr7_y_size1       EQU 0

spr0_x_size2       EQU spr_x_size2
spr0_y_size2       EQU 0
spr1_x_size2       EQU spr_x_size2
spr1_y_size2       EQU 0
spr2_x_size2       EQU spr_x_size2
spr2_y_size2       EQU 0
spr3_x_size2       EQU spr_x_size2
spr3_y_size2       EQU 0
spr4_x_size2       EQU spr_x_size2
spr4_y_size2       EQU 0
spr5_x_size2       EQU spr_x_size2
spr5_y_size2       EQU 0
spr6_x_size2       EQU spr_x_size2
spr6_y_size2       EQU 0
spr7_x_size2       EQU spr_x_size2
spr7_y_size2       EQU 0


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

; **** Horiz-Scrolltext ****
hst_image                  RS.L 1
hst_text_table_start       RS.W 1
hst_text_BLTCON0BITS       RS.W 1
hst_character_toggle_image RS.W 1
hst_text_y_offset          RS.W 1

; **** Twisted-Bars ****
tb_y_angle                 RS.W 1
tb_y_angle_step_angle      RS.W 1

; **** Sine-Striped-Bar ****
ssb_y_angle                RS.W 1

; **** Striped-Pattern ****
sp_stripes_y_angle         RS.W 1

variables_SIZE             RS.B 0


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

; **** Horiz-Scrolltext ****
  lea     hst_image_data,a0
  move.l  a0,hst_image(a3)
  moveq   #TRUE,d0
  move.w  d0,hst_text_table_start(a3)
  move.w  d0,hst_text_BLTCON0BITS(a3)
  move.w  d0,hst_character_toggle_image(a3)
  move.w  d0,hst_text_y_offset(a3)

; **** Twisted-Bars ****
  move.w  d0,tb_y_angle(a3)
  move.w  d0,tb_y_angle_step_angle(a3)

; **** Sine-Striped-Bar ****
  move.w  d0,ssb_y_angle(a3)

; **** Stripes-Pattern ****
  move.w  d0,sp_stripes_y_angle(a3)
  rts

; ** Alle Initialisierungsroutinen ausführen **
; ---------------------------------------------
  CNOP 0,4
init_all
  bsr.s   pt_DetectSysFrequ
  bsr.s   init_CIA_timers
  bsr     pt_InitRegisters
  bsr     pt_InitAudTempStrucs
  bsr     pt_ExamineSongStruc
  IFEQ pt_finetune
    bsr     pt_InitFtuPeriodTableStarts
  ENDC
  bsr     vm_init_audio_channel_info_structures
  bsr     tb_init_color_table
  bsr     ssb_init_color_table
  bsr     hst_init_color_table
  bsr     tb_init_mirror_switch_table
  bsr     get_channels_amplitudes
;  bsr     tb_get_yz_coordinates
  bsr     ssb_init_switch_table
  bsr     hst_init_characters_offsets
  bsr     hst_init_characters_x_positions
  bsr     hst_init_characters_images
  bsr     init_first_copperlist
  bsr     copy_first_copperlist
  bsr     init_second_copperlist
  bsr     copy_second_copperlist
  bra     swap_second_copperlist

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

; **** Twisted-Bars ****
; ** Farbtabelle initialisieren **
; --------------------------------
  CNOP 0,4
tb_init_color_table
  movem.l a4-a5,-(a7)
; COLOR00
; ** blau-weißer Farbverlauf **
  INIT_COLOR_GRADIENT_RGB8 $030323,$ffffff,color_values_number1-1,color_step1,pf1_color_table,pc,2,2
; ** rot-weißer Farbverlauf **
  INIT_COLOR_GRADIENT_RGB8 $230303,$ffffff,color_values_number1
; ** grauer Farbverlauf **
  INIT_COLOR_GRADIENT_RGB8 $030303,$ffffff,color_values_number1
; COLOR001
; ** blau-weißer Farbverlauf **
  INIT_COLOR_GRADIENT_RGB8 $030323,$ffffff,color_values_number1-1,color_step1,pf1_color_table,pc,3,2
; ** rot-weißer Farbverlauf **
  INIT_COLOR_GRADIENT_RGB8 $230303,$ffffff,color_values_number1
; ** grauer Farbverlauf **
  INIT_COLOR_GRADIENT_RGB8 $030303,$ffffff,color_values_number1
  movem.l (a7)+,a4-a5
  rts

; **** Sine-Striped-Bar ****
; ** Farbtabelle initialisieren **
; --------------------------------
  CNOP 0,4
ssb_init_color_table
  movem.l a4-a5,-(a7)
; COLOR00
; ** violett-weißer Farbverlauf **
  INIT_COLOR_GRADIENT_RGB8 $230323,$ffffff,color_values_number2,color_step2.1,extra_memory,a3,em_color_table/4,2
  INIT_COLOR_GRADIENT_RGB8 $230323,$ffffff,color_values_number2,,extra_memory,a3,(em_color_table/4)+((color_values_number2+(color_values_number2-1))*2),-2
; ** dunkelblauer Farbverlauf **
  INIT_COLOR_GRADIENT_RGB8 $030323,$888888,color_values_number2,color_step2.2,extra_memory,a3,(em_color_table/4)+1,2
  INIT_COLOR_GRADIENT_RGB8 $030323,$888888,color_values_number2,,extra_memory,a3,(em_color_table/4)+1+((color_values_number2+(color_values_number2-1))*2),-2
  movem.l (a7)+,a4-a5
  rts

; **** Horiz-Scrolltext ****
; ** Farbtabelle initialisieren **
; --------------------------------
hst_init_color_table
  movem.l a4-a5,-(a7)
; COLOR01
; ** gelb-weißer Farbverlauf **
  INIT_COLOR_GRADIENT_RGB8 $232303,$ffffff,color_values_number3,color_step3,pf1_color_table,pc,1+(((color_values_number1*segments_number1)+hst_colorrun_y_pos+(color_values_number3-1))*2),-2
  movem.l (a7)+,a4-a5
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
  bsr.s   cl1_init_color_registers
  bsr     cl1_init_bitplane_pointers
  COPMOVEQ TRUE,COPJMP2
  rts

  COP_INIT_PLAYFIELD_REGISTERS cl1

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

  COPY_COPPERLIST cl1,2

; ** 2. Copperliste initialisieren **
; -----------------------------------
  CNOP 0,4
init_second_copperlist
  move.l  cl2_construction1(a3),a0 ;Aufbau-CL
  bsr.s   cl2_init_BPLCON4_registers
  bsr.s   cl2_init_copint
  COPLISTEND
  rts

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
  bsr.s   swap_first_copperlist
  bsr.s   swap_second_copperlist
  bsr.s   swap_playfield1
  bsr     tb_clear_second_copperlist
  bsr     cl2_update_BPL1DAT
  bsr     get_channels_amplitudes
  bsr     tb_get_yz_coordinates
  bsr     tb_set_background_bars
  bsr     make_striped_bar
  bsr     tb_set_foreground_bars
  bsr     sp_get_stripes_y_coordinates
  bsr     sp_make_color_offsets_table
  bsr     sp_make_pattern
  IFNE tb_quick_clear
    bsr     restore_second_copperlist
  ENDC
  bsr     horiz_scrolltext
  bsr     hst_horiz_scroll
  btst    #CIAB_GAMEPORT0,CIAPRA(a4) ;Auf linke Maustaste warten
  bne.s   beam_routines
  rts

; ** Copperlisten vertauschen **
; ------------------------------
  SWAP_COPPERLIST cl1,2

  SWAP_COPPERLIST cl2,3

; ** Playfields vertauschen **
; ------------------------
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
  move.l  pf1_display(a3),a0 ;Playfield
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
  move.w  n_period(a0),d0    ;Angespielte Periode holen
  moveq   #FALSE,d1          ;Zähler für Ergebnis
  move.b  d1,n_note_trigger(a0) ;Note Trigger Flag zurücksetzen
get_channel_amplitude_loop
  addq.w  #1,d1              ;Zähler erhöhen
  sub.w   d2,d0              ;Skalierung solange von Periode abziehen
  bge.s   get_channel_amplitude_loop ;bis Dividend < Divisor
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
  move.w  d4,d0              ;retten
  move.w  tb_y_angle_step_angle(a3),d5 ;1. Y-Step-Winkel
  add.b   (vm_audio_channel1_info+vm_aci_yanglespeed+1,pc,d1.w*2),d0 ;Y-Winkel erhöhen
  move.w  d0,tb_y_angle(a3) ;retten
  move.w  d5,d0
  add.b   (vm_audio_channel1_info+vm_aci_yanglestep+1,pc,d1.w*2),d0
  move.w  d0,tb_y_angle_step_angle(a3) ;retten
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
  move.w  d4,d2              ;Y-Winkel holen
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
  addq.w  #sp_stripes_y_angle_speed,d0 ;nächster Y-Winkel
  and.w   d5,d0              ;Überlauf entfernen
  move.w  d0,sp_stripes_y_angle(a3) ;retten
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
  move.w  d0,(a1)+           ;retten
  addq.w  #sp_stripes_y_angle_step,d2 ;nächster Y-Winkel
  and.w   d5,d2              ;Überlauf entfernen
  dbf     d7,sp_get_stripes_y_coordinates_loop
  rts

; ** Hintere Stangen in Copperliste kopieren **
; ---------------------------------------------
  SET_TWISTED_BACKGROUND_BARS.B tb,cl2,construction2,extension1,bar_height,extra_memory,a3,,45

; ** Hintergrundbar setzen **
; ---------------------------
  CNOP 0,4
make_striped_bar
  move.w  ssb_y_angle(a3),d1 ;Y-Winkel holen
  move.w  d1,d0              ;retten
  addq.w  #ssb_y_angle_speed,d0 ;nächster Y-Winkel
  and.w   #(sine_table_length/2)-1,d0 ;Überlauf entfernen
  move.w  d0,ssb_y_angle(a3) ;Y-Winkel retten
  lea     sine_table(pc),a0    
  move.l  (a0,d1.w*4),d0     ;sin(w)
  MULUF.L ssb_y_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  move.w  d0,d1              ;retten
  add.w   #ssb_y_radius,d0   ;y' + Y-Radius
  move.w  d0,hst_text_y_offset(a3) ;retten
  add.w   #ssb_y_center,d1   ;y' + Y-Mittelpunkt
  MULUF.W cl2_extension1_SIZE/4,d1,d0 ;Y*cl2_extension1_SIZE
  move.l  extra_memory(a3),a0
  add.l   #em_switch_table2,a0 ;Zeiger auf Tabelle mit Switchwerten
  move.l  cl2_construction2(a3),a1 ;CL
  ADDF.W (cl2_extension1_entry+cl2_ext1_BPLCON4_1+2),a1 ;CL
  lea     (a1,d1.w*4),a1     ;Y-Offset in CL
  move.w  #cl2_extension1_SIZE,a2
  moveq   #(ssb_bar_height)-1,d7 ;Höhe der Bar
make_striped_bar_loop
  move.b  (a0)+,d0           ;Switchwert holen
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
  SET_TWISTED_FOREGROUND_BARS.B tb,cl2,construction2,extension1,bar_height,extra_memory,a3,,45

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
  move.w  (a0)+,d0           ;Y-Offset holen
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
  ADDF.W  cl1_COLOR00_high4+2,a2 ;CL
  moveq   #ssb_bar_height-1,d7 ;Anzahl der Zeilen
sp_make_stripe_bar_loop
  move.w  (a0)+,d0           ;Farboffset holen
  move.l  (a1,d0.w*4),d0     ;24 Bit-Farbwert holen
  move.l  d0,d2              ;retten
  RGB8_TO_RGB4HI d0,d1,d3
  move.w  d0,(a2)            ;COLOR00 High-Bits
  RGB8_TO_RGB4LO d2,d1,d3
  move.w  d2,cl1_COLOR00_low1-cl1_COLOR00_high1(a2) ;COLOR00 Low-Bits
  addq.w  #8,a1              ;Nächster Farbwert in Farbtabelle
  addq.w  #8,a2              ;nächste Zeile in CL
  add.b   d5,d4              ;Farbregisterzähler erhöhen
  bne.s   sp_no_restart_registers_counter ;Wenn <> Null -> verzweige
  addq.w  #4,a2              ;CMOVE überspringen
sp_no_restart_registers_counter
  dbf     d7,sp_make_stripe_bar_loop
  rts

; ** Copper-WAIT-Befehle wiederherstellen **
; ------------------------------------------
  IFNE tb_quick_clear
    RESTORE_BPLCON4_CHUNKY_SCREEN tb,cl2,construction2,extension1,32
  ENDC

; ** Laufschrift **
; -----------------
  CNOP 0,4
horiz_scrolltext
  movem.l a4-a5,-(a7)
  bsr.s   hst_init_character_blit
  move.w  #(hst_text_character_y_size*hst_text_character_depth*64)+(hst_text_character_x_size/16),d4 ;BLTSIZE
  move.w  #hst_text_character_x_restart,d5
  lea     hst_characters_x_positions(pc),a0 ;X-Positionen der Chars
  lea     hst_characters_image_pointers(pc),a1 ;Zeiger auf Adressen der Chars-Images
  move.l  pf1_construction1(a3),a2 ;Playfield
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
  move.w  d0,d2              ;X retten
  lsr.w   #3,d0              ;X/8
  WAITBLITTER
  move.l  (a1)+,(a2)         ;Char-Image
  add.l   d3,d0              ;X-Offset
  move.l  d0,(a4)            ;Playfield
  move.w  d4,(a5)            ;Blitter starten
  subq.w  #hst_horiz_scroll_speed,d2 ;X-Position verringern
  bpl.s   hst_no_new_character_image ;Wenn positiv -> verzweige
hst_new_character_image
  move.l  a0,-(a7)
  bsr.s   hst_get_new_character_image
  move.l  d0,-4(a1)          ;Neues Bild für Character
  add.w   d5,d2              ;X-Pos Neustart
  move.l  (a7)+,a0
hst_no_new_character_image
  move.w  d2,(a0)+           ;X-Pos retten
  dbf     d7,horiz_scrolltext_loop
  movem.l (a7)+,a4-a5
  move.w  #DMAF_BLITHOG,DMACON-DMACONR(a6) ;BLTPRI aus
  rts

; ** konstante Blitterregister initialisieren **
; ----------------------------------------------
  CNOP 0,4
hst_init_character_blit
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
  move.w  d0,hst_text_BLTCON0BITS(a3) ;retten
  rts

; ** Neues Image für Character ermitteln **
; -----------------------------------------
  GET_NEW_CHARACTER_IMAGE hst

; ** Laufschrift bewegen **
; -------------------------
  CNOP 0,4
hst_horiz_scroll
  move.l  pf1_construction1(a3),a0
  WAITBLITTER
  move.l  (a0),a0
  move.w  hst_text_BLTCON0BITS(a3),BLTCON0-DMACONR(a6)
  add.l   #(hst_text_x_position/8)+(hst_text_y_position*pf1_plane_width*pf1_depth3),a0 ;Y-Zentrierung
  move.l  a0,BLTAPT-DMACONR(a6) ;Quelle
  addq.w  #2,a0              ;16 Pixel überspringen
  move.l  a0,BLTDPT-DMACONR(a6) ;Ziel
  move.l  #((pf1_plane_width-hst_horiz_scroll_window_width)<<16)+(pf1_plane_width-hst_horiz_scroll_window_width),BLTAMOD-DMACONR(a6) ;A-Mod + D-Mod
  move.w  #(hst_horiz_scroll_window_y_size*hst_horiz_scroll_window_depth*64)+(hst_horiz_scroll_window_x_size/16),BLTSIZE-DMACONR(a6) ;Blitter starten
  rts

  IFEQ pt_music_fader
; ** Mouse-Handler **
; -------------------
    CNOP 0,4
pt_mouse_handler
    btst    #POTINPB_DATLY,POTINP-DMACONR(a6) ;Rechte Mustaste gedrückt?
    bne.s   pt_no_mouse_handler ;Nein -> verzweige
    clr.w   pt_fade_out_music_state(a3) ;Fader an
pt_no_mouse_handler
    rts
  ENDC


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
    PT_FADE_OUT

    CNOP 0,4
  ENDC

; ** PT-replay routine **
; -----------------------
  IFD pt_v2.3a
    PT2_REPLAY
  ENDC
  IFD pt_v3.0b
    PT3_REPLAY
  ENDC

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

; ** Pionters to priod tables for different tuning **
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
; ** YZ-Koordinatentabelle **
; ------------------------
  CNOP 0,4
tb_yz_coordinates
  DS.W tb_bars_number*(cl2_display_width-1)*2

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
  DC.B "DISSIDENT IS PROUD TO PRESENT A NEW INTRO CALLED  -FLEXI TWISTER-           "

  DC.B "GREETINGS GO TO  ALL RESISTANCE MEMBERS  BIFAT  JASMIN68K           "

  DC.B "THE CREDITS FOR THIS INTRO           "

  DC.B "CODING AND MUSIC BY DISSIDENT           "
  DC.B "GRAPHICS BY NN           "

  DC.B FALSE
  EVEN

; ** Programmversion für Version-Befehl **
; ----------------------------------------
prg_version DC.B "$VER: rse_flexi-twister 1.0 beta (29.1.24)",TRUE
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

  END
