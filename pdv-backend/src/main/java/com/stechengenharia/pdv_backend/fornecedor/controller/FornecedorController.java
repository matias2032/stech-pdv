package com.stechengenharia.pdv_backend.fornecedor.controller;

import com.stechengenharia.pdv_backend.fornecedor.dto.FornecedorRequestDTO;
import com.stechengenharia.pdv_backend.fornecedor.dto.FornecedorResponseDTO;
import com.stechengenharia.pdv_backend.fornecedor.service.FornecedorService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/fornecedores")
@RequiredArgsConstructor
public class FornecedorController {

    private final FornecedorService fornecedorService;

    // ── GET /api/fornecedores ────────────────────────────────────────
    // ?q=texto → pesquisa por nome/email/contacto/nuit/morada
    // sem params → lista todos

    @GetMapping
    public ResponseEntity<List<FornecedorResponseDTO>> listar(
            @RequestParam(required = false) String q
    ) {
        if (q != null && !q.isBlank()) {
            return ResponseEntity.ok(fornecedorService.pesquisar(q));
        }

        return ResponseEntity.ok(fornecedorService.listarTodos());
    }

    // ── GET /api/fornecedores/{id} ───────────────────────────────────

    @GetMapping("/{id}")
    public ResponseEntity<FornecedorResponseDTO> buscarPorId(@PathVariable Long id) {
        return ResponseEntity.ok(fornecedorService.buscarPorId(id));
    }

    // ── POST /api/fornecedores ───────────────────────────────────────

    @PostMapping
    public ResponseEntity<FornecedorResponseDTO> criar(
            @Valid @RequestBody FornecedorRequestDTO dto
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(fornecedorService.criar(dto));
    }

    // ── PUT /api/fornecedores/{id} ───────────────────────────────────

    @PutMapping("/{id}")
    public ResponseEntity<FornecedorResponseDTO> editar(
            @PathVariable Long id,
            @Valid @RequestBody FornecedorRequestDTO dto
    ) {
        return ResponseEntity.ok(fornecedorService.editar(id, dto));
    }

    // ── DELETE /api/fornecedores/{id} ────────────────────────────────

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id) {
        fornecedorService.excluir(id);
        return ResponseEntity.noContent().build();
    }
}