package com.stechengenharia.pdv_backend.fornecedor.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class FornecedorNotFoundException extends RuntimeException {

    public FornecedorNotFoundException(Long id) {
        super("Fornecedor não encontrado com o ID: " + id);
    }

    public FornecedorNotFoundException(String message) {
        super(message);
    }
}