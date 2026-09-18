@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Foto - Interface View'
define view entity ZI_RefDocPhoto
  as select from zrefdoc_photo

  association to parent ZI_RefDoc as _RefDoc on $projection.RefDocUUID = _RefDoc.RefDocUUID
{
  key photo_uuid                 as PhotoUUID,
      refdoc_uuid                  as RefDocUUID,

      @Semantics.largeObject: {
        mimeType: 'MimeType',
        fileName: 'FileName',
        acceptableMimeTypes: [ 'image/jpeg', 'image/png', 'image/gif', 'image/heic' ]
      }
      photo                         as Photo,
      mime_type                      as MimeType,
      file_name                       as FileName,

      comment                          as Comment,

      @Semantics.user.createdBy: true
      created_by                        as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                         as CreatedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at               as LocalLastChangedAt,

      _RefDoc
}
