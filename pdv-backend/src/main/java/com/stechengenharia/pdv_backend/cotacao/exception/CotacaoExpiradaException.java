package com.stechengenharia.pdv_backend.cotacao.exception;

import java.time.LocalDate;

public class CotacaoExpiradaException extends RuntimeException {

    public CotacaoExpiradaException(String referencia, LocalDate validadeAte) {
        super("A cotação " + referencia + " expirou em "
                + validadeAte + " e não pode ser alterada ou convertida.");
    }
}