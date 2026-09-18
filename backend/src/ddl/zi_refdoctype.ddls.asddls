@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Belegart - Werthilfe'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_RefDocType
  as select from zrefdoc_typet
  where spras = $session.system_language
{
  key ref_type       as ReferenceType,
      ref_type_text    as ReferenceTypeText
}
