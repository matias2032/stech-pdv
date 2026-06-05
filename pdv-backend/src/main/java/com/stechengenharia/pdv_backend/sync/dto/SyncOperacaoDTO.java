package com.stechengenharia.pdv_backend.sync.dto;

import com.fasterxml.jackson.annotation.JsonAnyGetter;
import com.fasterxml.jackson.annotation.JsonAnySetter;
import lombok.Data;

import java.util.LinkedHashMap;
import java.util.Map;

@Data
public class SyncOperacaoDTO {

    private String entidade;   // cliente | marca | categoria | servico | produto | pedido
    private String operacao;   // CREATE | UPDATE | DELETE
    private String localId;    // UUID gerado no Flutter (CREATE); null em UPDATE/DELETE
    private Integer id;        // ID real do backend (UPDATE/DELETE)

    /** Payload dinâmico — campos variam por entidade */
    private Map<String, Object> payload = new LinkedHashMap<>();
}