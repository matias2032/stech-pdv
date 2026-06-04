// lib/core/constants/constantes_fiscais.dart

/// Código atribuído pela Autoridade Tributária de Moçambique
/// que identifica este software emissor de documentos fiscais.
/// NÃO alterar sem comunicação prévia à AT.
abstract final class FiscalConstants {
  static const String codigoAT = 'STECH-MZ-2026-XXXX'; // ← substitui pelo real

  // Prefixos por tipo de documento
  static const Map<TipoDocumentoFiscal, String> prefixos = {
    TipoDocumentoFiscal.factura:       'FAT',
    TipoDocumentoFiscal.cotacao:       'COT',
    TipoDocumentoFiscal.recibo:        'REC',
    TipoDocumentoFiscal.notaDeCompra:  'NCO',
  };

  // IVA vigente em Moçambique
  static const double taxaIva = 0.16;
}

enum TipoDocumentoFiscal { factura, cotacao, recibo, notaDeCompra }