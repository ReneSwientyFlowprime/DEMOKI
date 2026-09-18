@EndUserText.label: 'Referenzbeleg (Header)'
define table entity ZRefDoc {
  key refdoc_uuid        : abap.raw(16) not null;
  ref_type                : abap.char(1) not null;
  ref_number               : abap.char(20) not null;
  created_by                : abap.syuname;
  created_at                 : timestampl;
  last_changed_by             : abap.syuname;
  last_changed_at              : timestampl;
  local_last_changed_at         : timestampl;
}
