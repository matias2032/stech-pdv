package com.stechengenharia.pdv_backend.categoria.exception;

public class CategoriaNotFoundException extends RuntimeException {
    
    public CategoriaNotFoundException(String message) {
        super(message);
    }
    
    public CategoriaNotFoundException(Integer id) {
        super("Categoria não encontrada com ID: " + id);
    }
    
    public CategoriaNotFoundException(String message, Throwable cause) {
        super(message, cause);
    }
}