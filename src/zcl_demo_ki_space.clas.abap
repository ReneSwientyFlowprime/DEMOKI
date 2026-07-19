"! <p class="shorttext synchronized" lang="en">Demo KI Space – Handling Unit Movement</p>
"!
"! <p>Creates a warehouse task (movement type 9999) to move a handling unit
"! to a target storage bin in SAP Extended Warehouse Management (EWM).</p>
"!
"! <h3>Sources used</h3>
"! <ul>
"!   <li><strong>EWM_DEV space – Warehouse Task Creation</strong>:
"!       Describes the standard function module <em>/SCWM/TO_CREATE</em>
"!       and the input structures <em>/SCWM/S_WHO_CREATE_INT</em> (header)
"!       and <em>/SCWM/S_WHR_CREATE_INT</em> (items).</li>
"!   <li><strong>EWM_DEV space – HU Stock Query</strong>:
"!       Describes the function module <em>/SCWM/HU_QUAN_GET</em> used to
"!       determine the current storage bin of a handling unit.</li>
"!   <li><strong>SAP Help Portal – EWM Warehouse Task API</strong>:
"!       Reference for movement type <em>BWLVS</em>, destination bin
"!       field <em>VLPLA</em>, and source bin field <em>NLPLA</em>.</li>
"! </ul>
CLASS zcl_demo_ki_space DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! <p class="shorttext synchronized" lang="en">Move handling unit to a target storage bin</p>
    "!
    "! Creates an EWM warehouse task with movement type 9999 that moves
    "! the given handling unit to the specified destination storage bin.
    "!
    "! @parameter iv_lgnum   | <p class="shorttext synchronized" lang="en">Warehouse number</p>
    "! @parameter iv_huident | <p class="shorttext synchronized" lang="en">Handling unit identification</p>
    "! @parameter iv_vlpla   | <p class="shorttext synchronized" lang="en">Destination storage bin</p>
    "! @raising   /scwm/cx_core | <p class="shorttext synchronized" lang="en">EWM core exception (errors in TO creation)</p>
    METHODS move_hu
      IMPORTING
        iv_lgnum   TYPE /scwm/lgnum
        iv_huident TYPE /scwm/huident
        iv_vlpla   TYPE /scwm/lgpla
      RAISING
        /scwm/cx_core.

  PROTECTED SECTION.
  PRIVATE SECTION.

    "! <p class="shorttext synchronized" lang="en">Movement type used for all warehouse tasks created by this class</p>
    CONSTANTS c_bwlvs TYPE /scwm/bwlvs VALUE '9999'.

    "! <p class="shorttext synchronized" lang="en">Get current storage bin of a handling unit</p>
    "!
    "! @parameter iv_lgnum   | <p class="shorttext synchronized" lang="en">Warehouse number</p>
    "! @parameter iv_huident | <p class="shorttext synchronized" lang="en">Handling unit identification</p>
    "! @parameter rv_nlpla   | <p class="shorttext synchronized" lang="en">Current (source) storage bin</p>
    "! @raising   /scwm/cx_core | <p class="shorttext synchronized" lang="en">HU not found or error reading stock</p>
    METHODS get_hu_source_bin
      IMPORTING
        iv_lgnum   TYPE /scwm/lgnum
        iv_huident TYPE /scwm/huident
      RETURNING
        VALUE(rv_nlpla) TYPE /scwm/lgpla
      RAISING
        /scwm/cx_core.

ENDCLASS.


CLASS zcl_demo_ki_space IMPLEMENTATION.

  METHOD move_hu.
    "--------------------------------------------------------------------
    " Step 1 – Determine current storage bin of the handling unit.
    "          Source: EWM_DEV space "HU Stock Query" section.
    "          The private helper calls /SCWM/HU_QUAN_GET and returns
    "          the LGPLA field of the first stock line found.
    "--------------------------------------------------------------------
    DATA(lv_nlpla) = get_hu_source_bin(
                       iv_lgnum   = iv_lgnum
                       iv_huident = iv_huident ).

    "--------------------------------------------------------------------
    " Step 2 – Build warehouse task header.
    "          Source: EWM_DEV space "Warehouse Task Creation" section.
    "          Structure /SCWM/S_WHO_CREATE_INT, field BWLVS = movement type.
    "--------------------------------------------------------------------
    DATA(ls_who) = VALUE /scwm/s_who_create_int(
                     lgnum = iv_lgnum
                     bwlvs = c_bwlvs ).

    DATA(lt_who) = VALUE /scwm/tt_who_create_int( ( ls_who ) ).

    "--------------------------------------------------------------------
    " Step 3 – Build warehouse task item.
    "          Source: EWM_DEV space "Warehouse Task Creation" section.
    "          /SCWM/S_WHR_CREATE_INT:
    "            HUIDENT – handling unit to move
    "            NLPLA   – source bin (current HU location)
    "            VLPLA   – destination bin
    "--------------------------------------------------------------------
    DATA(ls_whr) = VALUE /scwm/s_whr_create_int(
                     lgnum   = iv_lgnum
                     huident = iv_huident
                     nlpla   = lv_nlpla
                     vlpla   = iv_vlpla ).

    DATA(lt_whr) = VALUE /scwm/tt_whr_create_int( ( ls_whr ) ).

    "--------------------------------------------------------------------
    " Step 4 – Create the warehouse task via /SCWM/TO_CREATE.
    "          Source: EWM_DEV space "Warehouse Task Creation" section.
    "          IV_COMMIT = abap_true posts the TO immediately.
    "          Error messages are returned in TT_LOG (type E or A).
    "--------------------------------------------------------------------
    DATA: lt_wtask TYPE /scwm/tt_wtask,
          lt_log   TYPE /scwm/tt_ordim_msg.

    CALL FUNCTION '/SCWM/TO_CREATE'
      EXPORTING
        iv_lgnum  = iv_lgnum
        iv_commit = abap_true
      TABLES
        tt_who    = lt_who
        tt_whr    = lt_whr
        tt_wtask  = lt_wtask
        tt_log    = lt_log.

    "--------------------------------------------------------------------
    " Step 5 – Evaluate the application log returned by /SCWM/TO_CREATE.
    "          Any message of type E (Error) or A (Abort) is treated as
    "          a hard failure and raises the EWM core exception.
    "--------------------------------------------------------------------
    LOOP AT lt_log INTO DATA(ls_log)
      WHERE msgty CA 'EA'.
      RAISE EXCEPTION TYPE /scwm/cx_core
        MESSAGE ID   ls_log-msgid
                TYPE ls_log-msgty
                NUMBER ls_log-msgno
                WITH ls_log-msgv1 ls_log-msgv2
                     ls_log-msgv3 ls_log-msgv4.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_hu_source_bin.
    "--------------------------------------------------------------------
    " Source: EWM_DEV space "HU Stock Query" section.
    " /SCWM/HU_QUAN_GET returns a table of HU stock lines.
    " Each line carries LGPLA (current storage bin).
    " We read the first entry whose bin is not initial.
    "--------------------------------------------------------------------
    DATA: lt_huhdr TYPE /scwm/tt_huhdr_int,
          lt_huqty TYPE /scwm/tt_huqty_int.

    CALL FUNCTION '/SCWM/HU_QUAN_GET'
      EXPORTING
        iv_lgnum   = iv_lgnum
        iv_huident = iv_huident
      TABLES
        tt_huhdr   = lt_huhdr
        tt_huqty   = lt_huqty
      EXCEPTIONS
        not_found  = 1
        OTHERS     = 2.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE /scwm/cx_core.
    ENDIF.

    READ TABLE lt_huhdr INTO DATA(ls_huhdr)
      WITH KEY huident = iv_huident.

    IF sy-subrc <> 0 OR ls_huhdr-lgpla IS INITIAL.
      RAISE EXCEPTION TYPE /scwm/cx_core.
    ENDIF.

    rv_nlpla = ls_huhdr-lgpla.

  ENDMETHOD.

ENDCLASS.
