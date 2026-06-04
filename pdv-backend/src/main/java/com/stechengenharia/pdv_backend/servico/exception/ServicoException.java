package com.stechengenharia.pdv_backend.servico.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Excepções específicas do módulo de serviços.
 * Agrupadas num único ficheiro para simplicidade.
 */
public final class ServicoException {

    private ServicoException() {}

    // ─── 404 ──────────────────────────────────────────────────────────────────

    @ResponseStatus(HttpStatus.NOT_FOUND)
    public static class ServicoNaoEncontradoException extends RuntimeException {
        public ServicoNaoEncontradoException(Integer id) {
            super("Serviço não encontrado: id=" + id);
        }
    }

    // ─── 409 ──────────────────────────────────────────────────────────────────

    @ResponseStatus(HttpStatus.CONFLICT)
    public static class ServicoNomeDuplicadoException extends RuntimeException {
        public ServicoNomeDuplicadoException(String nome) {
            super("Já existe um serviço com o nome: \"" + nome + "\"");
        }
    }

    // ─── 422 ──────────────────────────────────────────────────────────────────

    /**
     * Lançada pelo PedidoService quando tenta adicionar um serviço inactivo ao pedido.
     */
    @ResponseStatus(HttpStatus.UNPROCESSABLE_ENTITY)
    public static class ServicoInativoException extends RuntimeException {
        public ServicoInativoException(Integer id) {
            super("O serviço id=" + id + " está inactivo e não pode ser adicionado a um pedido.");
        }
    }
}