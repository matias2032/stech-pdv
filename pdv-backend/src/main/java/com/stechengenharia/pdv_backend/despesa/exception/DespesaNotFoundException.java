package com.stechengenharia.pdv_backend.despesa.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class DespesaNotFoundException extends RuntimeException {

    public DespesaNotFoundException(Long id) {
        super("Despesa não encontrada com id: " + id);
    }
}