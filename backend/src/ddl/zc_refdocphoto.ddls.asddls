@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Foto - Projection View'
define view entity ZC_RefDocPhoto
  as projection on ZI_RefDocPhoto
{
  key PhotoUUID,
      RefDocUUID,

      Photo,
      MimeType,
      FileName,
      Comment,

      CreatedBy,
      CreatedAt,
      LocalLastChangedAt,

      _RefDoc : redirected to parent ZC_RefDoc
}
