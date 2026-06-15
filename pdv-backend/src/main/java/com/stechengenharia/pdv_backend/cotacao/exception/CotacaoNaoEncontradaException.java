package com.stechengenharia.pdv_backend.cotacao.exception;

public class CotacaoNaoEncontradaException extends RuntimeException {

    public CotacaoNaoEncontradaException(Long idCotacao) {
        super("Cotação não encontrada com o ID: " + idCotacao);
    }

    public CotacaoNaoEncontradaException(String referencia) {
        super("Cotação não encontrada com a referência: " + referencia);
    }
}