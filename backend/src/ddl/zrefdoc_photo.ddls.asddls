@EndUserText.label: 'Foto zu Referenzbeleg'
define table entity ZRefDocPhoto {
  key photo_uuid           : abap.raw(16) not null;
  refdoc_uuid                : abap.raw(16) not null;
  file_name                   : abap.char(128);
  mime_type                    : abap.char(128);
  photo                         : abap.rawstring(0);
  comment                        : abap.string(0);
  created_by                      : abap.syuname;
  created_at                       : timestampl;
  local_last_changed_at             : timestampl;

  _RefDoc : association [1..1] to ZRefDoc on $projection.refdoc_uuid = _RefDoc.refdoc_uuid;
}
