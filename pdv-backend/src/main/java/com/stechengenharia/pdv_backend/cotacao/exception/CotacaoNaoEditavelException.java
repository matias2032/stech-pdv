package com.stechengenharia.pdv_backend.cotacao.exception;

public class CotacaoNaoEditavelException extends RuntimeException {

    public CotacaoNaoEditavelException(String mensagem) {
        super(mensagem);
    }

    public CotacaoNaoEditavelException(Long idCotacao, String statusActual) {
        super("A cotação " + idCotacao + " está com status '"
                + statusActual + "' e não permite alterações.");
    }
}