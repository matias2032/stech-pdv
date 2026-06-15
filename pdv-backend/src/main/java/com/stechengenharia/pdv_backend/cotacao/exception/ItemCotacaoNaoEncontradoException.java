package com.stechengenharia.pdv_backend.cotacao.exception;

public class ItemCotacaoNaoEncontradoException extends RuntimeException {

    public ItemCotacaoNaoEncontradoException(Long idItem, Long idCotacao) {
        super("Item " + idItem + " não encontrado na cotação " + idCotacao + ".");
    }
}