package com.stechengenharia.pdv_backend.cotacao.exception;

public class CotacaoJaConvertidaException extends RuntimeException {

    public CotacaoJaConvertidaException(String referencia) {
        super("A cotação " + referencia + " já foi convertida em pedido e não pode ser convertida novamente.");
    }

    public CotacaoJaConvertidaException(Long idCotacao) {
        super("A cotação " + idCotacao + " já foi convertida em pedido e não pode ser convertida novamente.");
    }
}