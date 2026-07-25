// DocumentoFiscalRelacaoRepository.java
package com.stechengenharia.pdv_backend.pedido.repository;

import com.stechengenharia.pdv_backend.pedido.entity.DocumentoFiscalRelacao;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface DocumentoFiscalRelacaoRepository
        extends JpaRepository<DocumentoFiscalRelacao, Long> {

    List<DocumentoFiscalRelacao> findByIdDocumentoOrigemAndTipoRelacao(
            Integer idDocumentoOrigem, String tipoRelacao);

    List<DocumentoFiscalRelacao> findByIdDocumentoRelacionadoAndTipoRelacao(
            Integer idDocumentoRelacionado, String tipoRelacao);
}