package com.stechengenharia.pdv_backend.servico.controller;

import com.stechengenharia.pdv_backend.servico.dto.ServicoRequestDTO;
import com.stechengenharia.pdv_backend.servico.dto.ServicoResponseDTO;
import com.stechengenharia.pdv_backend.servico.service.ServicoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Endpoints de gestão do catálogo de serviços.
 *
 * POST   /api/servicos              → criar
 * PUT    /api/servicos/{id}         → actualizar
 * PATCH  /api/servicos/{id}/toggle  → activar / desactivar
 * GET    /api/servicos/{id}         → buscar por id
 * GET    /api/servicos              → listar todos (activos + inactivos)
 * GET    /api/servicos/ativos       → listar apenas activos (para criação de pedido)
 */
@RestController
@RequestMapping("/api/servicos")
@RequiredArgsConstructor
public class ServicoController {

    private final ServicoService servicoService;

    // ─── Criar ───────────────────────────────────────────────────────────────

    /**
     * POST /api/servicos
     * Cria um novo serviço no catálogo. Activo por omissão.
     */
    @PostMapping
    public ResponseEntity<ServicoResponseDTO> criar(
            @Valid @RequestBody ServicoRequestDTO dto) {

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(servicoService.criar(dto));
    }

    // ─── Actualizar ──────────────────────────────────────────────────────────

    /**
     * PUT /api/servicos/{id}
     * Actualiza nome, descrição, preço e unidade.
     * Não altera o estado ativo — use /toggle para isso.
     */
    @PutMapping("/{id}")
    public ResponseEntity<ServicoResponseDTO> actualizar(
            @PathVariable Integer id,
            @Valid @RequestBody ServicoRequestDTO dto) {

        return ResponseEntity.ok(servicoService.actualizar(id, dto));
    }

    // ─── Toggle activo/inactivo ───────────────────────────────────────────────

    /**
     * PATCH /api/servicos/{id}/toggle
     * Inverte o estado ativo do serviço (true → false ou false → true).
     * Nunca elimina o registo — preserva histórico de pedidos.
     */
    @PatchMapping("/{id}/toggle")
    public ResponseEntity<ServicoResponseDTO> toggleAtivo(
            @PathVariable Integer id) {

        return ResponseEntity.ok(servicoService.toggleAtivo(id));
    }

    // ─── Buscar por id ────────────────────────────────────────────────────────

    /**
     * GET /api/servicos/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<ServicoResponseDTO> buscarPorId(
            @PathVariable Integer id) {

        return ResponseEntity.ok(servicoService.buscarPorId(id));
    }

    // ─── Listar todos (painel de gestão) ─────────────────────────────────────

    /**
     * GET /api/servicos
     * Devolve activos e inactivos ordenados por nome.
     * Destinado ao painel de administração.
     */
    @GetMapping
    public ResponseEntity<List<ServicoResponseDTO>> listarTodos() {
        return ResponseEntity.ok(servicoService.listarTodos());
    }

    // ─── Listar apenas activos (criação de pedido) ───────────────────────────

    /**
     * GET /api/servicos/ativos
     * Devolve apenas os serviços activos.
     * Destinado ao ecrã de criação/edição de pedido no frontend.
     */
    @GetMapping("/ativos")
    public ResponseEntity<List<ServicoResponseDTO>> listarAtivos() {
        return ResponseEntity.ok(servicoService.listarAtivos());
    }
}