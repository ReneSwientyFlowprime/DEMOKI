@EndUserText.label: 'Belegart - Texte (Transport / Auslieferung / Handling Unit)'
define table entity ZRefDocTypeT {
  key ref_type   : abap.char(1) not null;
  key spras        : abap.lang not null;
  ref_type_text      : abap.char(60);
}
