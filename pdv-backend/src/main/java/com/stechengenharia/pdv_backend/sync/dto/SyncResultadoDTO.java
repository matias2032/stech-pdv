package com.stechengenharia.pdv_backend.sync.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SyncResultadoDTO {

    private String  localId;
    private String  entidade;
    private String  operacao;
    private boolean sucesso;
    private Integer idReal;   // preenchido em CREATE com sucesso
    private String  erro;     // mensagem em caso de falha
}