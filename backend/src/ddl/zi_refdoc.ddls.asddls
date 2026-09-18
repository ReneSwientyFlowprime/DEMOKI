@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Referenzbeleg - Interface View'
define root view entity ZI_RefDoc
  as select from zrefdoc_h

  composition [0..*] of ZI_RefDocPhoto as _Photo
  association [0..1] to ZI_RefDocType  as _RefDocType on $projection.ReferenceType = _RefDocType.ReferenceType
{
  key refdoc_uuid               as RefDocUUID,
      ref_type                   as ReferenceType,
      ref_number                  as ReferenceNumber,

      @Semantics.user.createdBy: true
      created_by                   as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                    as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by                as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at                 as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at            as LocalLastChangedAt,

      /* Associations */
      _Photo,
      _RefDocType
}
