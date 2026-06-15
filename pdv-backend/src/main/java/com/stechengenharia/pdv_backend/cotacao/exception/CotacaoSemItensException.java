package com.stechengenharia.pdv_backend.cotacao.exception;

public class CotacaoSemItensException extends RuntimeException {

    public CotacaoSemItensException(String referencia) {
        super("A cotação " + referencia + " não tem itens e não pode ser convertida em pedido.");
    }

    public CotacaoSemItensException(Long idCotacao) {
        super("A cotação " + idCotacao + " não tem itens e não pode ser convertida em pedido.");
    }
}