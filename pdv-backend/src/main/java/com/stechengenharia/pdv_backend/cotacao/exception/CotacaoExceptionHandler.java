package com.stechengenharia.pdv_backend.cotacao.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.Instant;
import java.util.Map;

@RestControllerAdvice(basePackages = "com.stechengenharia.pdv_backend.cotacao")
public class CotacaoExceptionHandler {

    // ── 404 ───────────────────────────────────────────────────────────
    @ExceptionHandler(CotacaoNaoEncontradaException.class)
    public ResponseEntity<Map<String, Object>> handleNaoEncontrada(
            CotacaoNaoEncontradaException ex) {

        return resposta(HttpStatus.NOT_FOUND, ex.getMessage());
    }

    @ExceptionHandler(ItemCotacaoNaoEncontradoException.class)
    public ResponseEntity<Map<String, Object>> handleItemNaoEncontrado(
            ItemCotacaoNaoEncontradoException ex) {

        return resposta(HttpStatus.NOT_FOUND, ex.getMessage());
    }

    // ── 409 ───────────────────────────────────────────────────────────
    @ExceptionHandler(CotacaoJaConvertidaException.class)
    public ResponseEntity<Map<String, Object>> handleJaConvertida(
            CotacaoJaConvertidaException ex) {

        return resposta(HttpStatus.CONFLICT, ex.getMessage());
    }

    // ── 422 ───────────────────────────────────────────────────────────
    @ExceptionHandler(CotacaoNaoEditavelException.class)
    public ResponseEntity<Map<String, Object>> handleNaoEditavel(
            CotacaoNaoEditavelException ex) {

        return resposta(HttpStatus.UNPROCESSABLE_ENTITY, ex.getMessage());
    }

    @ExceptionHandler(CotacaoSemItensException.class)
    public ResponseEntity<Map<String, Object>> handleSemItens(
            CotacaoSemItensException ex) {

        return resposta(HttpStatus.UNPROCESSABLE_ENTITY, ex.getMessage());
    }

    @ExceptionHandler(CotacaoExpiradaException.class)
    public ResponseEntity<Map<String, Object>> handleExpirada(
            CotacaoExpiradaException ex) {

        return resposta(HttpStatus.UNPROCESSABLE_ENTITY, ex.getMessage());
    }

    // ── 400 — validações de argumento ─────────────────────────────────
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalArgument(
            IllegalArgumentException ex) {

        return resposta(HttpStatus.BAD_REQUEST, ex.getMessage());
    }

    // ── Utilitário ────────────────────────────────────────────────────
    private ResponseEntity<Map<String, Object>> resposta(HttpStatus status, String mensagem) {
        return ResponseEntity.status(status).body(Map.of(
                "timestamp", Instant.now().toString(),
                "status",    status.value(),
                "erro",      status.getReasonPhrase(),
                "mensagem",  mensagem
        ));
    }
}