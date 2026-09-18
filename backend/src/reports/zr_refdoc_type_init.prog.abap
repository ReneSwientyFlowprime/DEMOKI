REPORT zr_refdoc_type_init.

"----------------------------------------------------------------------*
" Einmalig nach der Aktivierung von ZRefDocTypeT auszufuehren, um die
" Stammwerte fuer die Belegart (Transport / Auslieferung / Handling
" Unit) inklusive Sprachtexte anzulegen.
"----------------------------------------------------------------------*
START-OF-SELECTION.

  DATA(lt_types) = VALUE zrefdoc_typet(
    ( ref_type = 'T' spras = 'D' ref_type_text = 'Transport (LE-TRA)' )
    ( ref_type = 'D' spras = 'D' ref_type_text = 'Auslieferung (LE)' )
    ( ref_type = 'H' spras = 'D' ref_type_text = 'Handling Unit (EWM)' )
    ( ref_type = 'T' spras = 'E' ref_type_text = 'Shipment (LE-TRA)' )
    ( ref_type = 'D' spras = 'E' ref_type_text = 'Delivery (LE)' )
    ( ref_type = 'H' spras = 'E' ref_type_text = 'Handling unit (EWM)' ) ).

  MODIFY zrefdoc_typet FROM TABLE @lt_types.
  IF sy-subrc = 0.
    COMMIT WORK.
    WRITE: / 'Belegart-Texte wurden angelegt/aktualisiert.'.
  ELSE.
    WRITE: / 'Fehler beim Anlegen der Belegart-Texte.'.
  ENDIF.
