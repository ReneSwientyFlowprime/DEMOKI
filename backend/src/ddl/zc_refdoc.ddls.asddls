@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Referenzbeleg - Fotos hochladen'
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_RefDoc
  provider contract transactional_query
  as projection on ZI_RefDoc
{
  key RefDocUUID,

      @Search.defaultSearchElement: true
      ReferenceType,
      @Search.defaultSearchElement: true
      ReferenceNumber,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,

      /* Associations */
      _Photo : redirected to composition child ZC_RefDocPhoto,
      _RefDocType
}
