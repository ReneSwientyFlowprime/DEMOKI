"! <p class="shorttext synchronized" lang="en">Demo KI – EWM HU Movement</p>
"!
"! <p>This class provides a method to move a Handling Unit (HU) to a target
"! storage bin in SAP Extended Warehouse Management (EWM) by creating a
"! Warehouse Task (WT) with movement type 9999.</p>
"!
"! <h2>Key SAP EWM objects used</h2>
"! <ul>
"!   <li><strong>/SCWM/HU_READ_SINGLE</strong> – Function module to read a
"!       single HU header record (package /SCWM/HU).  Used to determine the
"!       current storage bin (LGPLA) of the HU so it can be set as the source
"!       position of the warehouse task.</li>
"!   <li><strong>/SCWM/TO_CREATE</strong> – Function module to create warehouse
"!       tasks (transfer orders) in EWM (package /SCWM/WT_CREATION). The
"!       caller fills the internal table CT_LTAP_VB with the desired WT lines
"!       and the FM creates the corresponding /SCWM/LTAP entries in the DB.</li>
"!   <li><strong>/SCWM/LTAP_VB</strong> – Structure that describes one warehouse
"!       task line (movement type BWLVS, source bin VLPLA, destination bin
"!       NLPLA, HU NLENR, etc.).</li>
"!   <li><strong>/SCWM/TT_LTAP_VB</strong> – Table type of /SCWM/LTAP_VB.</li>
"!   <li><strong>/SCWM/HUHDR</strong> – HU header structure containing the
"!       current warehouse and storage bin of the HU.</li>
"!   <li><strong>Movement type 9999</strong> – A generic / ad-hoc movement type
"!       in EWM that is used for unplanned HU relocations within the same
"!       warehouse. It must be configured in Customizing under
"!       EWM → Goods Movements → Define Movement Types.</li>
"! </ul>
CLASS zcl_demo_ki DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! <p class="shorttext synchronized" lang="en">Move HU to destination bin</p>
    "!
    "! <p>Creates a Warehouse Task with movement type 9999 that relocates the
    "! given Handling Unit from its current position to the specified
    "! destination storage bin.</p>
    "!
    "! @parameter iv_lgnum     | Warehouse number
    "! @parameter iv_huident   | Handling unit identification (licence plate)
    "! @parameter iv_lgpla_dest | Destination storage bin
    "! @parameter et_bapiret   | Return messages (type / id / number / message)
    METHODS move_hu
      IMPORTING
        iv_lgnum      TYPE /scwm/lgnum
        iv_huident    TYPE /scwm/huident
        iv_lgpla_dest TYPE /scwm/lgpla
      EXPORTING
        et_bapiret    TYPE bapirettab.

  PRIVATE SECTION.

    "! <p class="shorttext synchronized" lang="en">Append sy-message to return table</p>
    "! @parameter ct_bapiret | Return messages
    METHODS append_sy_message
      CHANGING
        ct_bapiret TYPE bapirettab.

ENDCLASS.


CLASS zcl_demo_ki IMPLEMENTATION.

  METHOD move_hu.
    "--------------------------------------------------------------------
    " Step 1 – Read the HU header to determine the current storage bin
    "--------------------------------------------------------------------
    DATA ls_huhdr TYPE /scwm/huhdr.

    CALL FUNCTION '/SCWM/HU_READ_SINGLE'
      EXPORTING
        iv_lgnum   = iv_lgnum
        iv_huident = iv_huident
      IMPORTING
        es_huhdr   = ls_huhdr
      EXCEPTIONS
        not_found  = 1
        OTHERS     = 2.

    IF sy-subrc <> 0.
      append_sy_message( CHANGING ct_bapiret = et_bapiret ).
      RETURN.
    ENDIF.

    "--------------------------------------------------------------------
    " Step 2 – Build the warehouse task request line
    " BWLVS 9999 = ad-hoc / unplanned HU relocation movement type
    "--------------------------------------------------------------------
    DATA lt_ltap_vb TYPE /scwm/tt_ltap_vb.

    APPEND VALUE /scwm/ltap_vb(
      lgnum  = iv_lgnum
      bwlvs  = '9999'          " Movement type: ad-hoc HU relocation
      vlpla  = ls_huhdr-lgpla  " Source bin – current position of the HU
      nlpla  = iv_lgpla_dest   " Destination bin – target position
      nlenr  = iv_huident      " HU to be moved (destination HU ident)
      tohu   = abap_true       " Mark WT as HU-relevant
    ) TO lt_ltap_vb.

    "--------------------------------------------------------------------
    " Step 3 – Create the warehouse task via standard EWM function module
    "--------------------------------------------------------------------
    CALL FUNCTION '/SCWM/TO_CREATE'
      EXPORTING
        iv_lgnum   = iv_lgnum
        iv_commit  = abap_true   " Perform DB commit after creation
      CHANGING
        ct_ltap_vb = lt_ltap_vb
      EXCEPTIONS
        OTHERS     = 1.

    IF sy-subrc <> 0.
      append_sy_message( CHANGING ct_bapiret = et_bapiret ).
      RETURN.
    ENDIF.

    " Report success
    APPEND VALUE #(
      type    = 'S'
      id      = '/SCWM/L3'
      number  = '000'
      message = |Warehouse task created for HU { iv_huident } → { iv_lgpla_dest }|
    ) TO et_bapiret.

  ENDMETHOD.


  METHOD append_sy_message.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
            INTO DATA(lv_text).
    APPEND VALUE #(
      type    = sy-msgty
      id      = sy-msgid
      number  = sy-msgno
      message = lv_text
      message_v1 = sy-msgv1
      message_v2 = sy-msgv2
      message_v3 = sy-msgv3
      message_v4 = sy-msgv4
    ) TO ct_bapiret.
  ENDMETHOD.

ENDCLASS.
